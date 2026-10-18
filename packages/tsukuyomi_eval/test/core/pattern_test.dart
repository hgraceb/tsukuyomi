import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/resolver.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  test('RegExpMatch inherits indexed capture groups from Match', () async {
    const source = r'''
void main() {
  final RegExpMatch match = RegExp(r'cover=(\w+)').firstMatch('cover=chapter')!;
  print(match[0]);
  print(match[1]);
}
''';
    await expectValidSource(source);
    await expectLater(() => eval(source), println(['cover=chapter', 'chapter']));
  });

  test('Match capture groups preserve nullable results', () async {
    const source = r'''
void main() {
  final Match match = RegExp(r'cover=(\w+)?').firstMatch('cover=')!;
  final String? group = match[1];
  print(group);
}
''';
    await expectValidSource(source);
    await expectLater(() => eval(source), println([null]));
  });
}

Future<void> expectValidSource(String source) async {
  final resolved = await resolve(source, dartLibraries);
  final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
  expect(errors.map((error) => error.message), isEmpty);
}
