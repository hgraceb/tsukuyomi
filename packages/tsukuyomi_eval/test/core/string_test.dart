import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  test('String concat', () {
    const source = r'''
void main() {
  print('print: ' + '$print' ' (${print.hashCode})');
}
      ''';
    expect(() => eval(source), println(['print: $print (${print.hashCode})']));
  });

  test('String escapes', () {
    const source = r'''
void main() {
  print('$print\n');
  print(r'$print\n');
}
      ''';
    expect(() => eval(source), println(['$print\n', r'$print\n']));
  });
}
