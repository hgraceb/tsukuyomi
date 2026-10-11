import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Script superclass aliases', () {
    for (final alias in ['Alias', 'AliasChain']) {
      for (final forward in [false, true]) {
        test('$alias preserves the real parent identity, forward=$forward', () async {
          const parent = 'class Parent {}';
          final source =
              '''
${forward ? '' : parent}
typedef Alias = Parent;
typedef AliasChain = Alias;
dynamic inspect(dynamic value) {
  print(value is Parent);
  print((value as Alias) == value);
  try { throw value; }
  on AliasChain catch (error) { print(error == value); }
  return null;
}
class Child extends $alias {
  static final checked = inspect(Child());
}
${forward ? parent : ''}
class Descendant extends Child {}
void main() { inspect(Descendant()); }
          ''';
          await expectLater(() => eval(source), println([true, true, true, true, true, true]));
        });
      }
    }

    test('inherited fields, methods and initializers retain their declaring class', () async {
      const source = '''
class Parent {
  final values = <int>[];
  String get origin => 'parent';
  void add(int value) { values.add(value); }
}
typedef Alias = Parent;
class Child extends Alias { final child = 'child'; }
class Descendant extends Child {}
void main() {
  final first = Descendant();
  final second = Descendant();
  first.add(0);
  print(first.origin);
  print(first.child);
  print(first.values);
  print(second.values);
}
      ''';
      await expectLater(() => eval(source), println(['parent', 'child', '[0]', '[]']));
    });

    test('a local script alias cannot borrow a same-name bridge class entry', () async {
      final calls = <String>[];
      final library = _bridgeLibrary(
        entries: ['PublicBase'],
        getter: (name) {
          calls.add(name);
          return _proxy(name);
        },
      );
      const source = '''
import 'package:parent_types/types.dart';
class ScriptParent { final origin = 'script'; }
typedef PublicBase = ScriptParent;
class Child extends PublicBase {}
void main() {
  final value = Child();
  print(value.origin);
  print(value is ScriptParent);
  print(value is PublicBase);
}
      ''';
      await expectLater(() => eval(source, libraries: [library]), println(['script', true, true]));
      expect(calls, isEmpty);
    });
  });

  group('Bridged superclass aliases', () {
    for (final entries in [
      ['PublicBase'],
      ['NativeBase'],
      ['PublicBase', 'NativeBase'],
    ]) {
      for (final isStatic in [false, true]) {
        test('${entries.join(' and ')} entries retain members and identity in ${isStatic ? 'static initialization' : 'main'}', () async {
          final calls = <String>[];
          final library = _bridgeLibrary(
            entries: entries,
            getter: (name) {
              calls.add(name);
              return _proxy(name);
            },
          );
          final initializer = isStatic ? 'static final checked = inspect(Parent());' : '';
          final source =
              '''
import 'package:parent_types/types.dart';
dynamic inspect(dynamic value) {
  print(value.origin);
  print(value is PublicBase);
  print(value is Parent);
  print(value is NativeOther);
  print((value as PublicBase) == value);
  try { throw value; }
  on PublicBase catch (error) { print(error == value); }
  print(null as Child?);
  return null;
}
class Parent extends PublicBase { $initializer }
class Child extends Parent {}
void main() {
  ${isStatic ? '' : 'inspect(Parent());'}
  inspect(Child());
}
          ''';
          final output = [entries.first, true, true, false, true, true, null];
          await expectLater(() => eval(source, libraries: [library]), println([...output, ...output]));
          expect(calls, [entries.first]);
        });
      }
    }

    for (final parent in ['AliasChain', 'LocalBase']) {
      for (final entry in ['PublicBase', 'NativeBase']) {
        test('$parent finds the registered $entry entry', () async {
          final source =
              '''
import 'package:parent_types/types.dart';
typedef LocalBase = AliasChain;
class Parent extends $parent {}
void main() {
  final value = Parent();
  print(value.origin);
  print(value is PublicBase);
}
          ''';
          await expectLater(
            () => eval(
              source,
              libraries: [
                _bridgeLibrary(entries: [entry]),
              ],
            ),
            println([entry, true]),
          );
        });
      }
    }

    for (final reverse in [false, true]) {
      test('same-name classes in different libraries cannot replace the parent, reverse=$reverse', () async {
        final source = '''
import 'package:parent_types/entry.dart';
dynamic inspect(dynamic value) {
  print(value is PublicBase);
  print(value is SecondAlias);
  try { print(value as SecondAlias); }
  on TypeError { print('other type'); }
  try { throw value; }
  on SecondAlias { print('other'); }
  on PublicBase { print('parent'); }
  return null;
}
class Parent extends PublicBase {
  static final checked = inspect(Parent());
}
class Child extends Parent {}
void main() { inspect(Child()); }
        ''';
        final first = _bridgeLibrary(entries: ['NativeBase']);
        final second = DartLibrary(
          'parent_types',
          path: 'second.dart',
          declarations: [
            DartClass<_NativeOther>(
              ($) =>
                  '''
// ${$.empty('NativeBase.class', () => _proxy('other'))}
// ${$.alias('NativeBase')}
class NativeBase {}
// ${$.alias('PublicBase')}
typedef PublicBase = NativeBase;
// ${$.alias('SecondAlias')}
typedef SecondAlias = NativeBase;
          ''',
            ),
          ],
        );
        final libraries = [
          DartLibrary(
            'parent_types',
            path: 'entry.dart',
            source: "export 'types.dart'; export 'second.dart' show SecondAlias;",
            declarations: [],
          ),
          if (reverse) ...[second, first] else ...[first, second],
        ];
        await expectLater(
          () => eval(source, libraries: libraries),
          println([true, false, 'other type', 'parent', true, false, 'other type', 'parent']),
        );
      });
    }

    test('an alias chain crossing libraries retains each declaration source', () async {
      const source = '''
import 'package:parent_types/aliases.dart';
class Parent extends ExternalBase {}
void main() { print(Parent().origin); }
      ''';
      final libraries = [
        _bridgeLibrary(entries: ['PublicBase']),
        DartLibrary(
          'parent_types',
          path: 'aliases.dart',
          source: "import 'types.dart'; typedef ExternalBase = AliasChain;",
          declarations: [],
        ),
      ];
      await expectLater(() => eval(source, libraries: libraries), println(['PublicBase']));
    });

    test('encoded bridge paths retain the canonical parent library URI', () async {
      const source = '''
import 'package:parent_types/my%20types.dart';
class Parent extends PublicBase {}
void main() { print(Parent().origin); }
      ''';
      await expectLater(
        () => eval(
          source,
          libraries: [
            _bridgeLibrary(entries: ['NativeBase'], path: 'my types.dart'),
          ],
        ),
        println(['NativeBase']),
      );
    });

    test('part aliases retain their owning library URI', () async {
      const source = '''
import 'package:parent_types/bridge.dart';
class Parent extends PublicBase {}
void main() { print(Parent().origin); }
      ''';
      final libraries = [
        DartLibrary('parent_types', path: 'bridge.dart', source: "part 'types.dart';", declarations: []),
        _bridgeLibrary(entries: ['NativeBase'], source: "part of 'bridge.dart';"),
      ];
      await expectLater(() => eval(source, libraries: libraries), println(['NativeBase']));
    });

    test('shared proxies retain each alias binding and call the getter once per edge', () async {
      var count = 0;
      final proxy = ObjClass('NativeBase');
      final library = _bridgeLibrary(
        entries: ['PublicBase'],
        getter: (_) {
          final origin = ++count == 1 ? 'first' : 'second';
          proxy.props['origin'] = DartProperty(getter: (_) => origin);
          return proxy;
        },
      );
      const source = '''
import 'package:parent_types/types.dart';
class First extends PublicBase {}
class Second extends AliasChain {}
void main() {
  print(First().origin);
  print(Second().origin);
  print(First() is PublicBase);
  print(Second() is PublicBase);
}
      ''';
      await expectLater(() => eval(source, libraries: [library]), println(['first', 'second', true, true]));
      expect(count, 2);
    });

    test('a missing registration reports the actual parent entry', () async {
      const source = "import 'package:parent_types/types.dart'; class Parent extends PublicBase {} void main() {}";
      await expectLater(
        eval(source, libraries: [_bridgeLibrary(entries: [])]),
        throwsA(
          isA<EvalRuntimeError>().having(
            (error) => error.toString(),
            'message',
            contains('package:parent_types/types.dart::NativeBase.class'),
          ),
        ),
      );
    });

    test('an invalid selected alias getter cannot silently fall back to another entry', () async {
      var canonicalCalls = 0;
      final library = DartLibrary(
        'invalid_parent',
        path: 'types.dart',
        declarations: [
          DartClass<_NativeBase>(
            ($) =>
                '''
// ${$.empty('NativeBase.class', () {
                  canonicalCalls++;
                  return _proxy('canonical');
                })}
class NativeBase {}
// ${$.alias('PublicBase')}
typedef PublicBase = NativeBase;
        ''',
          ),
        ],
      );
      library.props['PublicBase.class'] = DartProperty(getter: () => 'invalid');
      const source = "import 'package:invalid_parent/types.dart'; class Parent extends PublicBase {} void main() {}";
      await expectLater(
        eval(source, libraries: [library]),
        throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Superclass must be a class'))),
      );
      expect(canonicalCalls, 0);
    });
  });

  group('Superclass alias boundaries', () {
    for (final isStatic in [true, false]) {
      test('unsupported canonical bridge metadata propagates to descendants in ${isStatic ? 'static initialization' : 'main'}', () async {
        final initializer = isStatic ? 'static final Child? checked = null as Child?;' : '';
        final source =
            '''
import 'package:parent_types/types.dart';
class Before { $initializer }
class Parent extends PublicBase {}
class Child extends Parent {}
void main() { ${isStatic ? 'print(Before.checked);' : 'print(null as Child?);'} }
        ''';
        final library = _bridgeLibrary(entries: ['NativeBase'], getter: (_) => ObjClass('NativeBase', isTypeCheckSupported: false));
        await expectLater(
          eval(source, libraries: [library]),
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
        );
      });
    }

    for (final parent in ['NullableBase', 'NullableChain']) {
      test('$parent cannot be used as a nullable superclass', () async {
        final source =
            '''
import 'package:parent_types/types.dart';
class Parent extends $parent {}
void main() {}
        ''';
        await expectLater(
          eval(
            source,
            libraries: [
              _bridgeLibrary(entries: ['NativeBase']),
            ],
          ),
          throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('non-nullable class'))),
        );
      });
    }

    for (final parent in ['RawBase', 'RawChain']) {
      for (final isStatic in [true, false]) {
        test('$parent keeps raw inheritance supported in ${isStatic ? 'static initialization' : 'main'}', () async {
          final source = _genericSource(parent, isStatic, '''
final value = Child();
print(value is NativeBase);
print((value as Child) == value);
try { throw value; }
on Child catch (error) { print(error == value); }
print(null as Child?);
          ''');
          await expectLater(() => eval(source, libraries: [_genericLibrary()]), println([true, true, true, null]));
        });
      }
    }

    for (final parent in ['NativeBase<int>', 'AppliedBase', 'AppliedChain', 'GenericBase']) {
      for (final operation in [
        (name: 'is', body: 'print(null is Child?);'),
        (name: 'as', body: 'print(null as Child?);'),
        (name: 'typed catch', body: 'try { throw Child(); } on Child { print("child"); }'),
      ]) {
        for (final isStatic in [true, false]) {
          test('$parent rejects ${operation.name} in ${isStatic ? 'static initialization' : 'main'}', () async {
            final source = _genericSource(parent, isStatic, operation.body);
            await expectLater(
              eval(source, libraries: [_genericLibrary()]),
              throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
            );
          });
        }
      }
    }

    for (final isStatic in [true, false]) {
      test('explicit dynamic inside an alias remains unsupported in ${isStatic ? 'static initialization' : 'main'}', () async {
        final source = _genericSource('DynamicBase', isStatic, 'print(null as Child?);');
        await expectLater(
          eval(source, libraries: [_genericLibrary()]),
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Unsupported type check'))),
        );
      });
    }
  });
}

class _NativeBase {}

class _NativeOther {}

ObjClass _proxy(String origin) {
  return ObjClass('NativeBase')..props['origin'] = DartProperty(getter: (_) => origin);
}

DartLibrary _bridgeLibrary({
  required List<String> entries,
  ObjClass Function(String)? getter,
  String path = 'types.dart',
  String source = '',
}) {
  return DartLibrary(
    'parent_types',
    path: path,
    source: source,
    declarations: [
      DartClass<_NativeBase>(
        ($) =>
            '''
${entries.map((name) => '// ${$.empty('$name.class', () => (getter ?? _proxy)(name))}').join('\n')}
// ${$.alias('NativeBase')}
class NativeBase { external String get origin; }
// ${$.alias('PublicBase')}
typedef PublicBase = NativeBase;
typedef AliasChain = PublicBase;
typedef NullableBase = NativeBase?;
typedef NullableChain = NullableBase;
    ''',
      ),
      DartClass<_NativeOther>(
        ($) =>
            '''
// ${$.alias('NativeOther')}
class NativeOther {}
    ''',
      ),
    ],
  );
}

String _genericSource(String parent, bool isStatic, String body) {
  final initializer = isStatic ? 'static final checked = inspect();' : '';
  return '''
import 'package:generic_parent/types.dart';
dynamic inspect() { $body return null; }
class Child extends Parent {}
class Parent extends $parent { $initializer }
void main() { ${isStatic ? 'final checked = Parent.checked;' : 'inspect();'} }
  ''';
}

DartLibrary _genericLibrary() {
  return DartLibrary(
    'generic_parent',
    path: 'types.dart',
    declarations: [
      DartClass<_NativeBase>(
        ($) =>
            '''
// ${$.empty('NativeBase.class', () => _proxy('generic'))}
// ${$.alias('NativeBase')}
class NativeBase<T> {}
typedef RawBase = NativeBase;
typedef RawChain = RawBase;
typedef AppliedBase = NativeBase<int>;
typedef AppliedChain = AppliedBase;
typedef DynamicBase = NativeBase<dynamic>;
typedef GenericBase<T> = NativeBase;
    ''',
      ),
    ],
  );
}
