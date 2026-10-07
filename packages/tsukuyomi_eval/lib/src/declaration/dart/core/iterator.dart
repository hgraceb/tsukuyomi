part of 'core.dart';

DartClass get _$Iterator => DartClass<Iterator>(($) => '''
abstract interface class Iterator<E> {
  // ${$.debug('moveNext', ($, $$) => $.moveNext)}
  bool moveNext();

  // ${$.debug('current', ($, $$) => $.current)}
  E get current;
}
''');

List<DartDeclaration> get $iterator {
  return [
    _$Iterator,
  ];
}
