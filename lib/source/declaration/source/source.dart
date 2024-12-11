import 'package:tsukuyomi/source/declaration/dynamic.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'core.dart';
import 'http.dart';

List<DartLibrary> get $sourceLibraries {
  return [
    DartLibrary('tsukuyomi_sources', path: 'tsukuyomi_sources.dart', source: '''
library tsukuyomi_sources;

import 'package:html/dom.dart';
import 'package:dio/dio.dart' show DioException;
    ''', declarations: [
      ...$core,
      ...$http,
      ...$dynamic,
    ]),
  ];
}
