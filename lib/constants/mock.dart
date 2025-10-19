import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tsukuyomi/database/database.dart';

class MockSource {
  MockSource._({required this.name, required this.path, required this.enabled});

  factory MockSource.fromJson(Map<String, dynamic> json) => MockSource._(name: json['name'], path: json['path'], enabled: json['enabled']);

  final String name;

  final String path;

  final bool enabled;

  late final id = name.hashCode;

  late final nameWithPath = '$name\n$path';
}

Future<List<DatabaseSource>> getMockDatabaseSources() async {
  final decoded = jsonDecode(await rootBundle.loadString('assets/source/index.json')) as List<dynamic>;
  final sources = decoded.map((e) => MockSource.fromJson(e as Map<String, dynamic>)).where((e) => e.enabled);
  return [
    for (final source in sources) ...[
      DatabaseSource(
        id: source.id,
        name: source.nameWithPath,
        source: base64.encode(utf8.encode(await rootBundle.loadString(source.path))),
      ),
    ],
  ];
}
