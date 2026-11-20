import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class MangaStatusConverter extends TypeConverter<SourceMangaStatus, String> {
  const MangaStatusConverter();

  @override
  SourceMangaStatus fromSql(String fromDb) => SourceMangaStatus.fromJson(fromDb);

  @override
  String toSql(SourceMangaStatus value) => value.toJson();
}

class MangaAuthorsConverter extends TypeConverter<List<SourceMangaAuthor>, String> {
  const MangaAuthorsConverter();

  @override
  List<SourceMangaAuthor> fromSql(String fromDb) {
    final values = jsonDecode(fromDb) as List<dynamic>;
    return _normalize(values.map((value) => SourceMangaAuthor.fromJson(value as Map<String, dynamic>)));
  }

  @override
  String toSql(List<SourceMangaAuthor> value) => jsonEncode(_normalize(value));

  List<SourceMangaAuthor> _normalize(Iterable<SourceMangaAuthor> values) {
    final authors = <SourceMangaAuthor>{};
    for (final value in values) {
      final name = value.name.trim();
      if (name.isEmpty) throw const FormatException('Empty manga author name');
      authors.add(value.copyWith(name: name));
    }
    return List.unmodifiable(authors);
  }
}

class MangaTagsConverter extends TypeConverter<List<SourceMangaTag>, String> {
  const MangaTagsConverter();

  @override
  List<SourceMangaTag> fromSql(String fromDb) {
    final values = jsonDecode(fromDb) as List<dynamic>;
    return _normalize(values.map((value) => SourceMangaTag.fromJson(value as Map<String, dynamic>)));
  }

  @override
  String toSql(List<SourceMangaTag> value) => jsonEncode(_normalize(value));

  List<SourceMangaTag> _normalize(Iterable<SourceMangaTag> values) {
    final tags = <SourceMangaTag>{};
    for (final value in values) {
      final name = value.name.trim();
      if (name.isEmpty) throw const FormatException('Empty manga tag name');
      tags.add(value.copyWith(name: name));
    }
    return List.unmodifiable(tags);
  }
}

class MangaLanguagesConverter extends TypeConverter<List<String>, String> {
  const MangaLanguagesConverter();

  @override
  List<String> fromSql(String fromDb) => _normalize((jsonDecode(fromDb) as List<dynamic>).cast<String>());

  @override
  String toSql(List<String> value) => jsonEncode(_normalize(value));

  List<String> _normalize(Iterable<String> values) {
    final pattern = RegExp(r'^[a-z]{2,3}(?:-[A-Z][a-z]{3})?(?:-(?:[A-Z]{2}|[0-9]{3}))?(?:-(?:[a-z0-9]{5,8}|[0-9][a-z0-9]{3}))*$');
    final languages = <String>{};
    for (final value in values) {
      if (pattern.stringMatch(value) != value) {
        throw FormatException('Invalid manga content language format; expected zh-Hans or pt-BR', value);
      }
      languages.add(value);
    }
    return List.unmodifiable(languages.toList()..sort());
  }
}
