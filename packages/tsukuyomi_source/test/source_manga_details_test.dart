import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  test('Content languages normalize casing, deduplicate and sort without guessing scripts', () {
    expect(normalizeMangaLanguages([' zh ', 'ZH_hans', 'pt-br', 'zh-Hans', 'JA', 'es-419', 'zh-TW', 'de-1901']), [
      'de-1901',
      'es-419',
      'ja',
      'pt-BR',
      'zh',
      'zh-Hans',
      'zh-TW',
    ]);
    expect(normalizeMangaLanguages([]), isEmpty);
    for (final value in ['chinese', '4', '', 'all', 'und', 'mul', 'zxx', 'zh--Hans', 'en-US-US']) {
      expect(() => normalizeMangaLanguages([value]), throwsFormatException, reason: value);
    }
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
