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

  group('Non-parameterized type aliases', () {
    test('native aliases and alias chains use their underlying targets', () async {
      const source = '''
typedef Number = num;
typedef Numeric = Number;
typedef Text = String;
void main() {
  dynamic value = 0;
  print(value as Number);
  print(value as Numeric);
  print(value is Number);
  print(value is! Number);
  print(value is Text);
  value = '';
  print(value as Text);
  print(value is Text);
}
      ''';
      await expectLater(() => eval(source), println([0, 0, true, false, false, '', true]));
    });

    test('nullable aliases retain nullability from both the definition and the target', () async {
      const source = '''
typedef Number = num;
typedef MaybeNumber = num?;
typedef NullableNumber = MaybeNumber;
void main() {
  dynamic value = null;
  print(value as Number?);
  print(value as MaybeNumber);
  print(value as NullableNumber);
  print(value is Number);
  print(value is Number?);
  print(value is MaybeNumber);
  value = 0;
  print(value as MaybeNumber);
  print(value is NullableNumber);
}
      ''';
      await expectLater(() => eval(source), println([null, null, null, false, true, true, 0, true]));
    });

    test('intrinsic aliases retain their own null rules', () async {
      const source = '''
typedef Any = dynamic;
typedef Root = Object;
typedef Empty = Null;
typedef Bottom = Never;
void main() {
  dynamic value = null;
  print(value as Any);
  print(value as Root?);
  print(value as Empty);
  print(value as Bottom?);
  print(value is Any);
  print(value is Root);
  print(value is Empty);
  print(value is Bottom);
  value = 0;
  print(value as Root);
  print(value is Bottom);
}
      ''';
      await expectLater(() => eval(source), println([null, null, null, null, true, false, true, false, 0, false]));
    });

    test('bare Function aliases recognize script and native functions', () async {
      const source = '''
typedef Callback = Function;
typedef MaybeCallback = Callback?;
class Example { int read() => 0; }
void main() {
  dynamic callback = () => 0;
  print(callback is Callback);
  print((callback as Callback)());
  print(Example().read is Callback);
  print(print is Callback);
  print(null is Callback);
  print(null is MaybeCallback);
  print(null as MaybeCallback);
}
      ''';
      await expectLater(() => eval(source), println([true, 0, true, true, false, true, null]));
    });

    test('script aliases retain the underlying class identity and inheritance', () async {
      const source = '''
typedef ParentAlias = Parent;
typedef MaybeParent = ParentAlias?;
class Parent {}
class Child extends Parent {}
class Other {}
void main() {
  dynamic value = Child();
  print(value is ParentAlias);
  print((value as ParentAlias) == value);
  print(value is Child);
  print(Other() is ParentAlias);
  print(null is ParentAlias);
  print(null as MaybeParent);
}
      ''';
      await expectLater(() => eval(source), println([true, true, true, false, false, null]));
    });

    test('typed catches share the expanded aliases for native and script values', () async {
      const source = '''
typedef Number = num;
typedef ParentAlias = Parent;
typedef Callback = Function;
class Parent {}
class Child extends Parent {}
void main() {
  try { throw 0; }
  on Number catch (error) { print(error as Number); }
  try { throw Child(); }
  on ParentAlias catch (error) { print(error is Child); }
  try { throw () => 0; }
  on Callback catch (error) { print((error as Callback)()); }
}
      ''';
      await expectLater(() => eval(source), println([0, true, 0]));
    });

    test('failed alias casts remain TypeErrors for the underlying nullable target', () async {
      const source = '''
typedef MaybeNumber = num?;
void main() {
  dynamic value = '';
  try { print(value as MaybeNumber); }
  on TypeError { print('type error'); }
  finally { print('finally'); }
}
      ''';
      await expectLater(() => eval(source), println(['type error', 'finally']));
    });
  });

  group('Raw type aliases', () {
    for (final entry in [
      (type: 'List', value: '<int>[]'),
      (type: 'Iterable', value: '<int>[]'),
      (type: 'Map', value: '<String, int>{}'),
      (type: 'Set', value: '<int>{}'),
      (type: 'Iterator', value: '<int>[].iterator'),
    ]) {
      test('${entry.type} aliases preserve raw targets through chains and nullable annotations', () async {
        final source =
            '''
typedef Target = ${entry.type};
typedef Chained = Target;
typedef Nullable = Chained?;
void main() {
  dynamic value = ${entry.value};
  print(value is Target);
  print((value as Target) == value);
  print(value is! Chained);
  print((value as Chained) == value);
  print(null as Nullable);
  print(null as Target?);
  print(null is Nullable);
  print(null is Target);
  try { throw value; }
  on Chained catch (error) { print(error == value); }
}
        ''';
        await expectLater(() => eval(source), println([true, true, false, true, null, null, true, false, true]));
      });
    }

    test('a raw alias to a bounded generic script class still reports the script boundary', () async {
      const source = '''
class Box<T extends num> {}
typedef RawBox = Box;
void main() { print(null is RawBox?); }
      ''';
      await expectLater(
        eval(source),
        throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
      );
    });
  });

  group('Registered bridge aliases', () {
    test('an alias retains its registered matcher when the declared underlying name is unregistered', () async {
      const source = '''
import 'package:alias_types/alias_types.dart';
void main() {
  final value = hostValue;
  print(value is PublicValue);
  print(value is! PublicValue);
  print((value as PublicValue) == value);
  print(0 is PublicValue);
  print(null is PublicValue);
  print(null as PublicValue?);
  try { throw value; }
  on PublicValue catch (error) { print(error == value); }
}
      ''';
      await expectLater(() => eval(source, libraries: [_aliasLibrary()]), println([true, false, true, false, false, null, true]));
    });

    test('script aliases can resolve through a registered bridge alias', () async {
      const source = '''
import 'package:alias_types/alias_types.dart';
typedef Local = PublicValue;
typedef Nullable = Local?;
void main() {
  final value = hostValue;
  print(value is Local);
  print((value as Local) == value);
  print(null as Nullable);
  try { throw value; }
  on Local catch (error) { print(error == value); }
}
      ''';
      await expectLater(() => eval(source, libraries: [_aliasLibrary()]), println([true, true, null, true]));
    });

    test('unregistered library aliases can resolve through another registered alias', () async {
      const source = '''
import 'package:alias_types/alias_types.dart';
void main() {
  final value = hostValue;
  print(value is PublicChain);
  print((value as PublicChain) == value);
  print(null as PublicChain?);
  try { throw value; }
  on PublicChain catch (error) { print(error == value); }
}
      ''';
      await expectLater(() => eval(source, libraries: [_aliasLibrary()]), println([true, true, null, true]));
    });

    test('script declarations shadow an imported bridge alias', () async {
      const source = '''
import 'package:alias_types/alias_types.dart';
class PublicValue {}
void main() {
  final value = PublicValue();
  print(value is PublicValue);
  print((value as PublicValue) == value);
  print(hostValue is PublicValue);
}
      ''';
      await expectLater(() => eval(source, libraries: [_aliasLibrary()]), println([true, true, false]));
    });

    test('a script typedef does not reuse a shadowed imported bridge matcher', () async {
      const source = '''
import 'package:alias_types/alias_types.dart';
typedef PublicValue = num;
void main() {
  print(0 is PublicValue);
  print(0 as PublicValue);
  print(hostValue is PublicValue);
}
      ''';
      await expectLater(() => eval(source, libraries: [_aliasLibrary()]), println([true, 0, false]));
    });

    for (final entry in [
      (type: 'Values', value: '<int>[]'),
      (type: 'Entries', value: '<String, int>{}'),
      (type: 'Items', value: '<int>[]'),
    ]) {
      test('registered raw ${entry.type} aliases retain their matcher', () async {
        final source =
            '''
import 'package:alias_types/alias_types.dart';
void main() {
  dynamic value = ${entry.value};
  print(value is ${entry.type});
  print((value as ${entry.type}) == value);
  print(null as ${entry.type}?);
  try { throw value; }
  on ${entry.type} catch (error) { print(error == value); }
}
        ''';
        await expectLater(() => eval(source, libraries: [_aliasLibrary()]), println([true, true, null, true]));
      });
    }
  });

  group('Shadowed core type names', () {
    for (final name in ['Null', 'Never']) {
      test('script $name retains its identity for casts, nullable checks and typed catches', () async {
        final source =
            '''
class $name {}
class Child extends $name {}
typedef Target = $name;
void main() {
  final value = Child();
  print(value is $name);
  print((value as $name) == value);
  print(value is Target);
  print((value as Target) == value);
  print(0 is $name);
  print(null is $name);
  print(null is $name?);
  print(null as Target?);
  try { throw value; }
  on $name catch (error) { print(error == value); }
  try { dynamic other = 0; print(other as $name); }
  on TypeError { print('type error'); }
}
        ''';
        await expectLater(() => eval(source), println([true, true, true, true, false, false, true, null, true, 'type error']));
      });
    }

    test('library aliases retain their core origin when the script shadows the names', () async {
      const source = '''
import 'package:alias_types/alias_types.dart';
class Null {}
class Never {}
void main() {
  print(null as CoreNull);
  print(null as CoreNever?);
  print(0 as CoreObject);
  print((() => 0) is CoreFunction);
  print(Null() is CoreNull);
  print(Never() is CoreNever);
  print(Null() is Null);
  print(Never() is Never);
}
      ''';
      await expectLater(() => eval(source, libraries: [_aliasLibrary()]), println([null, null, 0, true, false, false, true, true]));
    });

    for (final name in ['Null', 'Never']) {
      test('script $name retains its unsupported interface boundary', () async {
        final source = 'class Interface {} class $name implements Interface {} void main() { print(null is $name?); }';
        await expectLater(
          eval(source),
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
        );
      });
    }
  });

  group('Host callback function results', () {
    test('map callbacks can return script closures declared as Function', () async {
      const source = '''
Function make(int value) => () => value;
void main() {
  final callbacks = [0, 1].map(make).toList();
  print(callbacks[0] is Function);
  print(callbacks[0]());
  print(callbacks[1]());
}
      ''';
      await expectLater(() => eval(source), println([true, 0, 1]));
    });

    test('returned functions retain writable captured variables across host calls', () async {
      const source = '''
Function make(int value) => () => ++value;
void main() {
  final callback = [0].map(make).first;
  print(callback());
  print(callback());
  print([0].map(make).first());
}
      ''';
      await expectLater(() => eval(source), println([1, 2, 1]));
    });

    test('Function aliases and nested returned functions adapt at each host boundary', () async {
      const source = '''
typedef Callback = Function;
Callback make(int value) => () => value;
Function outer(int value) => make;
void main() {
  print([0].map(make).first());
  final factory = [0].map(outer).first;
  print(factory(1)());
}
      ''';
      await expectLater(() => eval(source), println([0, 1]));
    });

    test('returned bound methods retain their receiver', () async {
      const source = '''
class Example {
  int value = 0;
  int next() => ++value;
}
Function make(int value) => Example().next;
void main() {
  final callback = [0].map(make).first;
  print(callback());
  print(callback());
  print([0].map(make).first());
}
      ''';
      await expectLater(() => eval(source), println([1, 2, 1]));
    });

    test('native functions returned through callbacks remain callable', () async {
      const source = '''
Function make(int value) => print;
void main() { [0].map(make).first('native'); }
      ''';
      await expectLater(() => eval(source), println(['native']));
    });

    test('nullable Function callback results retain null and adapt returned closures', () async {
      const source = '''
Function? make(int value) => value == 0 ? null : () => value;
void main() {
  final callbacks = [0, 1].map(make).toList();
  print(callbacks[0]);
  print(callbacks[1]!());
}
      ''';
      await expectLater(() => eval(source), println([null, 1]));
    });

    test('nullable Function method results use the same callback return adaptation', () async {
      const source = '''
class Example {
  Function? make(int value) => value == 0 ? null : () => value;
}
void main() {
  final example = Example();
  final callbacks = [0, 1].map(example.make).toList();
  print(callbacks[0]);
  print(callbacks[1]!());
}
      ''';
      await expectLater(() => eval(source), println([null, 1]));
    });

    test('nullable primitive callbacks also retain their declared return type', () async {
      const source = '''
int? make(int value) => value == 0 ? null : value;
void main() { print([0, 1].map(make).toList()); }
      ''';
      await expectLater(() => eval(source), println(['[null, 1]']));
    });

    test('dynamic and Object callback results retain their script class identity', () async {
      const source = '''
class Example {}
dynamic makeDynamic(int value) => Example();
Object makeObject(int value) => Example();
void main() {
  print([0].map(makeDynamic).first is Example);
  print([0].map(makeObject).first is Example);
}
      ''';
      await expectLater(() => eval(source), println([true, true]));
    });
  });

  group('Shadowed error constructors', () {
    for (final name in ['Error', 'TypeError']) {
      test('script $name can shadow the core constructor and retain its own identity', () async {
        final source =
            '''
class $name {}
class Child extends $name {}
void main() {
  final value = $name();
  print(value is $name);
  print((value as $name) == value);
  print(Child() is $name);
  try { throw value; }
  on $name catch (error) { print(error == value); }
}
        ''';
        await expectLater(() => eval(source), println([true, true, true, true]));
      });

      test('core error aliases keep matching native errors when script $name shadows them', () async {
        final source =
            '''
import 'package:core_aliases/core_aliases.dart';
class $name {}
void main() {
  print($name() is CoreError);
  try { dynamic value = ''; value as int; }
  on $name { print('script'); }
  on CoreTypeError catch (error) { print(error is CoreError); }
}
        ''';
        await expectLater(() => eval(source, libraries: [_coreAliasesLibrary()]), println([false, true]));
      });
    }

    test('core error constructors still work when they are not shadowed', () async {
      const source = '''
void main() {
  print(Error() is Error);
  print(TypeError() is TypeError);
  try { throw TypeError(); }
  on Error { print('error'); }
}
      ''';
      await expectLater(() => eval(source), println([true, true, 'error']));
    });
  });

  group('Forward ordinary inheritance', () {
    for (final operation in [
      (name: 'is', body: 'print(Child() is Root);', expected: true),
      (name: 'as', body: 'final value = Child(); print((value as Root) == value);', expected: true),
      (name: 'typed catch', body: "try { throw Child(); } on Root { print('root'); } catch (_) { print('other'); }", expected: 'root'),
    ]) {
      for (final isStatic in [true, false]) {
        final location = isStatic ? 'static initializer' : 'main';
        test('${operation.name} recognizes a later ancestor in $location', () async {
          final initializer = isStatic ? 'static final checked = inspect();' : '';
          final inspect = isStatic ? 'dynamic inspect() { ${operation.body} return null; }' : '';
          final body = isStatic ? 'final checked = Child.checked;' : operation.body;
          final source =
              '''
$inspect
class Child extends Parent { $initializer }
class Parent extends Root {}
class Root {}
void main() { $body }
          ''';
          await expectLater(() => eval(source), println([operation.expected]));
        });
      }
    }

    test('an early instance keeps the same class identities after later bodies execute', () async {
      const source = '''
class Child extends Parent { static final value = Child(); }
class Parent extends Root {}
class Root {}
void main() {
  print(Child.value is Child);
  print(Child.value is Parent);
  print(Child.value is Root);
}
      ''';
      await expectLater(() => eval(source), println([true, true, true]));
    });

    test('preparing parent links preserves initializer counts and static declaration order', () async {
      const source = '''
int initialize(String name) { print(name); return 0; }
bool inspect() { print('child static'); return true; }
class Root { final root = initialize('root field'); }
class Parent extends Root { final parent = initialize('parent field'); }
class Child extends Parent {
  static final checked = inspect();
  final child = initialize('child field');
}
void main() { final checked = Child.checked; print(Child().root); }
      ''';
      await expectLater(() => eval(source), println(['child static', 'child field', 'parent field', 'root field', 0]));
    });

    test('a forward chain also reaches the registered native ancestor', () async {
      const source = '''
import 'package:type_checks/type_checks.dart';
bool inspect() { print(Child() is NativeParent); return true; }
class Child extends Parent { static final checked = inspect(); }
class Parent extends NativeChild {}
void main() { print(Child() is NativeParent); }
      ''';
      await expectLater(() => eval(source, libraries: [_nativeLibrary()]), println([true, true]));
    });
  });

  group('Library type matcher identity', () {
    test('callback return aliases retain the same core matcher identity', () async {
      const source = '''
import 'package:shadow_types/shadow_types.dart';
import 'package:core_aliases/core_aliases.dart';
CoreTarget make(int value) => '';
void main() {
  final value = [0].map(make).first;
  print(value is CoreTarget);
  print(value);
}
      ''';
      await expectLater(
        () => eval(
          source,
          libraries: [
            _shadowLibrary('String'),
            _coreAliasesLibrary(type: 'String'),
          ],
        ),
        println([true, '']),
      );
    });

    for (final entry in [
      (name: 'String', value: "''"),
      (name: 'List', value: '[]'),
      (name: 'Map', value: '{}'),
      (name: 'int', value: '0'),
    ]) {
      test('core ${entry.name} aliases ignore a same-name matcher from another library', () async {
        final source =
            '''
import 'package:shadow_types/shadow_types.dart';
import 'package:core_aliases/core_aliases.dart';
void main() {
  dynamic value = ${entry.value};
  print(value is CoreTarget);
  print(value is! CoreTarget);
  print(hostValue is CoreTarget);
  print(hostValue is Target);
  print(value is Target);
  print((value as CoreTarget) == value);
  print(null as CoreTarget?);
  try { throw value; }
  on CoreTarget catch (error) { print(error == value); }
  try { throw hostValue; }
  on CoreTarget { print('core'); }
  on Target { print('host'); }
}
        ''';
        await expectLater(
          () => eval(
            source,
            libraries: [
              _shadowLibrary(entry.name),
              _coreAliasesLibrary(type: entry.name),
            ],
          ),
          println([true, false, false, true, false, true, null, true, 'host']),
        );
      });
    }

    test('an unregistered core alias cannot borrow another library alias matcher', () async {
      const source = '''
import 'package:core_aliases/core_aliases.dart';
void main() {
  print('' is CoreTarget);
  print(hostValue is CoreTarget);
  print('' as CoreTarget);
}
      ''';
      await expectLater(
        () => eval(
          source,
          libraries: [
            _shadowLibrary('CoreTarget'),
            _coreAliasesLibrary(type: 'String', exportHost: true),
          ],
        ),
        println([true, false, '']),
      );
    });
  });

  group('Imported core type names', () {
    for (final name in ['Null', 'Never', 'Object', 'Function']) {
      test('bridged $name uses its registered matcher for type checks', () async {
        final source =
            '''
import 'package:shadow_types/shadow_types.dart';
void main() {
  final value = hostValue;
  print(value is $name);
  print(value is! $name);
  print(value is Target);
  print(null is $name);
  print(null is $name?);
  print(0 is $name);
  print((() => 0) is $name);
}
        ''';
        await expectLater(() => eval(source, libraries: [_shadowLibrary(name)]), println([true, false, true, false, true, false, false]));
      });

      test('bridged $name retains successful casts and rejects unrelated values', () async {
        final source =
            '''
import 'package:shadow_types/shadow_types.dart';
void main() {
  final value = hostValue;
  print((value as $name) == value);
  print((value as Target) == value);
  print(null as $name?);
  try { dynamic other = 0; other as $name; }
  on TypeError { print('number rejected'); }
  try { dynamic other = null; other as $name; }
  on TypeError { print('null rejected'); }
}
        ''';
        await expectLater(
          () => eval(source, libraries: [_shadowLibrary(name)]),
          println([true, true, null, 'number rejected', 'null rejected']),
        );
      });

      test('typed catches for bridged $name match only the registered host type', () async {
        final source =
            '''
import 'package:shadow_types/shadow_types.dart';
void main() {
  final value = hostValue;
  try { throw value; }
  on $name catch (error) { print(error == value); }
  catch (_) { print(false); }
  try { throw 0; }
  on $name { print('host'); }
  catch (_) { print('other'); }
}
        ''';
        await expectLater(() => eval(source, libraries: [_shadowLibrary(name)]), println([true, 'other']));
      });

      test('core aliases retain their origin when an imported bridge shadows $name', () async {
        final source = '''
import 'package:shadow_types/shadow_types.dart';
import 'package:alias_types/alias_types.dart';
void main() {
  final value = hostValue;
  print(null is CoreNull);
  print(value is CoreNull);
  print(value is CoreNever);
  print(value is CoreObject);
  print(value is CoreFunction);
  print((() => 0) is CoreFunction);
  print(null as CoreNull);
  print((value as CoreObject) == value);
  try { throw value; }
  on CoreNull { print('null'); }
  on CoreNever { print('never'); }
  on CoreFunction { print('function'); }
  on CoreObject catch (error) { print(error == value); }
}
        ''';
        await expectLater(
          () => eval(source, libraries: [_shadowLibrary(name), _aliasLibrary()]),
          println([true, false, false, true, false, true, null, true, true]),
        );
      });
    }
  });

  group('Forward inherited type boundaries', () {
    for (final relation in [
      (name: 'direct parent', intermediate: '', parent: 'Parent'),
      (name: 'ancestor', intermediate: 'class Intermediate extends Parent {}', parent: 'Intermediate'),
    ]) {
      for (final operation in [
        (name: 'nullable is', body: 'print(null is Child?);'),
        (name: 'nullable is!', body: 'print(null is! Child?);'),
        (name: 'nullable as', body: 'print(null as Child?);'),
        (name: 'typed catch', body: 'try { throw 0; } on Child {} catch (_) {}'),
      ]) {
        for (final isStatic in [true, false]) {
          final location = isStatic ? 'static initializer' : 'main';
          test('${operation.name} rejects a generic native ${relation.name} in $location', () async {
            final initializer = isStatic ? 'static final Child? child = inspect();' : '';
            final inspect = isStatic ? 'Child? inspect() { ${operation.body} return null; }' : '';
            final body = isStatic ? 'print(Parent.child);' : operation.body;
            final source =
                '''
import 'package:generic_types/generic_types.dart';
$inspect
class Parent extends NativeBase<int> { $initializer }
${relation.intermediate}
class Child extends ${relation.parent} {}
void main() { $body }
            ''';
            await expectLater(
              eval(source, libraries: [_genericLibrary()]),
              throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
            );
          });
        }
      }
    }

    for (final isStatic in [true, false]) {
      final location = isStatic ? 'static initializer' : 'main';
      test('raw native inheritance keeps its nullable checks in $location', () async {
        const checks = 'print(null is Child?); print(null is Child); print(null is! Child?); print(null as Child?);';
        final initializer = isStatic ? 'static final Child? child = inspect();' : '';
        final inspect = isStatic ? 'Child? inspect() { $checks return null; }' : '';
        final body = isStatic ? 'final child = Parent.child;' : checks;
        final source =
            '''
import 'package:generic_types/generic_types.dart';
$inspect
class Parent extends NativeBase { $initializer }
class Child extends Parent {}
void main() { $body }
        ''';
        await expectLater(() => eval(source, libraries: [_genericLibrary()]), println([true, false, false, null]));
      });
    }
  });

  group('Forward script type checks', () {
    test('nullable casts in parent static fields can target a later child', () async {
      const source = '''
class Parent { static final Child? child = null as Child?; }
class Child extends Parent {}
void main() { print(Parent.child); }
      ''';
      await expectLater(() => eval(source), println([null]));
    });

    test('nullable aliases can target a script class declared after the static field', () async {
      const source = '''
typedef MaybeChild = Child?;
class Parent { static final Child? child = null as MaybeChild; }
class Child extends Parent {}
void main() { print(Parent.child); }
      ''';
      await expectLater(() => eval(source), println([null]));
    });

    test('null checks retain nullable and non-nullable rules before the class body runs', () async {
      const source = '''
class Parent {
  static final bool nullable = null is Child?;
  static final bool nonNullable = null is Child;
  static final bool negated = null is! Child?;
}
class Child extends Parent {}
void main() {
  print(Parent.nullable);
  print(Parent.nonNullable);
  print(Parent.negated);
}
      ''';
      await expectLater(() => eval(source), println([true, false, false]));
    });

    test('an earlier parent instance still fails a cast to the later child', () async {
      const source = '''
class Parent {
  static final bool rejected = inspect();
  static bool inspect() {
    dynamic value = Parent();
    try { value as Child?; }
    on TypeError { return true; }
    return false;
  }
}
class Child extends Parent {}
void main() { print(Parent.rejected); }
      ''';
      await expectLater(() => eval(source), println([true]));
    });

    test('a typed catch registered early keeps the final class identity', () async {
      const source = '''
class Parent {
  static final String matched = inspect();
  static String inspect() {
    try { throw Parent(); }
    on Child { return 'child'; }
    on Parent { return 'parent'; }
  }
}
class Child extends Parent {}
void main() {
  print(Parent.matched);
  try { throw Child(); }
  on Child { print('child'); }
}
      ''';
      await expectLater(() => eval(source), println(['parent', 'child']));
    });

    test('preparing identities preserves static order and does not run instance initializers', () async {
      const source = '''
String childValue() { print('child static'); return ''; }
class Parent {
  static final Child? child = inspect();
  static Child? inspect() { print('parent static'); return null as Child?; }
}
class Child extends Parent {
  static final String value = childValue();
  final field = initialize();
}
int initialize() { print('instance'); return 0; }
void main() {
  final child = Parent.child;
  final value = Child.value;
  print(child);
  print(value);
}
      ''';
      await expectLater(() => eval(source), println(['parent static', 'child static', null, '']));
    });

    for (final entry in [
      (name: 'generic parent', parent: 'class Parent<T>', extra: ''),
      (name: 'interface parent', parent: 'class Parent implements Interface', extra: 'class Interface {}'),
      (name: 'mixin parent', parent: 'class Parent with Extra', extra: 'mixin Extra {}'),
    ]) {
      test('a forward target with an unsupported ${entry.name} still reports its boundary', () async {
        final source = '''
${entry.extra}
${entry.parent} { static final Child? child = null as Child?; }
class Child extends Parent {}
void main() { print(Parent.child); }
        ''';
        await expectLater(
          eval(source),
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
        );
      });
    }
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

  group('Catch matcher failures', () {
    test('replace the original error and run both finally blocks before the outer catch', () async {
      const source = '''
class Interface {}
class Unsupported implements Interface {}

void main() {
  try {
    try {
      try { throw Unsupported(); }
      on Interface { print('typed'); }
      catch (error) { print('same handler fallback'); }
      finally { print('inner finally'); }
    } finally {
      print('outer finally');
    }
  } catch (error) {
    print(error.toString().contains('Unsupported type check'));
  }
  print('after');
}
      ''';
      await expectLater(() => eval(source), println(['inner finally', 'outer finally', true, 'after']));
    });

    test('can be caught after awaited finally without escaping the async continuation', () async {
      const source = '''
class Interface {}
class Unsupported implements Interface {}

Future<void> main() async {
  await null;
  try {
    try { throw Unsupported(); }
    on Interface { print('typed'); }
    finally {
      print('inner finally');
      await null;
      print('inner done');
    }
  } catch (error) {
    print(error.toString().contains('Unsupported type check'));
  } finally {
    await null;
    print('outer finally');
  }
  print('after');
}
      ''';
      await expectLater(() => eval(source), println(['inner finally', 'inner done', true, 'outer finally', 'after']));
    });

    test('complete the async error future with the replacement stack after awaited finally', () async {
      const source = '''
class Interface {}
class Unsupported implements Interface {}

Future<void> main() async {
  await null;
  try {
    try { throw Unsupported(); }
    on Interface { print('typed'); }
    finally {
      print('inner finally');
      await null;
      print('inner done');
    }
  } finally {
    await null;
    print('outer finally');
  }
}
      ''';
      await expectLater(() async {
        final future = eval(source) as Future;
        await expectLater(
          future,
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
        );
        await future.then<void>(
          (_) => fail('Expected an error'),
          onError: (Object error, StackTrace stackTrace) {
            expect(stackTrace.toString(), contains('matchInstance'));
          },
        );
      }, println(['inner finally', 'inner done', 'outer finally']));
    });

    test('close captured locals and allow later host invocation after an uncaught failure', () async {
      const source = '''
class Interface {}
class Unsupported implements Interface {}
class Example {
  Function read = () => 0;
  void fail() {
    int value = 0;
    read = () => value;
    try { throw Unsupported(); }
    on Interface { print('typed'); }
    finally {
      value++;
      print(value);
    }
  }
  int inspect() => read();
}
Example main() => Example();
      ''';
      final instance = await eval(source) as ObjInstance;
      expect(() => expect(() => instance.invoke('fail', null), throwsA(isA<EvalRuntimeError>())), println([1]));
      expect(instance.invoke('inspect', null), 1);
    });

    test('a finally return can replace the matcher failure', () async {
      const source = '''
class Interface {}
class Unsupported implements Interface {}
int inspect() {
  try { throw Unsupported(); }
  on Interface { return 1; }
  finally { return 0; }
}
void main() { print(inspect()); }
      ''';
      await expectLater(() => eval(source), println([0]));
    });
  });

  group('Cast error type bridge', () {
    test('on TypeError catches casts and retains the Error ancestry', () async {
      const source = '''
void main() {
  try {
    dynamic value = '';
    print(value as int);
  } on TypeError catch (error) {
    print(error is TypeError);
    print(error is Error);
    print(error is Exception);
    print((error as Error) == error);
  } finally {
    print('finally');
  }
  print('after');
}
      ''';
      await expectLater(() => eval(source), println([true, true, false, true, 'finally', 'after']));
    });

    test('on Error catches a cast failure after await', () async {
      const source = '''
Future<void> main() async {
  await null;
  try {
    dynamic value = null;
    print(value as int);
  } on Error catch (error) {
    print(error is TypeError);
    print((error as TypeError) == error);
    await null;
    print('caught');
  } finally {
    print('finally');
  }
}
      ''';
      await expectLater(() => eval(source), println([true, true, 'caught', 'finally']));
    });

    test('native Error and TypeError factories also use the registered types', () async {
      const source = '''
void main() {
  final error = Error();
  final typeError = TypeError();
  print(error is Error);
  print(error is TypeError);
  print(typeError is Error);
  print(typeError is TypeError);
  print((typeError as Error) == typeError);
}
      ''';
      await expectLater(() => eval(source), println([true, false, true, true, true]));
    });
  });

  group('Unsupported type checks', () {
    for (final entry in [
      (name: 'parameterized alias', declaration: 'typedef Target = List<int>;'),
      (name: 'nested parameterized alias', declaration: 'typedef Target = List<List<int>>;'),
      (name: 'parameterized alias chain', declaration: 'typedef IntList = List<int>; typedef Target = IntList;'),
      (name: 'explicit dynamic alias', declaration: 'typedef Target = List<dynamic>;'),
      (name: 'explicit dynamic map alias', declaration: 'typedef Target = Map<dynamic, dynamic>;'),
      (name: 'explicit dynamic alias chain', declaration: 'typedef Values = List<dynamic>; typedef Target = Values;'),
      (name: 'generic alias declaration', declaration: 'typedef Target<T> = List;'),
    ]) {
      for (final operator in ['is', 'as', 'on']) {
        test('${entry.name} is rejected before execution for $operator', () async {
          final body = operator == 'on' ? 'try { throw value; } on Target {}' : 'print(value $operator Target);';
          final source = '${entry.declaration} void main() { dynamic value = null; $body }';
          await expectLater(
            eval(source),
            throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('type check'))),
          );
        });
      }
    }

    for (final operator in ['is', 'as', 'on']) {
      test('registered explicit parameterized aliases remain rejected for $operator', () async {
        final body = operator == 'on' ? 'try { throw value; } on ExplicitValues {}' : 'print(value $operator ExplicitValues);';
        final source = "import 'package:alias_types/alias_types.dart'; void main() { dynamic value = null; $body }";
        await expectLater(
          eval(source, libraries: [_aliasLibrary()]),
          throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('type check'))),
        );
      });
    }

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

class _HostValue {}

class _NativeBase<T> {}

class _AliasMarker {}

DartLibrary _coreAliasesLibrary({String? type, bool exportHost = false}) {
  return DartLibrary(
    'core_aliases',
    path: 'core_aliases.dart',
    source: exportHost ? "export 'package:shadow_types/shadow_types.dart' show hostValue;" : '',
    declarations: [
      DartClass<_AliasMarker>(
        ($) =>
            '''
typedef CoreError = Error;
typedef CoreTypeError = TypeError;
${type != null ? 'typedef CoreTarget = $type;' : ''}
    ''',
      ),
    ],
  );
}

DartLibrary _shadowLibrary(String name) {
  return DartLibrary(
    'shadow_types',
    path: 'shadow_types.dart',
    declarations: [
      DartClass<_HostValue>(
        ($) =>
            '''
// ${$.alias(name)}
class $name {}
typedef Target = $name;
    ''',
      ),
      DartVariable('hostValue', _HostValue(), 'external $name get hostValue;'),
    ],
  );
}

DartLibrary _genericLibrary() {
  return DartLibrary(
    'generic_types',
    path: 'generic_types.dart',
    declarations: [
      DartClass<_NativeBase>(
        ($) =>
            '''
// ${$.alias('NativeBase')}
// ${$.empty('NativeBase.class', () => ObjClass('NativeBase'))}
class NativeBase<T> {}
    ''',
      ),
    ],
  );
}

DartLibrary _aliasLibrary() {
  return DartLibrary('alias_types', path: 'alias_types.dart', declarations: [
    DartClass<_HostValue>(($) => '''
class InternalValue {}
// ${$.alias('PublicValue')}
typedef PublicValue = InternalValue;
typedef PublicChain = PublicValue;
    '''),
    DartVariable('hostValue', _HostValue(), 'external PublicValue get hostValue;'),
    DartClass<List>(($) => '''
// ${$.alias('Values')}
typedef Values = List;
// ${$.alias('ExplicitValues')}
typedef ExplicitValues = List<dynamic>;
    '''),
    DartClass<Map>(($) => '''
// ${$.alias('Entries')}
typedef Entries = Map;
    '''),
    DartClass<Iterable>(($) => '''
// ${$.alias('Items')}
typedef Items = Iterable;
    '''),
    DartClass<Null>(($) => 'typedef CoreNull = Null;'),
    DartClass<Never>(($) => 'typedef CoreNever = Never;'),
    DartClass<Object>(($) => 'typedef CoreObject = Object;'),
    DartClass<Function>(($) => 'typedef CoreFunction = Function;'),
  ]);
}

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
