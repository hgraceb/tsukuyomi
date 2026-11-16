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

  test('Creators preserve display text, links and source order when deduplicating', () {
    final creators = normalizeMangaCreators([
      const SourceMangaCreator(name: ' Alice (Writer) ', url: 'https://example.com/authors/1'),
      const SourceMangaCreator(name: 'Bob'),
      SourceMangaCreator.fromJson({'name': 'Alice (Writer)', 'url': 'https://example.com/authors/1'}),
      const SourceMangaCreator(name: 'Alice (Writer)', url: 'https://example.com/authors/2'),
    ]);
    expect(creators.map((value) => value.toJson()), [
      {'name': 'Alice (Writer)', 'url': 'https://example.com/authors/1'},
      {'name': 'Bob', 'url': null},
      {'name': 'Alice (Writer)', 'url': 'https://example.com/authors/2'},
    ]);
    expect(creators.map((value) => SourceMangaCreator.fromJson(value.toJson())), creators);
    expect(() => normalizeMangaCreators([const SourceMangaCreator(name: ' ')]), throwsFormatException);
  });

  test('Tags preserve distinct types and links when deduplicating', () {
    final tags = normalizeMangaTags([
      const SourceMangaTag(type: SourceMangaTagType.category, name: ' Adventure ', url: 'https://example.com/categories/1'),
      const SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', url: 'https://example.com/categories/1'),
      SourceMangaTag.fromJson({'type': 'tag', 'name': 'Adventure'}),
      const SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', url: 'https://example.com/categories/2'),
    ]);
    expect(tags.map((value) => value.toJson()), [
      {'type': 'category', 'name': 'Adventure', 'url': 'https://example.com/categories/1'},
      {'type': 'tag', 'name': 'Adventure', 'url': null},
      {'type': 'category', 'name': 'Adventure', 'url': 'https://example.com/categories/2'},
    ]);
    expect(tags.map((value) => SourceMangaTag.fromJson(value.toJson())), tags);
    expect(tags.first.toJson().keys, ['type', 'name', 'url']);
    for (final type in ['genre', 'theme', 'format', 'demographic', 'content', 'site-category']) {
      expect(() => SourceMangaTag.fromJson({'type': type, 'name': 'Adventure'}), throwsArgumentError, reason: type);
    }
    expect(() => normalizeMangaTags([const SourceMangaTag(type: SourceMangaTagType.tag, name: '')]), throwsFormatException);
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
    for (final value in ['In progress', 'ONGOING', 'canceld', '']) {
      expect(() => SourceMangaStatus.fromJson(value), throwsArgumentError);
    }
  });

  test('Generated field conversions round-trip every tag type and nullable links', () {
    const values = {
      SourceMangaTagType.tag: 'tag',
      SourceMangaTagType.character: 'character',
      SourceMangaTagType.category: 'category',
      SourceMangaTagType.other: 'other',
    };
    for (final entry in values.entries) {
      final tag = SourceMangaTag(type: entry.key, name: 'Tag');
      final json = jsonDecode(jsonEncode(tag)) as Map<String, dynamic>;
      expect(json, {'type': entry.value, 'name': 'Tag', 'url': null});
      expect(json.keys, ['type', 'name', 'url']);
      expect(SourceMangaTag.fromJson(json), tag);
      expect(SourceMangaTagType.fromJson(entry.value), same(entry.key));
      expect(entry.key.toJson(), entry.value);
    }
    const creator = SourceMangaCreator(name: 'Alice');
    final json = jsonDecode(jsonEncode(creator)) as Map<String, dynamic>;
    expect(json, {'name': 'Alice', 'url': null});
    expect(SourceMangaCreator.fromJson(json), creator);
    expect(SourceMangaCreator.fromJson({'name': 'Alice'}), creator);
    expect(SourceMangaCreator.fromJson({'name': 'Alice', 'url': null}), creator);
    expect(SourceMangaTag.fromJson({'type': 'tag', 'name': 'Tag', 'url': null}).url, isNull);
  });

  test('Generated decoding rejects missing required fields and incorrectly typed values', () {
    expect(() => SourceMangaCreator.fromJson({}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaCreator.fromJson({'name': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaCreator.fromJson({'name': 'Alice', 'url': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaTag.fromJson({'name': 'Adventure'}), throwsArgumentError);
    expect(() => SourceMangaTag.fromJson({'type': 0, 'name': 'Adventure'}), throwsArgumentError);
    expect(() => SourceMangaTag.fromJson({'type': 'tag', 'name': 'Adventure', 'url': 1}), throwsA(isA<TypeError>()));
  });
}
