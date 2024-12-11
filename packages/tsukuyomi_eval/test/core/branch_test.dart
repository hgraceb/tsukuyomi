import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  test('Conditional operator', () {
    const source = '''
void main() {
  true ? print(1) : (throw AssertionError());
  false ? (throw AssertionError()) : print(2);
  true ? true ? print(3) : (throw AssertionError()) : (throw AssertionError());
  false ? (throw AssertionError()) : false ? (throw AssertionError()) : print(4);
}
    ''';
    expectLater(() => eval(source), println([1, 2, 3, 4]));
  });

  test('If-else', () {
    const source = '''
void main() {
  if (0 <= 0) {
    if (0 >= 0) print(1);
    print(2);
  }

  if (0 != 0)
    throw AssertionError();
  else if (0 == 0)
    print(3);
  else
    throw AssertionError();

  if (0 > 0) {
    throw AssertionError();
  } else if (0 < 0) {
    throw AssertionError();
  } else {
    print(4);
  }
}
    ''';
    expectLater(() => eval(source), println([1, 2, 3, 4]));
  });
}
