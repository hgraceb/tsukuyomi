import 'package:convert/convert.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartVariable get _$hex => DartVariable('hex', hex, '''
const hex = HexCodec._();
''');

DartClass get _$HexCodec => DartClass<HexCodec>(($) => '''
class HexCodec extends Codec<List<int>, String> {
  // ${$.debug('encoder', ($, $$) => $.encoder)}
  HexEncoder get encoder => hexEncoder;

  // ${$.debug('decoder', ($, $$) => $.decoder)}
  HexDecoder get decoder => hexDecoder;

  const HexCodec._();
}
''');

List<DartDeclaration> get $hex {
  return [
    _$hex,
    _$HexCodec,
  ];
}
