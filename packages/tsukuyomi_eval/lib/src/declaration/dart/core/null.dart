part of declaration.dart.core;

// ignore: prefer_void_to_null
DartClass get _$Null => DartClass<Null>(($) => '''
final class Null {
  Null._();

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

List<DartDeclaration> get $null {
  return [
    _$Null,
  ];
}
