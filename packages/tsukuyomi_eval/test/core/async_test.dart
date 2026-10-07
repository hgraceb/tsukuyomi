import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Async function errors', () {
    test('before the first await complete the returned future', () async {
      const source = '''
Future<void> foo() async {
  print(2);
  throw 'error';
}

Future<void> main() async {
  print(1);
  final future = foo();
  print(3);
  await future;
}
      ''';
      await expectLater(() => expectLater(eval(source), throwsA('error')), println([1, 2, 3]));
    });

    test('after await complete the returned future', () async {
      const source = '''
Future<void> main() async {
  print(1);
  await Future.value(null);
  print(2);
  throw 'error';
}
      ''';
      await expectLater(() => expectLater(eval(source), throwsA('error')), println([1, 2]));
    });

    test('from an awaited future preserve the error and stack trace', () async {
      const source = '''
Future<void> main() async {
  await Future.error('error', StackTrace.fromString('original stack trace'));
}
      ''';
      final future = eval(source) as Future;
      await expectLater(future, throwsA('error'));
      await future.then<void>((_) => fail('Expected an error'), onError: (Object error, StackTrace stackTrace) {
        expect(error, 'error');
        expect(stackTrace.toString(), 'original stack trace');
      });
    });

    test('thrown in catch complete the returned future', () async {
      const source = '''
Future<void> main() async {
  try {
    await Future.error('first error');
  } catch (e) {
    print(1);
    throw 'second error';
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), throwsA('second error')), println([1]));
    });

    test('thrown after await in catch complete the returned future', () async {
      const source = '''
Future<void> main() async {
  try {
    await Future.error('first error');
  } catch (e) {
    print(1);
    await null;
    print(2);
    throw 'second error';
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), throwsA('second error')), println([1, 2]));
    });

    test('from an async native callback complete the returned future', () async {
      const source = '''
Future<void> main() async {
  print(1);
  await Future.delayed(const Duration(), () async {
    print(2);
    await null;
    print(3);
    throw 'error';
  });
}
      ''';
      await expectLater(() => expectLater(eval(source), throwsA('error')), println([1, 2, 3]));
    });

    test('from instance methods remain isolated after compute', () async {
      const source = '''
class Source {
  Future<String> load() async {
    try {
      await Future.delayed(const Duration(), () async {
        await null;
        ['error'].forEach((value) {
          throw value;
        });
      });
    } catch (e) {
      return e;
    }
    return 'unreachable';
  }
}

Source main() => Source();
      ''';
      final instances = await Future.wait([
        compute<String, ObjInstance>((source) async => await eval(source) as ObjInstance, source),
        compute<String, ObjInstance>((source) async => await eval(source) as ObjInstance, source),
      ]);
      final futures = instances.map((instance) => instance.invoke('load', null) as Future);
      await expectLater(Future.wait(futures), completion(['error', 'error']));
    });
  });

  group('Async function return without a value', () {
    test('without await anything', () async {
      const source = '''
Future<void> main() async {
  const value = 1;
  print(value);
  return;
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1]));
    });

    test('with await anything in nested scope', () async {
      const source = '''
Future<void> main() async {
  const value = 1;
  print(value);
  await null;
  {
    final nestedValue = value + 1;
    print(nestedValue);
    return;
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });
  });

  test('Async function without await anything', () {
    const source = '''
Future<void> foo() async {
  print(2);
}

Future<int> bar() async {
  print(4);
  return 0;
}

Future<int> main() async {
  print(1);
  foo();
  print(3);
  return bar();
}
    ''';
    expectLater(() => expectLater(eval(source), completion(0)), println([1, 2, 3, 4]));
  });

  test('Async function with await anything', () {
    const source = '''
Future<void> foo() async {
  print(2);
  await Future.delayed(const Duration());
  print(10);
}

Future<void> bar() async {
  print(4);
  await Object();
  print(8);
}

Future<void> baz() async {
  print(6);
  await null;
  print(9);
}

Future<int> main() async {
  print(1);
  foo();
  print(3);
  bar();
  print(5);
  baz();
  print(7);
  return Future.delayed(const Duration(), () => 0);
}
    ''';
    expectLater(() => expectLater(eval(source), completion(0)), println([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
  });

  test('Async function as an argument', () {
    const source = '''
Future<List<Future<int>>> main() async {
  const length = 2;
  return List.generate(length, (index) async {
    print(index + 1);
    await null;
    print(index + length + 1);
    return index + 1;
  });
}
    ''';
    expectLater(() => expectLater(eval(source), completion([completion(1), completion(2)])), println([1, 2, 3, 4]));
  });
}
