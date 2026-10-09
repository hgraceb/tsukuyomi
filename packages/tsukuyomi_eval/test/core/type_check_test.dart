import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Basic type checks', () {
    test('nullable callback collection annotations retain their existing behavior', () async {
      const source = '''
List<void Function(int)>? global = null;
class Example { final List<void Function(int)>? callbacks = null; }

void main() {
  List<void Function(int)>? local = null;
  print(global);
  print(local);
  print(Example().callbacks);
}
      ''';
      await expectLater(() => eval(source), println([null, null, null]));
    });

    test('native subtypes include private implementations', () async {
      const source = '''
void main() {
  dynamic value = 0;
  print(value is int);
  print(value is num);
  print(value is double);
  print(value is String);
  print(DateTime(2026) is DateTime);
  print(<int>[] is List);
  print(<int>[] is Iterable);
  print(<int>[].iterator is Iterator);
  print(FormatException() is Exception);
}
      ''';
      await expectLater(() => eval(source), println([true, true, false, false, true, true, true, true, true]));
    });

    test('nullable targets retain both null and non-null type checks', () async {
      const source = '''
void main() {
  dynamic value = null;
  print(value is int?);
  print(value is int);
  print(value is! int?);
  print(value is! int);
  value = 0;
  print(value is int?);
  print(value is num?);
  print(value is String?);
  value = '';
  print(value is String?);
  print(value is int?);
}
      ''';
      await expectLater(() => eval(source), println([true, false, false, true, true, true, false, true, false]));
    });

    test('Object, dynamic, Null and Never use their own null rules', () async {
      const source = '''
void main() {
  dynamic value = null;
  print(value is Object);
  print(value is Object?);
  print(value is dynamic);
  print(value is Null);
  print(value is Never);
  print(value is Never?);
  value = 0;
  print(value is Object);
  print(value is Object?);
  print(value is dynamic);
  print(value is Null);
  print(value is Never);
  print(value is Never?);
}
      ''';
      await expectLater(() => eval(source), println([false, true, true, true, false, true, true, true, true, false, false, false]));
    });

    test('successful native casts retain the original value', () async {
      const source = '''
void main() {
  dynamic number = 0;
  print(number as num);
  print(number as int?);
  dynamic values = <int>[];
  print((values as Iterable) == values);
  dynamic date = DateTime(2026);
  print((date as DateTime) == date);
  print((date as Object) == date);
  dynamic value = null;
  print(value as int?);
  print(value as Object?);
  print(value as dynamic);
  print(value as Null);
  print(value as Never?);
}
      ''';
      await expectLater(() => eval(source), println([0, 0, true, true, true, null, null, null, null, null]));
    });

    for (final entry in [
      (name: 'unrelated native type', value: "''", type: 'int'),
      (name: 'numeric conversion', value: '0.0', type: 'int'),
      (name: 'null to non-nullable type', value: 'null', type: 'int'),
      (name: 'wrong nullable type', value: "''", type: 'int?'),
      (name: 'null to Object', value: 'null', type: 'Object'),
      (name: 'non-null value to Null', value: '0', type: 'Null'),
      (name: 'value to Never', value: '0', type: 'Never'),
    ]) {
      test('casts reject ${entry.name}', () async {
        final source =
            '''
dynamic main() {
  dynamic value = ${entry.value};
  return value as ${entry.type};
}
        ''';
        await expectLater(
          eval(source),
          throwsA(isA<TypeError>().having((error) => error.toString(), 'message', contains("type '${entry.type}'"))),
        );
      });
    }

    test('cast errors can be caught and execute finally before continuing', () async {
      const source = '''
void main() {
  dynamic value = '';
  try {
    print(value as int);
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  } finally {
    print('finally');
  }
  print(value);
  print(0 as num);
}
      ''';
      await expectLater(() => eval(source), println([true, 'finally', '', 0]));
    });
  });

  group('Script class type checks', () {
    test('is and as evaluate the operand only once', () async {
      const source = '''
int count = 0;
class Parent {}
class Child extends Parent {}

dynamic next() { count++; return Child(); }

void main() {
  print(next() is Parent);
  print(count);
  final value = next() as Parent;
  print(count);
  print(value is Child);
}
      ''';
      await expectLater(() => eval(source), println([true, 1, 2, true]));
    });

    test('own class identity differs from classes with the same fields', () async {
      const source = '''
class Example { int value = 0; }
class Other { int value = 0; }

void main() {
  dynamic value = Example();
  print(value is Example);
  print(value is Other);
  print(value is! Example);
  print(value is! Other);
  print(value is Object);
  print(value is dynamic);
  print(value is String);
  print(0 is Example);
  print(null is Example);
  print(null is Example?);
  print((value as Example) == value);
}
      ''';
      await expectLater(() => eval(source), println([true, false, false, true, true, true, false, false, false, true, true]));
    });

    test('multi-level extends chains preserve direction and distinguish siblings', () async {
      const source = '''
class Parent { int value = 0; }
class Child extends Parent {}
class Grandchild extends Child {}
class Sibling extends Parent {}

void main() {
  dynamic value = Grandchild();
  print(value is Grandchild);
  print(value is Child);
  print(value is Parent);
  print(value is Parent?);
  print(value is Sibling);
  print(Parent() is Child);
  print(Child() is Grandchild);
  final parent = value as Parent;
  print(parent == value);
  parent.value = 1;
  print(value.value);
  print(parent is Grandchild);
}
      ''';
      await expectLater(() => eval(source), println([true, true, true, true, false, false, false, true, 1, true]));
    });

    test('objects retrieved from fields and dynamic collections keep their class', () async {
      const source = '''
class Example { int value = 0; }
class Container { final child = Example(); }

void main() {
  final container = Container();
  print(container is Example);
  print(container.child is Example);
  final values = <dynamic>[container.child];
  final entries = <String, dynamic>{'child': container.child};
  print(values[0] is Example);
  print(entries['child'] is Example);
  final child = values[0] as Example;
  child.value = 1;
  print(container.child.value);
}
      ''';
      await expectLater(() => eval(source), println([false, true, true, true, 1]));
    });

    test('nullable script casts accept null without creating an instance', () async {
      const source = '''
class Example {}

void main() {
  dynamic value = null;
  print(value as Example?);
  print(value is Example?);
  value = Example();
  print((value as Example?) == value);
  print(value is Null);
  print(value is Never);
  print(value is Function);
}
      ''';
      await expectLater(() => eval(source), println([null, true, true, false, false, false]));
    });

    for (final entry in [
      (name: 'unrelated script class', value: 'Other()', type: 'Example'),
      (name: 'nullable unrelated class', value: 'Other()', type: 'Example?'),
      (name: 'native value to script class', value: '0', type: 'Example'),
      (name: 'null to script class', value: 'null', type: 'Example'),
      (name: 'parent to child', value: 'Example()', type: 'Child'),
    ]) {
      test('casts reject ${entry.name}', () async {
        final source =
            '''
class Example {}
class Child extends Example {}
class Other {}

dynamic main() {
  dynamic value = ${entry.value};
  return value as ${entry.type};
}
        ''';
        await expectLater(eval(source), throwsA(isA<TypeError>()));
      });
    }

    test('typed catch matches a script ancestor and skips sibling handlers', () async {
      const source = '''
class Parent {}
class Child extends Parent {}
class Sibling extends Parent {}

void main() {
  final value = Child();
  try {
    throw value;
  } on Sibling {
    print('sibling');
  } on Parent catch (error) {
    print(error == value);
    print(error is Child);
    print((error as Parent) == value);
  } finally {
    print('finally');
  }
  print('after');
}
      ''';
      await expectLater(() => eval(source), println([true, true, true, 'finally', 'after']));
    });

    test('async type failures are caught after await', () async {
      const source = '''
class Example {}
class Other {}

Future<void> main() async {
  await null;
  dynamic value = Example();
  print(value is Example);
  try {
    print(value as Other);
  } catch (error) {
    await null;
    print(error.runtimeType.toString().contains('TypeError'));
  } finally {
    print('finally');
  }
}
      ''';
      await expectLater(() => eval(source), println([true, true, 'finally']));
    });

    test('class identity remains distinct across eval contexts', () async {
      final previous = await eval('class Example {} dynamic main() => Example();') as ObjInstance;
      final library = DartLibrary(
        'previous',
        path: 'previous.dart',
        declarations: [
          DartVariable('previous', previous, 'external dynamic get previous;'),
        ],
      );
      const source = '''
import 'package:previous/previous.dart';

class Example {}

void main() {
  print(previous is Example);
  print(previous is Object);
  print(Example() is Example);
  try {
    print(previous as Example);
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
}
      ''';
      await expectLater(() => eval(source, libraries: [library]), println([false, true, true, true]));
    });

    test('inheritance checks survive compute and later method invocation', () async {
      const source = '''
class Parent {}
class Child extends Parent {
  bool check() => this is Parent && (this as Parent) == this;
}

dynamic main() => Child();
      ''';
      final instance = await compute(eval, source) as ObjInstance;
      expect(instance.invoke('check', null), true);
    });
  });

  group('Function type checks', () {
    test('native functions, script closures and bound methods are Function values', () async {
      const source = '''
int read() => 0;
class Example { int read() => 0; }

void main() {
  dynamic native = print;
  dynamic closure = () => 0;
  dynamic method = Example().read;
  print(native is Function);
  print(read is Function);
  print(closure is Function);
  print(method is Function);
  print((closure as Function)());
  print((method as Function)());
  print(null is Function);
  print(null is Function?);
  print(null as Function?);
  print(0 is Function);
}
      ''';
      await expectLater(() => eval(source), println([true, true, true, true, 0, 0, false, true, null, false]));
    });

    test('casting a non-function to Function fails', () async {
      await expectLater(eval('dynamic main() { dynamic value = 0; return value as Function; }'), throwsA(isA<TypeError>()));
    });

    test('typed catch recognizes thrown script functions', () async {
      const source = '''
void main() {
  try {
    throw () => 0;
  } on Function catch (error) {
    print((error as Function)());
  }
}
      ''';
      await expectLater(() => eval(source), println([0]));
    });
  });

  group('Bridged type checks', () {
    test('bridged Object and Function aliases retain intrinsic classifications', () async {
      const source = '''
import 'package:type_checks/type_checks.dart';

class Example { int read() => 0; }
class Interface {}
class Other implements Interface {}

void main() {
  final value = Example();
  print(value is ObjectAlias);
  print((value as ObjectAlias) == value);
  final callback = () => 0;
  print(callback is CallbackAlias);
  print((callback as CallbackAlias)());
  print(print is CallbackAlias);
  print(value.read is CallbackAlias);
  print(Other() is ObjectAlias);
}
      ''';
      await expectLater(() => eval(source, libraries: [_nativeLibrary()]), println([true, true, true, 0, true, true, true]));
    });

    test('native and script subclasses share the registered host ancestry', () async {
      const source = '''
import 'package:type_checks/type_checks.dart';

class Example extends NativeChild {}
class Descendant extends Example {}

void main() {
  dynamic value = Descendant();
  print(value is Example);
  print(value is NativeChild);
  print(value is NativeParent);
  print(value is ParentAlias);
  print(value is NativeSibling);
  print(value is NativeChild);
  print((value as NativeParent) == value);
  print((value as ParentAlias) == value);
  print(native is NativeParent);
  print(native is NativeChild);
  print(native is Example);
  print((native as NativeParent) == native);
  print(null is NativeParent?);
}
      ''';
      await expectLater(
        () => eval(source, libraries: [_nativeLibrary()]),
        println([true, true, true, true, false, true, true, true, true, true, false, true, true]),
      );
    });

    test('typed catch also matches the native ancestor of a script instance', () async {
      const source = '''
import 'package:type_checks/type_checks.dart';

class Example extends NativeChild {}

void main() {
  try {
    throw Example();
  } on NativeSibling {
    print('sibling');
  } on NativeParent catch (error) {
    print(error is Example);
    print(error is NativeChild);
  }
}
      ''';
      await expectLater(() => eval(source, libraries: [_nativeLibrary()]), println([true, true]));
    });

    test('a script instance cannot cast to an unrelated host subtype', () async {
      const source = '''
import 'package:type_checks/type_checks.dart';

class Example extends NativeChild {}
dynamic main() { dynamic value = Example(); return value as NativeSibling; }
      ''';
      await expectLater(eval(source, libraries: [_nativeLibrary()]), throwsA(isA<TypeError>()));
    });
  });

  group('Unsupported type checks', () {
    for (final operator in ['is', 'as']) {
      test('function signature aliases are rejected for $operator', () async {
        final source = '''
typedef Callback = int Function();
void main() { dynamic value = () => 0; print(value $operator Callback); }
        ''';
        await expectLater(
          eval(source),
          throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('type check'))),
        );
      });
    }

    for (final entry in [
      (name: 'parameterized is', body: 'print(value is List<int>);'),
      (name: 'parameterized as', body: 'print(value as List<int>);'),
      (name: 'nested generic is', body: 'print(value is List<List<int>>);'),
      (name: 'nested generic as', body: 'print(value as List<List<int>>);'),
      (name: 'function signature is', body: 'print(value is int Function());'),
      (name: 'function signature as', body: 'print(value as int Function());'),
      (name: 'parameterized catch', body: 'try { throw value; } on List<int> {}'),
    ]) {
      test('${entry.name} is rejected before execution', () async {
        final source = 'void main() { dynamic value = null; ${entry.body} }';
        await expectLater(
          eval(source),
          throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('type check'))),
        );
      });
    }

    for (final entry in [
      (
        name: 'script interface relation',
        classes: 'class Example {} class Other implements Example {}',
        body: 'print(Other() is Example);',
      ),
      (name: 'script interface cast', classes: 'class Example {} class Other implements Example {}', body: 'print(Other() as Example);'),
      (name: 'interface relation to Function', classes: 'class Example {} class Other implements Example {}', body: 'print(Other() is Function);'),
      (name: 'interface cast to Function', classes: 'class Example {} class Other implements Example {}', body: 'print(Other() as Function);'),
      (
        name: 'inherited interface relation',
        classes: 'class Example {} class Parent implements Example {} class Child extends Parent {}',
        body: 'print(Child() is Example);',
      ),
      (name: 'generic script class', classes: 'class Example<T> {}', body: 'print(Example<int>() is Example);'),
      (name: 'mixin relation', classes: 'mixin Extra {} class Example with Extra {}', body: 'print(Example() is Example);'),
      (
        name: 'inherited unsupported relation',
        classes: 'class Parent<T> {} class Example extends Parent<int> {}',
        body: 'print(Example() is Example);',
      ),
    ]) {
      test('${entry.name} reports its unsupported boundary', () async {
        final source = '${entry.classes} void main() { ${entry.body} }';
        await expectLater(
          eval(source),
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
        );
      });
    }

    test('unregistered targets are errors rather than false matches', () async {
      await expectLater(
        eval('void main() { dynamic value = null; print(value is Unknown?); }'),
        throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unknown.with'))),
      );
    });
  });
}

class _NativeParent {}

class _NativeChild extends _NativeParent {}

class _NativeSibling extends _NativeParent {}

DartLibrary _nativeLibrary() {
  return DartLibrary('type_checks', path: 'type_checks.dart', declarations: [
    DartClass<Object>(($) => '''
// ${$.alias('ObjectAlias')}
typedef ObjectAlias = Object;
    '''),
    DartClass<Function>(($) => '''
// ${$.alias('CallbackAlias')}
typedef CallbackAlias = Function;
    '''),
    DartClass<_NativeParent>(($) => '''
// ${$.alias('NativeParent')}
// ${$.alias('ParentAlias')}
class NativeParent {}
typedef ParentAlias = NativeParent;
    '''),
    DartClass<_NativeChild>(($) => '''
// ${$.alias('NativeChild')}
// ${$.empty('NativeChild.class', () => ObjClass('NativeChild'))}
class NativeChild extends NativeParent {}
    '''),
    DartClass<_NativeSibling>(($) => '''
// ${$.alias('NativeSibling')}
class NativeSibling extends NativeParent {}
    '''),
    DartVariable('native', _NativeChild(), 'external dynamic get native;'),
  ]);
}
