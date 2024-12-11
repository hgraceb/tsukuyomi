import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Function loop invocations', () {
    test('in for loop', () {
      const source = '''
void main() {
  for (var i = 1; i < 5; i++) {
    ((i) => print(i))(i);
  }
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('in while loop', () {
      const source = '''
void main() {
  int i = 1;
  while (i < 5) {
    ((i) => print(i))(i++);
  }
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });

    test('in do-while loop', () {
      const source = '''
void main() {
  int i = 1;
  do {
    ((i) => print(i))(i++);
  } while (i < 5);
}
      ''';
      expect(() => eval(source), println([1, 2, 3, 4]));
    });
  });

  group('Function recursive invocations', () {
    test('in local scope', () {
      const source = '''
void main() {
  int fib(int n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
  }

  print(fib(10));
}
      ''';
      expect(() => eval(source), println([55]));
    });

    test('in global scope', () {
      const source = '''
int fib(int n) {
  if (n < 2) return n;
  return fib(n - 1) + fib(n - 2);
}

void main() {
  print(fib(10));
}
      ''';
      expect(() => eval(source), println([55]));
    });

    test('in static scope', () {
      const source = '''
class Class {
  static int fib(int n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
  }
}

void main() {
  print(Class.fib(10));
}
      ''';
      expect(() => eval(source), println([55]));
    });

    test('in instance scope', () {
      const source = '''
class Class {
  int fib(int n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
  }
}

void main() {
  print(Class().fib(10));
}
      ''';
      expect(() => eval(source), println([55]));
    });
  });

  group('Function positional parameters', () {
    final matcherPrintln = println([
      'p1: v1, p2: v2, p3: null, p4: d4.',
      'p1: v1, p2: v2, p3: v3, p4: d4.',
      'p1: v1, p2: v2, p3: v3, p4: v4.',
    ]);

    final throwsRequired = throwsA(
      isA<EvalRuntimeError>().having((e) => e.toString(), 'message', contains('is required')),
    );

    test('in local scope', () {
      expect(() => eval(r'''
void main() {
  void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }

  function('v1', 'v2');
  function('v1', 'v2', 'v3');
  function('v1', 'v2', 'v3', 'v4');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
void main() {
  void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }

  function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
void main() {
  void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }

  function('v1');
}
      '''), throwsRequired);
    });

    test('in global scope', () {
      expect(() => eval(r'''
void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
  print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
}

void main() {
  function('v1', 'v2');
  function('v1', 'v2', 'v3');
  function('v1', 'v2', 'v3', 'v4');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
  print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
}

void main() {
  function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
  print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
}

void main() {
  function('v1');
}
      '''), throwsRequired);
    });

    test('in static scope', () {
      expect(() => eval(r'''
class Class {
  static void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class.function('v1', 'v2');
  Class.function('v1', 'v2', 'v3');
  Class.function('v1', 'v2', 'v3', 'v4');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
class Class {
  static void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class.function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
class Class {
  static void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class.function('v1');
}
      '''), throwsRequired);
    });

    test('in instance scope', () {
      expect(() => eval(r'''
class Class {
  void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class().function('v1', 'v2');
  Class().function('v1', 'v2', 'v3');
  Class().function('v1', 'v2', 'v3', 'v4');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
class Class {
  void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class().function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
class Class {
  void function(String p1, String p2, [String? p3, String p4 = 'd4']) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class().function('v1');
}
      '''), throwsRequired);
    });
  });

  group('Function named parameters', () {
    final matcherPrintln = println([
      'p1: v1, p2: v2, p3: null, p4: d4.',
      'p1: v1, p2: v2, p3: v3, p4: d4.',
      'p1: v1, p2: v2, p3: v3, p4: v4.',
    ]);

    final throwsRequired = throwsA(
      isA<EvalRuntimeError>().having((e) => e.toString(), 'message', contains('is required')),
    );

    test('in local scope', () {
      expect(() => eval(r'''
void main() {
  void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }

  function('v1', p2: 'v2');
  function(p3: 'v3', 'v1', p2: 'v2');
  function(p4: 'v4', p2: 'v2', 'v1', p3: 'v3');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
void main() {
  void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }

  function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
void main() {
  void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }

  function('v1');
}
      '''), throwsRequired);
    });

    test('in global scope', () {
      expect(() => eval(r'''
void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
  print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
}

void main() {
  function('v1', p2: 'v2');
  function(p3: 'v3', 'v1', p2: 'v2');
  function(p4: 'v4', p2: 'v2', 'v1', p3: 'v3');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
  print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
}

void main() {
  function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
  print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
}

void main() {
  function('v1');
}
      '''), throwsRequired);
    });

    test('in static scope', () {
      expect(() => eval(r'''
class Class {
  static void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class.function('v1', p2: 'v2');
  Class.function(p3: 'v3', 'v1', p2: 'v2');
  Class.function(p4: 'v4', p2: 'v2', 'v1', p3: 'v3');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
class Class {
  static void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class.function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
class Class {
  static void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class.function('v1');
}
      '''), throwsRequired);
    });

    test('in instance scope', () {
      expect(() => eval(r'''
class Class {
  void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class().function('v1', p2: 'v2');
  Class().function(p3: 'v3', 'v1', p2: 'v2');
  Class().function(p4: 'v4', p2: 'v2', 'v1', p3: 'v3');
}
      '''), matcherPrintln);

      expect(() => eval(r'''
class Class {
  void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class().function();
}
      '''), throwsRequired);

      expect(() => eval(r'''
class Class {
  void function(String p1, {required String? p2, String? p3, String p4 = 'd4'}) {
    print('p1: $p1, p2: $p2, p3: $p3, p4: $p4.');
  }
}

void main() {
  Class().function('v1');
}
      '''), throwsRequired);
    });
  });

  test('Global function expression invocations', () {
    const source = '''
int function1() => 1;

int function2() {
  const function = function1;
  return function() + 1;
}

void main() {
  const reference1 = function1;
  const reference2 = function2;
  print(reference1());
  print(reference2());
}
      ''';
    expect(() => eval(source), println([1, 2]));
  });

  test('Instance method expression invocations', () {
    const source = '''
class Class {
  int function1() => 1;

  int function2() {
    final function = function1;
    return function() + 1;
  }
}

void main() {
  final instance = Class();
  final reference1 = instance.function1;
  final reference2 = instance.function2;
  print(reference1());
  print(reference2());
}
      ''';
    expect(() => eval(source), println([1, 2]));
  });
}
