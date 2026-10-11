part of declaration.dart.core;

DartClass get _$Error => DartClass<Error>(($) => '''
class Error {
  // ${$.empty('Error.new', () => Error.new)}
  Error();
}
''');

DartClass get _$TypeError => DartClass<TypeError>(($) => '''
class TypeError extends Error {
  // ${$.empty('TypeError.new', () => TypeError.new)}
  TypeError();
}
''');

List<DartDeclaration> get $errors {
  return [
    _$Error,
    _$TypeError,
  ];
}
