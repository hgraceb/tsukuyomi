import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Script function values in native collections', () {
    for (final method in ['whereType', 'cast']) {
      for (final value in ['() => 1', 'Example().next']) {
        test('$method retains $value and the original function identity', () async {
          final source =
              '''
class Example { int value = 0; int next() => ++value; }
void main() {
  final value = $value;
  final values = <dynamic>[value].$method<Function>();
  print(values.first == value);
  print(values.first());
  print(values.toList().first == value);
}
          ''';
          await expectLater(() => eval(source), println([true, 1, true]));
        });
      }
    }

    test('Function filtering includes native and script functions and excludes other values', () async {
      const source = '''
void main() {
  final value = () => 1;
  final values = <dynamic>[null, value, print, 0].whereType<Function>().toList();
  print(values.length);
  print(values[0] == value);
  print(values[0]());
  values[1]('native');
}
      ''';
      await expectLater(() => eval(source), println([2, true, 1, 'native']));
    });

    test('nullable function filtering retains null and excludes nonfunctions', () async {
      const source = '''
void main() {
  final value = () => 1;
  final values = <dynamic>[null, value, 0].whereType<Function?>().toList();
  print(values.length);
  print(values[0]);
  print(values[1] == value);
}
      ''';
      await expectLater(() => eval(source), println([2, null, true]));
    });

    test('nullable function casts retain null and the original callable', () async {
      const source = '''
void main() {
  final value = () => 1;
  final values = <dynamic>[null, value].cast<Function?>();
  print(values[0]);
  print(values[1] == value);
  print(values[1]!());
}
      ''';
      await expectLater(() => eval(source), println([null, true, 1]));
    });

    test('function casts defer nonfunction failures until the element is read', () async {
      const source = '''
void main() {
  final values = <dynamic>[() => 1, 0].cast<Function>();
  print('created');
  print(values.first());
  try { values.last; } on TypeError { print('type error'); }
  print('resumed');
}
      ''';
      await expectLater(() => eval(source), println(['created', 1, 'type error', 'resumed']));
    });

    test('bound function values retain their separate receivers', () async {
      const source = '''
class Example { int value = 0; int next() => ++value; }
void main() {
  final first = Example();
  final second = Example();
  final values = <dynamic>[first.next, second.next].cast<Function>().toList();
  print(values[0]());
  print(values[0]());
  print(values[1]());
}
      ''';
      await expectLater(() => eval(source), println([1, 2, 1]));
    });

    for (final collection in ['<dynamic>[value]', '<dynamic>{value}', '<dynamic>[value].where((value) => true)']) {
      test('$collection casts retain the native collection kind', () async {
        final source =
            '''
void main() {
  final value = () => 1;
  final values = $collection.cast<Function>();
  print(values is List);
  print(values is Set);
  print(values.first == value);
}
        ''';
        final isList = collection == '<dynamic>[value]';
        final isSet = collection == '<dynamic>{value}';
        await expectLater(() => eval(source), println([isList, isSet, true]));
      });
    }

    test('List function casts preserve writes to the original list', () async {
      const source = '''
void main() {
  final first = () => 0;
  final second = () => 1;
  final values = <dynamic>[first];
  final functions = values.cast<Function>();
  functions[0] = second;
  print(values[0] == second);
  functions.add(first);
  print(values.last == first);
  print(functions.contains(first));
  print(functions.indexOf(first));
  functions.remove(second);
  print(values.length);
}
      ''';
      await expectLater(() => eval(source), println([true, true, true, 1, 1]));
    });

    test('Set function casts preserve writes and membership in the original set', () async {
      const source = '''
void main() {
  final first = () => 0;
  final second = () => 1;
  final values = <dynamic>{first};
  final functions = values.cast<Function>();
  functions.add(second);
  print(values.contains(second));
  print(functions.lookup(first) == first);
  functions.remove(first);
  print(values.length);
  print(values.first == second);
}
      ''';
      await expectLater(() => eval(source), println([true, true, 1, true]));
    });

    test('ordinary Function aliases use the same value bridge', () async {
      const source = '''
typedef Callback = Function;
void main() {
  final value = () => 1;
  print(<dynamic>[value].whereType<Callback>().first == value);
  print(<dynamic>[value].cast<Callback>().first());
}
      ''';
      await expectLater(() => eval(source), println([true, 1]));
    });

    test('functions with unsupported host signatures are still valid collection values', () async {
      const source = '''
class Example {}
void main() {
  final named = ({int value = 1}) => value;
  final many = (int first, int second, int third) => first + second + third;
  final scriptResult = () => Example();
  final values = <dynamic>[named, many, scriptResult].whereType<Function>().toList();
  print(values.length);
  print(values[0] == named);
  print(values[0](value: 1));
  print(values[1](0, 0, 1));
  print(values[2]() is Example);
}
      ''';
      await expectLater(() => eval(source), println([3, true, 1, 1, true]));
    });

    test('collection value methods do not require a host callback signature', () async {
      const source = '''
void main() {
  final value = ({int number = 1}) => number;
  final values = <Function>[];
  values.add(value);
  print(values.contains(value));
  print(values.first == value);
  print(values.first(number: 1));
}
      ''';
      await expectLater(() => eval(source), println([true, true, 1]));
    });

    test('map results retain function identity through Object and dynamic results', () async {
      const source = '''
void main() {
  final value = () => 1;
  print(<int>[0].map<Function>((number) => value).first == value);
  print(<int>[0].map<Object>((number) => value).first == value);
  print(<int>[0].map<dynamic>((number) => value).whereType<Function>().first == value);
}
      ''';
      await expectLater(() => eval(source), println([true, true, true]));
    });

    test('captured function values retain state across await', () async {
      const source = '''
Future<void> main() async {
  int value = 0;
  final callback = () => ++value;
  final callbacks = <dynamic>[callback].cast<Function>();
  await Future.value();
  print(callbacks.first());
  print(callback());
  print(callbacks.first == callback);
}
      ''';
      await expectLater(() => eval(source), println([1, 2, true]));
    });

    test('function values retain their identity as map keys and values', () async {
      const source = '''
void main() {
  final key = () => 0;
  final value = () => 1;
  final values = <dynamic, dynamic>{key: value};
  print(values[key] == value);
  values[key] = key;
  print(values[key] == key);
}
      ''';
      await expectLater(() => eval(source), println([true, true]));
    });

    test('function data added to typed collections retains the native Function identity', () async {
      const source = '''
import 'package:function_values/checks.dart';
void main() {
  final value = () => 1;
  print(isFunctions(<Function>[value]));
  print(isFunctions(<dynamic>[value].cast<Function>().toList()));
}
      ''';
      final library = DartLibrary(
        'function_values',
        path: 'checks.dart',
        declarations: [
          DartFunction('isFunctions', (dynamic value) => value is List<Function>, 'external bool isFunctions(dynamic value);'),
        ],
      );
      await expectLater(() => eval(source, libraries: [library]), println([true, true]));
    });

    test('native overridden collection methods still receive the actual type argument', () async {
      const source = '''
import 'package:function_values/checks.dart';
void main() {
  print(nativeValues.whereType<Function>().length);
  print(nativeValues.cast<Function>().first == print);
  print(calls);
}
      ''';
      final values = _NativeValues();
      final library = DartLibrary(
        'function_values',
        path: 'checks.dart',
        declarations: [
          DartVariable('nativeValues', values, 'external Iterable<dynamic> get nativeValues;'),
          DartVariable('calls', values.calls, 'external List<String> get calls;'),
        ],
      );
      await expectLater(() => eval(source, libraries: [library]), println([1, true, '[whereType Function, cast Function]']));
    });

    for (final isolated in [false, true]) {
      test('returned instances retain their function values across VM calls, compute=$isolated', () async {
        final instance = isolated ? await compute(_createInstance, _instanceSource) : await _createInstance(_instanceSource);
        expect(instance.invoke('same', []), true);
        expect(instance.invoke('invokeStored', []), 1);
      });
    }
  });
}

Future<ObjInstance> _createInstance(String source) async => await eval(source) as ObjInstance;

const _instanceSource = '''
class Example {
  Function original = () => 1;
  List values = <dynamic>[];
  void initialize() { this.values = <dynamic>[this.original]; }
  bool same() => this.values.first == this.original;
  int invokeStored() => this.values.first();
}
main() { final value = Example(); value.initialize(); return value; }
''';

class _NativeValues extends Iterable<dynamic> {
  final calls = <String>[];

  @override
  Iterator<dynamic> get iterator => <dynamic>[print].iterator;

  @override
  Iterable<T> whereType<T>() {
    calls.add('whereType $T');
    return super.whereType<T>();
  }

  @override
  Iterable<R> cast<R>() {
    calls.add('cast $R');
    return super.cast<R>();
  }
}
