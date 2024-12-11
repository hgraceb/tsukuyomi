import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Type test operator', () {
    test('is', () {
      const source = '''
void main() {
  print(0 is int);
  print(0 is dynamic);
  print(0 is double);
  print(0 is String);
}
      ''';
      expect(() => eval(source), println([true, true, false, false]));
    });

    test('is!', () {
      const source = '''
void main() {
  print(0 is! int);
  print(0 is! dynamic);
  print(0 is! double);
  print(0 is! String);
}
      ''';
      expect(() => eval(source), println([false, false, true, true]));
    });
  });

  group('Unary prefix operator', () {
    test('-', () {
      const source = '''
void main() {
  print(-(-1));
  print(-(-2));
  print(-(-(3)));
  print(-(-(4)));
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('~', () {
      const source = '''
void main() {
  print(~(-2));
  print(~(-3));
  print(~(~3));
  print(~(~4));
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('!', () {
      const source = '''
void main() {
  print(!false);
  print(!true);
  print(!!true);
  print(!!false);
}
      ''';
      expect(() => eval(source), println([true, false, true, false]));
    });
  });

  group('Unary postfix operator', () {
    test('!', () {
      const source = '''
void main() {
  try {
    null!;
  } catch (e) {
    print(1);
  }
  try {
    dynamic foo;
    foo!;
  } catch (e) {
    print(2);
  }
  try {
    const foo = null;
    foo!;
  } catch (e) {
    print(3);
  }
  print(4!);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('?.property', () {
      const source = '''
void main() {
  print(null.runtimeType);
  print(null?.runtimeType);
  print(null?.runtimeType.runtimeType);
  print(null?.runtimeType?.runtimeType);
}
      ''';
      expect(() => eval(source), println(['Null', 'null', 'null', 'null']));
    });

    test('?.method', () {
      const source = '''
void main() {
  print(null.toString());
  print(null?.toString());
  print(null?.toString().toString());
  print(null?.toString()?.toString());
}
      ''';
      expect(() => eval(source), println(['null', 'null', 'null', 'null']));
    });
  });

  group('Binary operator', () {
    test('+', () {
      const source = '''
void main() {
  print(0.5 + 0.5);
  print(0.5 + 1.5);
  print(0.5 + 3.5 + -1);
  print(0.5 + 5.5 + -2);
}
      ''';
      expect(() => eval(source), println([1.0, 2.0, 3.0, 4.0]));
    });

    test('-', () {
      const source = '''
void main() {
  print(0.5 - -0.5);
  print(0.5 - -1.5);
  print(0.5 - -3.5 - 1);
  print(0.5 - -5.5 - 2);
}
      ''';
      expect(() => eval(source), println([1.0, 2.0, 3.0, 4.0]));
    });

    test('*', () {
      const source = '''
void main() {
  print(0.5 * 2.0);
  print(0.5 * 4.0);
  print(0.5 * 0.5 * 12);
  print(0.5 * 0.5 * 16);
}
      ''';
      expect(() => eval(source), println([1.0, 2.0, 3.0, 4.0]));
    });

    test('/', () {
      const source = '''
void main() {
  print(0.5 / 0.5);
  print(0.5 / 0.5 / 0.5);
  print(0.5 / 0.5 / (0.5 / 1.5));
  print(0.5 / 0.5 / (0.5 / 2.0));
}
      ''';
      expect(() => eval(source), println([1.0, 2.0, 3.0, 4.0]));
    });

    test('%', () {
      const source = '''
void main() {
  print(3.5 % 2.5);
  print(5.5 % 3.5);
  print(7.5 % 9.5 % 4.5);
  print(8.5 % 9.5 % 4.5);
}
      ''';
      expect(() => eval(source), println([1.0, 2.0, 3.0, 4.0]));
    });

    test('~/', () {
      const source = '''
void main() {
  print(2.3 ~/ 1.2);
  print(3.4 ~/ 1.2);
  print(5.6 ~/ 1.2 ~/ 1.2);
  print(6.7 ~/ 1.2 ~/ 1.2);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('&', () {
      const source = '''
void main() {
  print(3 & 5);
  print(3 & 6);
  print(3 & 7 & 15);
  print(5 & 6 & 15);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('^', () {
      const source = '''
void main() {
  print(2 ^ 3);
  print(1 ^ 3);
  print(2 ^ 4 ^ 5);
  print(2 ^ 3 ^ 5);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('|', () {
      const source = '''
void main() {
  print(0 | 1);
  print(2 | 0);
  print(1 | 0 | 2);
  print(0 | 4 | 0);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('<<', () {
      const source = '''
void main() {
  print(1 << 0);
  print(1 << 1);
  print(1 << 1 << 1);
  print(1 << 1 << 2);
}
      ''';
      expect(() => eval(source), println([1, 2, 4, 8]));
    });

    test('>>', () {
      const source = '''
void main() {
  print(8 >> 0);
  print(8 >> 1);
  print(8 >> 1 >> 1);
  print(8 >> 1 >> 2);
}
      ''';
      expect(() => eval(source), println([8, 4, 2, 1]));
    });

    test('>>>', () {
      const source = '''
void main() {
  print(-1 >>> 1);
  print(-1 >>> 2);
  print(-1 >>> 3 >>> 3);
  print(-1 >>> 4 >>> 4);
}
      ''';
      expect(() => eval(source), println([-1 >>> 1, -1 >>> 2, -1 >>> 3 >>> 3, -1 >>> 4 >>> 4]));
    });

    test('>', () {
      const source = '''
void main() {
  print(0 > 1);
  print(1 > 1);
  print(2 > 1);
}
      ''';
      expect(() => eval(source), println([false, false, true]));
    });

    test('<', () {
      const source = '''
void main() {
  print(0 < 1);
  print(1 < 1);
  print(2 < 1);
}
      ''';
      expect(() => eval(source), println([true, false, false]));
    });

    test('>=', () {
      const source = '''
void main() {
  print(0 >= 1);
  print(1 >= 1);
  print(2 >= 1);
}
      ''';
      expect(() => eval(source), println([false, true, true]));
    });

    test('<=', () {
      const source = '''
void main() {
  print(0 <= 1);
  print(1 <= 1);
  print(2 <= 1);
}
      ''';
      expect(() => eval(source), println([true, true, false]));
    });

    test('==', () {
      const source = '''
void main() {
  print(0 == 1);
  print(1 == 1);
  print(2 == 1);
}
      ''';
      expect(() => eval(source), println([false, true, false]));
    });

    test('!=', () {
      const source = '''
void main() {
  print(0 != 1);
  print(1 != 1);
  print(2 != 1);
}
      ''';
      expect(() => eval(source), println([true, false, true]));
    });

    test('&&', () {
      const source = '''
void main() {
  print(true && true);
  print(true && false);
  print(false && (throw AssertionError()));
  print(true && true && true);
  print(true && true && false);
  print(true && false && (throw AssertionError()));
}
      ''';
      expect(() => eval(source), println([true, false, false, true, false, false]));
    });

    test('||', () {
      const source = '''
void main() {
  print(false || false);
  print(false || true);
  print(true || (throw AssertionError()));
  print(false || false || false);
  print(false || false || true);
  print(false || true || (throw AssertionError()));
}
      ''';
      expect(() => eval(source), println([false, true, true, false, true, true]));
    });

    test('??', () {
      const source = '''
void main() {
  print(1 ?? (throw AssertionError()));
  print(null ?? 2);
  print(3 ?? (throw AssertionError()) ?? (throw AssertionError()));
  print(null ?? 4 ?? (throw AssertionError()));
  print(null ?? null ?? 5);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });

  group('Ternary operator', () {
    test('[]=', () {
      const source = '''
void main() {
  final list = [1];
  print(list[0]);
  list[0] = list[0] + 1;
  print(list[0]);
  list..[0] = list[0] + 1;
  print(list[0]);
  print(list[0] = list[0] + 1);
  print((list..[0] = list[0] + 1)[0]);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });

  group('Cascade operator', () {
    test('..', () {
      const source = '''
class Class {
  Class? self;

  int field = 0;

  dynamic get getter => print(field++);

  set setter(int value) => print(value);

  void method(int value) => print(value);
}

void main() {
  final instance = Class();
  instance
    ..self?.field
    ..self?.field = 0
    ..self?.getter
    ..self?.setter = instance.field++
    ..self?.method(instance.field++)
    ..self = instance
    ..self?.field
    ..self?.field = 1
    ..self?.getter
    ..self?.setter = instance.field++
    ..self?.method(instance.field++);
}
      ''';
      expect(() => eval(source), println([1, 2, 3]));
    });

    test('?..', () {
      const source = '''
class Class {
  Class? self;

  int field = 0;

  dynamic get getter => print(field++);

  set setter(int value) => print(value);

  void method(int value) => print(value);
}

void main() {
  Class? instance;
  instance
    ?..self?.field
    ..self?.field = 0
    ..self?.getter
    ..self?.setter = instance.field++
    ..self?.method(instance.field++)
    ..self = instance
    ..self?.field
    ..self?.field = 0
    ..self?.getter
    ..self?.setter = instance.field++
    ..self?.method(instance.field++);
  instance = Class() as dynamic;
  instance
    ?..self?.field
    ..self?.field = 0
    ..self?.getter
    ..self?.setter = instance.field++
    ..self?.method(instance.field++)
    ..self = instance
    ..self?.field
    ..self?.field = 1
    ..self?.getter
    ..self?.setter = instance.field++
    ..self?.method(instance.field++);
}
      ''';
      expect(() => eval(source), println([1, 2, 3]));
    });
  });
}
