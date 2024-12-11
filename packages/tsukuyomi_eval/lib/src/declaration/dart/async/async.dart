library declaration.dart.async;

import 'dart:async';

import 'package:tsukuyomi_eval/src/property.dart';

part 'future.dart';

DartLibrary get dartAsyncLibrary {
  return DartLibrary('dart:async', path: 'async/async.dart', source: 'library dart.async;', declarations: [
    ...$future,
  ]);
}
