import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tsukuyomi/database/database.dart';

class MockSource {
  MockSource._(this.name, this.path);

  final String name;

  final String path;

  late final id = name.hashCode;

  late final nameWithPath = '$name\n$path';

  static final example = MockSource._('Example Source', 'assets/source/example.dart');
}

Future<List<DatabaseSource>> getMockDatabaseSources() async {
  return [
    DatabaseSource(
      id: MockSource.example.id,
      name: MockSource.example.nameWithPath,
      source: base64.encode(utf8.encode(await rootBundle.loadString(MockSource.example.path))),
    ),
  ];
}
