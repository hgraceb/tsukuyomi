import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/src/resolver.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Single-level collection type checks', () {
    for (final entry in [
      (type: 'List<int>', value: '<int>[0]', empty: '<int>[]', wrong: '<dynamic>[0]', wrongEmpty: '<dynamic>[]'),
      (type: 'Iterable<int>', value: '<int>[0]', empty: '<int>[]', wrong: '<dynamic>[0]', wrongEmpty: '<dynamic>[]'),
      (type: 'Set<int>', value: '<int>{0}', empty: '<int>{}', wrong: '<dynamic>{0}', wrongEmpty: '<dynamic>{}'),
      (
        type: 'Map<String, int>',
        value: "<String, int>{'chapter': 0}",
        empty: '<String, int>{}',
        wrong: "<dynamic, dynamic>{'chapter': 0}",
        wrongEmpty: '<dynamic, dynamic>{}',
      ),
    ]) {
      test('${entry.type} checks the reified type of empty and nonempty values', () async {
        final source =
            '''
void main() {
  dynamic value = ${entry.value};
  print(value is ${entry.type});
  print(value is! ${entry.type});
  value = ${entry.empty};
  print(value is ${entry.type});
  value = ${entry.wrong};
  print(value is ${entry.type});
  print(value is! ${entry.type});
  value = ${entry.wrongEmpty};
  print(value is ${entry.type});
}
''';
        await expectLater(() => evalChecked(source), println([true, false, true, false, true, false]));
      });

      test('${entry.type} casts preserve identity and reject the wrong generic type', () async {
        final source =
            '''
void main() {
  dynamic value = ${entry.value};
  print((value as ${entry.type}) == value);
  value = ${entry.wrong};
  try { value as ${entry.type}; } on TypeError { print('type error'); }
  value = ${entry.wrongEmpty};
  try { value as ${entry.type}; } on TypeError { print('empty type error'); }
}
''';
        await expectLater(() => evalChecked(source), println([true, 'type error', 'empty type error']));
      });

      test('${entry.type} catches share the same generic checks', () async {
        final source =
            '''
void main() {
  dynamic value = ${entry.value};
  try { throw value; } on ${entry.type} catch (error) { print(error == value); }
  value = ${entry.wrong};
  try { throw value; } on ${entry.type} { print('wrong catch'); } catch (error) { print(error == value); }
  finally { print('finally'); }
}
''';
        await expectLater(() => evalChecked(source), println([true, true, 'finally']));
      });
    }

    test('map key and value arguments are both checked with Dart covariance', () async {
      const source = '''
void main() {
  dynamic value = <String, int>{'chapter': 0};
  print(value is Map<String, num>);
  print(value is Map<Object, Object>);
  print(value is Map<int, int>);
  print(value is Map<String, String>);
  value = <String, dynamic>{'chapter': 0};
  print(value is Map<String, int>);
  print(value is Map<String, dynamic>);
}
''';
      await expectLater(() => evalChecked(source), println([true, true, false, false, false, true]));
    });

    test('nullable containers and arguments use their independent null rules', () async {
      const source = '''
void main() {
  dynamic value = null;
  print(value is List<int>?);
  print(value is List<int?>);
  print(value as Map<String?, int?>?);
  value = nullableInts;
  print(value is List<int?>);
  print(value is List<int>);
  value = nullableEntries;
  print(value is Map<String?, int?>);
  print(value is Map<String, int?>);
  print(value is Map<String?, int>);
}
''';
      final values = [
        DartVariable('nullableInts', <int?>[null], 'external dynamic get nullableInts;'),
        DartVariable('nullableEntries', <String?, int?>{null: null}, 'external dynamic get nullableEntries;'),
      ];
      await expectLater(
        () => evalChecked(source, declarations: values),
        println([true, false, null, true, false, true, false, false]),
      );
    });

    test('dynamic Object Null and Never arguments retain real host semantics', () async {
      const source = '''
void main() {
  dynamic value = <int>[];
  print(value is List<dynamic>);
  print(value is List<Object>);
  print(value is List<Never>);
  value = <Never>[];
  print(value is List<int>);
  print(value is List<Never>);
  value = nulls;
  print(value is List<Null>);
  print(value is List<Object>);
  print(value is List<Object?>);
}
''';
      await expectLater(
        () => evalChecked(
          source,
          declarations: [
            DartVariable('nulls', <Null>[null], 'external dynamic get nulls;'),
          ],
        ),
        println([true, true, false, true, true, true, false, true]),
      );
    });

    test('cast views are checked without reading their deferred elements', () async {
      const source = '''
void main() {
  dynamic value = <dynamic>['chapter'].cast<int>();
  print(value is List<int>);
  print((value as List<int>) == value);
  try { print(value.first); } on TypeError { print('deferred type error'); }
}
''';
      await expectLater(() => evalChecked(source), println([true, true, 'deferred type error']));
    });

    test('native Function collections preserve script function values', () async {
      const source = '''
void main() {
  dynamic value = <Function>[() => 'chapter'];
  print(value is List<Function>);
  print((value as List<Function>).single());
  value = <dynamic>[() => 'chapter'];
  print(value is List<Function>);
}
''';
      await expectLater(() => evalChecked(source), println([true, 'chapter', false]));
    });

    for (final entry in [
      (declaration: 'typedef Target = List<int>;', value: '<int>[0]'),
      (declaration: 'typedef Ints = List<int>; typedef Target = Ints;', value: '<int>[0]'),
      (declaration: 'typedef Target = List<dynamic>;', value: '<int>[0]'),
      (declaration: 'typedef Values = List<dynamic>; typedef Target = Values;', value: '<int>[0]'),
      (declaration: 'typedef Target = Map<dynamic, dynamic>;', value: "<String, int>{'chapter': 0}"),
      (declaration: 'typedef Target = Map<String, int>;', value: "<String, int>{'chapter': 0}"),
    ]) {
      test('${entry.declaration} works for is as and on', () async {
        final source =
            '''
${entry.declaration}
void main() {
  dynamic value = ${entry.value};
  print(value is Target);
  print((value as Target) == value);
  try { throw value; } on Target catch (error) { print(error == value); }
}
''';
        await expectLater(() => evalChecked(source), println([true, true, true]));
      });
    }

    test('nullable collection aliases retain declaration and use site nullability', () async {
      const source = '''
typedef MaybeInts = List<int>?;
typedef Ints = List<int>;
void main() {
  dynamic value = null;
  print(value is MaybeInts);
  print(value as MaybeInts);
  print(value as Ints?);
  value = <dynamic>[];
  print(value is MaybeInts);
}
''';
      await expectLater(() => evalChecked(source), println([true, null, null, false]));
    });

    test('raw types remain leaves rather than implicitly nested targets', () async {
      const source = '''
typedef RawList = List;
void main() {
  dynamic value = lists;
  print(value is List<List>);
  print(value is List<RawList>);
  print(value is List);
  print(value is List<dynamic>);
}
''';
      await expectLater(
        () => evalChecked(source, declarations: [DartVariable('lists', <List>[], 'external dynamic get lists;')]),
        println([true, true, true, true]),
      );
    });

    test('await operands and typed catches retain evaluation and finally order', () async {
      const source = '''
int calls = 0;
Future<dynamic> values() async { calls++; await null; return <int>[0]; }
Future<void> main() async {
  print(await values() is List<int>);
  print(calls);
  try { throw await values(); } on List<int> catch (error) {
    await null;
    print(error.first);
  } finally { await null; print('finally'); }
  print(calls);
}
''';
      await expectLater(() => evalChecked(source), println([true, 1, 0, 'finally', 2]));
    });

    test('collection targets survive compute and later invocation of the returned instance', () async {
      const source = '''
class Example {
  bool matches(dynamic value) => value is List<int>;
  dynamic checked(dynamic value) => value as Map<String, int>;
}
main() => Example();
''';
      await expectValidSource(source, const []);
      final instance = await compute((source) async => await eval(source) as ObjInstance, source);
      expect(await instance.invoke('matches', [<int>[]]), isTrue);
      expect(await instance.invoke('matches', [<dynamic>[]]), isFalse);
      final value = <String, int>{'chapter': 0};
      expect(await instance.invoke('checked', [value]), same(value));
    });
  });

  group('Collection bridge type identities', () {
    for (final reverse in [false, true]) {
      test('same-named argument types retain their libraries when reverse=$reverse', () async {
        final first = DartLibrary(
          'items',
          path: 'first.dart',
          declarations: [
            DartClass<_First>(
              ($) =>
                  '''
// ${$.alias('Item')}
class Item {}
''',
            ),
            DartVariable('firstValues', <_First>[], 'external dynamic get firstValues;'),
          ],
        );
        final second = DartLibrary(
          'items',
          path: 'second.dart',
          declarations: [
            DartClass<_Second>(
              ($) =>
                  '''
// ${$.alias('Item')}
class Item {}
typedef SecondAlias = Item;
''',
            ),
            DartVariable('secondValues', <_Second>[], 'external dynamic get secondValues;'),
          ],
        );
        final entry = DartLibrary(
          'items',
          path: 'items.dart',
          source: '''
export 'first.dart' show Item, firstValues;
export 'second.dart' show SecondAlias, secondValues;
''',
          declarations: [],
        );
        const source = '''
import 'package:items/items.dart';
void main() {
  dynamic value = firstValues;
  print(value is List<Item>);
  print(value is List<SecondAlias>);
  print((value as List<Item>) == value);
  try { throw value; } on List<SecondAlias> { print('wrong catch'); }
  on List<Item> catch (error) { print(error == value); }
  value = secondValues;
  print(value is List<Item>);
  print(value is List<SecondAlias>);
}
''';
        final libraries = [
          entry,
          if (reverse) ...[second, first] else ...[first, second],
        ];
        await expectLater(() => evalChecked(source, libraries: libraries), println([true, false, true, true, false, true]));
      });
    }

    test('alias-only argument registrations retain their real host type', () async {
      final library = DartLibrary(
        'items',
        path: 'items.dart',
        declarations: [
          DartClass<_First>(
            ($) =>
                '''
class InternalItem {}
// ${$.alias('PublicItem')}
typedef PublicItem = InternalItem;
typedef PublicChain = PublicItem;
''',
          ),
          DartVariable('items', <_First>[], 'external dynamic get items;'),
        ],
      );
      const source = '''
import 'package:items/items.dart';
void main() {
  dynamic value = items;
  print(value is List<PublicChain>);
  print(value is List<PublicItem?>);
  print((value as List<PublicItem>) == value);
  try { throw value; } on List<PublicChain> catch (error) { print(error == value); }
}
''';
      await expectLater(() => evalChecked(source, libraries: [library]), println([true, true, true, true]));
    });

    test('raw bounded arguments do not become explicit nested arguments', () async {
      final library = DartLibrary(
        'bounded',
        path: 'bounded.dart',
        declarations: [
          DartClass<_Bounded>(
            ($) =>
                '''
// ${$.alias('Bounded')}
class Bounded<T extends num> {}
typedef RawBounded = Bounded;
''',
          ),
          DartVariable('items', <_Bounded>[], 'external dynamic get items;'),
        ],
      );
      const source = '''
import 'package:bounded/bounded.dart';
void main() {
  dynamic value = items;
  print(value is List<Bounded>);
  print(value is List<RawBounded>);
  print((value as List<RawBounded>) == value);
  try { throw value; } on List<Bounded> catch (error) { print(error == value); }
}
''';
      await expectLater(() => evalChecked(source, libraries: [library]), println([true, true, true, true]));
    });

    test('core argument aliases retain their library under a shadowing String bridge', () async {
      final aliases = DartLibrary(
        'texts',
        path: 'texts.dart',
        source: '''
typedef Text = String;
typedef Texts = List<String>;
typedef Entries = Map<String, int>;
''',
        declarations: [
          DartVariable('texts', <String>[], 'external dynamic get texts;'),
          DartVariable('entries', <String, int>{}, 'external dynamic get entries;'),
        ],
      );
      final shadow = DartLibrary(
        'shadow',
        path: 'shadow.dart',
        declarations: [
          DartClass<_First>(
            ($) =>
                '''
// ${$.alias('String')}
class String {}
''',
          ),
        ],
      );
      const source = '''
import 'package:texts/texts.dart';
import 'package:shadow/shadow.dart';
void main() {
  dynamic value = texts;
  print(value is List<Text>);
  print(value is List<String>);
  print((value as Texts) == value);
  value = entries;
  print(value is Map<Text, int>);
  print(value is Map<String, int>);
  print((value as Entries) == value);
}
''';
      await expectLater(() => evalChecked(source, libraries: [aliases, shadow]), println([true, false, true, true, false, true]));
    });

    for (final operator in ['is', 'as', 'on']) {
      test('a noncore List remains unsupported for $operator', () async {
        final library = DartLibrary(
          'shadow',
          path: 'shadow.dart',
          declarations: [
            DartClass<_First>(
              ($) =>
                  '''
// ${$.alias('List')}
class List<T> {}
''',
            ),
          ],
        );
        final body = operator == 'on' ? 'try { throw value; } on List<int> {}' : 'print(value $operator List<int>);';
        final source = "import 'package:shadow/shadow.dart'; void main() { dynamic value = null; $body }";
        await expectValidSource(source, [library]);
        await expectLater(eval(source, libraries: [library]), throwsA(isA<EvalCompileError>()));
      });
    }

    for (final operator in ['is', 'as']) {
      test('an unregistered argument is not silently accepted by nullable $operator', () async {
        final library = DartLibrary('missing', path: 'missing.dart', source: 'class Missing {}', declarations: []);
        final source =
            "import 'package:missing/missing.dart'; void main() { dynamic value = null; print(value $operator List<Missing>?); }";
        await expectValidSource(source, [library]);
        await expectLater(eval(source, libraries: [library]), throwsA(isA<EvalRuntimeError>()));
      });
    }
  });

  group('Collection type check boundaries', () {
    for (final target in [
      'List<List<int>>',
      'Map<String, List<int>>',
      'List<Rows>',
      'List<Example>',
      'List<Callback>',
      'List<void>',
      'Future<int>',
      'Generic<int>',
    ]) {
      for (final operator in ['is', 'as', 'on']) {
        test('$target is rejected before execution for $operator', () async {
          final body = operator == 'on' ? 'try { throw value; } on $target {}' : 'print(value $operator $target);';
          final source =
              '''
typedef Rows = List<int>;
typedef Callback = int Function();
typedef Generic<T> = List<T>;
class Example {}
void main() { print('must not execute'); dynamic value = null; $body }
''';
          await expectValidSource(source, const []);
          await expectLater(eval(source), throwsA(isA<EvalCompileError>()));
        });
      }
    }
  });
}

Future<dynamic> evalChecked(String source, {List<DartDeclaration> declarations = const [], List<DartLibrary> libraries = const []}) async {
  final context = [...libraries, if (declarations.isNotEmpty) DartLibrary('values', path: 'values.dart', declarations: declarations)];
  final imports = declarations.isEmpty ? source : "import 'package:values/values.dart';\n$source";
  await expectValidSource(imports, context);
  return eval(imports, libraries: context);
}

Future<void> expectValidSource(String source, List<DartLibrary> libraries) async {
  final resolved = await resolve(source, [...dartLibraries, ...libraries]);
  final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
  expect(errors.map((error) => error.message), isEmpty);
}

class _First {}

class _Second {}

class _Bounded<T extends num> {}
