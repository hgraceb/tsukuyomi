import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host function argument roles', () {
    for (final tearOff in [false, true]) {
      test('List function values retain their identity, tear-off=$tearOff', () async {
        final source =
            '''
void main() {
  final value = ({int number = 1}) => number;
  final values = <Function>[];
  ${tearOff ? 'final add = values.add; add(value);' : 'values.add(value);'}
  ${tearOff ? 'final contains = values.contains; print(contains(value));' : 'print(values.contains(value));'}
  print(values.first == value);
  print(values.first(number: 1));
}
        ''';
        await expectLater(() => eval(source), println([true, true, 1]));
      });

      test('Map key and value methods retain function identity, tear-off=$tearOff', () async {
        final source =
            '''
void main() {
  final key = ({int number = 0}) => number;
  final value = ({int number = 1}) => number;
  final values = <dynamic, dynamic>{key: value};
  ${tearOff ? 'final containsKey = values.containsKey; print(containsKey(key));' : 'print(values.containsKey(key));'}
  ${tearOff ? 'final containsValue = values.containsValue; print(containsValue(value));' : 'print(values.containsValue(value));'}
  print(values[key] == value);
  values[key] = key;
  ${tearOff ? 'final remove = values.remove; print(remove(key) == key);' : 'print(values.remove(key) == key);'}
  print(values.length);
}
        ''';
        await expectLater(() => eval(source), println([true, true, true, true, 0]));
      });

      test('a native method named add still validates its callback, tear-off=$tearOff', () async {
        final callbacks = _NativeCallbacks();
        final declaration = DartClass<_NativeCallbacks>(
          ($) =>
              '''
// ${$.alias('NativeCallbacks')}
class NativeCallbacks extends Iterable<int> {
  external Iterator<int> get iterator;
  // ${$.debug('add', ($, $$) => $.add)}
  external void add(void callback(int value));
}
        ''',
        );
        final library = DartLibrary(
          'function_arguments',
          path: 'callbacks.dart',
          declarations: [
            declaration,
            DartVariable('callbacks', callbacks, 'external NativeCallbacks get callbacks;'),
          ],
        );
        final source =
            '''
import 'package:function_arguments/callbacks.dart';
void main() {
  dynamic callback = ({int number = 1}) => number;
  ${tearOff ? 'final add = callbacks.add; add(callback);' : 'callbacks.add(callback);'}
}
        ''';
        await expectLater(
          eval(source, libraries: [library]),
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('with named parameters'))),
        );
        expect(callbacks.calls, isEmpty);
      });

      for (final alias in [false, true]) {
        test('custom native methods accept ordinary Function values, tear-off=$tearOff, alias=$alias', () async {
          final declaration = DartClass<_NativeStore>(
            ($) =>
                '''
// ${$.alias(alias ? 'PublicStore' : 'NativeStore')}
class NativeStore {
  // ${$.debug('convert', ($, $$) => $.convert)}
  external Function convert(Function value);
}
${alias ? 'typedef PublicStore = NativeStore;' : ''}
          ''',
          );
          declaration.props.remove('_NativeStore.with');
          final library = DartLibrary(
            'function_arguments',
            path: 'store.dart',
            declarations: [
              declaration,
              DartVariable('store', _NativeStore(), 'external ${alias ? 'PublicStore' : 'NativeStore'} get store;'),
            ],
          );
          final source =
              '''
import 'package:function_arguments/store.dart';
void main() {
  final value = ({int number = 1}) => number;
  ${tearOff ? 'final convert = store.convert; final result = convert(value);' : 'final result = store.convert(value);'}
  print(result == value);
  print(result(number: 1));
}
          ''';
          await expectLater(() => eval(source, libraries: [library]), println([true, 1]));
        });
      }
    }

    test('Map update separates keys, positional callbacks and named callbacks', () async {
      const source = '''
void main() {
  final key = ({int number = 0}) => number;
  final value = ({int number = 1}) => number;
  final values = <dynamic, dynamic>{key: value};
  print(values.update(key, (original) {
    print(original == value);
    return key;
  }) == key);
  values.clear();
  final update = values.update;
  print(update(key, (original) => value, ifAbsent: () => value) == value);
  print(values[key] == value);
  values.clear();
  print(values.putIfAbsent(key, () => value) == value);
}
      ''';
      await expectLater(() => eval(source), println([true, true, true, true, true]));
    });

    test('empty collections still reject unsupported callback signatures', () async {
      const source = '''
void main() {
  dynamic callback = ({int number = 1}) => true;
  final where = <int>[].where;
  where(callback);
}
      ''';
      await expectLater(
        eval(source),
        throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('with named parameters'))),
      );
    });

    for (final isolated in [false, true]) {
      test('method argument roles survive a new VM, compute=$isolated', () async {
        final instance = isolated ? await compute(_createInstance, _instanceSource) : await _createInstance(_instanceSource);
        expect(instance.invoke('store', []), 1);
      });
    }
  });
}

Future<ObjInstance> _createInstance(String source) async => await eval(source) as ObjInstance;

const _instanceSource = '''
class Example {
  List values = <Function>[];
  dynamic add;
  void initialize() { this.add = this.values.add; }
  int store() {
    final value = ({int number = 1}) => number;
    this.add(value);
    return this.values.first(number: 1);
  }
}
main() { final value = Example(); value.initialize(); return value; }
''';

class _NativeStore {
  Function convert(Function value) => value;
}

class _NativeCallbacks extends Iterable<int> {
  final calls = <String>[];

  void add(void Function(int) callback) => calls.add('add');

  @override
  Iterator<int> get iterator => <int>[].iterator;
}
