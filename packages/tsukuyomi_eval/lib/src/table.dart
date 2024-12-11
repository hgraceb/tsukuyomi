import 'dart:collection';

class Table<E> {
  final _hashMap = HashMap<String, E>();

  E? operator [](String key) => _hashMap[key];

  void operator []=(String key, E value) => _hashMap[key] = value;

  bool containsKey(String key) => _hashMap.containsKey(key);

  void addAll(Table<E> other) => _hashMap.addAll(other._hashMap);
}
