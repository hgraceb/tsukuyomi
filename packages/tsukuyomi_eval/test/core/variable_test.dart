import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Variable accessors', () {
    test('in global scope', () {
      const source = '''
int variable = 1;

int get getter => variable + 1;

set setter(int value) => variable = value - 1;

void main() {
  print(variable);
  print(getter);
  setter = getter + 1;
  print(getter);
  print(setter = getter + 1);
  print(getter + 1);
  print(getter + variable - 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static int variable = 1;

  static int get getter => variable + 1;

  static set setter(int value) => variable = value - 1;
}

void main() {
  print(Class.variable);
  print(Class.getter);
  Class.setter = Class.getter + 1;
  print(Class.getter);
  print(Class.setter = Class.getter + 1);
  print(Class.getter + 1);
  print(Class.getter + Class.variable - 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  int variable = 1;

  int get getter => variable + 1;

  set setter(int value) => variable = value - 1;
}

void main() {
  final instance = Class();
  print(instance.variable);
  print(instance.getter);
  instance.setter = instance.getter + 1;
  print(instance.getter);
  print(instance.setter = instance.getter + 1);
  print(instance.getter + 1);
  print(instance.getter + instance.variable - 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });
  });

  group('Variable with default value of null', () {
    test('in local scope', () {
      const source = '''
void main() {
  dynamic variable1;
  Object? variable2;
  print(variable1);
  print(variable2);
}
      ''';
      expect(() => eval(source), println([null, null]));
    });

    test('in global scope', () {
      const source = '''
dynamic variable1;
Object? variable2;

void main() {
  print(variable1);
  print(variable2);
}
      ''';
      expect(() => eval(source), println([null, null]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static dynamic variable1;
  static Object? variable2;
}

void main() {
  print(Class.variable1);
  print(Class.variable2);
}
      ''';
      expect(() => eval(source), println([null, null]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  dynamic variable1;
  Object? variable2;
}

void main() {
  final instance = Class();
  print(instance.variable1);
  print(instance.variable2);
}
      ''';
      expect(() => eval(source), println([null, null]));
    });
  });

  group('Variable with unary prefix operator ++', () {
    test('in index scope', () {
      const source = '''
void main() {
  final array = [1];
  void update() => ++array[0];
  print(array[0]);
  print(++array[0]);
  print(array[0] + 1);
  print(++array[0] + 1);
  ++array[0];
  print(array[0] + 1);
  update();
  print(array[0] + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in local scope', () {
      const source = '''
void main() {
  int variable = 1;
  void update() => ++variable;
  print(variable);
  print(++variable);
  print(variable + 1);
  print(++variable + 1);
  ++variable;
  print(variable + 1);
  update();
  print(variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in global scope', () {
      const source = '''
int variable = 1;

void update() => ++variable;

void main() {
  print(variable);
  print(++variable);
  print(variable + 1);
  print(++variable + 1);
  ++variable;
  print(variable + 1);
  update();
  print(variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static int variable = 1;

  static void update() => ++variable;
}

void main() {
  print(Class.variable);
  print(++Class.variable);
  print(Class.variable + 1);
  print(++Class.variable + 1);
  ++Class.variable;
  print(Class.variable + 1);
  Class.update();
  print(Class.variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  int variable = 1;

  void update() => ++variable;
}

void main() {
  final instance = Class();
  print(instance.variable);
  print(++instance.variable);
  print(instance.variable + 1);
  print(++instance.variable + 1);
  ++instance.variable;
  print(instance.variable + 1);
  instance.update();
  print(instance.variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });
  });

  group('Variable with unary prefix operator --', () {
    test('in index scope', () {
      const source = '''
void main() {
  final array = [6];
  void update() => --array[0];
  print(array[0]);
  print(--array[0]);
  print(array[0] - 1);
  print(--array[0] - 1);
  --array[0];
  print(array[0] - 1);
  update();
  print(array[0] - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in local scope', () {
      const source = '''
void main() {
  int variable = 6;
  void update() => --variable;
  print(variable);
  print(--variable);
  print(variable - 1);
  print(--variable - 1);
  --variable;
  print(variable - 1);
  update();
  print(variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in global scope', () {
      const source = '''
int variable = 6;

void update() => --variable;

void main() {
  print(variable);
  print(--variable);
  print(variable - 1);
  print(--variable - 1);
  --variable;
  print(variable - 1);
  update();
  print(variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static int variable = 6;

  static void update() => --variable;
}

void main() {
  print(Class.variable);
  print(--Class.variable);
  print(Class.variable - 1);
  print(--Class.variable - 1);
  --Class.variable;
  print(Class.variable - 1);
  Class.update();
  print(Class.variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  int variable = 6;

  void update() => --variable;
}

void main() {
  final instance = Class();
  print(instance.variable);
  print(--instance.variable);
  print(instance.variable - 1);
  print(--instance.variable - 1);
  --instance.variable;
  print(instance.variable - 1);
  instance.update();
  print(instance.variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });
  });

  group('Variable with unary postfix operator ++', () {
    test('in index scope', () {
      const source = '''
void main() {
  final array = [1];
  void update() => array[0]++;
  print(array[0]);
  update();
  print(array[0]);
  array[0]++;
  print(array[0]++);
  print(array[0]);
  print(array[0]++ + 1);
  print(array[0] + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in local scope', () {
      const source = '''
void main() {
  int variable = 1;
  void update() => variable++;
  print(variable);
  update();
  print(variable);
  variable++;
  print(variable++);
  print(variable);
  print(variable++ + 1);
  print(variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in global scope', () {
      const source = '''
int variable = 1;

void update() => variable++;

void main() {
  print(variable);
  update();
  print(variable);
  variable++;
  print(variable++);
  print(variable);
  print(variable++ + 1);
  print(variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static int variable = 1;

  static void update() => variable++;
}

void main() {
  print(Class.variable);
  Class.update();
  print(Class.variable);
  Class.variable++;
  print(Class.variable++);
  print(Class.variable);
  print(Class.variable++ + 1);
  print(Class.variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  int variable = 1;

  void update() => variable++;
}

void main() {
  final instance = Class();
  print(instance.variable);
  instance.update();
  print(instance.variable);
  instance.variable++;
  print(instance.variable++);
  print(instance.variable);
  print(instance.variable++ + 1);
  print(instance.variable + 1);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
    });
  });

  group('Variable with unary postfix operator --', () {
    test('in index scope', () {
      const source = '''
void main() {
  final array = [6];
  void update() => array[0]--;
  print(array[0]);
  update();
  print(array[0]);
  array[0]--;
  print(array[0]--);
  print(array[0]);
  print(array[0]-- - 1);
  print(array[0] - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in local scope', () {
      const source = '''
void main() {
  int variable = 6;
  void update() => variable--;
  print(variable);
  update();
  print(variable);
  variable--;
  print(variable--);
  print(variable);
  print(variable-- - 1);
  print(variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in global scope', () {
      const source = '''
int variable = 6;

void update() => variable--;

void main() {
  print(variable);
  update();
  print(variable);
  variable--;
  print(variable--);
  print(variable);
  print(variable-- - 1);
  print(variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static int variable = 6;

  static void update() => variable--;
}

void main() {
  print(Class.variable);
  Class.update();
  print(Class.variable);
  Class.variable--;
  print(Class.variable--);
  print(Class.variable);
  print(Class.variable-- - 1);
  print(Class.variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  int variable = 6;

  void update() => variable--;
}

void main() {
  final instance = Class();
  print(instance.variable);
  instance.update();
  print(instance.variable);
  instance.variable--;
  print(instance.variable--);
  print(instance.variable);
  print(instance.variable-- - 1);
  print(instance.variable - 1);
}
      ''';
      expect(() => eval(source), println([6, 5, 4, 3, 2, 1]));
    });
  });

  group('Variable declarations with function type', () {
    test('in local scope', () {
      const source = '''
void main() {
  final function1 = (int value) => value + 1;
  final function2 = (int value) {
    return function1(value) + value + 1;
  };
  print(function1(0));
  print(function2(0));
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });

    test('in global scope', () {
      const source = '''
final function1 = (int value) => value + 1;
final function2 = (int value) {
  return function1(value) + value + 1;
};

void main() {
  print(function1(0));
  print(function2(0));
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static final function1 = (int value) => value + 1;
  static final function2 = (int value) {
    return function1(value) + value + 1;
  };
}

void main() {
  print(Class.function1(0));
  print(Class.function2(0));
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  final function1 = (int value) => value + 1;
  final function2 = (int value) {
    return Class().function1(value) + value + 1;
  };
}

void main() {
  final instance = Class();
  print(instance.function1(0));
  print(instance.function2(0));
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });
  });

  group('Variable declarations with function initializer', () {
    test('in local scope', () {
      const source = '''
void main() {
  final variable1 = (() => 1)();
  final variable2 = (value) {
    return value + variable1;
  }(variable1);
  print(variable1);
  print(variable2);
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });

    test('in global scope', () {
      const source = '''
final variable1 = (() => 1)();
final variable2 = (value) {
  return value + variable1;
}(variable1);

void main() {
  print(variable1);
  print(variable2);
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static final variable1 = (() => 1)();
  static final variable2 = (value) {
    return value + variable1;
  }(variable1);
}

void main() {
  print(Class.variable1);
  print(Class.variable2);
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  final variable1 = (() => 1)();
  final variable2 = (value) {
    return value + Class().variable1;
  }(Class().variable1);
}

void main() {
  final instance = Class();
  print(instance.variable1);
  print(instance.variable2);
}
      ''';
      expect(() => eval(source), println([1, 2]));
    });
  });
}
