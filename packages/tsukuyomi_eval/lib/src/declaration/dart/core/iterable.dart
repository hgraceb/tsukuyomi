part of declaration.dart.core;

DartClass get _$Iterable => DartClass<Iterable>(($) => '''
abstract mixin class Iterable<E> {
  const Iterable();

  // ${$.empty('Iterable.generate', () => Iterable.generate)}
  external factory Iterable.generate(int count, [E generator(int index)?]);

  // ${$.empty('Iterable.empty', () => Iterable.empty)}
  const factory Iterable.empty() = EmptyIterable<E>;

  // ${$.empty('Iterable.castFrom', () => Iterable.castFrom)}
  external static Iterable<T> castFrom<S, T>(Iterable<S> source);

  // ${$.debug('iterator', ($, $$) => $.iterator)}
  Iterator<E> get iterator;

  // ${$.debug('cast', ($, $$) => $.cast)}
  external Iterable<R> cast<R>();

  // ${$.debug('followedBy', ($, $$) => $.followedBy)}
  external Iterable<E> followedBy(Iterable<E> other);

  // ${$.debug('map', ($, $$) => $.map)}
  external Iterable<T> map<T>(T toElement(E e));

  // ${$.debug('where', ($, $$) => $.where)}
  external Iterable<E> where(bool test(E element));

  // ${$.debug('whereType', ($, $$) => $.whereType)}
  external Iterable<T> whereType<T>();

  // ${$.debug('expand', ($, $$) => $.expand)}
  external Iterable<T> expand<T>(Iterable<T> toElements(E element));

  // ${$.debug('contains', ($, $$) => $.contains)}
  external bool contains(Object? element);

  // ${$.debug('forEach', ($, $$) => $.forEach)}
  external void forEach(void action(E element));

  // ${$.debug('reduce', ($, $$) => $.reduce)}
  external E reduce(E combine(E value, E element));

  // ${$.debug('fold', ($, $$) => $.fold)}
  external T fold<T>(T initialValue, T combine(T previousValue, E element));

  // ${$.debug('every', ($, $$) => $.every)}
  external bool every(bool test(E element));

  // ${$.debug('join', ($, $$) => $.join)}
  external String join([String separator = ""]);

  // ${$.debug('any', ($, $$) => $.any)}
  external bool any(bool test(E element));

  // ${$.debug('toList', ($, $$) => $.toList)}
  external List<E> toList({bool growable = true});

  // ${$.debug('toSet', ($, $$) => $.toSet)}
  external Set<E> toSet();

  // ${$.debug('length', ($, $$) => $.length)}
  external int get length;

  // ${$.debug('isEmpty', ($, $$) => $.isEmpty)}
  external bool get isEmpty;

  // ${$.debug('isNotEmpty', ($, $$) => $.isNotEmpty)}
  external bool get isNotEmpty;

  // ${$.debug('take', ($, $$) => $.take)}
  external Iterable<E> take(int count);

  // ${$.debug('takeWhile', ($, $$) => $.takeWhile)}
  external Iterable<E> takeWhile(bool test(E value));

  // ${$.debug('skip', ($, $$) => $.skip)}
  external Iterable<E> skip(int count);

  // ${$.debug('skipWhile', ($, $$) => $.skipWhile)}
  external Iterable<E> skipWhile(bool test(E value));

  // ${$.debug('first', ($, $$) => $.first)}
  external E get first;

  // ${$.debug('last', ($, $$) => $.last)}
  external E get last;

  // ${$.debug('single', ($, $$) => $.single)}
  external E get single;

  // ${$.debug('firstWhere', ($, $$) => $.firstWhere)}
  external E firstWhere(bool test(E element), {E orElse()?});

  // ${$.debug('lastWhere', ($, $$) => $.lastWhere)}
  external E lastWhere(bool test(E element), {E orElse()?});

  // ${$.debug('singleWhere', ($, $$) => $.singleWhere)}
  external E singleWhere(bool test(E element), {E orElse()?});

  // ${$.debug('elementAt', ($, $$) => $.elementAt)}
  external E elementAt(int index);

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();

  // ${$.empty('Iterable.iterableToShortString', () => Iterable.iterableToShortString)}
  external static String iterableToShortString(Iterable iterable, [String leftDelimiter = '(', String rightDelimiter = ')']);

  // ${$.empty('Iterable.iterableToFullString', () => Iterable.iterableToFullString)}
  external static String iterableToFullString(Iterable iterable, [String leftDelimiter = '(', String rightDelimiter = ')']);
}
''');

List<DartDeclaration> get $iterable {
  return [
    _$Iterable,
  ];
}
