part of declaration.dart.core;

DartClass get _$Object => DartClass<Object>(($) => '''
class Object {
  // ${$.empty('Object.new', () => Object.new)}
  const Object();

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(Object other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();

  // ${$.debug('noSuchMethod', ($, $$) => $.noSuchMethod)}
  external dynamic noSuchMethod(Invocation invocation);

  // ${$.debug('runtimeType', ($, $$) => $.runtimeType)}
  external Type get runtimeType;

  // ${$.empty('Object.hash', () => Object.hash)}
  external static int hash(
    Object? object1,
    Object? object2, [
    Object? object3,
    Object? object4,
    Object? object5,
    Object? object6,
    Object? object7,
    Object? object8,
    Object? object9,
    Object? object10,
    Object? object11,
    Object? object12,
    Object? object13,
    Object? object14,
    Object? object15,
    Object? object16,
    Object? object17,
    Object? object18,
    Object? object19,
    Object? object20,
  ]);

  // ${$.empty('Object.hashAll', () => Object.hashAll)}
  external static int hashAll(Iterable<Object?> objects);

  // ${$.empty('Object.hashAllUnordered', () => Object.hashAllUnordered)}
  external static int hashAllUnordered(Iterable<Object?> objects);
}
''');

List<DartDeclaration> get $object {
  return [
    _$Object,
  ];
}
