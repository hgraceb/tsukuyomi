part of declaration.dart.core;

DartClass get _$bool => DartClass<bool>(($) => '''
final class bool {
  // ${$.empty('bool.fromEnvironment', () => throw EvalPermissionError('bool.fromEnvironment'))}
  external const factory bool.fromEnvironment(String name, {bool defaultValue});

  // ${$.empty('bool.hasEnvironment', () => throw EvalPermissionError('bool.fromEnvironment'))}
  external const factory bool.hasEnvironment(String name);

  // ${$.empty('bool.parse', () => bool.parse)}
  external static bool parse(String source, {bool caseSensitive});

  // ${$.empty('bool.tryParse', () => bool.tryParse)}
  external static bool? tryParse(String source, {bool caseSensitive});

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('&', ($, $$) => $ & $$)}
  external bool operator &(bool other);

  // ${$.debug('|', ($, $$) => $ | $$)}
  external bool operator |(bool other);

  // ${$.debug('^', ($, $$) => $ ^ $$)}
  external bool operator ^(bool other);

  // ${$.debug('hashCode', ($, $$) => $.toString)}
  external String toString();
}
''');

List<DartDeclaration> get $bool {
  return [
    _$bool,
  ];
}
