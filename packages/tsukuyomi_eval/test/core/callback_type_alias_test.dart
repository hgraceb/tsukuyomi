import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host callback return aliases', () {
    for (final entry in [
      (name: 'alias-only', alias: true, canonical: false),
      (name: 'canonical-only', alias: false, canonical: true),
      (name: 'alias and canonical', alias: true, canonical: true),
    ]) {
      test('${entry.name} callbacks retain the actual host return type', () async {
        const source = '''
import 'package:callback_types/types.dart';
PublicValue make(int value) => hostValue;
void main() {
  print([0].map(make).first == hostValue);
  print(isTyped(make));
  print(call(make) == hostValue);
}
        ''';
        final library = _callbackLibrary(registerAlias: entry.alias, registerCanonical: entry.canonical);
        await expectLater(() => eval(source, libraries: [library]), println([true, true, true]));
      });
    }

    for (final type in ['PublicValue?', 'NullableValue', 'PublicChain?']) {
      test('$type callbacks retain null and the actual nullable host return type', () async {
        final source =
            '''
import 'package:callback_types/types.dart';
$type make(int value) => value == 0 ? null : hostValue;
void main() {
  final values = callNullable(make);
  print(values[0]);
  print(values[1] == hostValue);
  print(isNullableTyped(make));
}
        ''';
        await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([null, true, true]));
      });
    }

    test('alias chains find an inner registered entry', () async {
      const source = '''
import 'package:callback_types/types.dart';
PublicChain make(int value) => hostValue;
void main() { print(call(make) == hostValue); }
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([true]));
    });

    test('bound methods retain their receiver and alias return type', () async {
      const source = '''
import 'package:callback_types/types.dart';
class Example {
  PublicValue stored = hostValue;
  PublicValue make(int value) => stored;
  PublicValue? maybe(int value) => value == 0 ? null : stored;
}
void main() {
  final example = Example();
  print(call(example.make) == hostValue);
  print(isTyped(example.make));
  final values = callNullable(example.maybe);
  print(values[0]);
  print(values[1] == hostValue);
}
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([true, true, null, true]));
    });

    test('local callbacks retain captured state across host calls', () async {
      const source = '''
import 'package:callback_types/types.dart';
void main() {
  final stored = hostValue;
  int calls = 0;
  PublicValue make(int value) {
    calls++;
    return stored;
  }
  print(call(make) == stored);
  print(call(make) == stored);
  print(calls);
}
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([true, true, 2]));
    });

    test('callbacks inferred from a bridged alias use the same entry', () async {
      const source = '''
import 'package:callback_types/types.dart';
void main() {
  print(call((int value) => hostValue) == hostValue);
  print(isTyped((int value) => hostValue));
}
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([true, true]));
    });

    for (final reverse in [false, true]) {
      test('same-name aliases in other libraries cannot replace the callback entry, reverse=$reverse', () async {
        const source = '''
import 'package:callback_types/types.dart';
PublicValue make(int value) => hostValue;
void main() { print(call(make) == hostValue); }
        ''';
        final libraries = [_callbackLibrary(), _shadowLibrary()];
        await expectLater(() => eval(source, libraries: reverse ? libraries.reversed.toList() : libraries), println([true]));
      });
    }

    test('a script alias cannot borrow a shadowed bridge entry', () async {
      const source = '''
import 'package:callback_types/types.dart';
typedef PublicValue = int;
PublicValue make(int value) => value;
void main() { print([0].map(make).first); }
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([0]));
    });

    test('bridge paths use the normalized URI for alias entries', () async {
      const source = '''
import 'package:callback_types/my%20types.dart';
PublicValue make(int value) => hostValue;
void main() { print(call(make) == hostValue); }
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary(path: 'my types.dart')]), println([true]));
    });

    test('part aliases retain their owning library identity', () async {
      const source = '''
import 'package:callback_types/bridge.dart';
PublicValue make(int value) => hostValue;
void main() { print(call(make) == hostValue); }
      ''';
      final libraries = [
        DartLibrary('callback_types', path: 'bridge.dart', source: "part 'types.dart';", declarations: []),
        _callbackLibrary(source: "part of 'bridge.dart';"),
      ];
      await expectLater(() => eval(source, libraries: libraries), println([true]));
    });

    test('raw aliases and existing generic return annotations remain accepted', () async {
      const source = '''
import 'package:callback_generics/types.dart';
typedef Values = List;
typedef Entries = Map;
typedef Items = Iterable;
typedef Numbers = List<int>;
typedef GenericValues<T> = List<T>;
Values values(int value) => <int>[value];
Entries entries(int value) => <int, int>{value: value};
Items items(int value) => <int>[value];
Numbers numbers(int value) => <int>[value];
GenericValues<int> generic(int value) => <int>[value];
List<List<int>> nested(int value) => nestedValues;
void main() {
  print([0].map(values).first);
  print([0].map(entries).first);
  print([0].map(items).first);
  print([0].map(numbers).first);
  print([0].map(generic).first);
  print([0].map(nested).first);
}
      ''';
      final library = DartLibrary(
        'callback_generics',
        path: 'types.dart',
        declarations: [
          DartVariable('nestedValues', <List<int>>[
            [0],
          ], 'external List<List<int>> get nestedValues;'),
        ],
      );
      await expectLater(() => eval(source, libraries: [library]), println(['[0]', '{0: 0}', '[0]', '[0]', '[0]', '[[0]]']));
    });

    test('raw bridge aliases retain their registered entry despite implicit dynamic arguments', () async {
      const source = '''
import 'package:callback_types/types.dart';
RawValue make(int value) => rawValue;
void main() { print(callRaw(make) == rawValue); }
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([true]));
    });

    test('callback failures restore the caller before the next host call', () async {
      const source = '''
import 'package:callback_types/types.dart';
PublicValue make(int value) {
  if (value == 0) throw 'callback';
  return hostValue;
}
void main() {
  try { [0].map(make).first; }
  catch (error) { print(error); }
  finally { print('finally'); }
  print([1].map(make).first == hostValue);
}
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println(['callback', 'finally', true]));
    });

    test('async callers can await host calls with alias-returning callbacks', () async {
      const source = '''
import 'package:callback_types/types.dart';
PublicValue make(int value) => hostValue;
void main() async {
  final value = await callAsync(make);
  print(value == hostValue);
  print(call(make) == hostValue);
}
      ''';
      await expectLater(() => eval(source, libraries: [_callbackLibrary()]), println([true, true]));
    });
  });
}

class _HostValue {}

class _HostGeneric<T> {}

DartLibrary _callbackLibrary({bool registerAlias = true, bool registerCanonical = false, String path = 'types.dart', String source = ''}) {
  return DartLibrary(
    'callback_types',
    path: path,
    source: source,
    declarations: [
      DartClass<_HostValue>(
        ($) =>
            '''
${registerCanonical ? '// ${$.alias('InternalValue')}' : ''}
class InternalValue {}
${registerAlias ? '// ${$.alias('PublicValue')}' : ''}
typedef PublicValue = InternalValue;
typedef PublicChain = PublicValue;
typedef NullableValue = PublicValue?;
    ''',
      ),
      DartVariable('hostValue', _HostValue(), 'external PublicValue get hostValue;'),
      DartClass<_HostGeneric>(
        ($) =>
            '''
class GenericValue<T> {}
// ${$.alias('RawValue')}
typedef RawValue = GenericValue;
    ''',
      ),
      DartVariable('rawValue', _HostGeneric<int>(), 'external RawValue get rawValue;'),
      DartFunction(
        'callRaw',
        (_HostGeneric Function(int) callback) => callback(0),
        'external RawValue callRaw(RawValue Function(int) callback);',
      ),
      DartFunction('isTyped', (Function callback) => callback is _HostValue Function(int), 'external bool isTyped(Function callback);'),
      DartFunction(
        'call',
        (_HostValue Function(int) callback) => callback(0),
        'external PublicValue call(PublicValue Function(int) callback);',
      ),
      DartFunction(
        'isNullableTyped',
        (Function callback) => callback is _HostValue? Function(int),
        'external bool isNullableTyped(Function callback);',
      ),
      DartFunction(
        'callNullable',
        (_HostValue? Function(int) callback) => [callback(0), callback(1)],
        'external List<PublicValue?> callNullable(PublicValue? Function(int) callback);',
      ),
      DartFunction(
        'callAsync',
        (_HostValue Function(int) callback) async => callback(0),
        'external Future<PublicValue> callAsync(PublicValue Function(int) callback);',
      ),
    ],
  );
}

DartLibrary _shadowLibrary() {
  return DartLibrary(
    'callback_types',
    path: 'shadow.dart',
    declarations: [
      DartClass<String>(
        ($) =>
            '''
class InternalValue {}
// ${$.alias('PublicValue')}
typedef PublicValue = InternalValue;
    ''',
      ),
    ],
  );
}
