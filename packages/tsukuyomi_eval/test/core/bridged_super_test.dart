import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Directives and script super slots', () {
    for (final directive in [
      (name: 'no directive', source: ''),
      (name: 'core import', source: "import 'dart:core';"),
      (name: 'bridge import', source: "import 'package:super_types/types.dart';"),
      (name: 'multiple imports', source: "import 'dart:core'; import 'package:super_types/types.dart';"),
      (name: 'export', source: "export 'package:super_types/types.dart';"),
      (name: 'import and export', source: "import 'dart:core'; export 'package:super_types/types.dart';"),
      (
        name: 'combinators',
        source: "import 'package:super_types/types.dart' show PublicBase; export 'package:super_types/types.dart' hide PublicBase;",
      ),
      (
        name: 'conditional URIs',
        source:
            "import 'dart:core' if (dart.library.io) 'dart:core'; export 'package:super_types/types.dart' if (dart.library.io) 'package:super_types/types.dart';",
      ),
    ]) {
      for (final captured in [false, true]) {
        test('${directive.name} preserves the lexical parent, captured=$captured', () async {
          final read = captured ? '(() => super.origin)()' : 'super.origin';
          final source =
              '''
${directive.source}
class Parent {
  int count = 0;
  String get origin => 'parent';
  String greet(String suffix) => 'parent:' + suffix;
}
class Child extends Parent {
  String get origin => 'child';
  String read() => $read;
  String call() => super.greet('method');
  int advance() => ++super.count;
  Function capture() => () => super.origin;
}
void main() {
  final first = Child();
  final second = Child();
  print(first.read());
  print(first.call());
  print(first.advance());
  print(first.capture()());
  print(first.origin);
  print(second.count);
}
          ''';
          await expectLater(() => eval(source, libraries: [_library()]), println(['parent', 'parent:method', 1, 'parent', 'child', 0]));
        });
      }
    }
  });

  group('Bridged super members', () {
    for (final parent in ['NativeBase', 'PublicBase', 'LocalBase', 'ScriptParent']) {
      final configurations = parent == 'NativeBase'
          ? [
              ['NativeBase'],
            ]
          : [
              ['PublicBase'],
              ['NativeBase'],
              ['PublicBase', 'NativeBase'],
            ];
      for (final entries in configurations) {
        test('$parent with ${entries.join(' and ')} preserves getters, setters, methods and receivers', () async {
          final calls = <String>[];
          final source =
              '''
import 'package:super_types/types.dart';
typedef LocalBase = PublicBase;
class ScriptParent extends PublicBase {}
class Child extends $parent {
  final String origin = 'child';
  String greet(String suffix) => 'child:' + suffix;
  String read() => super.origin;
  void write(int value) { super.count = value; }
  int advance() => ++super.count;
  String call(String suffix) => super.greet(suffix);
  Function bind() => super.greet;
  Function capture() => () => super.origin;
  Function nested() => () => () => super.origin;
  Function counter() => () => ++super.count;
}
class Descendant extends Child {
  String get origin => 'descendant';
}
void main() {
  final first = Descendant();
  final second = Descendant();
  final read = first.capture();
  final bound = first.bind();
  final advance = first.counter();
  first.write(1);
  print(first.read());
  print(read());
  print(first.nested()()());
  print(first.call('method'));
  print(bound('bound'));
  print(first.advance());
  print(advance());
  print(first.count);
  print(second.count);
  print(first.origin);
  print(first is NativeBase);
  print((first as PublicBase) == first);
  try { throw first; } on PublicBase catch (error) { print(error == first); }
}
          ''';
          final library = _library(
            entries: entries,
            getter: (name) {
              calls.add(name);
              return _proxy(name);
            },
          );
          final origin = entries.first;
          await expectLater(
            () => eval(source, libraries: [library]),
            println([origin, origin, origin, '$origin:method', '$origin:bound', 2, 3, 3, 0, 'descendant', true, true, true]),
          );
          expect(calls, [origin, if (parent != 'ScriptParent') origin]);
        });
      }
    }

    for (final reverse in [false, true]) {
      test('shared proxies retain the declaring binding after later classes, reverse=$reverse', () async {
        var count = 0;
        final proxy = _proxy('unused');
        final library = _library(
          getter: (_) {
            final origin = ++count == 1 ? 'first' : 'second';
            proxy.props['origin'] = DartProperty(getter: (_) => origin);
            return proxy;
          },
        );
        const first = '''
class First extends PublicBase {
  String read() => super.origin;
  Function capture() => () => super.origin;
}
        ''';
        const second = '''
class Second extends PublicBase {
  String read() => super.origin;
  Function capture() => () => super.origin;
}
        ''';
        final source =
            '''
import 'package:super_types/types.dart';
${reverse ? second : first}
${reverse ? first : second}
void main() {
  final first = First();
  final second = Second();
  print(first.read());
  print(second.read());
  print(first.capture()());
  print(second.capture()());
  print(first is PublicBase);
  print(second is PublicBase);
}
        ''';
        final origins = reverse ? ['second', 'first'] : ['first', 'second'];
        await expectLater(() => eval(source, libraries: [library]), println([...origins, ...origins, true, true]));
        expect(count, 2);
      });

      test('same-name bridge classes cannot replace the captured parent, reverse=$reverse', () async {
        final first = _library();
        final second = DartLibrary(
          'super_types',
          path: 'other.dart',
          declarations: [
            DartClass<_OtherBase>(
              ($) =>
                  '''
// ${$.empty('NativeBase.class', () => _proxy('other'))}
class NativeBase { external String get origin; }
// ${$.alias('OtherBase')}
typedef OtherBase = NativeBase;
          ''',
            ),
          ],
        );
        final entry = DartLibrary(
          'super_types',
          path: 'entry.dart',
          source: "export 'types.dart'; export 'other.dart' show OtherBase;",
          declarations: [],
        );
        const source = '''
import 'package:super_types/entry.dart';
class Child extends PublicBase {
  String read() => super.origin;
  Function capture() => () => super.origin;
}
void main() {
  final value = Child();
  print(value.read());
  print(value.capture()());
  print(value is PublicBase);
  print(value is OtherBase);
}
        ''';
        final libraries = [
          entry,
          if (reverse) ...[second, first] else ...[first, second],
        ];
        await expectLater(() => eval(source, libraries: libraries), println(['NativeBase', 'NativeBase', true, false]));
      });
    }

    test('static initialization can invoke methods using super', () async {
      const source = '''
import 'package:super_types/types.dart';
class Child extends PublicBase {
  static final checked = Child().read();
  String read() => super.origin;
  Function capture() => () => super.origin;
}
void main() {
  print(Child.checked);
  print(Child().capture()());
}
      ''';
      await expectLater(() => eval(source, libraries: [_library()]), println(['NativeBase', 'NativeBase']));
    });

    test('escaped closures retain super across await and host callbacks', () async {
      const source = '''
import 'package:super_types/types.dart';
class Child extends PublicBase {
  capture() => (int index) => super.greet(index.toString());
  Future<String> read() async {
    final getter = () => super.origin;
    await null;
    return getter();
  }
}
Future<void> main() async {
  final first = Child();
  final second = Child();
  final callback = first.capture();
  await null;
  print([0, 1].map(callback).join(','));
  print(await first.read());
  print(await second.read());
}
      ''';
      await expectLater(() => eval(source, libraries: [_library()]), println(['NativeBase:0,NativeBase:1', 'NativeBase', 'NativeBase']));
    });

    test('super remains usable after host errors and finally', () async {
      const source = '''
import 'package:super_types/types.dart';
class Child extends PublicBase {
  void attempt() {
    try { super.fail(); }
    catch (error) { print(error); }
    finally { print(super.origin); }
  }
  Function capture() {
    try { return () => super.origin; }
    finally { print(super.origin); }
  }
}
void main() {
  final value = Child();
  value.attempt();
  print(value.capture()());
  value.attempt();
}
      ''';
      await expectLater(
        () => eval(source, libraries: [_library()]),
        println(['host error', 'NativeBase', 'NativeBase', 'NativeBase', 'host error', 'NativeBase']),
      );
    });

    for (final member in ['origin', 'count']) {
      test('missing parent $member reports the corresponding getter or setter', () async {
        final proxy = _proxy('unused');
        proxy.props[member] = DartProperty();
        final body = member == 'origin' ? 'print(super.origin);' : 'super.count = 1;';
        final source =
            '''
import 'package:super_types/types.dart';
class Child extends PublicBase { void access() { $body } }
void main() { Child().access(); }
        ''';
        final operation = member == 'origin' ? 'getter' : 'setter';
        await expectLater(
          eval(source, libraries: [_library(getter: (_) => proxy)]),
          throwsA(
            isA<EvalRuntimeError>().having(
              (error) => error.toString(),
              'message',
              contains("Undefined $operation '$member' in superclass 'NativeBase'"),
            ),
          ),
        );
      });
    }
  });
}

class _NativeBase {}

class _OtherBase {}

ObjClass _proxy(String origin) {
  final proxy = ObjClass('NativeBase');
  proxy.props['origin'] = DartProperty(getter: (_) => origin);
  proxy.props['count'] = DartProperty(
    getter: (ObjInstance instance) => instance.fields['NativeBase.count'] ?? 0,
    setter: (ObjInstance instance, value) => instance.fields['NativeBase.count'] = value,
  );
  proxy.props['greet'] = DartProperty(
    getter: (_) =>
        (String suffix) => '$origin:$suffix',
  );
  proxy.props['fail'] = DartProperty(
    getter: (_) =>
        () => throw 'host error',
  );
  return proxy;
}

DartLibrary _library({List<String> entries = const ['NativeBase'], ObjClass Function(String)? getter}) {
  return DartLibrary(
    'super_types',
    path: 'types.dart',
    declarations: [
      DartClass<_NativeBase>(
        ($) =>
            '''
${entries.map((name) => '// ${$.empty('$name.class', () => (getter ?? _proxy)(name))}').join('\n')}
// ${$.alias('NativeBase')}
class NativeBase {
  external String get origin;
  external int count;
  external String greet(String suffix);
  external void fail();
}
// ${$.alias('PublicBase')}
typedef PublicBase = NativeBase;
    ''',
      ),
    ],
  );
}
