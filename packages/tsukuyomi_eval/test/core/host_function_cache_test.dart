import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Live host function associations', () {
    for (final isolated in [false, true]) {
      for (final function in ['closure', 'bound method', 'named parameters']) {
        test('$function retains identity and argument roles, compute=$isolated', () async {
          final value = switch (function) {
            'bound method' => 'this.number',
            'named parameters' => '({int number = 1}) => number',
            _ => '() => 1',
          };
          final invocation = function == 'named parameters' ? '(number: 1)' : '()';
          final source =
              '''
class Example {
  dynamic original;
  List values = <Function>[];
  Map entries = <dynamic, dynamic>{};
  dynamic add;
  dynamic select;
  int number() => 1;
  void initialize() {
    this.original = $value;
    this.values.add(this.original);
    this.entries[this.original] = this.original;
    this.add = this.values.add;
    this.select = this.values.whereType;
  }
  void verify() {
    print(this.values.first == this.original);
    print(this.entries[this.original] == this.original);
    print(this.values.first$invocation);
    print(this.select().first == this.original);
    final value = ({int number = 1}) => number;
    this.add(value);
    print(this.values.last == value);
    print(this.values.last(number: 1));
    this.values.remove(value);
  }
}
main() { final value = Example(); value.initialize(); return value; }
          ''';
          final instance = isolated ? await compute(_createInstance, source) : await _createInstance(source);
          for (final call in [0, 1]) {
            await expectLater(() => instance.invoke('verify', []), println([true, true, 1, true, true, 1]), reason: 'call $call');
          }
        });
      }
    }
  });
}

Future<ObjInstance> _createInstance(String source) async => await eval(source) as ObjInstance;
