import 'package:crypto/crypto.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartVariable get _$sha256 => DartVariable('sha256', sha256, '''
class _Sha256 extends Hash {
  external final int blockSize;

  const _Sha256._();

  external ByteConversionSink startChunkedConversion(Sink<Digest> sink);
}

const Hash sha256 = _Sha256._();
''');

DartVariable get _$sha224 => DartVariable('sha224', sha224, '''
class _Sha224 extends Hash {
  external final int blockSize;

  const _Sha224._();

  external ByteConversionSink startChunkedConversion(Sink<Digest> sink);
}

const Hash sha224 = _Sha224._();
''');

List<DartDeclaration> get $sha256 {
  return [
    _$sha256,
    _$sha224,
  ];
}
