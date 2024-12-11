library declaration.dart.ui;

import 'dart:ui';

import 'package:tsukuyomi_eval/src/property.dart';

part 'geometry.dart';

part 'painting.dart';

DartLibrary get dartUiLibrary {
  return DartLibrary('dart:ui', path: 'ui/ui.dart', source: 'library dart.ui;', declarations: [
    ...$geometry,
    ...$painting,
  ]);
}
