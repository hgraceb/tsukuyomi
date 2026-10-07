import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Assignment target evaluation', () {
    test('postfix ++ evaluates the index once', () async {
      const source = '''
void main() {
  final values = [1, 3];
  int index = 0;
  print(values[index++]++);
  print(index);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          1,
          1,
          [2, 3],
        ]),
      );
    });

    test('postfix ++ evaluates the receiver once', () async {
      const source = '''
class Counter {
  int value = 1;
}

void main() {
  final first = Counter();
  final second = Counter();
  int calls = 0;
  Counter next() => calls++ == 0 ? first : second;
  print(next().value++);
  print(calls);
  print(first.value);
  print(second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 1, 2, 1]));
    });

    test('prefix ++ evaluates the index once', () async {
      const source = '''
void main() {
  final values = [1, 3];
  int index = 0;
  print(++values[index++]);
  print(index);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          2,
          1,
          [2, 3],
        ]),
      );
    });

    test('prefix ++ evaluates the receiver once', () async {
      const source = '''
class Counter {
  int value = 1;
}

void main() {
  final first = Counter();
  final second = Counter();
  int calls = 0;
  Counter next() => calls++ == 0 ? first : second;
  print(++next().value);
  print(calls);
  print(first.value);
  print(second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 1, 2, 1]));
    });

    test('postfix -- evaluates the index once', () async {
      const source = '''
void main() {
  final values = [1, 3];
  int index = 0;
  print(values[index++]--);
  print(index);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          1,
          1,
          [0, 3],
        ]),
      );
    });

    test('postfix -- evaluates the receiver once', () async {
      const source = '''
class Counter {
  int value = 1;
}

void main() {
  final first = Counter();
  final second = Counter();
  int calls = 0;
  Counter next() => calls++ == 0 ? first : second;
  print(next().value--);
  print(calls);
  print(first.value);
  print(second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 1, 0, 1]));
    });

    test('prefix -- evaluates the index once', () async {
      const source = '''
void main() {
  final values = [1, 3];
  int index = 0;
  print(--values[index++]);
  print(index);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          0,
          1,
          [0, 3],
        ]),
      );
    });

    test('prefix -- evaluates the receiver once', () async {
      const source = '''
class Counter {
  int value = 1;
}

void main() {
  final first = Counter();
  final second = Counter();
  int calls = 0;
  Counter next() => calls++ == 0 ? first : second;
  print(--next().value);
  print(calls);
  print(first.value);
  print(second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([0, 1, 0, 1]));
    });

    test('index updates preserve receiver and index evaluation order', () async {
      const source = '''
void main() {
  final values = [1, 3];
  String events = '';
  List<int> receiver() {
    events = events + 'receiver ';
    return values;
  }
  int index() {
    events = events + 'index ';
    return 0;
  }
  print(receiver()[index()]++);
  print(++receiver()[index()]);
  print(events);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          1,
          3,
          "receiver index receiver index ",
          [3, 3],
        ]),
      );
    });

    test('an index changing the receiver variable still writes the original list', () async {
      const source = '''
List<int> current = [1, 3];
List<int> replacement = [2, 4];
int index() {
  current = replacement;
  return 0;
}

void main() {
  final original = current;
  print(current[index()]++);
  print(original);
  print(replacement);
  current = original;
  print(++current[index()]);
  print(original);
  print(replacement);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          1,
          [2, 3],
          [2, 4],
          3,
          [3, 3],
          [2, 4],
        ]),
      );
    });

    test('property updates call each getter and setter once in order', () async {
      const source = '''
String events = '';
class Counter {
  int stored = 1;
  int get value {
    events = events + 'get ';
    return stored;
  }
  set value(int value) {
    events = events + 'set ';
    stored = value;
  }
}

void main() {
  final counter = Counter();
  Counter receiver() {
    events = events + 'receiver ';
    return counter;
  }
  print(receiver().value++);
  print(++receiver().value);
  print(events);
  print(counter.stored);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 3, "receiver get set receiver get set ", 3]));
    });

    test('a getter changing the receiver variable still writes the original object', () async {
      const source = '''
class Counter {
  int stored = 1;
  int get value {
    current = replacement;
    return stored;
  }
  set value(int value) => stored = value;
}

Counter current = Counter();
Counter replacement = Counter();

void main() {
  final original = current;
  print(current.value++);
  print(original.stored);
  print(replacement.stored);
  current = original;
  print(++current.value);
  print(original.stored);
  print(replacement.stored);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 1, 3, 3, 1]));
    });

    test('a chained getter selects the nested receiver only once', () async {
      const source = '''
class Counter {
  int value = 1;
}
class Holder {
  final first = Counter();
  final second = Counter();
  int calls = 0;
  Counter get next => calls++ == 0 ? first : second;
}

void main() {
  final holder = Holder();
  print(holder.next.value++);
  print(holder.calls);
  print(holder.first.value);
  print(holder.second.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 1, 2, 1]));
    });

    test('null aware property updates skip reads and writes', () async {
      const source = '''
class Counter {
  int value = 1;
}

void main() {
  Counter? counter;
  int calls = 0;
  Counter? receiver() {
    calls++;
    return counter;
  }
  print(receiver()?.value++);
  print(++receiver()?.value);
  print(calls);
  counter = Counter();
  print(receiver()?.value++);
  print(++receiver()?.value);
  print(calls);
  print(counter.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([null, null, 2, 1, 3, 4, 3]));
    });

    test('null aware index updates skip the index expression', () async {
      const source = '''
void main() {
  List<int>? values;
  int index = 0;
  print(values?[index++]++);
  print(++values?[index++]);
  print(index);
  values = [1, 3];
  print(values?[index++]++);
  print(++values?[index++]);
  print(index);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          null,
          null,
          0,
          1,
          4,
          2,
          [2, 4],
        ]),
      );
    });

    test('null shorting covers chained index updates', () async {
      const source = '''
class Holder {
  final values = [1, 3];
}

void main() {
  Holder? holder;
  int index = 0;
  print(holder?.values[index++]++);
  print(++holder?.values[index++]);
  print(index);
  holder = Holder();
  print(holder?.values[index++]++);
  print(++holder?.values[index++]);
  print(index);
  print(holder.values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          null,
          null,
          0,
          1,
          4,
          2,
          [2, 4],
        ]),
      );
    });

    test('cascade assignments keep their target and skip null sections', () async {
      const source = '''
class Counter {
  int value = 1;
  Counter? child;
}

void main() {
  final counter = Counter();
  print((counter..value = 2..value = 1) == counter);
  print(counter.value);
  int calls = 1;
  counter..child?.value = ++calls..value = ++calls;
  print(counter.value);
  print(calls);
  Counter? absent;
  print(absent?..value = ++calls);
  print(calls);
  final values = [1, 3];
  int index = 0;
  values..[index++] = 1..[index++] = 2;
  print(index);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          true,
          1,
          2,
          2,
          null,
          2,
          2,
          [1, 2],
        ]),
      );
    });

    test('ordinary assignments evaluate the target before the value', () async {
      const source = '''
void main() {
  final values = [1];
  String events = '';
  List<int> receiver() {
    events = events + 'receiver ';
    return values;
  }
  int index() {
    events = events + 'index ';
    return 0;
  }
  int value() {
    events = events + 'value ';
    return 2;
  }
  print(receiver()[index()] = value());
  print(events);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          2,
          "receiver index value ",
          [2],
        ]),
      );
    });

    test('null aware assignments skip the right hand side', () async {
      const source = '''
class Counter {
  int value = 1;
}

void main() {
  Counter? counter;
  List<int>? values;
  int calls = 0;
  int next() => ++calls;
  print(counter?.value = next());
  print(values?[next()] = next());
  print(calls);
  counter = Counter();
  print(counter?.value = next());
  print(calls);
  print(counter.value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([null, null, 0, 1, 1, 1]));
    });

    test('nested updates preserve old values and enclosing expression operands', () async {
      const source = '''
List<int> pair(int first, int second) => [first, second];

void main() {
  final values = [1, 3];
  int index = 0;
  print(values[index++]++ + ++values[index++]);
  print(index);
  print(values);
  index = 0;
  print(pair(values[index++]++, ++values[index++]));
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          5,
          2,
          [2, 4],
          [2, 5],
          [3, 5],
        ]),
      );
    });

    test('async receiver and index updates survive suspension', () async {
      const source = '''
Future<void> main() async {
  final values = [1, 3];
  int receiverCalls = 0;
  int indexCalls = 0;
  Future<List<int>> receiver() async {
    await null;
    receiverCalls++;
    return values;
  }
  Future<int> index() async {
    await null;
    return indexCalls++;
  }
  print((await receiver())[await index()]++);
  print(++(await receiver())[await index()]);
  print(receiverCalls);
  print(indexCalls);
  print(values);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          1,
          4,
          2,
          2,
          [2, 4],
        ]),
      );
    });

    test('getter and setter errors leave later updates usable', () async {
      const source = '''
class Counter {
  int stored = 1;
  bool failRead = true;
  bool failWrite = false;
  int get value {
    if (failRead) throw 'read';
    return stored;
  }
  set value(int value) {
    if (failWrite) throw 'write';
    stored = value;
  }
}

void main() {
  final counter = Counter();
  try {
    counter.value++;
  } catch (error) {
    print(error);
  }
  counter.failRead = false;
  counter.failWrite = true;
  try {
    ++counter.value;
  } catch (error) {
    print(error);
  }
  counter.failWrite = false;
  print(counter.value++);
  print(++counter.value);
  print(counter.stored);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(["read", "write", 1, 3, 3]));
    });

    test('super updates use the parent getter and setter', () async {
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
    print(super.value++);
    print(++super.value);
    print(super.value--);
    print(--super.value);
    print(stored);
    print(own);
    print(super.value = 2);
    print(stored);
    print(own);
  }
}

void main() {
  Child().update();
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 3, 3, 1, 1, 3, 2, 2, 3]));
    });
  });
}
