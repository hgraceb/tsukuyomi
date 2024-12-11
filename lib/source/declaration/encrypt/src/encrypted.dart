import 'package:encrypt/encrypt.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$Encrypted => DartClass<Encrypted>(($) => '''
class Encrypted {
  // ${$.empty('Encrypted.new', () => Encrypted.new)}
  external Encrypted(Uint8List bytes);

  // ${$.empty('Encrypted.fromBase16', () => Encrypted.fromBase16)}
  external Encrypted.fromBase16(String encoded);

  // ${$.empty('Encrypted.fromBase64', () => Encrypted.fromBase64)}
  external Encrypted.fromBase64(String encoded);

  // ${$.empty('Encrypted.from64', () => Encrypted.from64)}
  external Encrypted.from64(String encoded);

  // ${$.empty('Encrypted.fromUtf8', () => Encrypted.fromUtf8)}
  external Encrypted.fromUtf8(String input);

  // ${$.empty('Encrypted.fromLength', () => Encrypted.fromLength)}
  external Encrypted.fromLength(int length);

  // ${$.empty('Encrypted.fromSecureRandom', () => Encrypted.fromSecureRandom)}
  external Encrypted.fromSecureRandom(int length);

  // ${$.empty('Encrypted.allZerosOfLength', () => Encrypted.allZerosOfLength)}
  external Encrypted.allZerosOfLength(int length);

  // ${$.debug('bytes', ($, $$) => $.bytes)}
  external Uint8List get bytes;

  // ${$.debug('base16', ($, $$) => $.base16)}
  external String get base16;

  // ${$.debug('base64', ($, $$) => $.base64)}
  external String get base64;

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;
}
''');

DartClass get _$IV => DartClass<IV>(($) => '''
class IV extends Encrypted {
  // ${$.empty('IV.new', () => IV.new)}
  external IV(Uint8List bytes);

  // ${$.empty('IV.fromBase16', () => IV.fromBase16)}
  external IV.fromBase16(String encoded);

  // ${$.empty('IV.fromBase64', () => IV.fromBase64)}
  external IV.fromBase64(String encoded);

  // ${$.empty('IV.fromUtf8', () => IV.fromUtf8)}
  external IV.fromUtf8(String input);

  // ${$.empty('IV.fromLength', () => IV.fromLength)}
  external IV.fromLength(int length);

  // ${$.empty('IV.fromSecureRandom', () => IV.fromSecureRandom)}
  external IV.fromSecureRandom(int length);

  // ${$.empty('IV.allZerosOfLength', () => IV.allZerosOfLength)}
  external IV.allZerosOfLength(int length);
}
''');

DartClass get _$Key => DartClass<Key>(($) => '''
class Key extends Encrypted {
  // ${$.empty('Key.new', () => Key.new)}
  external Key(Uint8List bytes);

  // ${$.empty('Key.fromBase16', () => Key.fromBase16)}
  external Key.fromBase16(String encoded);

  // ${$.empty('Key.fromBase64', () => Key.fromBase64)}
  external Key.fromBase64(String encoded);

  // ${$.empty('Key.fromUtf8', () => Key.fromUtf8)}
  external Key.fromUtf8(String input);

  // ${$.empty('Key.fromLength', () => Key.fromLength)}
  external Key.fromLength(int length);

  // ${$.empty('Key.fromSecureRandom', () => Key.fromSecureRandom)}
  external Key.fromSecureRandom(int length);

  // ${$.empty('Key.allZerosOfLength', () => Key.allZerosOfLength)}
  external Key.allZerosOfLength(int length);

  // ${$.debug('stretch', ($, $$) => $.stretch)}
  external Key stretch(int desiredKeyLength, {int iterationCount = 100, Uint8List? salt});

  // ${$.debug('length', ($, $$) => $.length)}
  external int get length;
}
''');

List<DartDeclaration> get $encrypted {
  return [
    _$Encrypted,
    _$IV,
    _$Key,
  ];
}
