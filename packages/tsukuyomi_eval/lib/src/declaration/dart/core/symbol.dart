part of declaration.dart.core;

DartClass get _$Symbol => DartClass<Symbol>(($) => '''
abstract class Symbol {
  // ${$.empty('Symbol.unaryMinus', () => Symbol.unaryMinus)}
  static const Symbol unaryMinus = Symbol("unary-");

  // ${$.empty('Symbol.empty', () => Symbol.empty)}
  static const Symbol empty = Symbol("");

  // ${$.empty('Symbol.new', () => Symbol.new)}
  external const factory Symbol(String name);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  int get hashCode;

  // ${$.debug('==', ($, $$) => $ == $$)}
  bool operator ==(Object other);
}
''');

List<DartDeclaration> get $symbol {
  return [
    _$Symbol,
  ];
}
