part of 'core.dart';

DartClass get _$Iterator => DartClass<Iterator>(($) => '''
abstract interface class Iterator<E> {
  // ${$.debug('current', ($, $$) => $.current)}
  E get current;

  // ${$.debug('moveNext', ($, $$) => $.moveNext)}
  bool moveNext();
}
''');

List<DartDeclaration> get $iterator {
  return [
    _$Iterator,
  ];
}
