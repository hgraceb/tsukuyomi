import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  for (final prefix in ['', 'host.']) {
    test('Host enums expose constants static methods and values with prefix "$prefix"', () async {
      final directive = prefix.isEmpty ? '' : ' as host';
      final source = '''
import 'package:enum_types/types.dart'$directive;
import 'package:enum_types/types.dart' show HostStatus;

void main() {
  final status = ${prefix}HostStatus.parse('paused');
  print(status == ${prefix}HostStatus.paused);
  print(status is HostStatus);
  print((status as HostStatus).label);
  print(${prefix}HostStatus.values.map((value) => value.label).toList());
}
''';
      await expectLater(() => eval(source, libraries: [_library()]), println([true, true, 'paused', '[ready, paused]']));
    });
  }

  test('Host enum methods receive typed script callbacks', () async {
    const source = '''
import 'package:enum_types/types.dart';

void main() {
  final result = HostStatus.ready.apply((value) => value == HostStatus.ready ? HostStatus.paused : value);
  print(result == HostStatus.paused);
}
''';
    await expectLater(() => eval(source, libraries: [_library()]), println([true]));
  });

  test('Unsupported switch expressions fail instead of returning the last enum branch', () async {
    const source = '''
import 'package:enum_types/types.dart';

String label(HostStatus value) => switch (value) {
  HostStatus.ready => 'ready',
  HostStatus.paused => 'paused',
};

void main() {
  print(label(HostStatus.ready));
  print(label(HostStatus.paused));
}
''';
    await expectLater(
      eval(source, libraries: [_library()]),
      throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('Unsupported switch expression'))),
    );
  });

  test('Unsupported switch statements fail instead of executing every enum branch', () async {
    const source = '''
import 'package:enum_types/types.dart';

void main() {
  switch (HostStatus.ready) {
    case HostStatus.ready: print('ready'); break;
    case HostStatus.paused: print('paused'); break;
  }
}
''';
    await expectLater(
      eval(source, libraries: [_library()]),
      throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('Unsupported switch statement'))),
    );
  });
}

enum HostStatus {
  ready,
  paused;

  String get label => name;

  static HostStatus parse(String value) => values.byName(value);

  HostStatus apply(HostStatus Function(HostStatus) callback) => callback(this);
}

DartClass get _$HostStatus => DartClass<HostStatus>(($) => '''
// ${$.empty('HostStatus.values', () => HostStatus.values)}
enum HostStatus {
  // ${$.empty('HostStatus.ready', () => HostStatus.ready)}
  ready,
  // ${$.empty('HostStatus.paused', () => HostStatus.paused)}
  paused;

  // ${$.debug('label', ($, $$) => $.label)}
  external String get label;

  // ${$.empty('HostStatus.parse', () => HostStatus.parse)}
  external static HostStatus parse(String value);

  // ${$.debug('apply', ($, $$) => $.apply)}
  external HostStatus apply(HostStatus Function(HostStatus) callback);
}
''');

DartLibrary _library() {
  return DartLibrary('enum_types', path: 'types.dart', declarations: [
    _$HostStatus,
    DartClass<dynamic>.dynamic({
      'label': (($) => $.label, ($, $$) => $.label = $$),
      'apply': (($) => $.apply, ($, $$) => $.apply = $$),
    }),
  ]);
}
