import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
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

  test('Generated field conversions round-trip every tag type, nullable roles and links', () {
    const values = {
      SourceMangaTagType.tag: 'tag',
      SourceMangaTagType.character: 'character',
      SourceMangaTagType.category: 'category',
      SourceMangaTagType.origin: 'origin',
      SourceMangaTagType.group: 'group',
      SourceMangaTagType.other: 'other',
    };
    for (final entry in values.entries) {
      final tag = SourceMangaTag(type: entry.key, name: 'Tag', id: '3269754496379892707');
      final json = jsonDecode(jsonEncode(tag)) as Map<String, dynamic>;
      expect(json, {'type': entry.value, 'name': 'Tag', 'id': '3269754496379892707', 'url': null});
      expect(json.keys, ['type', 'name', 'id', 'url']);
      expect(SourceMangaTag.fromJson(json), tag);
      expect(SourceMangaTagType.fromJson(entry.value), same(entry.key));
      expect(entry.key.toJson(), entry.value);
    }
    const author = SourceMangaAuthor(name: 'Alice', id: 'author-1');
    final json = jsonDecode(jsonEncode(author)) as Map<String, dynamic>;
    expect(json, {'name': 'Alice', 'role': null, 'id': 'author-1', 'url': null});
    expect(SourceMangaAuthor.fromJson(json), author);
    const unidentified = SourceMangaAuthor(name: 'Alice');
    expect(SourceMangaAuthor.fromJson({'name': 'Alice'}), unidentified);
    expect(SourceMangaAuthor.fromJson({'name': 'Alice', 'role': null, 'id': null, 'url': null}), unidentified);
    const tag = SourceMangaTag(type: SourceMangaTagType.tag, name: 'Tag');
    expect(SourceMangaTag.fromJson({'type': 'tag', 'name': 'Tag', 'url': null}), tag);
  });

  test('Generated decoding rejects missing required fields and incorrectly typed values', () {
    expect(() => SourceMangaAuthor.fromJson({}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaAuthor.fromJson({'name': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaAuthor.fromJson({'name': 'Alice', 'role': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaAuthor.fromJson({'name': 'Alice', 'id': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaAuthor.fromJson({'name': 'Alice', 'url': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaTag.fromJson({'name': 'Adventure'}), throwsArgumentError);
    expect(() => SourceMangaTag.fromJson({'type': 0, 'name': 'Adventure'}), throwsArgumentError);
    expect(() => SourceMangaTag.fromJson({'type': 'tag', 'name': 'Adventure', 'id': 1}), throwsA(isA<TypeError>()));
    expect(() => SourceMangaTag.fromJson({'type': 'tag', 'name': 'Adventure', 'url': 1}), throwsA(isA<TypeError>()));
    for (final type in ['genre', 'theme', 'format', 'demographic', 'content', 'site-category']) {
      expect(() => SourceMangaTag.fromJson({'type': type, 'name': 'Adventure'}), throwsArgumentError, reason: type);
    }
  });
}
