import 'dart:convert';

import 'package:flutter/services.dart';
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
        mangas: json['mangas'],
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
  final decoded = jsonDecode(await rootBundle.loadString('assets/source/index.json')) as List<dynamic>;
  final sources = decoded.map((e) => MockSource.fromJson(e as Map<String, dynamic>)).where((e) => e.enabled);
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
        ]
      ]
    ],
  );
}
