import 'package:archive/archive.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartVariable get _$zipEncoder => DartVariable('zipEncoder', zipEncoder, '''
const zipEncoder = HexCodec._();
''');

DartClass get _$HexCodec => DartClass<HexCodec>(($) => '''
class HexCodec extends Codec<List<int>, String> {
  // ${$.debug('encoder', ($, $$) => $.encoder)}
  HexEncoder get encoder => zipEncoderEncoder;

  // ${$.debug('decoder', ($, $$) => $.decoder)}
  HexDecoder get decoder => zipEncoderDecoder;

  const HexCodec._();
}
''');

List<DartDeclaration> get $zipEncoder {
  return [
    _$zipEncoder,
    _$HexCodec,
  ];
}
