part of declaration.dart.core;

DartClass get _$List => DartClass<List>(($) => '''
abstract interface class List<E> implements EfficientLengthIterable<E> {
  // ${$.empty('List.filled', () => List.filled)}
  external factory List.filled(int length, E fill, {bool growable = false});

  // ${$.empty('List.empty', () => List.empty)}
  external factory List.empty({bool growable = false});

  // ${$.empty('List.from', () => List.from)}
  external factory List.from(Iterable elements, {bool growable = true});

  // ${$.empty('List.of', () => List.of)}
  external factory List.of(Iterable<E> elements, {bool growable = true});

  // ${$.empty('List.generate', () => List.generate)}
  external factory List.generate(int length, E generator(int index), {bool growable = true});

  // ${$.empty('List.unmodifiable', () => List.unmodifiable)}
  external factory List.unmodifiable(Iterable elements);

  // ${$.empty('List.castFrom', () => List.castFrom)}
  external static List<T> castFrom<S, T>(List<S> source);

  // ${$.empty('List.copyRange', () => List.copyRange)}
  external static void copyRange<T>(List<T> target, int at, List<T> source, [int? start, int? end]);

  // ${$.empty('List.writeIterable', () => List.writeIterable)}
  external static void writeIterable<T>(List<T> target, int at, Iterable<T> source);

  // ${$.debug('cast', ($, $$) => $.cast)}
  List<R> cast<R>();

  // ${$.debug('[]', ($, $$) => $[$$])}
  E operator [](int index);

  // ${$.debug('[]=', ($, $$) => $[$$] = $$)}
  void operator []=(int index, E value);

  // ${$.debug('first', ($, $$) => $.first = $$)}
  void set first(E value);

  // ${$.debug('last', ($, $$) => $.last = $$)}
  void set last(E value);

  // ${$.debug('length', ($, $$) => $.length)}
  int get length;

  // ${$.debug('length', ($, $$) => $.length = $$)}
  set length(int newLength);

  // ${$.debug('add', ($, $$) => $.add)}
  void add(E value);

  // ${$.debug('addAll', ($, $$) => $.addAll)}
  void addAll(Iterable<E> iterable);

  // ${$.debug('reversed', ($, $$) => $.reversed)}
  Iterable<E> get reversed;

  // ${$.debug('sort', ($, $$) => $.sort)}
  void sort([int compare(E a, E b)?]);

  // ${$.debug('shuffle', ($, $$) => $.shuffle)}
  void shuffle([Random? random]);

  // ${$.debug('indexOf', ($, $$) => $.indexOf)}
  int indexOf(E element, [int start = 0]);

  // ${$.debug('indexWhere', ($, $$) => $.indexWhere)}
  int indexWhere(bool test(E element), [int start = 0]);

  // ${$.debug('lastIndexWhere', ($, $$) => $.lastIndexWhere)}
  int lastIndexWhere(bool test(E element), [int? start]);

  // ${$.debug('lastIndexOf', ($, $$) => $.lastIndexOf)}
  int lastIndexOf(E element, [int? start]);

  // ${$.debug('clear', ($, $$) => $.clear)}
  void clear();

  // ${$.debug('insert', ($, $$) => $.insert)}
  void insert(int index, E element);

  // ${$.debug('insertAll', ($, $$) => $.insertAll)}
  void insertAll(int index, Iterable<E> iterable);

  // ${$.debug('setAll', ($, $$) => $.setAll)}
  void setAll(int index, Iterable<E> iterable);

  // ${$.debug('remove', ($, $$) => $.remove)}
  bool remove(Object? value);

  // ${$.debug('removeAt', ($, $$) => $.removeAt)}
  E removeAt(int index);

  // ${$.debug('removeLast', ($, $$) => $.removeLast)}
  E removeLast();

  // ${$.debug('removeWhere', ($, $$) => $.removeWhere)}
  void removeWhere(bool test(E element));

  // ${$.debug('retainWhere', ($, $$) => $.retainWhere)}
  void retainWhere(bool test(E element));

  // ${$.debug('+', ($, $$) => $ + $$)}
  List<E> operator +(List<E> other);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  List<E> sublist(int start, [int? end]);

  // ${$.debug('getRange', ($, $$) => $.getRange)}
  Iterable<E> getRange(int start, int end);

  // ${$.debug('setRange', ($, $$) => $.setRange)}
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]);

  // ${$.debug('removeRange', ($, $$) => $.removeRange)}
  void removeRange(int start, int end);

  // ${$.debug('fillRange', ($, $$) => $.fillRange)}
  void fillRange(int start, int end, [E? fillValue]);

  // ${$.debug('replaceRange', ($, $$) => $.replaceRange)}
  void replaceRange(int start, int end, Iterable<E> replacements);

  // ${$.debug('asMap', ($, $$) => $.asMap)}
  Map<int, E> asMap();

  // ${$.debug('==', ($, $$) => $ == $$)}
  bool operator ==(Object other);
}
''');

List<DartDeclaration> get $list {
  return [
    _$List,
  ];
}
