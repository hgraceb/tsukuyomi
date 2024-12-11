import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'src/hex.dart';

List<DartLibrary> get $convertLibraries {
  return [
    DartLibrary('convert', path: 'convert.dart', source: '''
library convert;

import 'dart:convert';
import 'dart:typed_data';
    ''', declarations: [
      ...$hex,
    ]),
  ];
}
