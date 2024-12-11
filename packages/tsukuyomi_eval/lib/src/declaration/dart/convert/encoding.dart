part of declaration.dart.convert;

DartClass get _$Encoding => DartClass<Encoding>(($) => '''
abstract class Encoding extends Codec<String, List<int>> {
  const Encoding();

  // ${$.debug('encoder', ($, $$) => $.encoder)}
  Converter<String, List<int>> get encoder;

  // ${$.debug('decoder', ($, $$) => $.decoder)}
  Converter<List<int>, String> get decoder;

  // ${$.debug('decodeStream', ($, $$) => $.decodeStream)}
  external Future<String> decodeStream(Stream<List<int>> byteStream);

  // ${$.debug('name', ($, $$) => $.name)}
  String get name;

  // ${$.empty('Encoding.getByName', () => Encoding.getByName)}
  external static Encoding? getByName(String? name);
}
''');

List<DartDeclaration> get $encoding {
  return [
    _$Encoding,
  ];
}
