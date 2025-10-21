import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'src/digest.dart';
import 'src/sha256.dart';
import 'src/sha512.dart';

List<DartLibrary> get $cryptoLibraries {
  return [
    DartLibrary('crypto', path: 'crypto.dart', source: 'library crypto;', declarations: [
      ...$digest,
      ...$sha256,
      ...$sha512,
    ]),
  ];
}
