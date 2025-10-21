import 'package:crypto/crypto.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$Digest => DartClass<Digest>(($) => '''
class Digest {
  // ${$.debug('bytes', ($, $$) => $.bytes)}
  final List<int> bytes;

  // ${$.empty('Digest.new', () => Digest.new)}
  Digest(this.bytes);

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

List<DartDeclaration> get $digest {
  return [
    _$Digest,
  ];
}
