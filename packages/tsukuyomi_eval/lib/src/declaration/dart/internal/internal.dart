library declaration.dart.internal;

import 'package:tsukuyomi_eval/src/property.dart';

part 'iterable.dart';

DartLibrary get dartInternalLibrary {
  return DartLibrary('dart:_internal', path: 'internal/internal.dart', source: 'library dart._internal;', declarations: [
    ...$iterable,
  ]);
}
