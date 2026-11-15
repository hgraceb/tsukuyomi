import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  test('Content languages retain their spelling, deduplicate and sort without guessing scripts', () {
    final values = ['zh', 'zh-Hans', 'pt-BR', 'zh-Hans', 'ja', 'es-419', 'zh-TW', 'de-1901', 'zh-Hant-HK', 'sl-rozaj-biske'];
    expect(normalizeMangaLanguages(values), [
      'de-1901',
      'es-419',
      'ja',
      'pt-BR',
      'sl-rozaj-biske',
      'zh',
      'zh-Hans',
      'zh-Hant-HK',
      'zh-TW',
    ]);
    expect(normalizeMangaLanguages([]), isEmpty);
  });

  test('Content languages reject malformed codes, underscores, whitespace and noncanonical casing', () {
    for (final value in [
      'chinese',
      '4',
      '',
      'zh--Hans',
      'en-US-US',
      'zh_Hans',
      'ZH_hans',
      'pt_BR',
      ' ja',
      'ja ',
      'ja\n',
      'ja\r\n',
      '\tja',
      'zh- Hans',
      'JA',
      'zh-hans',
      'zh-HANS',
      'pt-br',
      'pt-Br',
      'zh-Hant-hk',
      'sl-ROZAJ',
    ]) {
      expect(
        () => normalizeMangaLanguages(['en', value]),
        throwsA(isA<FormatException>().having((error) => error.source, 'source', value)),
        reason: jsonEncode(value),
      );
    }
  });

  test('Language normalization preserves standard special codes and unrecognized languages', () {
    expect(normalizeMangaLanguages(['all', 'und', 'mul', 'zxx', 'und-Latn', 'qaa', 'und']), [
      'all',
      'mul',
      'qaa',
      'und',
      'und-Latn',
      'zxx',
    ]);
  });

  test('Creators preserve source order and only serialize names', () {
    final creators = normalizeMangaCreators([
      const SourceMangaCreator(name: ' 甲 '),
      const SourceMangaCreator(name: '乙'),
      SourceMangaCreator.fromJson({'name': '甲'}),
    ]);
    expect(creators.map((value) => value.toJson()), [
      {'name': '甲'},
      {'name': '乙'},
    ]);
    expect(() => normalizeMangaCreators([const SourceMangaCreator(name: ' ')]), throwsFormatException);
  });

  test('Tag identity includes type and unknown classifications require explicit mapping', () {
    final tags = normalizeMangaTags([
      const SourceMangaTag(name: ' 冒险 ', type: SourceMangaTagType.category),
      const SourceMangaTag(name: '冒险', type: SourceMangaTagType.category),
      SourceMangaTag.fromJson({'name': '冒险', 'type': 'tag'}),
    ]);
    expect(tags.map((value) => value.toJson()), [
      {'name': '冒险', 'type': 'category'},
      {'name': '冒险', 'type': 'tag'},
    ]);
    for (final type in ['genre', 'theme', 'format', 'demographic', 'content', 'site-category']) {
      expect(() => SourceMangaTag.fromJson({'name': '冒险', 'type': type}), throwsArgumentError, reason: type);
    }
    expect(() => normalizeMangaTags([const SourceMangaTag(name: '', type: SourceMangaTagType.tag)]), throwsFormatException);
  });

  test('Status JSON uses stable string codes and rejects unsupported values', () {
    const values = {
      SourceMangaStatus.unknown: 'unknown',
      SourceMangaStatus.ongoing: 'ongoing',
      SourceMangaStatus.completed: 'completed',
      SourceMangaStatus.hiatus: 'hiatus',
      SourceMangaStatus.cancelled: 'cancelled',
    };
    for (final entry in values.entries) {
      expect(entry.key.toJson(), entry.value);
      expect(jsonEncode(entry.key), jsonEncode(entry.value));
      expect(SourceMangaStatus.fromJson(entry.value), same(entry.key));
    }
    for (final value in ['连载中', 'ONGOING', 'canceld', '']) {
      expect(() => SourceMangaStatus.fromJson(value), throwsArgumentError);
    }
  });

  test('Generated field conversions round-trip every tag type without adding fields', () {
    const values = {
      SourceMangaTagType.tag: 'tag',
      SourceMangaTagType.character: 'character',
      SourceMangaTagType.category: 'category',
      SourceMangaTagType.other: 'other',
    };
    for (final entry in values.entries) {
      final tag = SourceMangaTag(name: '标签', type: entry.key);
      final json = jsonDecode(jsonEncode(tag)) as Map<String, dynamic>;
      expect(json, {'name': '标签', 'type': entry.value});
      expect(SourceMangaTag.fromJson(json), tag);
      expect(SourceMangaTagType.fromJson(entry.value), same(entry.key));
      expect(entry.key.toJson(), entry.value);
    }
    const creator = SourceMangaCreator(name: '甲');
    final json = jsonDecode(jsonEncode(creator)) as Map<String, dynamic>;
    expect(json, {'name': '甲'});
    expect(SourceMangaCreator.fromJson(json), creator);
  });

  test('Generated decoding rejects missing and incorrectly typed required fields', () {
    expect(() => SourceMangaCreator.fromJson({}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaCreator.fromJson({'name': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaTag.fromJson({'name': '冒险'}), throwsArgumentError);
    expect(() => SourceMangaTag.fromJson({'name': '冒险', 'type': 0}), throwsArgumentError);
  });
}
