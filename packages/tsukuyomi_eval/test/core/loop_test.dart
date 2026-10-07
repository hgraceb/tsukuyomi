import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Loop scope cleanup', () {
    test('for break leaves nested scopes', () async {
      const source = '''
void main() {
  final outer = 1;
  print(outer);
  for (var i = 0; i < 1; i++) {
    final value = 2;
    {
      final nestedValue = 3;
      print(value);
      print(nestedValue);
      break;
    }
  }
  final value = 4;
  print(value);
  print(outer + value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4, 5]));
    });

    test('for continue keeps locals available in other branches', () async {
      const source = '''
void main() {
  for (var i = 1; i < 4; i++) {
    final value = i;
    {
      final nestedValue = value;
      if (i < 3) {
        print(nestedValue);
        continue;
      }
      print(nestedValue);
    }
    final nextValue = value + 1;
    print(nextValue);
  }
  final value = 5;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4, 5]));
    });

    test('while break leaves nested scopes', () async {
      const source = '''
void main() {
  while (true) {
    final value = 1;
    {
      final nestedValue = value + 1;
      print(value);
      print(nestedValue);
      break;
    }
  }
  final value = 3;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('while continue leaves nested scopes', () async {
      const source = '''
void main() {
  var i = 0;
  while (i < 3) {
    i++;
    final value = i;
    {
      final nestedValue = value;
      print(nestedValue);
      if (i < 3) continue;
    }
  }
  final value = 4;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('do-while break leaves nested scopes', () async {
      const source = '''
void main() {
  do {
    final value = 1;
    {
      final nestedValue = value + 1;
      print(value);
      print(nestedValue);
      break;
    }
  } while (false);
  final value = 3;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('do-while continue cleans locals before checking the condition', () async {
      const source = '''
void main() {
  var i = 1;
  do {
    final value = i;
    {
      final nestedValue = value;
      print(nestedValue);
      if (i < 3) continue;
    }
  } while (++i < 4);
  final value = i;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('for break closes captured initializer and body locals', () async {
      const source = '''
void main() {
  var first = () => 0;
  var second = () => 0;
  for (var i = 1; i < 2; i++) {
    first = () => i;
    {
      final value = i + 1;
      second = () => value;
      break;
    }
  }
  final value = 3;
  final nextValue = 4;
  print(first());
  print(second());
  print(value);
  print(nextValue);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('while break closes captured nested locals before reusing their slots', () async {
      const source = '''
void main() {
  var first = () => 0;
  var second = () => 0;
  while (true) {
    final value = 1;
    first = () => value;
    {
      final nestedValue = value + 1;
      second = () => nestedValue;
      break;
    }
  }
  final value = 3;
  final nextValue = 4;
  print(first());
  print(second());
  print(value);
  print(nextValue);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('for continue closes captured body locals each iteration', () async {
      const source = '''
void main() {
  final callbacks = [];
  for (var i = 1; i < 4; i++) {
    final value = i;
    callbacks.add(() => value);
    continue;
  }
  final value = 4;
  callbacks.forEach((callback) => print(callback()));
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('while continue closes captured body locals each iteration', () async {
      const source = '''
void main() {
  final callbacks = [];
  var i = 0;
  while (i < 3) {
    i++;
    final value = i;
    callbacks.add(() => value);
    continue;
  }
  final value = 4;
  callbacks.forEach((callback) => print(callback()));
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('do-while continue closes captured body locals each iteration', () async {
      const source = '''
void main() {
  final callbacks = [];
  var i = 1;
  do {
    final value = i;
    callbacks.add(() => value);
    continue;
  } while (++i < 4);
  final value = i;
  callbacks.forEach((callback) => print(callback()));
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('nested loops preserve outer locals', () async {
      const source = '''
void main() {
  final outer = 1;
  while (true) {
    var value = 2;
    final callback = () => value;
    while (true) {
      final nestedValue = 3;
      print(outer);
      print(value);
      print(nestedValue);
      break;
    }
    final nextValue = 4;
    print(nextValue);
    value = nextValue + outer;
    print(callback());
    break;
  }
  final value = 6;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4, 5, 6]));
    });

    test('for without a condition cleans locals on continue and break', () async {
      const source = '''
void main() {
  for (var i = 1;; i++) {
    final value = i;
    print(value);
    if (i < 3) continue;
    break;
  }
  final value = 4;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('for without initialization or a condition cleans locals on break', () async {
      const source = '''
void main() {
  for (;;) {
    final value = 1;
    print(value);
    break;
  }
  final value = 2;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('for discards each updater result', () async {
      const source = '''
void main() {
  var nextValue = 1;
  for (var i = 1; i < 4; i++, nextValue++) {
    print(i);
  }
  print(nextValue);
  final value = 5;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4, 5]));
    });

    test('continue and break after await clean nested locals', () async {
      const source = '''
Future<void> main() async {
  for (var i = 1; i < 4; i++) {
    final value = i;
    await null;
    {
      final nestedValue = value;
      print(nestedValue);
      if (i < 3) continue;
      break;
    }
  }
  final value = 4;
  await null;
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });
  });

  group('For loop', () {
    test('with declaration', () {
      const source = '''
void main() {
  int i = 5;
  for (int i = 1; i < 4; i++) {
    print(i);
  }
  for (int i = 4; i < 5; i++) {
    int i = 2;
    print(i + 2);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with expression', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 4; i++) {
    print(i);
  }
  for (i = 4; i < 5; i++) {
    int i = 2;
    print(i + 2);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with continue', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 10; i++) {
    if (i >= 5) continue;
    print(i);
  }
  print(i - 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with break', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 10; i++) {
    if (i >= 5) break;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with return', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 10; i++) {
    if (i > 5) return;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });

  group('While loop', () {
    test('with condition', () {
      const source = '''
void main() {
  int i = 0;
  while (i++ < 5) {
    print(i);
  }
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with continue', () {
      const source = '''
void main() {
  int i = 0;
  while (++i < 10) {
    if (i >= 5) continue;
    print(i);
  }
  print(i - 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with break', () {
      const source = '''
void main() {
  int i = 0;
  while (++i < 10) {
    if (i >= 5) break;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with return', () {
      const source = '''
void main() {
  int i = 0;
  while (++i < 10) {
    if (i > 5) return;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });

  group('Do-while loop', () {
    test('with condition', () {
      const source = '''
void main() {
  int i = 1;
  do {
    print(i);
  } while (i++ < 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with continue', () {
      const source = '''
void main() {
  int i = 1;
  do {
    if (i >= 5) continue;
    print(i);
  } while (++i < 10);
  print(i - 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with break', () {
      const source = '''
void main() {
  int i = 1;
  do {
    if (i >= 5) break;
    print(i);
  } while (++i < 10);
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with return', () {
      const source = '''
void main() {
  int i = 1;
  do {
    if (i > 5) return;
    print(i);
  } while (++i < 10);
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });
}
