library declaration.dart.convert;

import 'dart:convert';

import 'package:tsukuyomi_eval/src/property.dart';

part 'encoding.dart';

part 'json.dart';

part 'utf.dart';

DartLibrary get dartConvertLibrary {
  return DartLibrary('dart:convert', path: 'convert/convert.dart', source: 'library dart.convert;', declarations: [
    ...$json,
    ...$encoding,
    ...$utf,
  ]);
}
