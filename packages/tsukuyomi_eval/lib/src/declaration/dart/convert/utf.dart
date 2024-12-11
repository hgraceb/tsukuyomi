part of declaration.dart.convert;

DartVariable get _$unicodeReplacementCharacterRune => DartVariable('unicodeReplacementCharacterRune', unicodeReplacementCharacterRune, '''
const int unicodeReplacementCharacterRune = 0xFFFD;
''');

DartVariable get _$unicodeBomCharacterRune => DartVariable('unicodeBomCharacterRune', unicodeBomCharacterRune, '''
const int unicodeBomCharacterRune = 0xFEFF;
''');

DartVariable get _$utf8 => DartVariable('utf8', utf8, '''
const Utf8Codec utf8 = Utf8Codec();
''');

DartClass get _$Utf8Codec => DartClass<Utf8Codec>(($) => '''
final class Utf8Codec extends Encoding {
  // ${$.empty('Utf8Codec.new', () => Utf8Codec.new)}
  external const Utf8Codec({bool allowMalformed = false});

  // ${$.debug('name', ($, $$) => $.name)}
  external String get name;

  // ${$.debug('decode', ($, $$) => $.decode)}
  external String decode(List<int> codeUnits, {bool? allowMalformed});

  // ${$.debug('encoder', ($, $$) => $.encoder)}
  external Utf8Encoder get encoder;

  // ${$.debug('decoder', ($, $$) => $.decoder)}
  external Utf8Decoder get decoder;
}
''');

DartClass get _$Utf8Encoder => DartClass<Utf8Encoder>(($) => '''
final class Utf8Encoder extends Converter<String, List<int>> {
  // ${$.empty('Utf8Encoder.new', () => Utf8Encoder.new)}
  const Utf8Encoder();

  // ${$.debug('convert', ($, $$) => $.convert)}
  external Uint8List convert(String string, [int start = 0, int? end]);

  // ${$.debug('startChunkedConversion', ($, $$) => $.startChunkedConversion)}
  external StringConversionSink startChunkedConversion(Sink<List<int>> sink);

  // ${$.debug('bind', ($, $$) => $.bind)}
  external Stream<List<int>> bind(Stream<String> stream);
}
''');

List<DartDeclaration> get $utf {
  return [
    _$unicodeReplacementCharacterRune,
    _$unicodeBomCharacterRune,
    _$utf8,
    _$Utf8Codec,
    _$Utf8Encoder,
  ];
}
