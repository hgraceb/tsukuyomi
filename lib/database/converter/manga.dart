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

class MangaCreatorsConverter extends TypeConverter<List<SourceMangaCreator>, String> {
  const MangaCreatorsConverter();

  @override
  List<SourceMangaCreator> fromSql(String fromDb) {
    final values = jsonDecode(fromDb) as List<dynamic>;
    return normalizeMangaCreators(values.map((value) => SourceMangaCreator.fromJson(value as Map<String, dynamic>)));
  }

  @override
  String toSql(List<SourceMangaCreator> value) => jsonEncode(normalizeMangaCreators(value));
}

class MangaTagsConverter extends TypeConverter<List<SourceMangaTag>, String> {
  const MangaTagsConverter();

  @override
  List<SourceMangaTag> fromSql(String fromDb) {
    final values = jsonDecode(fromDb) as List<dynamic>;
    return normalizeMangaTags(values.map((value) => SourceMangaTag.fromJson(value as Map<String, dynamic>)));
  }

  @override
  String toSql(List<SourceMangaTag> value) => jsonEncode(normalizeMangaTags(value));
}

class MangaLanguagesConverter extends TypeConverter<List<String>, String> {
  const MangaLanguagesConverter();

  @override
  List<String> fromSql(String fromDb) => normalizeMangaLanguages((jsonDecode(fromDb) as List<dynamic>).cast<String>());

  @override
  String toSql(List<String> value) => jsonEncode(normalizeMangaLanguages(value));
}
