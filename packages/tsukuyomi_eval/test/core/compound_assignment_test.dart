import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Compound assignment', () {
    test('arithmetic assignments return their new values', () async {
      const source = '''
void main() {
  var value = 3;
  print(value += 1);
  print(value -= 1);
  print(value *= 2);
  print(value %= 4);
  print(value ~/= 2);
  double fraction = 3.0;
  print(fraction /= 2.0);
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([4, 3, 6, 2, 1, 1.5, 1]));
    });

    test('bitwise assignments include unsigned shift', () async {
      const source = '''
void main() {
  var value = 3;
  print(value &= 1);
  print(value |= 2);
  print(value ^= 1);
  print(value <<= 1);
  print(value >>= 1);
  print(value >>>= 1);
  var negative = -1;
  print((negative >>>= 1) == (-1 >>> 1));
  print(negative > 0);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 3, 2, 4, 2, 1, true, true]));
    });

    test('native string list and duration operators remain available', () async {
      const source = '''
void main() {
  var text = 'first';
  print(text += ' second');
  var values = [1];
  print(values += [2]);
  var duration = Duration(seconds: 1);
  print((duration += Duration(seconds: 1)).inSeconds);
  print((duration *= 2).inSeconds);
  print((duration ~/= 2).inSeconds);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['first second', '[1, 2]', 2, 4, 2]));
    });

    test('local captured and global assignments write their original bindings', () async {
      const source = '''
var global = 1;
void main() {
  var local = 1;
  print(local += 1);
  void update() {
    print(local *= 2);
    print(global += 1);
  }
  update();
  print(local);
  print(global);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 4, 2, 4, 2]));
    });

    test('the old value is read before a right side mutation', () async {
      const source = '''
void main() {
  var value = 1;
  print(value += (value = 2));
  print(value);
  var other = 1;
  print(value += (other *= 2));
  print(other);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([3, 3, 5, 2]));
    });

    test('property receiver getter right side and setter run once in order', () async {
      const source = '''
class Counter {
  int stored = 1;
  int get value {
    print('getter');
    return stored;
  }
  set value(int value) {
    print('setter');
    stored = value;
  }
}
void main() {
  final counter = Counter();
  Counter receiver() {
    print('receiver');
    return counter;
  }
  int right() {
    print('right');
    return 2;
  }
  print(receiver().value += right());
  print(counter.stored);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['receiver', 'getter', 'right', 'setter', 3, 3]));
    });

    test('index receiver and index are evaluated before the right side once', () async {
      const source = '''
void main() {
  final values = [1, 3];
  List<int> receiver() {
    print('receiver');
    return values;
  }
  int index = 0;
  int nextIndex() {
    print('index');
    return index++;
  }
  int right() {
    print('right');
    return 2;
  }
  print(receiver()[nextIndex()] += right());
  print(index);
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['receiver', 'index', 'right', 3, 1, '[3, 3]']));
    });

    test('implicit instance fields and accessors use this', () async {
      const source = '''
class Counter {
  int field = 1;
  int get value => field;
  set value(int value) => field = value;
  void update() {
    print(field += 1);
    print(value *= 2);
    print(field);
  }
}
void main() => Counter().update();
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 4, 4]));
    });

    test('implicit and qualified static fields and accessors share class storage', () async {
      const source = '''
class Counter {
  static int field = 1;
  static int get value => field;
  static set value(int value) => field = value;
  static void update() {
    print(field += 1);
    print(value *= 2);
    print(Counter.field -= 1);
    print(Counter.value += 1);
    print(field);
  }
}
void main() => Counter.update();
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 4, 3, 4, 4]));
    });

    test('top level getter and setter participate in compound assignment', () async {
      const source = '''
int stored = 1;
int get value {
  print('getter');
  return stored;
}
set value(int value) {
  print('setter');
  stored = value;
}
void main() {
  print(value += 1);
  print(stored);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['getter', 'setter', 2, 2]));
    });

    test('super assignment reads and writes the parent accessor', () async {
      const source = '''
class Parent {
  int stored = 1;
  int get value => stored;
  set value(int value) => stored = value;
}
class Child extends Parent {
  int own = 3;
  int get value => own;
  set value(int value) => own = value;
  void update() {
    print(super.value += 1);
    print(super.value *= 2);
    print(stored);
    print(own);
  }
}
void main() => Child().update();
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 4, 4, 3]));
    });

    test('null local assignment short circuits the right side', () async {
      const source = '''
void main() {
  int? value;
  int right() {
    print('right');
    return 1;
  }
  print(value ??= right());
  print(value ??= right());
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['right', 1, 1, 1]));
    });

    test('null assignment returns the computed value without rereading the getter', () async {
      const source = '''
class Counter {
  int? stored;
  int? get value {
    print('getter');
    return stored;
  }
  set value(int? value) {
    print('setter');
    stored = value == null ? null : value + 1;
  }
}
void main() {
  final counter = Counter();
  int right() {
    print('right');
    return 1;
  }
  print(counter.value ??= right());
  print(counter.stored);
  print(counter.value ??= right());
  print(counter.stored);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['getter', 'right', 'setter', 1, 2, 'getter', 2, 2]));
    });

    test('nonnull index assignment keeps its value and removes address operands', () async {
      const source = '''
void main() {
  final values = <dynamic>[1, null];
  int index = 0;
  int right() {
    print('right');
    return 2;
  }
  print(values[index++] ??= right());
  print(values[index++] ??= right());
  print(index);
  print(values);
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 'right', 2, 2, '[1, 2]', 'after']));
    });

    test('nonnull property receivers are evaluated once without calling a setter', () async {
      const source = '''
class Counter {
  int? stored = 1;
  int? get value {
    print('getter');
    return stored;
  }
  set value(int? value) {
    print('unreachable setter');
    stored = value;
  }
}
void main() {
  final counter = Counter();
  Counter receiver() {
    print('receiver');
    return counter;
  }
  print(receiver().value ??= 2);
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['receiver', 'getter', 1, 'after']));
    });

    test('super null assignment preserves both branches and parent dispatch', () async {
      const source = '''
class Parent {
  int? stored;
  int? get value {
    print('parent getter');
    return stored;
  }
  set value(int? value) {
    print('parent setter');
    stored = value;
  }
}
class Child extends Parent {
  int? own = 3;
  int? get value => own;
  set value(int? value) => own = value;
  void update() {
    print(super.value ??= 1);
    print(super.value ??= 2);
    var after = 'after';
    print(after);
    print(stored);
    print(own);
  }
}
void main() => Child().update();
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['parent getter', 'parent setter', 1, 'parent getter', 1, 'after', 1, 3]),
      );
    });

    test('null assignment supports implicit global static and captured bindings', () async {
      const source = '''
int? global;
class Counter {
  static int? value;
  static void update() {
    print(value ??= 1);
    print(Counter.value ??= 2);
  }
}
void main() {
  int? value;
  void update() {
    print(value ??= 1);
    print(value ??= 2);
    print(global ??= 1);
  }
  update();
  Counter.update();
  print(global ??= 2);
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 1, 1, 1, 1, 1, 1]));
    });

    test('a null right side is written and remains eligible for another assignment', () async {
      const source = '''
class Counter {
  int? stored;
  int? get value {
    print('getter');
    return stored;
  }
  set value(int? value) {
    print('setter');
    stored = value;
  }
}
void main() {
  final counter = Counter();
  print(counter.value ??= null);
  print(counter.value ??= 1);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['getter', 'setter', null, 'getter', 'setter', 1]));
    });

    test('null aware properties skip the entire assignment', () async {
      const source = '''
class Counter {
  int value = 1;
  int? optional;
}
void main() {
  Counter? counter;
  int right() {
    print('right');
    return 1;
  }
  print(counter?.value += right());
  print(counter?.optional ??= right());
  counter = Counter();
  print(counter?.value += right());
  print(counter?.optional ??= right());
  print(counter?.optional ??= right());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([null, null, 'right', 2, 'right', 1, 1]));
    });

    test('null aware indexes skip index and right side evaluation', () async {
      const source = '''
void main() {
  List<dynamic>? values;
  int index = 0;
  int right() {
    print('right');
    return 1;
  }
  print(values?[index++] ??= right());
  print(index);
  values = [1, null];
  print(values?[index++] ??= right());
  print(values?[index++] ??= right());
  print(index);
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([null, 0, 1, 'right', 1, 2, '[1, 1]']));
    });

    test('chained null aware targets skip arithmetic right sides', () async {
      const source = '''
class Holder {
  List<int> values = [1];
}
void main() {
  Holder? holder;
  int index = 0;
  int right() {
    print('right');
    return 1;
  }
  print(holder?.values[index++] += right());
  print(index);
  holder = Holder();
  print(holder?.values[index++] += right());
  print(index);
  print(holder.values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([null, 0, 'right', 2, 1, '[2]']));
    });

    test('cascade assignments keep the cascade target and isolate null sections', () async {
      const source = '''
class Counter {
  int value = 1;
  int? optional;
  Counter? child;
}
void main() {
  final counter = Counter();
  print((counter..value += 1..optional ??= 1..optional ??= 2) == counter);
  print(counter.value);
  print(counter.optional);
  int calls = 0;
  int right() {
    calls++;
    return 1;
  }
  counter..child?.value += right()..value += right();
  Counter? absent;
  print(absent?..value += right()..optional ??= right());
  print(calls);
  print(counter.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true, 2, 1, null, 1, 3]));
    });

    test('cascade index null assignment cleans both address operands', () async {
      const source = '''
void main() {
  final values = <dynamic>[1, null];
  int index = 0;
  print((values..[index++] ??= 2..[index++] ??= 2) == values);
  print(index);
  print(values);
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true, 2, '[1, 2]', 'after']));
    });

    test('compound assignments retain read values across await', () async {
      const source = '''
class Counter {
  int value = 1;
}
Future<void> main() async {
  final counter = Counter();
  final values = [1, 3];
  int index = 0;
  Future<int> right() async {
    await null;
    counter.value = 3;
    values[0] = 3;
    return 1;
  }
  print(counter.value += await right());
  print(values[index++] += await right());
  print(index);
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 4, 1, '[4, 3]']));
    });

    test('null assignment short circuits await and preserves pending addresses', () async {
      const source = '''
Future<void> main() async {
  final values = <dynamic>[1, null];
  int index = 0;
  Future<int> right() async {
    print('right');
    await null;
    return 2;
  }
  print(values[index++] ??= await right());
  print(values[index++] ??= await right());
  print(index);
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 'right', 2, 2, '[1, 2]']));
    });

    test('right side errors skip writes and unwind retained address operands', () async {
      const source = '''
void main() {
  final values = [1];
  final optional = <dynamic>[null];
  int fail() => throw 'right';
  try {
    values[0] += fail();
  } catch (error) {
    print(error);
  } finally {
    print('finally');
  }
  try {
    optional[0] ??= fail();
  } catch (error) {
    print(error);
  }
  print(<dynamic>[values[0], optional[0]]);
  print(optional[0] ??= 2);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['right', 'finally', 'right', '[1, null]', 2]));
    });

    test('awaited errors preserve the assignment target and finally state', () async {
      const source = '''
Future<void> main() async {
  final values = [1];
  Future<int> fail() async {
    await null;
    throw 'right';
  }
  try {
    values[0] += await fail();
  } catch (error) {
    print(error);
  } finally {
    await null;
    print(values[0]);
  }
  print(values[0] += 1);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['right', 1, 2]));
    });

    test('host callbacks restore assignment state after failure', () async {
      const source = '''
void main() {
  final values = [1];
  int fail() => throw 'right';
  try {
    [1].forEach((value) => values[0] += fail());
  } catch (error) {
    print(error);
  }
  [1].forEach((value) => print(values[0] += value));
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['right', 2, '[2]']));
    });

    test('nonnull short circuits discard no surrounding expression operands', () async {
      const source = r'''
void main() {
  final values = <dynamic>[1];
  String join(String first, int? second, int? third) => '$first/$second/$third';
  print(join('before', values[0] ??= 2, values[0] ??= 3));
  print([values[0] ??= 2, values[0] ??= 3]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['before/1/1', '[1, 1]']));
    });

    test('map null assignment reads existing keys and inserts missing keys once', () async {
      const source = '''
void main() {
  final values = {'first': 1};
  String key(String value) {
    print(value);
    return value;
  }
  int right() {
    print('right');
    return 2;
  }
  print(values[key('first')] ??= right());
  print(values[key('second')] ??= right());
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['first', 1, 'second', 'right', 2, '{first: 1, second: 2}']),
      );
    });

    test('getter and setter failures do not execute the remaining assignment steps', () async {
      const source = '''
class Counter {
  int? stored;
  bool failRead = true;
  bool failWrite = false;
  int? get value {
    if (failRead) throw 'getter';
    return stored;
  }
  set value(int? value) {
    if (failWrite) throw 'setter';
    stored = value;
  }
}
void main() {
  final counter = Counter();
  int right() {
    print('right');
    return 1;
  }
  try {
    counter.value ??= right();
  } catch (error) {
    print(error);
  }
  counter.failRead = false;
  counter.failWrite = true;
  try {
    counter.value ??= right();
  } catch (error) {
    print(error);
  }
  print(counter.stored);
  counter.failWrite = false;
  print(counter.value ??= right());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['getter', 'right', 'setter', null, 'right', 1]));
    });

    test('operator failure skips the write and leaves the target usable', () async {
      const source = '''
void main() {
  final values = [1];
  try {
    values[0] ~/= 0;
  } catch (error) {
    print('operator');
  } finally {
    print(values[0]);
  }
  print(values[0] += 1);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['operator', 1, 2]));
    });
  });
}
