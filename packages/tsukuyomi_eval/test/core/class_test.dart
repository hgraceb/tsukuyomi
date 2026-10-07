import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Instance field initialization', () {
    test('fields are read and written per instance', () async {
      const source = '''
class Example {
  int value = 0;
}

void main() {
  final first = Example();
  final second = Example();
  print(first.value);
  print(second.value);
  first.value = 1;
  print(first.value);
  print(second.value);
  second.value = 2;
  print(first.value);
  print(second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([0, 0, 1, 0, 1, 2]));
    });

    test('fields without initializers remain independent', () async {
      const source = '''
class Example {
  int? first, second;
}

void main() {
  final first = Example();
  final second = Example();
  print(first.first);
  print(first.second);
  first.first = 1;
  first.second = 2;
  print(first.first);
  print(first.second);
  print(second.first);
  print(second.second);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([null, null, 1, 2, null, null]));
    });

    test('mutable and nested initializers are evaluated per instance', () async {
      const source = '''
class Example {
  final values = <int>[];
  final entries = <String, dynamic>{'values': <int>[]};
}

void main() {
  final first = Example();
  final second = Example();
  first.values.add(1);
  first.entries['values']!.add(2);
  print(first.values);
  print(second.values);
  print(first.entries['values']);
  print(second.entries['values']);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          [1],
          [],
          [2],
          [],
        ]),
      );
    });

    test('unused classes do not run instance initializers', () async {
      const source = '''
int count = 0;
int next() => ++count;

class Unused {
  final value = next();
}

class Example {
  final first = next(), second = next();
}

void main() {
  print(count);
  final first = Example();
  print(first.first);
  print(first.second);
  final second = Example();
  print(second.first);
  print(second.second);
  print(count);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([0, 1, 2, 3, 4, 4]));
    });

    test('initializers observe globals at construction time', () async {
      const source = '''
int value = 0;

class Example {
  final initial = value;
}

void main() {
  value = 1;
  final first = Example();
  value = 2;
  final second = Example();
  print(first.initial);
  print(second.initial);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('child fields initialize before parent fields for each instance', () async {
      const source = '''
int count = 0;
int next() => ++count;

class Parent {
  final parent = next();
}

class Child extends Parent {
  final child = next();
}

class Grandchild extends Child {
  final grandchild = next();
}

void main() {
  print(count);
  final first = Grandchild();
  final second = Grandchild();
  print(first.parent);
  print(first.child);
  print(first.grandchild);
  print(second.parent);
  print(second.child);
  print(second.grandchild);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([0, 3, 2, 1, 6, 5, 4]));
    });

    test('inherited initializers run when the child declares no fields', () async {
      const source = '''
int count = 0;

class Parent {
  final value = ++count;
}

class Child extends Parent {}

void main() {
  print(Child().value);
  print(Child().value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('overridden fields retain separate parent storage', () async {
      const source = '''
class Parent {
  int value = 1;
  int read() => value;
}

class Child extends Parent {
  int value = 2;
  int readParent() => super.value;
}

void main() {
  final first = Child();
  final second = Child();
  print(first.readParent());
  print(first.value);
  print(first.read());
  first.value = 3;
  print(first.readParent());
  print(first.value);
  print(second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 2, 1, 3, 2]));
    });

    test('methods and accessors use the receiving instance', () async {
      const source = '''
class Example {
  int value = 0;
  int get current => value;
  set current(int value) { this.value = value; }
  void advance() { value++; }
}

void main() {
  final first = Example();
  final second = Example();
  first.advance();
  print(first.current);
  print(second.current);
  second.current = 2;
  print(first.current);
  print(second.current);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 0, 1, 2]));
    });

    test('static fields remain shared and initialize only once', () async {
      const source = '''
int count = 0;
int next() => ++count;

class Example {
  static int shared = next();
  final value = next();
}

void main() {
  print(Example.shared);
  print(Example().value);
  print(Example().value);
  Example.shared = 4;
  print(Example.shared);
  print(count);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4, 3]));
    });

    test('static constants remain available to method parameter defaults', () async {
      const source = '''
class Example {
  static const initial = 1;
  final value = initial;
  int read([int count = initial]) => value + count;
}

void main() {
  final instance = Example();
  print(instance.read());
  print(instance.read(2));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3]));
    });

    test('a static field can construct an initialized instance of its own class', () async {
      const source = '''
class Example {
  static final instance = Example();
  final value = 1;
  int read() => value;
}

void main() {
  print(Example.instance.value);
  print(Example.instance.read());
  print(Example().value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 1, 1]));
    });

    test('initializer errors propagate without contaminating later instances', () async {
      const source = '''
bool fail = false;
int initialize() {
  if (fail) throw 'initializer failed';
  return 1;
}

class Example {
  final value = initialize();
}

void main() {
  final first = Example();
  fail = true;
  try {
    Example();
  } catch (error) {
    print(error);
  }
  fail = false;
  final second = Example();
  print(first.value);
  print(second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['initializer failed', 1, 1]));
    });

    test('field closures retain their own captured locals', () async {
      const source = '''
Function counter() {
  int count = 0;
  return () => ++count;
}

class Example {
  final next = counter();
}

void main() {
  final first = Example();
  final second = Example();
  print(first.next());
  print(first.next());
  print(second.next());
  print(second.next());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 1, 2]));
    });

    test('async methods keep instance fields after suspension', () async {
      const source = '''
class Example {
  int value = 0;
  Future<int> advance() async {
    await null;
    value++;
    return value;
  }
}

Future<void> main() async {
  final first = Example();
  final second = Example();
  print(await first.advance());
  print(second.value);
  print(await first.advance());
  print(await second.advance());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 0, 2, 1]));
    });
  });

  test('Recursive instance initializers fail instead of reusing a class value', () async {
    const source = '''
class Example {
  final value = Example();
}

void main() { Example(); }
    ''';
    await expectLater(
      eval(source),
      throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Stack overflow'))),
    );
  });

  test('Instance properties injected by the host remain isolated', () async {
    const source = '''
class Example {
  int value = 0;
  String label() => this.hostLabel;
}

dynamic main() => <dynamic>[Example(), Example()];
    ''';
    final instances = (await eval(source) as List).cast<ObjInstance>();
    final first = instances.first;
    final second = instances.last;
    expect(first.clazz, same(second.clazz));
    first.props['hostLabel'] = EvalProperty.getter((_) => 'first');
    second.props['hostLabel'] = EvalProperty.getter((_) => 'second');
    expect(first.has('hostLabel'), isTrue);
    expect(first.get('hostLabel'), 'first');
    expect(second.get('hostLabel'), 'second');
    expect(first.clazz.props['hostLabel'], isNull);
    expect(await first.invoke('label', null), 'first');
    expect(await second.invoke('label', null), 'second');
  });

  test('Instances from one class retain independent fields after compute', () async {
    const source = '''
class Example {
  int value = 0;
  Future<int> advance() async {
    await null;
    value++;
    return value;
  }
}

dynamic main() => <dynamic>[Example(), Example()];
    ''';
    final instances = (await eval(source) as List).cast<ObjInstance>();
    final result = compute<List<ObjInstance>, List<int>>((instances) async {
      final first = instances.first;
      final second = instances.last;
      return [
        await first.invoke('advance', null),
        second.get('value'),
        await first.invoke('advance', null),
        await second.invoke('advance', null),
      ];
    }, instances);
    await expectLater(result, completion([1, 0, 2, 1]));
  });

  test('Instance method invocations', () {
    const source = '''
class Parent {
  int method1() => 1;

  int method2() => method1() + 1;
}

class Child extends Parent {
  @override
  int method1() => super.method1() + 2;

  int method3() => method1() + super.method1() + 1;

  int method4() => super.method1() + method2() + 1;
}

void main() {
  final parent = Parent();
  print(parent.method1());
  print(parent.method2());
  final child = Child();
  print(child.method1());
  print(child.method2());
  print(child.method3());
  print(child.method4());
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4, 5, 6]));
  });

  test('Instance variable shadowing', () {
    const source = '''
class Parent {
  int get shadow => 1 + 1;
}

class Child extends Parent {
  @override
  int get shadow => super.shadow - 1;

  int method1(int shadow) => shadow + 1;

  int method2(int shadow) => this.shadow + 1;

  int method3(int shadow) => super.shadow + 1;

  int method4(int shadow) => shadow + this.shadow + super.shadow + 1;
}

void main() {
  final instance = Child();
  print(instance.method1(0));
  print(instance.method2(0));
  print(instance.method3(0));
  print(instance.method4(0));
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4]));
  });
}
