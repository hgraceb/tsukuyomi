import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'convert/convert.dart';
import 'dio/dio.dart';
import 'encrypt/encrypt.dart';
import 'html/html.dart';
import 'source/source.dart';

final List<DartLibrary> evalLibraries = [
  ...$convertLibraries,
  ...$dioLibraries,
  ...$encryptLibraries,
  ...$htmlLibraries,
  ...$sourceLibraries,
];
