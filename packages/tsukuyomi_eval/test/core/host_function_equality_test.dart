import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host function equality conversion', () {
    for (final function in ['() => 1', '({int number = 1}) => number', 'Example().number']) {
      for (final matches in [false, true]) {
        test('$function uses the same representation for == and !=, matches=$matches', () async {
          final equality = _Equality(matches);
          final source =
              '''
import 'package:function_equality/equality.dart';
class Example { int number() => 1; }
void main() {
  final function = $function;
  print(value == function);
  print(value != function);
  print((value == function) == !(value != function));
}
          ''';
          await expectLater(() => eval(source, libraries: [_library(equality)]), println([matches, !matches, true]));
          expect(equality.calls, 4);
        });
      }
    }

    test('native function values and non-function values keep complementary equality', () async {
      const source = '''
import 'package:function_equality/equality.dart';
void main() {
  print(value == nativeFunction);
  print(value != nativeFunction);
  print(value == 'other');
  print(value != 'other');
  print(value == null);
  print(value != null);
}
      ''';
      await expectLater(() => eval(source, libraries: [_library(_Equality(true))]), println([true, false, false, true, false, true]));
    });

    test('inequality converts the operand once and invokes native equality once', () async {
      final equality = _Equality(true);
      const source = '''
import 'package:function_equality/equality.dart';
int reads = 0;
Function make() { reads++; return ({int number = 1}) => number; }
void main() {
  print(value != make());
  print(reads);
}
      ''';
      await expectLater(() => eval(source, libraries: [_library(equality)]), println([false, 1]));
      expect(equality.calls, 1);
    });

    for (final overrideEquality in [false, true]) {
      test('independently registered operators keep their getters, equality=$overrideEquality', () async {
        final equality = _Equality(true);
        final operators = <String>[];
        final functions = <bool>[];
        final library = DartLibrary(
          'custom_operators',
          path: 'operators.dart',
          declarations: [
            DartClass.operator(
              ($) => [
                if (overrideEquality) ...[
                  $.binary('==', (left, right) {
                    operators.add('==');
                    functions.add(right is Function);
                    return left == right;
                  }),
                ],
                $.binary('!=', (left, right) {
                  operators.add('!=');
                  functions.add(right is Function);
                  return left != right;
                }),
              ],
            ),
          ],
        );
        const source = '''
import 'package:function_equality/equality.dart';
import 'package:custom_operators/operators.dart';
void main() {
  final function = ({int number = 1}) => number;
  print(value == function);
  print(value != function);
}
        ''';
        await expectLater(() => eval(source, libraries: [_library(equality), library]), println([true, false]));
        expect(operators, [if (overrideEquality) '==', '!=']);
        expect(functions, [if (overrideEquality) true, true]);
        expect(equality.calls, 2);
      });
    }
  });
}

DartLibrary _library(_Equality value) {
  return DartLibrary(
    'function_equality',
    path: 'equality.dart',
    declarations: [
      DartClass<_Equality>(
        ($) =>
            '''
// ${$.alias('Equality')}
class Equality {
  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(Object other);
  external int get hashCode;
}
    ''',
      ),
      DartVariable('value', value, 'external Equality get value;'),
      DartVariable('nativeFunction', () => 1, 'external Function get nativeFunction;'),
    ],
  );
}

class _Equality {
  _Equality(this.matches);

  final bool matches;

  int calls = 0;

  @override
  bool operator ==(Object other) {
    calls++;
    return matches && other is Function;
  }

  @override
  int get hashCode => identityHashCode(this);
}
