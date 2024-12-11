import 'package:encrypt/encrypt.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$Algorithm => DartClass<Algorithm>(($) => '''
abstract class Algorithm {
  // ${$.debug('encrypt', ($, $$) => $.encrypt)}
  Encrypted encrypt(Uint8List bytes, {IV? iv, Uint8List? associatedData});

  // ${$.debug('decrypt', ($, $$) => $.decrypt)}
  Uint8List decrypt(Encrypted encrypted, {IV? iv, Uint8List? associatedData});
}
''');

DartClass get _$SignerAlgorithm => DartClass<SignerAlgorithm>(($) => '''
abstract class SignerAlgorithm {
  // ${$.debug('sign', ($, $$) => $.sign)}
  Encrypted sign(Uint8List bytes);

  // ${$.debug('verify', ($, $$) => $.verify)}
  bool verify(Uint8List bytes, Encrypted encrypted);
}
''');

List<DartDeclaration> get $algorithm {
  return [
    _$Algorithm,
    _$SignerAlgorithm,
  ];
}
