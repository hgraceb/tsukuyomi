import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'src/algorithm.dart';
import 'src/algorithms/aes.dart';
import 'src/encrypted.dart';

List<DartLibrary> get $encryptLibraries {
  return [
    DartLibrary('encrypt', path: 'encrypt.dart', source: '''
library encrypt;

import 'dart:typed_data';
    ''', declarations: [
      ...$aes,
      ...$algorithm,
      ...$encrypted,
    ]),
  ];
}
