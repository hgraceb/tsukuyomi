import 'package:crypto/crypto.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$Hash => DartClass<Hash>(($) => '''
abstract class Hash extends Converter<List<int>, Digest> {
  // ${$.debug('blockSize', ($, $$) => $.blockSize)}
  int get blockSize;

  const Hash();

  // ${$.debug('convert', ($, $$) => $.convert)}
  external Digest convert(List<int> input);

  // ${$.debug('startChunkedConversion', ($, $$) => $.startChunkedConversion)}
  ByteConversionSink startChunkedConversion(Sink<Digest> sink);
}
''');

List<DartDeclaration> get $hash {
  return [
    _$Hash,
  ];
}
