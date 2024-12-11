import 'dart:collection';

class Stack<E> with IterableMixin<E> {
  Stack(this.maxSize) : assert(maxSize >= 0);

  final int maxSize;

  final _list = <E>[];

  @override
  Iterator<E> get iterator => _list.iterator;

  int get size => _list.length;

  int indexOf(E element, [int start = 0]) => _list.indexOf(element, start);

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) => _list[index] = value;

  void removeRange(int start, int end) => _list.removeRange(start, end);

  List<E> sublist(int start, [int? end]) => _list.sublist(start, end);

  void clear() => _list.clear();

  E pop() => _list.removeLast();

  void push(E value) {
    if (_list.length >= maxSize) {
      throw RangeError.range(_list.length + 1, 0, maxSize);
    }
    _list.add(value);
  }

  void pushAll(Iterable<E> iterable) {
    if (_list.length + iterable.length > maxSize) {
      throw RangeError.range(_list.length + iterable.length, 0, maxSize);
    }
    _list.addAll(iterable);
  }
}
