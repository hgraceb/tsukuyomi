import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  test('Literal set', () {
    const source = '''
void main() {
  print(<int>{});
  print({1, 2, 3});
  print(Set.from({1, 2, 3}));
}
    ''';
    final expected1 = <int>{};
    final expected2 = {1, 2, 3};
    final expected3 = Set.from({1, 2, 3});
    expectLater(() => eval(source), println([expected1, expected2, expected3]));
  });

  test('Literal map', () {
    const source = '''
void main() {
  print({});
  print({'key1': 'value1', 'key2': 'value2', 'key3': 'value3'});
  print(Map.fromIterable([1, 2, 3]));
}
    ''';
    final expected1 = {};
    final expected2 = {'key1': 'value1', 'key2': 'value2', 'key3': 'value3'};
    final expected3 = Map.fromIterable([1, 2, 3]);
    expectLater(() => eval(source), println([expected1, expected2, expected3]));
  });

  test('Literal list', () {
    const source = '''
void main() {
  print([]);
  print([1, 2, 3]);
  print(List.of({1, 2, 3}));
}
    ''';
    final expected1 = [];
    final expected2 = [1, 2, 3];
    final expected3 = List.of({1, 2, 3});
    expectLater(() => eval(source), println([expected1, expected2, expected3]));
  });

  test('Literal null', () {
    const source = '''
void main() {
  print(null);
}
    ''';
    expectLater(() => eval(source), println([null]));
  });

  test('Literal boolean', () {
    const source = '''
void main() {
  print(true);
  print(false);
}
    ''';
    expectLater(() => eval(source), println([true, false]));
  });

  test('Literal integer', () {
    const source = '''
void main() {
  print(10);
  print(020);
  print(0x1e);
  print(0x28);
  print(0X032);
  print(0X03C);
}
    ''';
    expectLater(() => eval(source), println([10, 20, 30, 40, 50, 60]));
  });

  test('Literal double', () {
    const source = '''
void main() {
  print(.10000);
  print(0000.2);
  print(0.03e1);
  print(0.4e+0);
  print(5.0E-1);
  print(600E-3);
}
    ''';
    expectLater(() => eval(source), println([0.1, 0.2, 0.3, 0.4, 0.5, 0.6]));
  });
}
