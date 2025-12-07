import 'package:archive/archive.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$ZipDecoder => DartClass<ZipDecoder>(($) => '''
// ${$.empty('ZipDecoder.new', () => ZipDecoder.new)}
class ZipDecoder {
  // ${$.debug('directory', ($, $$) => $.directory = $$)}
  late ZipDirectory directory;

  // ${$.debug('decodeBytes', ($, $$) => $.decodeBytes)}
  external Archive decodeBytes(List<int> data, {bool verify = false, String? password});

  // ${$.debug('decodeBuffer', ($, $$) => $.decodeBuffer)}
  external Archive decodeBuffer(InputStreamBase input, {bool verify = false, String? password});
}
''');

List<DartDeclaration> get $zipEncoder {
  return [
    _$ZipDecoder,
  ];
}
