import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  for (final reversed in [false, true]) {
    test('Prefixed host functions preserve library identity and ignore local shadowing, reversed=$reversed', () async {
      const source = '''
import 'package:first/functions.dart' as first;
import 'package:second/functions.dart' as second;
import 'package:forward/functions.dart' as forward;

void main() {
  final label = (String value) => 'local:' + value;
  final hostLabel = second.label;
  print(first.label('direct'));
  print(hostLabel('captured'));
  print(forward.label('exported'));
  print(label('local'));
}
''';
      final libraries = [
        _library('first'),
        _library('second'),
        DartLibrary('forward', path: 'functions.dart', source: "export 'package:first/functions.dart';", declarations: []),
      ];
      await expectLater(
        () => eval(source, libraries: reversed ? libraries.reversed.toList() : libraries),
        println(['first:direct', 'second:captured', 'first:exported', 'local:local']),
      );
    });
  }
}

DartFunction _label(String name) => DartFunction('label', (String value) => '$name:$value', '''
external String label(String value);
''');

DartLibrary _library(String name) {
  return DartLibrary(name, path: 'functions.dart', declarations: [_label(name)]);
}
