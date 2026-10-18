import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host generic callback return types', () {
    test('anonymous mapping callbacks return functions with the native collection type', () async {
      const source = '''
import 'package:callback_checks/checks.dart';
void main() {
  final callbacks = <int>[0].map<Function>((value) => () => value).toList();
  print(isFunctions(callbacks));
  print(callbacks.first());
}
      ''';
      await expectLater(() => eval(source, libraries: [_checks()]), println([true, 0]));
    });

    test('nullable anonymous function results retain null and the native collection type', () async {
      const source = '''
import 'package:callback_checks/checks.dart';
void main() {
  final callbacks = <int>[0, 1].map<Function?>((value) => value == 0 ? null : () => value).toList();
  print(isNullableFunctions(callbacks));
  print(callbacks[0]);
  print(callbacks[1]!());
}
      ''';
      await expectLater(() => eval(source, libraries: [_checks()]), println([true, null, 1]));
    });

    test('returned bound methods retain their receiver and state', () async {
      const source = '''
class Example { int value = 0; int next() => ++value; }
void main() {
  final example = Example();
  final callback = <int>[0].map<Function>((value) => example.next).first;
  print(callback());
  print(callback());
}
      ''';
      await expectLater(() => eval(source), println([1, 2]));
    });

    test('empty inferred Never mappings do not invoke their callback', () async {
      const source = '''
void main() { print(<int>[].map((value) => throw 'error').length); }
      ''';
      await expectLater(() => eval(source), println([0]));
    });

    test('empty explicit Never mappings retain their native result type', () async {
      const source = '''
import 'package:callback_checks/checks.dart';
void main() { print(isNeverValues(<int>[].map<Never>((value) => throw 'error').toList())); }
      ''';
      await expectLater(() => eval(source, libraries: [_checks()]), println([true]));
    });

    test('Never callbacks throw on iteration and preserve exception recovery', () async {
      const source = '''
void main() {
  final values = <int>[0].map((value) => throw 'error');
  print('created');
  try { values.first; } catch (error) { print(error); } finally { print('finally'); }
  print(<int>[0].map((value) => value + 1).first);
}
      ''';
      await expectLater(() => eval(source), println(['created', 'error', 'finally', 1]));
    });

    test('Never callback failures preserve a surrounding asynchronous continuation', () async {
      const source = '''
Future<void> main() async {
  await Future.value();
  try { <int>[0].map((value) => throw 'error').first; } catch (error) { print(error); }
  await Future.value();
  print('resumed');
}
      ''';
      await expectLater(() => eval(source), println(['error', 'resumed']));
    });

    test('native callbacks retain their return type check even for an empty source', () async {
      const source = '''
import 'package:callback_checks/checks.dart';
void main() {
  try { <int>[].map<int>(wrongNativeCallback); } on TypeError { print('native type error'); }
}
      ''';
      await expectLater(() => eval(source, libraries: [_checks()]), println(['native type error']));
    });

    test('script callbacks with incompatible declared returns retain the native check', () async {
      const source = '''
num convert(int value) => value;
void main() {
  dynamic callback = convert;
  try { <int>[].map<int>(callback); } on TypeError { print('script type error'); }
}
      ''';
      await expectLater(() => eval(source), println(['script type error']));
    });
  });
}

DartLibrary _checks() => DartLibrary(
  'callback_checks',
  path: 'checks.dart',
  declarations: [
    DartFunction('isFunctions', (dynamic value) => value is List<Function>, 'external bool isFunctions(dynamic value);'),
    DartFunction('isNullableFunctions', (dynamic value) => value is List<Function?>, 'external bool isNullableFunctions(dynamic value);'),
    DartFunction('isNeverValues', (dynamic value) => value is List<Never>, 'external bool isNeverValues(dynamic value);'),
    DartVariable('wrongNativeCallback', (int value) => 'chapter', 'external dynamic get wrongNativeCallback;'),
  ],
);
