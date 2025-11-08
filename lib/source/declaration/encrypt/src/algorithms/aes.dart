import 'package:encrypt/encrypt.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$AES => DartClass<AES>(($) => '''
class AES implements Algorithm {
  // ${$.debug('key', ($, $$) => $.key)}
  final Key key;

  // ${$.debug('mode', ($, $$) => $.mode)}
  final AESMode mode;

  // ${$.debug('padding', ($, $$) => $.padding)}
  final String? padding;

  // ${$.empty('AES.new', () => AES.new)}
  AES(this.key, {this.mode = AESMode.sic, this.padding = 'PKCS7'});

  // ${$.debug('encrypt', ($, $$) => $.encrypt)}
  external Encrypted encrypt(Uint8List bytes, {IV? iv, Uint8List? associatedData});

  // ${$.debug('decrypt', ($, $$) => $.decrypt)}
  external Uint8List decrypt(Encrypted encrypted, {IV? iv, Uint8List? associatedData});
}
''');

DartClass get _$AESMode => DartClass<AESMode>(($) => '''
class AESMode {
  const AESMode._();

  // ${$.empty('AESMode.cbc', () => AESMode.cbc)}
  static const AESMode cbc = AESMode._();
  
  // ${$.empty('AESMode.cfb64', () => AESMode.cfb64)}
  static const AESMode cfb64 = AESMode._();
  
  // ${$.empty('AESMode.ctr', () => AESMode.ctr)}
  static const AESMode ctr = AESMode._();
  
  // ${$.empty('AESMode.ecb', () => AESMode.ecb)}
  static const AESMode ecb = AESMode._();
  
  // ${$.empty('AESMode.ofb64Gctr', () => AESMode.ofb64Gctr)}
  static const AESMode ofb64Gctr = AESMode._();
  
  // ${$.empty('AESMode.ofb64', () => AESMode.ofb64)}
  static const AESMode ofb64 = AESMode._();
  
  // ${$.empty('AESMode.sic', () => AESMode.sic)}
  static const AESMode sic = AESMode._();
  
  // ${$.empty('AESMode.gcm', () => AESMode.gcm)}
  static const AESMode gcm = AESMode._();
}
''');

List<DartDeclaration> get $aes {
  return [
    _$AES,
    _$AESMode,
  ];
}
