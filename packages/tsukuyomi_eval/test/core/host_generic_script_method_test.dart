import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Script methods through core collection declarations', () {
    for (final arguments in ['', '<int>']) {
      test('map$arguments retains the script override and callback', () async {
        final source =
            '''
$_scriptIterable
void main() {
  Iterable<int> values = Values();
  print(values.map$arguments((value) => value + 1).toList());
}
        ''';
        await expectLater(() => eval(source), println(['script map', '[1]']));
      });
    }

    for (final method in ['whereType', 'cast']) {
      test('$method retains the script override', () async {
        final source =
            '''
$_scriptIterable
void main() {
  Iterable<int> values = Values();
  print(values.$method<int>().toList());
}
        ''';
        await expectLater(() => eval(source), println(['script $method', '[0]']));
      });
    }

    test('script mapping methods retain their separate receivers', () async {
      final source =
          '''
$_scriptIterable
void main() {
  final first = Values();
  final second = Values();
  second.value = 1;
  Iterable<int> firstValues = first;
  Iterable<int> secondValues = second;
  print(firstValues.map((value) => value + 1).toList());
  print(secondValues.map((value) => value + 1).toList());
}
      ''';
      await expectLater(() => eval(source), println(['script map', '[1]', 'script map', '[2]']));
    });

    test('nullable script receivers retain the normal short circuit', () async {
      final source =
          '''
$_scriptIterable
void main() {
  Iterable<int>? values = Values();
  print(values?.map<int>((value) => value + 1).toList());
  values = null;
  print(values?.map<int>((value) => value + 1).toList());
}
      ''';
      await expectLater(() => eval(source), println(['script map', '[1]', null]));
    });
  });
}

const _scriptIterable = '''
class Values implements Iterable<int> {
  int value = 0;
  Iterable<R> map<R>(dynamic transform) {
    print('script map');
    return <int>[value].map(transform);
  }
  Iterable<R> whereType<R>() {
    print('script whereType');
    return <int>[value] as dynamic;
  }
  Iterable<R> cast<R>() {
    print('script cast');
    return <int>[value] as dynamic;
  }
  dynamic noSuchMethod(dynamic invocation) => null;
}
''';
