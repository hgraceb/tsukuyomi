import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tsukuyomi/constants/assets.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

part 'mock.freezed.dart';
part 'mock.g.dart';

class MockDatabase {
  MockDatabase._({required this.sources, required this.mangas});

  final List<DatabaseSource> sources;

  final List<MangaTableCompanion> mangas;
}

@freezed
class MockSource with _$MockSource {
  const MockSource._();

  const factory MockSource({
    required String name,
    required String path,
    required bool enabled,
    required List<MockManga> mangas,
  }) = _MockSource;

  factory MockSource.fromJson(Map<String, dynamic> json) => _$MockSourceFromJson(json);

  int get id => name.hashCode;

  String get nameWithPath => '$name\n$path';
}

@freezed
class MockManga with _$MockManga {
  const MockManga._();

  const factory MockManga({
    @JsonKey(fromJson: _mangaIdFromJson) required int id, // ignore: invalid_annotation_target
    required String url,
    required String title,
    required String cover,
    SourceMangaStatus? status,
    String? description,
    List<SourceMangaCreator>? creators,
    List<SourceMangaTag>? tags,
    List<String>? languages,
    @Default(false) bool auto,
  }) = _MockManga;

  factory MockManga.fromJson(Map<String, dynamic> json) => _$MockMangaFromJson(json);

  MangaTableCompanion toInsertable(int source) {
    final manga = HttpSourceManga(
      url: url,
      name: title,
      cover: cover,
      status: status,
      description: description,
      creators: creators,
      tags: tags,
      languages: languages,
    );
    return manga
        .toInsertable(source)
        .copyWith(
          id: Value(id),
          title: Value(title),
          favorite: const Value(true),
          auto: Value(auto),
        );
  }
}

// 主键严格接受整数，避免截断小数后更新其他漫画
int _mangaIdFromJson(Object? value) => value as int;

Future<MockDatabase> getMockDatabase({AssetBundle? bundle}) async {
  final assets = bundle ?? rootBundle;
  final String index;
  try {
    index = await assets.loadString('assets/sources/index.json');
  } on FlutterError {
    return _getExampleDatabase(assets);
  }
  final List<MockSource> sources;
  final List<MangaTableCompanion> mangas;
  try {
    final decoded = jsonDecode(index) as List<dynamic>;
    sources = decoded.map((e) => MockSource.fromJson(e as Map<String, dynamic>)).where((e) => e.enabled).toList();
    mangas = [
      for (final source in sources) ...[
        for (final manga in source.mangas) manga.toInsertable(source.id),
      ],
    ];
  } catch (error, stackTrace) {
    Error.throwWithStackTrace(FormatException('Invalid assets/sources/index.json: $error'), stackTrace);
  }
  return MockDatabase._(
    sources: [
      for (final source in sources) ...[
        DatabaseSource(
          id: source.id,
          name: source.nameWithPath,
          source: base64.encode(utf8.encode(await assets.loadString(source.path))),
        ),
      ],
    ],
    mangas: mangas,
  );
}

Future<MockDatabase> _getExampleDatabase(AssetBundle assets) async {
  const mockSource = MockSource(name: 'Example Source', path: Assets.sourceExample, enabled: true, mangas: []);
  final sourceCode = base64.encode(utf8.encode(await assets.loadString(mockSource.path)));
  final databaseSource = DatabaseSource(id: mockSource.id, name: mockSource.nameWithPath, source: sourceCode);
  // TODO 使用更通用的方式获取示例漫画数据
  final mockManga = MangaTableCompanion.insert(
    id: const Value(0),
    source: mockSource.id,
    url: '16,74,176,213,218,266,381,385,404,461,477,481,516,603,609,626,640,657,715,716',
    title: 'Example Manga',
    cover: 'https://picsum.photos/id/384/800/1200',
    favorite: true,
  );
  return MockDatabase._(sources: [databaseSource], mangas: [mockManga]);
}
