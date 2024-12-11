import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  test('Async function without await anything', () {
    const source = '''
Future<void> foo() async {
  print(2);
}

Future<int> bar() async {
  print(4);
  return 0;
}

Future<int> main() async {
  print(1);
  foo();
  print(3);
  return bar();
}
    ''';
    expectLater(() => expectLater(eval(source), completion(0)), println([1, 2, 3, 4]));
  });

  test('Async function with await anything', () {
    const source = '''
Future<void> foo() async {
  print(2);
  await Future.delayed(const Duration());
  print(10);
}

Future<void> bar() async {
  print(4);
  await Object();
  print(8);
}

Future<void> baz() async {
  print(6);
  await null;
  print(9);
}

Future<int> main() async {
  print(1);
  foo();
  print(3);
  bar();
  print(5);
  baz();
  print(7);
  return Future.delayed(const Duration(), () => 0);
}
    ''';
    expectLater(() => expectLater(eval(source), completion(0)), println([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
  });

  test('Async function as an argument', () {
    const source = '''
Future<List<Future<int>>> main() async {
  const length = 2;
  return List.generate(length, (index) async {
    print(index + 1);
    await null;
    print(index + length + 1);
    return index + 1;
  });
}
    ''';
    expectLater(() => expectLater(eval(source), completion([completion(1), completion(2)])), println([1, 2, 3, 4]));
  });
}
