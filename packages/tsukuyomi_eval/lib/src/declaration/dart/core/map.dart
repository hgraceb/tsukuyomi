part of declaration.dart.core;

DartClass get _$Map => DartClass<Map>(($) => '''
abstract interface class Map<K, V> {
  // ${$.empty('Map.new', () => Map.new)}
  external factory Map();

  // ${$.empty('Map.from', () => Map.from)}
  external factory Map.from(Map other);

  // ${$.empty('Map.of', () => Map.of)}
  external factory Map.of(Map<K, V> other);

  // ${$.empty('Map.unmodifiable', () => Map.unmodifiable)}
  external factory Map.unmodifiable(Map<dynamic, dynamic> other);

  // ${$.empty('Map.identity', () => Map.identity)}
  external factory Map.identity();

  // ${$.empty('Map.fromIterable', () => Map.fromIterable)}
  external factory Map.fromIterable(Iterable iterable, {K key(dynamic element)?, V value(dynamic element)?});

  // ${$.empty('Map.fromIterables', () => Map.fromIterables)}
  external factory Map.fromIterables(Iterable<K> keys, Iterable<V> values);

  // ${$.empty('Map.castFrom', () => Map.castFrom)}
  external static Map<K2, V2> castFrom<K, V, K2, V2>(Map<K, V> source);

  // ${$.empty('Map.fromEntries', () => Map.fromEntries)}
  external factory Map.fromEntries(Iterable<MapEntry<K, V>> entries);

  // ${$.debug('cast', ($, $$) => $.cast)}
  Map<RK, RV> cast<RK, RV>();

  // ${$.debug('containsValue', ($, $$) => $.containsValue)}
  bool containsValue(Object? value);

  // ${$.debug('containsKey', ($, $$) => $.containsKey)}
  bool containsKey(Object? key);

  // ${$.debug('[]', ($, $$) => $[$$])}
  V? operator [](Object? key);

  // ${$.debug('[]=', ($, $$) => $[$$] = $$)}
  void operator []=(K key, V value);

  // ${$.debug('entries', ($, $$) => $.entries)}
  Iterable<MapEntry<K, V>> get entries;

  // ${$.debug('map', ($, $$) => $.map)}
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> convert(K key, V value));

  // ${$.debug('addEntries', ($, $$) => $.addEntries)}
  void addEntries(Iterable<MapEntry<K, V>> newEntries);

  // ${$.debug('update', ($, $$) => $.update)}
  V update(K key, V update(V value), {V ifAbsent()?});

  // ${$.debug('updateAll', ($, $$) => $.updateAll)}
  void updateAll(V update(K key, V value));

  // ${$.debug('removeWhere', ($, $$) => $.removeWhere)}
  void removeWhere(bool test(K key, V value));

  // ${$.debug('putIfAbsent', ($, $$) => $.putIfAbsent)}
  V putIfAbsent(K key, V ifAbsent());

  // ${$.debug('addAll', ($, $$) => $.addAll)}
  void addAll(Map<K, V> other);

  // ${$.debug('remove', ($, $$) => $.remove)}
  V? remove(Object? key);

  // ${$.debug('clear', ($, $$) => $.clear)}
  void clear();

  // ${$.debug('forEach', ($, $$) => $.forEach)}
  void forEach(void action(K key, V value));

  // ${$.debug('keys', ($, $$) => $.keys)}
  Iterable<K> get keys;

  // ${$.debug('values', ($, $$) => $.values)}
  Iterable<V> get values;

  // ${$.debug('length', ($, $$) => $.length)}
  int get length;

  // ${$.debug('isEmpty', ($, $$) => $.isEmpty)}
  bool get isEmpty;

  // ${$.debug('isNotEmpty', ($, $$) => $.isNotEmpty)}
  bool get isNotEmpty;
}
''');

DartClass get _$MapEntry => DartClass<MapEntry>(($) => '''
final class MapEntry<K, V> {
  const MapEntry._(this.key, this.value);

  // ${$.empty('MapEntry.new', () => MapEntry.new)}
  const factory MapEntry(K key, V value) = MapEntry<K, V>._;

  // ${$.debug('key', ($, $$) => $.key)}
  final K key;

  // ${$.debug('value', ($, $$) => $.value)}
  final V value;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

List<DartDeclaration> get $map {
  return [
    _$Map,
    _$MapEntry,
  ];
}
