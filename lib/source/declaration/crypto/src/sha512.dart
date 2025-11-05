import 'package:crypto/crypto.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartVariable get _$sha384 => DartVariable('sha384', sha384, '''
class _Sha384 extends Hash {
  external final int blockSize;

  const _Sha384._();

  external ByteConversionSink startChunkedConversion(Sink<Digest> sink);
}

const Hash sha384 = _Sha384._();
''');

DartVariable get _$sha512 => DartVariable('sha512', sha512, '''
class _Sha512 extends Hash {
  external final int blockSize;

  const _Sha512._();

  external ByteConversionSink startChunkedConversion(Sink<Digest> sink);
}

const Hash sha512 = _Sha512._();
''');

DartVariable get _$sha512224 => DartVariable('sha512224', sha512224, '''
class _Sha512224 extends Hash {
  external final int blockSize;

  const _Sha512224._();

  external ByteConversionSink startChunkedConversion(Sink<Digest> sink);
}

const Hash sha512224 = _Sha512224._();
''');

DartVariable get _$sha512256 => DartVariable('sha512256', sha512256, '''
class _Sha512256 extends Hash {
  external final int blockSize;

  const _Sha512256._();

  external ByteConversionSink startChunkedConversion(Sink<Digest> sink);
}

const Hash sha512256 = _Sha512256._();
''');

List<DartDeclaration> get $sha512 {
  return [
    _$sha384,
    _$sha512,
    _$sha512224,
    _$sha512256,
  ];
}
