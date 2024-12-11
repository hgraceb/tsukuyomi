import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  test('Type of list', () {
    const source = '''
void main() {
  print([0].runtimeType);
  print(<int>[0].runtimeType);
  print(<num>[0].runtimeType);
}
    ''';
    final matcher = [
      [0].runtimeType,
      <int>[0].runtimeType,
      <num>[0].runtimeType,
    ];
    expectLater(() => eval(source), println(matcher));
  });

  test('Type of set', () {
    const source = '''
void main() {
  print({0}.runtimeType);
  print(<int>{0}.runtimeType);
  print(<num>{0}.runtimeType);
}
    ''';
    final matcher = [
      {0}.runtimeType,
      <int>{0}.runtimeType,
      <num>{0}.runtimeType,
    ];
    expectLater(() => eval(source), println(matcher));
  });

  test('Type of map', () {
    const source = '''
void main() {
  print({0: 0}.runtimeType);
  print(<int, int>{0: 0}.runtimeType);
  print(<int, num>{0: 0}.runtimeType);
}
    ''';
    final matcher = [
      {0: 0}.runtimeType,
      <int, int>{0: 0}.runtimeType,
      <int, num>{0: 0}.runtimeType,
    ];
    expectLater(() => eval(source), println(matcher));
  });
}
