part of declaration.dart.convert;

DartVariable get _$base64 => DartVariable('base64', base64, '''
const Base64Codec base64 = Base64Codec();
''');

DartVariable get _$base64Url => DartVariable('base64Url', base64Url, '''
const Base64Codec base64Url = Base64Codec.urlSafe();
''');

DartFunction get _$base64Encode => DartFunction('base64Encode', base64Encode, '''
String base64Encode(List<int> bytes) => base64.encode(bytes);
''');

DartFunction get _$base64UrlEncode => DartFunction('base64UrlEncode', base64UrlEncode, '''
String base64UrlEncode(List<int> bytes) => base64Url.encode(bytes);
''');

DartFunction get _$base64Decode => DartFunction('base64Decode', base64Decode, '''
Uint8List base64Decode(String source) => base64.decode(source);
''');

DartClass get _$Base64Codec => DartClass<Base64Codec>(($) => '''
final class Base64Codec extends Codec<List<int>, String> {
  // ${$.empty('Base64Codec.new', () => Base64Codec.new)}
  const Base64Codec();

  // ${$.empty('Base64Codec.urlSafe', () => Base64Codec.urlSafe)}
  const Base64Codec.urlSafe();

  // ${$.debug('encoder', ($, $$) => $.encoder)}
  external Base64Encoder get encoder;

  // ${$.debug('decoder', ($, $$) => $.decoder)}
  external Base64Decoder get decoder;

  // ${$.debug('decode', ($, $$) => $.decode)}
  external Uint8List decode(String encoded);

  // ${$.debug('normalize', ($, $$) => $.normalize)}
  external String normalize(String source, [int start = 0, int? end]);
}
''');

DartClass get _$Base64Encoder => DartClass<Base64Encoder>(($) => '''
final class Base64Encoder extends Converter<List<int>, String> {
  // ${$.empty('Base64Encoder.new', () => Base64Encoder.new)}
  const Base64Encoder();

  // ${$.empty('Base64Encoder.urlSafe', () => Base64Encoder.urlSafe)}
  const Base64Encoder.urlSafe();

  // ${$.debug('convert', ($, $$) => $.convert)}
  external String convert(List<int> input);

  // ${$.debug('startChunkedConversion', ($, $$) => $.startChunkedConversion)}
  external ByteConversionSink startChunkedConversion(Sink<String> sink);
}
''');

DartClass get _$Base64Decoder => DartClass<Base64Decoder>(($) => '''
final class Base64Decoder extends Converter<String, List<int>> {
  // ${$.empty('Base64Decoder.new', () => Base64Decoder.new)}
  const Base64Decoder();

  // ${$.debug('convert', ($, $$) => $.convert)}
  external Uint8List convert(String input, [int start = 0, int? end]);

  // ${$.debug('startChunkedConversion', ($, $$) => $.startChunkedConversion)}
  external StringConversionSink startChunkedConversion(Sink<List<int>> sink);
}
''');

List<DartDeclaration> get $base64 {
  return [
    _$base64,
    _$base64Url,
    _$base64Encode,
    _$base64UrlEncode,
    _$base64Decode,
    _$Base64Codec,
    _$Base64Encoder,
    _$Base64Decoder,
  ];
}
