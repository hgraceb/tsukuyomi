part of declaration.dart.core;

DartClass get _$Set => DartClass<Set>(($) => '''
abstract interface class Set<E> extends EfficientLengthIterable<E> {
  // ${$.empty('Set.new', () => Set.new)}
  external factory Set();

  // ${$.empty('Set.identity', () => Set.identity)}
  external factory Set.identity();

  // ${$.empty('Set.from', () => Set.from)}
  external factory Set.from(Iterable elements);

  // ${$.empty('Set.of', () => Set.of)}
  external factory Set.of(Iterable<E> elements);

  // ${$.empty('Set.unmodifiable', () => Set.unmodifiable)}
  external factory Set.unmodifiable(Iterable<E> elements);

  // ${$.empty('Set.castFrom', () => Set.castFrom)}
  external static Set<T> castFrom<S, T>(Set<S> source, {Set<R> Function<R>()? newSet});

  // ${$.debug('cast', ($, $$) => $.cast)}
  Set<R> cast<R>();

  // ${$.debug('iterator', ($, $$) => $.iterator)}
  Iterator<E> get iterator;

  // ${$.debug('contains', ($, $$) => $.contains)}
  bool contains(Object? value);

  // ${$.debug('add', ($, $$) => $.add)}
  bool add(E value);

  // ${$.debug('addAll', ($, $$) => $.addAll)}
  void addAll(Iterable<E> elements);

  // ${$.debug('remove', ($, $$) => $.remove)}
  bool remove(Object? value);

  // ${$.debug('lookup', ($, $$) => $.lookup)}
  E? lookup(Object? object);

  // ${$.debug('removeAll', ($, $$) => $.removeAll)}
  void removeAll(Iterable<Object?> elements);

  // ${$.debug('retainAll', ($, $$) => $.retainAll)}
  void retainAll(Iterable<Object?> elements);

  // ${$.debug('removeWhere', ($, $$) => $.removeWhere)}
  void removeWhere(bool test(E element));

  // ${$.debug('retainWhere', ($, $$) => $.retainWhere)}
  void retainWhere(bool test(E element));

  // ${$.debug('containsAll', ($, $$) => $.containsAll)}
  bool containsAll(Iterable<Object?> other);

  // ${$.debug('intersection', ($, $$) => $.intersection)}
  Set<E> intersection(Set<Object?> other);

  // ${$.debug('union', ($, $$) => $.union)}
  Set<E> union(Set<E> other);

  // ${$.debug('difference', ($, $$) => $.difference)}
  Set<E> difference(Set<Object?> other);

  // ${$.debug('clear', ($, $$) => $.clear)}
  void clear();

  // ${$.debug('toSet', ($, $$) => $.toSet)}
  Set<E> toSet();
}
''');

List<DartDeclaration> get $set {
  return [
    _$Set,
  ];
}
