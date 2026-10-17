import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host function property writes', () {
    for (final setter in ['first', 'last']) {
      for (final cast in [false, true]) {
        for (final function in ['closure', 'bound method', 'named parameters']) {
          test('$setter preserves $function values, cast=$cast', () async {
            final value = switch (function) {
              'bound method' => 'Example().value',
              'named parameters' => '({int number = 1}) => number',
              _ => '() => 1',
            };
            final invocation = function == 'named parameters' ? '(number: 1)' : '()';
            final source =
                '''
class Example { int value() => 1; }
void main() {
  final value = $value;
  final values = <dynamic>[null]${cast ? '.cast<Function?>()' : ''};
  print((values.$setter = value) == value);
  print(values.$setter == value);
  print(values.whereType<Function>().length);
  print(values.$setter!$invocation);
  values.$setter = null;
  print(values.$setter);
}
            ''';
            await expectLater(() => eval(source), println([true, true, 1, 1, null]));
          });
        }
      }
    }

    test('script fields and setters keep script function values', () async {
      const source = '''
class Example {
  Function field = () => 0;
  Function get value => this.field;
  set value(Function value) { this.field = value; }
}
void main() {
  final value = ({int number = 1}) => number;
  final example = Example();
  print((example.field = value) == value);
  print(example.field == value);
  print((example.value = value) == value);
  print(example.value == value);
  print(example.value(number: 1));
}
      ''';
      await expectLater(() => eval(source), println([true, true, true, true, 1]));
    });
  });
}
