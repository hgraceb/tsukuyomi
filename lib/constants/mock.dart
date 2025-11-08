import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tsukuyomi/constants/assets.dart';
import 'package:tsukuyomi/database/database.dart';

class MockDatabase {
  MockDatabase._({required this.sources, required this.mangas});

  final List<DatabaseSource> sources;

  final List<DatabaseManga> mangas;
}

class MockSource {
  MockSource._({required this.name, required this.path, required this.enabled, required this.mangas});

  factory MockSource.fromJson(Map<String, dynamic> json) => MockSource._(
    name: json['name'],
    path: json['path'],
    enabled: json['enabled'],
    mangas: (json['mangas'] as List).map((e) => MockManga.fromJson(e)).toList(),
  );

  final String name;

  final String path;

  final bool enabled;

  final List<MockManga> mangas;

  late final id = name.hashCode;

  late final nameWithPath = '$name\n$path';
}

class MockManga {
  MockManga._({required this.id, required this.url, required this.title, required this.cover});

  factory MockManga.fromJson(Map<String, dynamic> json) => MockManga._(
    id: json['id'],
    url: json['url'],
    title: json['title'],
    cover: json['cover'],
  );

  final int id;

  final String url;

  final String title;

  final String cover;
}

Future<MockDatabase> getMockDatabase() async {
  try {
    final decoded = jsonDecode(await rootBundle.loadString('assets/source/index.json')) as List<dynamic>;
    final sources = decoded.map((e) => MockSource.fromJson(e as Map<String, dynamic>)).where((e) => e.enabled).toList();
    return MockDatabase._(
      sources: [
        for (final source in sources) ...[
          DatabaseSource(
            id: source.id,
            name: source.nameWithPath,
            source: base64.encode(utf8.encode(await rootBundle.loadString(source.path))),
          ),
        ],
      ],
      mangas: [
        for (final source in sources) ...[
          for (final manga in source.mangas) ...[
            DatabaseManga(
              id: manga.id,
              source: source.id,
              url: manga.url,
              title: manga.title,
              cover: manga.cover,
              favorite: true,
            ),
          ],
        ],
      ],
    );
  } on FlutterError catch (_) {
    final mockSource = MockSource._(name: 'Example Source', path: Assets.sourceExample, enabled: true, mangas: []);
    final sourceCode = base64.encode(utf8.encode(await rootBundle.loadString(mockSource.path)));
    final databaseSource = DatabaseSource(id: mockSource.id, name: mockSource.nameWithPath, source: sourceCode);
    // TODO 使用更通用的方式获取示例漫画数据
    final mockManga = DatabaseManga(
      id: 0,
      source: mockSource.id,
      url: '16,74,176,213,218,266,381,385,404,461,477,481,516,603,609,626,640,657,715,716',
      title: 'Example Manga',
      cover: 'https://picsum.photos/id/384/800/1200',
      favorite: true,
    );
    return MockDatabase._(sources: [databaseSource], mangas: [mockManga]);
  } catch (e) {
    // TODO 判断是否需要通过控制台日志提示可以进行本地模拟数据配置
    return MockDatabase._(sources: [], mangas: []);
  }
}
