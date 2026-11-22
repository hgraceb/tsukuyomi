import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/database/converter/manga.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  test('Authors are trimmed and deduplicated by name, role, ID and URL in source order on read and write', () {
    const converter = MangaAuthorsConverter();
    const writer = SourceMangaAuthor(name: 'Alice', role: 'Writer', url: '/authors/1');
    const other = SourceMangaAuthor(name: 'Bob');
    const artist = SourceMangaAuthor(name: 'Alice', role: 'Artist', url: '/authors/1');
    const linked = SourceMangaAuthor(name: 'Alice', role: 'Writer', url: '/authors/2');
    final identified = other.copyWith(id: 'author-2');
    final input = [writer.copyWith(name: ' Alice '), other, writer, artist, linked, identified, identified];
    final expected = [writer, other, artist, linked, identified];
    expect(converter.fromSql(jsonEncode(input)), expected);
    expect(converter.toSql(input), jsonEncode(expected));

    const invalid = [SourceMangaAuthor(name: ' ')];
    expect(() => converter.fromSql(jsonEncode(invalid)), throwsFormatException);
    expect(() => converter.toSql(invalid), throwsFormatException);
  });

  test('Tags are trimmed and deduplicated by name, type, ID and URL in source order on read and write', () {
    const converter = MangaTagsConverter();
    const category = SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', url: '/categories/1');
    const tag = SourceMangaTag(type: SourceMangaTagType.tag, name: 'Adventure');
    const linked = SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', url: '/categories/2');
    final identified = tag.copyWith(id: '2');
    final input = [category.copyWith(name: ' Adventure '), category, tag, linked, identified, identified];
    final expected = [category, tag, linked, identified];
    expect(converter.fromSql(jsonEncode(input)), expected);
    expect(converter.toSql(input), jsonEncode(expected));

    const invalid = [SourceMangaTag(type: SourceMangaTagType.tag, name: '')];
    expect(() => converter.fromSql(jsonEncode(invalid)), throwsFormatException);
    expect(() => converter.toSql(invalid), throwsFormatException);
  });

  test('Languages retain their spelling, deduplicate and sort on read and write', () {
    const converter = MangaLanguagesConverter();
    const input = ['zh', 'zh-Hans', 'pt-BR', 'zh-Hans', 'ja', 'es-419', 'zh-TW', 'de-1901', 'zh-Hant-HK', 'sl-rozaj-biske'];
    const expected = ['de-1901', 'es-419', 'ja', 'pt-BR', 'sl-rozaj-biske', 'zh', 'zh-Hans', 'zh-Hant-HK', 'zh-TW'];
    expect(converter.fromSql(jsonEncode(input)), expected);
    expect(converter.toSql(input), jsonEncode(expected));
    expect(converter.fromSql('[]'), isEmpty);
    expect(converter.toSql([]), '[]');
  });

  test('Languages preserve special and unrecognized codes on read and write', () {
    const converter = MangaLanguagesConverter();
    const input = ['all', 'und', 'mul', 'zxx', 'und-Latn', 'qaa', 'und'];
    const expected = ['all', 'mul', 'qaa', 'und', 'und-Latn', 'zxx'];
    expect(converter.fromSql(jsonEncode(input)), expected);
    expect(converter.toSql(input), jsonEncode(expected));
  });

  test('Languages reject malformed and noncanonical codes on read and write', () {
    const converter = MangaLanguagesConverter();
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
      final input = ['en', value];
      final error = throwsA(isA<FormatException>().having((error) => error.source, 'source', value));
      expect(() => converter.fromSql(jsonEncode(input)), error, reason: jsonEncode(value));
      expect(() => converter.toSql(input), error, reason: jsonEncode(value));
    }
  });
}
