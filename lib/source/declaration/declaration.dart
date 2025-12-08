import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'archive/archive.dart';
import 'convert/convert.dart';
import 'crypto/crypto.dart';
import 'dio/dio.dart';
import 'encrypt/encrypt.dart';
import 'html/html.dart';
import 'source/source.dart';

final List<DartLibrary> evalLibraries = [
  ...$archiveLibraries,
  ...$convertLibraries,
  ...$cryptoLibraries,
  ...$dioLibraries,
  ...$encryptLibraries,
  ...$htmlLibraries,
  ...$sourceLibraries,
];
