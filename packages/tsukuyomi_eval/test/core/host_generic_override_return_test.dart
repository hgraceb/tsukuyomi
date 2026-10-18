import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host generic overridden callback returns', () {
    for (final nullable in [false, true]) {
      for (final explicit in [false, true]) {
        for (final empty in [false, true]) {
          test('nullable=$nullable, explicit=$explicit, empty=$empty', () async {
            final type = nullable ? 'String?' : 'String';
            final typeArguments = explicit ? '<$type>' : '';
            final input = empty ? '<int>[]' : '<int>[0, 1]';
            final result = nullable ? '[null, chapter]' : '[chapter, chapter]';
            final expected = empty ? '[]' : result;
            final body = nullable ? "number == 0 ? null : 'chapter'" : "'chapter'";
            final source =
                '''
import 'package:override_checks/checks.dart';
class Parent { $type convert(int number) => 'parent'; }
class Converter extends Parent { @override convert(int number) => $body; }
void main() {
  final values = $input.map$typeArguments(Converter().convert).toList();
  print(values);
  print(isStrings(values));
  print(isNullableStrings(values));
}
            ''';
            await expectLater(() => eval(source, libraries: [_checks()]), println([expected, !nullable, true]));
          });
        }
      }
    }

    test('block-bodied overrides keep their receiver and lazy invocation', () async {
      const source = '''
class Parent { String convert(int number) => 'parent'; }
class Converter extends Parent {
  String title = 'chapter';
  int calls = 0;
  @override convert(int number) { this.calls++; return this.title; }
}
void main() {
  final converter = Converter();
  final convert = converter.convert;
  final values = <int>[0].map<String>(convert);
  print(converter.calls);
  converter.title = 'updated';
  print(values.first);
  print(converter.calls);
}
      ''';
      await expectLater(() => eval(source), println([0, 'updated', 1]));
    });

    test('omitted returns without an inherited type remain dynamic', () async {
      const source = '''
import 'package:override_checks/checks.dart';
class Converter { convert(int number) => 'chapter'; }
void main() {
  final values = <int>[0].map(Converter().convert).toList();
  print(values);
  print(isStrings(values));
}
      ''';
      await expectLater(() => eval(source, libraries: [_checks()]), println(['[chapter]', false]));
    });

    test('inherited Function returns still adapt script closure results', () async {
      const source = '''
import 'package:override_checks/checks.dart';
class Parent { Function convert(int number) => () => number; }
class Converter extends Parent { @override convert(int number) => () => number; }
void main() {
  final values = <int>[0].map(Converter().convert).toList();
  print(isFunctions(values));
  print(values.first());
}
      ''';
      await expectLater(() => eval(source, libraries: [_checks()]), println([true, 0]));
    });

    test('inherited Never returns retain empty results and callback exceptions', () async {
      const source = '''
import 'package:override_checks/checks.dart';
class Parent { Never convert(int number) => throw 'parent'; }
class Converter extends Parent { @override convert(int number) => throw 'child'; }
void main() {
  print(isNeverValues(<int>[].map(Converter().convert).toList()));
  try { <int>[0].map(Converter().convert).first; } catch (error) { print(error); }
}
      ''';
      await expectLater(() => eval(source, libraries: [_checks()]), println([true, 'child']));
    });

    test('inherited alias returns retain their registered bridge entry', () async {
      final value = _HostValue();
      final declaration = DartClass<_HostValue>(
        ($) =>
            '''
class InternalValue {}
// ${$.alias('PublicValue')}
typedef PublicValue = InternalValue;
      ''',
      );
      declaration.props.remove('_HostValue.with');
      final library = DartLibrary(
        'override_values',
        path: 'values.dart',
        declarations: [
          declaration,
          DartVariable('hostValue', value, 'external PublicValue get hostValue;'),
          DartFunction('isValues', (Object? values) => values is List<_HostValue>, 'external bool isValues(Object? values);'),
        ],
      );
      const source = '''
import 'package:override_values/values.dart';
class Parent { PublicValue convert(int number) => hostValue; }
class Converter extends Parent { @override convert(int number) => hostValue; }
void main() {
  final values = <int>[0].map(Converter().convert).toList();
  print(isValues(values));
  print(values.first == hostValue);
}
      ''';
      await expectLater(() => eval(source, libraries: [library]), println([true, true]));
    });

    for (final stored in [false, true]) {
      for (final explicit in [false, true]) {
        test('inherited script returns keep the dynamic delegate, stored=$stored, explicit=$explicit', () async {
          final callback = stored ? '<dynamic>[converter.convert].first' : 'converter.convert';
          final typeArguments = explicit ? '<dynamic>' : '';
          final source =
              '''
class Value {}
class Parent { Value convert(int number) => Value(); }
class Converter extends Parent { @override convert(int number) => Value(); }
void main() {
  final converter = Converter();
  final values = <int>[0].map$typeArguments($callback).toList();
  print(values.length);
  print(values.first is Value);
}
          ''';
          await expectLater(() => eval(source), println([1, true]));
        });
      }
    }

    for (final explicit in [false, true]) {
      test('unregistered inherited host returns keep the dynamic delegate, explicit=$explicit', () async {
        final library = DartLibrary(
          'unregistered_returns',
          path: 'values.dart',
          declarations: [
            DartVariable('hostValue', _HostValue(), 'class Unregistered {} external Unregistered get hostValue;'),
          ],
        );
        final typeArguments = explicit ? '<dynamic>' : '';
        final source =
            '''
import 'package:unregistered_returns/values.dart';
class Parent { Unregistered convert(int number) => hostValue; }
class Converter extends Parent { @override convert(int number) => hostValue; }
void main() {
  final values = <int>[0].map$typeArguments(Converter().convert).toList();
  print(values.length);
  print(values.first == hostValue);
}
        ''';
        await expectLater(() => eval(source, libraries: [library]), println([1, true]));
      });
    }

    test('explicit unregistered returns still require their bridge entry', () async {
      const source = '''
class Value {}
class Parent { Value convert(int number) => Value(); }
class Converter extends Parent { @override Value convert(int number) => Value(); }
void main() { <int>[0].map<dynamic>(Converter().convert).toList(); }
      ''';
      await expectLater(
        eval(source),
        throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('Value.with'))),
      );
    });
  });
}

DartLibrary _checks() => DartLibrary(
  'override_checks',
  path: 'checks.dart',
  declarations: [
    DartFunction('isStrings', (Object? value) => value is List<String>, 'external bool isStrings(Object? value);'),
    DartFunction('isNullableStrings', (Object? value) => value is List<String?>, 'external bool isNullableStrings(Object? value);'),
    DartFunction('isFunctions', (Object? value) => value is List<Function>, 'external bool isFunctions(Object? value);'),
    DartFunction('isNeverValues', (Object? value) => value is List<Never>, 'external bool isNeverValues(Object? value);'),
  ],
);

class _HostValue {}
