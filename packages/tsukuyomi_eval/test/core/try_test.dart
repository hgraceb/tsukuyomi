import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Try-catch with async errors and native callbacks', () {
    test('handle a native callback error and continue execution', () async {
      const source = '''
void main() {
  print(1);
  try {
    [2].forEach((value) {
      throw value;
    });
  } on int catch (e) {
    print(e);
  }
  print(3);
  [4].forEach((value) => print(value));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('handle a nested native callback error', () async {
      const source = '''
void main() {
  print(1);
  try {
    [2].forEach((value) {
      [value].forEach((value) {
        throw value;
      });
    });
  } catch (e) {
    print(e);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('handle a native callback error after await', () async {
      const source = '''
Future<void> main() async {
  print(1);
  await null;
  try {
    [2].forEach((value) {
      throw value;
    });
  } catch (e) {
    print(e);
  }
  print(3);
  await null;
  print(4);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('handle an interpreted async error before the first await', () async {
      const source = '''
Future<void> foo() async {
  throw 2;
}

Future<void> main() async {
  print(1);
  try {
    await foo();
  } catch (e) {
    print(e);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('handle an interpreted async error after await', () async {
      const source = '''
Future<void> foo() async {
  await null;
  throw 2;
}

Future<void> main() async {
  print(1);
  try {
    await foo();
  } catch (e) {
    print(e);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('handle rethrow after nested await in an outer catch', () async {
      const source = '''
Future<void> main() async {
  print(1);
  try {
    try {
      await null;
      await Future.error(2);
    } catch (e) {
      print(e);
      await null;
      rethrow;
    }
  } on int catch (e) {
    print(e + 1);
  }
  await null;
  print(4);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('preserve captured locals when an async function fails', () async {
      const source = '''
var callback = () => 0;

Future<void> foo() async {
  final value = 2;
  callback = () => value;
  await null;
  throw value;
}

Future<void> main() async {
  print(1);
  try {
    await foo();
  } catch (e) {
    print(e);
  }
  print(callback() + 1);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('rethrow after await preserves the original stack trace', () async {
      const source = '''
Future<void> main() async {
  try {
    await Future.error('error', StackTrace.fromString('original stack trace'));
  } catch (e) {
    print(1);
    await null;
    rethrow;
  }
}
      ''';
      await expectLater(() async {
        final future = eval(source) as Future;
        await expectLater(future, throwsA('error'));
        await future.then<void>((_) => fail('Expected an error'), onError: (Object error, StackTrace stackTrace) {
          expect(stackTrace.toString(), 'original stack trace');
        });
      }, println([1]));
    });
  });

  test('Try-catch handle error thrown directly', () {
    const source = '''
void main() {
  print(1);
  try {
    print(2);
    throw 3;
    print(0);
  } catch (e, s) {
    print(e);
  }
  int e = 4;
  print(e);
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4]));
  });

  test('Try-catch handle error thrown in function', () {
    const source = '''
void main() {
  print(1);
  try {
    print(2);
    (() {
      throw 3;
      print(0);
    })();
    print(0);
  } catch (e) {
    print(e);
  }
  int e = 4;
  print(e);
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4]));
  });

  test('Try-catch handle error thrown in native async function', () {
    const source = '''
void main() async {
  print(1);
  try {
    print(2);
    await Future.error(3);
    print(0);
  } catch (e) {
    print(e);
  }
  int e = 4;
  print(e);
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4]));
  });

  test('Try-catch handle error on specified type', () {
    const source = '''
void main() {
  print(1);
  try {
    print(2);
    throw 3;
    print(0);
  } on Never {
    print(0);
  } on int catch (e) {
    print(e);
  } catch (e) {
    print(0);
  }
  int e = 4;
  print(e);
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4]));
  });

  test('Try-catch handle error thrown by rethrow', () {
    const source = '''
void main() {
  try {
    try {
      try {
        throw 1;
      } catch (e) {
        print(e);
        rethrow;
      }
    } on int catch (e) {
      print(e + 1);
      rethrow;
    }
  } on int catch (e) {
    print(e + 2);
  }
  int e = 4;
  print(e);
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4]));
  });

  test('Try with finally', () {
    const source = '''
void main() {
  print(1);
  try {
    print(2);
  } finally {
    print(3);
  }
  print(4);
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4]));
  });

  test('Try with catch and finally', () {
    const source = '''
void main() {
  print(1);
  try {
    print(2);
    throw 3;
    print(0);
  } catch (e) {
    print(e);
  } finally {
    int e = 4;
    print(e);
  }
  int e = 5;
  print(e);
}
      ''';
    expect(() => eval(source), println([1, 2, 3, 4, 5]));
  });
}
