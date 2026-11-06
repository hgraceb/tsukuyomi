part of 'core.dart';

DartClass get _$Type => DartClass<Type>(($) => '''
abstract interface class Type {
  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  int get hashCode;

  // ${$.debug('==', ($, $$) => $ == $$)}
  bool operator ==(Object other);

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();
}
''');

List<DartDeclaration> get $type {
  return [
    _$Type,
  ];
}
