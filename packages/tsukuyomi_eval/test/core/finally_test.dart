import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Finally on every exit', () {
    test('return evaluates its value before finally', () async {
      const source = '''
int run() {
  int value = 1;
  try {
    return value++;
  } finally {
    print(value);
    value++;
    print(value);
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 1]));
    });

    test('an empty return still executes finally', () async {
      const source = '''
void run() {
  try {
    return;
  } finally {
    print(1);
  }
}
void main() {
  run();
  print(2);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('nested finally blocks run from inner to outer on return', () async {
      const source = '''
int run() {
  try {
    try {
      return 3;
    } finally {
      print(1);
    }
  } finally {
    print(2);
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a finally return replaces the pending return', () async {
      const source = '''
int run() {
  try {
    try {
      return 0;
    } finally {
      print(1);
      return 3;
    }
  } finally {
    print(2);
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a finally return replaces a pending exception', () async {
      const source = '''
int run() {
  try {
    throw 'original';
  } finally {
    print(1);
    return 2;
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('a finally exception replaces a pending return', () async {
      const source = '''
int run() {
  try {
    return 0;
  } finally {
    print(1);
    throw 2;
  }
}
void main() {
  try {
    run();
  } catch (error) {
    print(error);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('an unmatched exception executes finally before an outer catch', () async {
      const source = '''
void main() {
  try {
    try {
      throw 2;
    } on String {
      print('wrong catch');
    } finally {
      print(1);
    }
  } catch (error) {
    print(error);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('exceptions from catch execute finally and bypass the same catch', () async {
      const source = '''
void main() {
  try {
    try {
      throw 1;
    } catch (error) {
      print(error);
      throw 3;
    } finally {
      print(2);
    }
  } catch (error) {
    print(error);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a finally exception replaces the original exception', () async {
      const source = '''
void main() {
  try {
    try {
      throw 'original';
    } finally {
      print(1);
      throw 2;
    }
  } catch (error) {
    print(error);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('nested finally blocks precede the outer catch', () async {
      const source = '''
void main() {
  try {
    try {
      try {
        throw 3;
      } finally {
        print(1);
      }
    } finally {
      print(2);
    }
  } catch (error) {
    print(error);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('return from catch executes its finally', () async {
      const source = '''
int run() {
  try {
    throw 1;
  } catch (error) {
    print(error);
    return 3;
  } finally {
    print(2);
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('break executes finally before leaving the loop', () async {
      const source = '''
void main() {
  for (int index = 0; index < 2; index++) {
    try {
      print(1);
      break;
    } finally {
      print(2);
    }
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('continue executes finally before the updater', () async {
      const source = '''
void main() {
  for (int index = 0; index < 2; index++) {
    try {
      print(index);
      continue;
    } finally {
      print(index + 1);
    }
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([0, 1, 1, 2, 3]));
    });

    test('nested finally blocks run on break and continue', () async {
      const source = '''
void main() {
  for (int index = 0; index < 2; index++) {
    try {
      try {
        if (index == 0) continue;
        break;
      } finally {
        print(1);
      }
    } finally {
      print(2);
    }
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 1, 2, 3]));
    });

    test('loops inside try do not execute finally on their internal jumps', () async {
      const source = '''
void main() {
  try {
    for (int index = 0; index < 3; index++) {
      if (index == 0) continue;
      print(1);
      break;
    }
    print(2);
  } finally {
    print(3);
  }
  print(4);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('do while continue uses its condition after finally', () async {
      const source = '''
void main() {
  int count = 0;
  do {
    try {
      count++;
      continue;
    } finally {
      print(count);
    }
  } while (count < 2);
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a finally break replaces the pending continue', () async {
      const source = '''
void main() {
  for (int index = 0; index < 2; index++) {
    try {
      continue;
    } finally {
      print(1);
      break;
    }
  }
  print(2);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('a finally continue replaces the pending break', () async {
      const source = '''
void main() {
  for (int index = 0; index < 2; index++) {
    try {
      break;
    } finally {
      print(index + 1);
      continue;
    }
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a finally break replaces the pending return', () async {
      const source = '''
int run() {
  while (true) {
    try {
      return 0;
    } finally {
      print(1);
      break;
    }
  }
  return 2;
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('an internal finally loop preserves the pending return', () async {
      const source = '''
int run() {
  try {
    return 3;
  } finally {
    for (int index = 0; index < 3; index++) {
      if (index == 0) continue;
      print(1);
      break;
    }
    print(2);
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a caught error inside finally preserves the pending return', () async {
      const source = '''
int run() {
  try {
    return 3;
  } finally {
    try {
      throw 1;
    } catch (error) {
      print(error);
    }
    print(2);
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a normal nested try inside finally preserves the pending return', () async {
      const source = '''
int run() {
  try {
    return 4;
  } finally {
    try {
      print(1);
    } finally {
      print(2);
    }
    print(3);
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('finally can call another function before completing the return', () async {
      const source = '''
int helper() {
  print(1);
  return 2;
}
int run() {
  try {
    return 3;
  } finally {
    print(helper());
  }
}
void main() {
  print(run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('finally completes each iteration without stale handlers', () async {
      const source = '''
void main() {
  int sequence = 0;
  for (int index = 0; index < 2; index++) {
    try {
      if (index == 0) throw ++sequence;
      print(++sequence);
    } catch (error) {
      print(error);
    } finally {
      print(++sequence);
    }
  }
  print(++sequence);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4, 5]));
    });

    test('a completed try cannot catch a later exception', () async {
      const source = '''
void main() {
  try {
    try {
      print(1);
    } catch (error) {
      print('stale catch');
    } finally {
      print(2);
    }
    throw 3;
  } catch (error) {
    print(error);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('finally preserves outer locals until loop exit cleanup', () async {
      const source = '''
void main() {
  var callback = () => 0;
  while (true) {
    int value = 1;
    callback = () => value;
    try {
      break;
    } finally {
      value++;
      print(value);
    }
  }
  print(callback());
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 2, 3]));
    });

    test('finally closes captured try locals before reusing their slots', () async {
      const source = '''
void main() {
  var callback = () => 0;
  for (int index = 0; index < 2; index++) {
    try {
      final value = index + 1;
      if (index == 0) callback = () => value;
      continue;
    } finally {
      final value = index + 2;
      print(value);
    }
  }
  print(callback());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 1]));
    });

    test('finally can update the object returned by a captured closure', () async {
      const source = '''
Function run() {
  int value = 1;
  try {
    return () => value;
  } finally {
    value++;
    print(value);
  }
}
void main() {
  print(run()());
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 2, 3]));
    });

    test('native callback exceptions execute both callback and caller finally', () async {
      const source = '''
void main() {
  try {
    try {
      [3].forEach((value) {
        try {
          throw value;
        } finally {
          print(1);
        }
      });
    } finally {
      print(2);
    }
  } catch (error) {
    print(error);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('native callback returns execute finally without unwinding the caller', () async {
      const source = '''
void main() {
  try {
    [1].forEach((value) {
      try {
        print(value);
        return;
      } finally {
        print(2);
      }
    });
    print(3);
  } finally {
    print(4);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('finally awaits before resuming the pending return', () async {
      const source = '''
Future<int> run() async {
  try {
    await null;
    return 3;
  } finally {
    print(1);
    await null;
    print(2);
  }
}
Future<void> main() async {
  print(await run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('nested async finally blocks keep their separate pending exits', () async {
      const source = '''
Future<int> run() async {
  try {
    try {
      await null;
      return 3;
    } finally {
      await null;
      print(1);
    }
  } finally {
    await null;
    print(2);
  }
}
Future<void> main() async {
  print(await run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('async finally executes before propagating an awaited error', () async {
      const source = '''
Future<void> run() async {
  try {
    await Future.error(3);
  } finally {
    print(1);
    await null;
    print(2);
  }
}
Future<void> main() async {
  try {
    await run();
  } catch (error) {
    print(error);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('an awaited finally error replaces the pending return', () async {
      const source = '''
Future<int> run() async {
  try {
    return 0;
  } finally {
    print(1);
    await Future.error(2);
  }
}
Future<void> main() async {
  try {
    await run();
  } catch (error) {
    print(error);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('an async finally return replaces the pending exception', () async {
      const source = '''
Future<int> run() async {
  try {
    await Future.error('original');
  } finally {
    print(1);
    await null;
    return 2;
  }
}
Future<void> main() async {
  print(await run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('async continue awaits finally before the next iteration', () async {
      const source = '''
Future<void> main() async {
  for (int index = 0; index < 2; index++) {
    try {
      continue;
    } finally {
      await null;
      print(index + 1);
    }
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('rethrow finds the lexical catch through a nested finally', () async {
      const source = '''
void main() {
  try {
    try {
      throw 2;
    } catch (error) {
      try {
        print(1);
      } finally {
        rethrow;
      }
    }
  } catch (error) {
    print(error);
  }
  print(3);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('rethrow after a completed nested catch uses the original error', () async {
      const source = '''
void main() {
  try {
    try {
      throw 4;
    } catch (error) {
      print(1);
      try {
        throw 2;
      } catch (nested) {
        print(nested);
      } finally {
        print(3);
      }
      rethrow;
    }
  } catch (error) {
    print(error);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 4]));
    });

    test('concurrent async calls keep separate pending return values', () async {
      const source = '''
List<int> completions = [0, 0];
Future<int> run(int value) async {
  try {
    await null;
    return value;
  } finally {
    await null;
    completions[value - 1]++;
  }
}
Future<void> main() async {
  final first = run(1);
  final second = run(2);
  print(await first);
  print(await second);
  print(completions);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          1,
          2,
          [1, 1],
        ]),
      );
    });

    test('an async helper in finally preserves the caller pending return', () async {
      const source = '''
Future<int> helper() async {
  await null;
  print(1);
  return 2;
}
Future<int> run() async {
  try {
    return 3;
  } finally {
    print(await helper());
  }
}
Future<void> main() async {
  print(await run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a future return value survives an awaited finally', () async {
      const source = '''
Future<int> run() async {
  try {
    return Future.value(3);
  } finally {
    print(1);
    await null;
    print(2);
  }
}
Future<void> main() async {
  print(await run());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('a return completes its future once after finally', () async {
      const source = '''
Future<int> run() async {
  try {
    return 2;
  } finally {
    await null;
    print(1);
  }
}
Future<void> main() async {
  int completions = 0;
  final future = run().then((value) {
    completions++;
    return value;
  });
  print(await future);
  print(completions);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 1]));
    });
  });

  group('Finally preserves errors and stack traces', () {
    test('an uncaught synchronous error executes finally', () async {
      const source = '''
void main() {
  try {
    throw 'error';
  } finally {
    print(1);
    print(2);
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), throwsA('error')), println([1, 2]));
    });

    test('an uncaught awaited error keeps its stack through finally', () async {
      const source = '''
Future<void> main() async {
  try {
    await Future.error('error', StackTrace.fromString('original stack trace'));
  } finally {
    print(1);
    await null;
    print(2);
  }
}
      ''';
      await expectLater(() async {
        final future = eval(source) as Future;
        await expectLater(future, throwsA('error'));
        await future.then<void>(
          (_) => fail('Expected an error'),
          onError: (Object error, StackTrace stackTrace) {
            expect(stackTrace.toString(), 'original stack trace');
          },
        );
      }, println([1, 2]));
    });

    test('rethrow keeps its original stack through awaited finally', () async {
      const source = '''
Future<void> main() async {
  try {
    await Future.error('error', StackTrace.fromString('original stack trace'));
  } catch (error) {
    print(1);
    await null;
    rethrow;
  } finally {
    print(2);
    await null;
    print(3);
  }
}
      ''';
      await expectLater(() async {
        final future = eval(source) as Future;
        await expectLater(future, throwsA('error'));
        await future.then<void>(
          (_) => fail('Expected an error'),
          onError: (Object error, StackTrace stackTrace) {
            expect(stackTrace.toString(), 'original stack trace');
          },
        );
      }, println([1, 2, 3]));
    });

    test('an awaited finally error uses the replacement stack trace', () async {
      const source = '''
Future<void> main() async {
  try {
    await Future.error('original', StackTrace.fromString('original stack trace'));
  } finally {
    print(1);
    await Future.error('replacement', StackTrace.fromString('replacement stack trace'));
  }
}
      ''';
      await expectLater(() async {
        final future = eval(source) as Future;
        await expectLater(future, throwsA('replacement'));
        await future.then<void>(
          (_) => fail('Expected an error'),
          onError: (Object error, StackTrace stackTrace) {
            expect(stackTrace.toString(), 'replacement stack trace');
          },
        );
      }, println([1]));
    });

    test('an uncaught host invocation closes captured locals after finally', () async {
      const source = '''
class Example {
  Function read = () => 0;
  int fail() {
    int value = 1;
    read = () => value;
    try {
      throw 'error';
    } finally {
      value++;
      print(value);
    }
  }
  int inspect() => read();
}
Example main() => Example();
      ''';
      final instance = await eval(source) as ObjInstance;
      expect(() => expect(() => instance.invoke('fail', null), throwsA('error')), println([2]));
      expect(instance.invoke('inspect', null), 2);
    });
  });
}
