part of declaration.dart.convert;

DartClass get _$Codec => DartClass<Codec>(($) => '''
abstract mixin class Codec<S, T> {
  const Codec();

  // ${$.debug('encode', ($, $$) => $.encode)}
  external T encode(S input);

  // ${$.debug('decode', ($, $$) => $.decode)}
  external S decode(T encoded);

  // ${$.debug('encoder', ($, $$) => $.encoder)}
  Converter<S, T> get encoder;

  // ${$.debug('decoder', ($, $$) => $.decoder)}
  Converter<T, S> get decoder;

  // ${$.debug('fuse', ($, $$) => $.fuse)}
  external Codec<S, R> fuse<R>(Codec<T, R> other);

  // ${$.debug('inverted', ($, $$) => $.inverted)}
  external Codec<T, S> get inverted;
}
''');

List<DartDeclaration> get $codec {
  return [
    _$Codec,
  ];
}
