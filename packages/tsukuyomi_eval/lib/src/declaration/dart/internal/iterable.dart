part of declaration.dart.internal;

DartClass get _$EfficientLengthIterable => DartClass<Never>(($) => '''
abstract class EfficientLengthIterable<T> extends Iterable<T> {
  const EfficientLengthIterable();

  int get length;
}
''');

List<DartDeclaration> get $iterable {
  return [
    _$EfficientLengthIterable,
  ];
}
