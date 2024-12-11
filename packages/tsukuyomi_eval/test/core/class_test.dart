import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
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
