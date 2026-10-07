import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/compiler.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Synchronous for-in', () {
    test('list iteration and typed declarations', () async {
      const source = '''
void main() {
  for (var value in [1, 2, 3]) print(value);
  for (final int value in [1, 2]) print(value);
  for (int value in [3]) print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3, 1, 2, 3]));
    });

    test('empty loops leave existing variables unchanged', () async {
      const source = '''
void main() {
  var value = 'before';
  for (value in <String>[]) print('unreachable');
  for (final item in <int>[]) print('unreachable');
  print(value);
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['before', 'after']));
    });

    test('set and map views use native iterators', () async {
      const source = '''
void main() {
  for (final value in {1, 2, 1}) print(value);
  final values = {'first': 1, 'second': 2};
  for (final key in values.keys) print(key);
  for (final value in values.values) print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 'first', 'second', 1, 2]));
    });

    test('lazy iterable evaluates only requested elements', () async {
      const source = '''
void main() {
  final values = [1, 2, 3].where((value) {
    print(value);
    return value > 1;
  });
  for (final value in values) {
    print('body');
    print(value);
    break;
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 'body', 2]));
    });

    test('map entries expose their native keys and values', () async {
      const source = r'''
void main() {
  final values = {'first': 1, 'second': 2};
  for (final entry in values.entries) print('${entry.key}:${entry.value}');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['first:1', 'second:2']));
    });

    test('dynamic iterable keeps native iterator access', () async {
      const source = '''
void main() {
  dynamic values = [1, 2];
  for (final value in values) print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('iterable expression runs once', () async {
      const source = '''
List<int> values() {
  print('iterable');
  return [1, 2];
}
void main() {
  for (final value in values()) print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['iterable', 1, 2]));
    });

    test('loop declaration does not shadow its iterable expression', () async {
      const source = '''
void main() {
  final values = [1, 2];
  for (final values in values) print(values);
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, '[1, 2]']));
    });

    test('declared variable closures keep each iteration', () async {
      const source = '''
void main() {
  final callbacks = [];
  for (final value in [1, 2, 3]) callbacks.add(() => value);
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 3]));
    });

    test('closures share writes within an iteration only', () async {
      const source = '''
void main() {
  final readers = [];
  final writers = [];
  for (var value in [1, 2]) {
    readers.add(() => value);
    writers.add(() => ++value);
  }
  print(writers[0]());
  print(readers[0]());
  print(readers[1]());
  print(writers[1]());
  print(readers[0]());
  print(readers[1]());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 2, 2, 3, 2, 3]));
    });

    test('existing variable closures share the outer binding', () async {
      const source = '''
void main() {
  var value = 0;
  final callbacks = [];
  for (value in [1, 2]) callbacks.add(() => value);
  print(value);
  value++;
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 3]));
    });

    test('existing upvalue assignment updates its enclosing scope', () async {
      const source = '''
void main() {
  var value = 0;
  void run() {
    for (value in [1, 2]) print(value);
  }
  run();
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 2]));
    });

    test('existing global variable assignment', () async {
      const source = '''
var value = 0;
void main() {
  for (value in [1, 2]) print(value);
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 2]));
    });

    test('instance fields and setters accept loop assignment', () async {
      const source = '''
class Example {
  int field = 0;
  set value(int value) {
    print('setter');
    field = value;
  }
  void run() {
    for (field in [1, 2]) print(field);
    for (value in [3]) print(field);
    print(field);
  }
}
void main() => Example().run();
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 'setter', 3, 3]));
    });

    test('static fields and setters accept loop assignment', () async {
      const source = '''
class Example {
  static int field = 0;
  static set value(int value) {
    print('setter');
    field = value;
  }
  static void run() {
    for (field in [1, 2]) print(field);
    for (value in [3]) print(field);
    print(field);
  }
}
void main() => Example.run();
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 'setter', 3, 3]));
    });

    test('top level setters accept loop assignment', () async {
      const source = '''
int stored = 0;
set value(int value) {
  print('setter');
  stored = value;
}
void main() {
  for (value in [1, 2]) print(stored);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['setter', 1, 'setter', 2]));
    });

    test('continue and break close iteration and body captures', () async {
      const source = '''
void main() {
  final callbacks = [];
  for (var value in [1, 2, 3]) {
    final body = value;
    callbacks.add(() => value + body);
    if (value == 1) continue;
    if (value == 2) break;
  }
  var after = 'after';
  print(after);
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['after', 2, 4]));
    });

    test('nested loops retain separate iterators and captures', () async {
      const source = '''
void main() {
  final callbacks = [];
  for (final outer in [1, 2]) {
    for (final inner in [1, 2]) {
      callbacks.add(() => outer + inner);
      if (inner == 1) continue;
      break;
    }
  }
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 3, 4]));
    });

    test('sequential loops release hidden iterator slots', () async {
      const source = '''
void main() {
  for (final value in [1]) print(value);
  final between = 'between';
  print(between);
  for (var value in [2]) print(value);
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 'between', 2, 'after']));
    });

    test('loop exits run finally before closing captured bindings', () async {
      const source = '''
void main() {
  final callbacks = [];
  for (var value in [1, 2, 3]) {
    try {
      callbacks.add(() => value);
      if (value == 1) continue;
      break;
    } finally {
      value++;
      print(value);
    }
  }
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 2, 3]));
    });

    test('return runs loop finally and retains the returned closure', () async {
      const source = '''
Function run() {
  for (var value in [1, 2]) {
    try {
      return () => value;
    } finally {
      value++;
      print('finally');
    }
  }
  return () => 0;
}
void main() => print(run()());
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['finally', 2]));
    });

    test('finally can replace continue with break', () async {
      const source = '''
void main() {
  for (final value in [1, 2]) {
    try {
      print(value);
      continue;
    } finally {
      print('finally');
      break;
    }
  }
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 'finally', 'after']));
    });

    test('synchronous iteration resumes after await in body and finally', () async {
      const source = '''
Future<void> main() async {
  final callbacks = [];
  for (var value in [1, 2, 3]) {
    try {
      await null;
      callbacks.add(() => value);
      if (value == 1) continue;
      break;
    } finally {
      await null;
      value++;
      print(value);
    }
  }
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 2, 3]));
    });

    test('native callback iteration restores the calling frame', () async {
      const source = '''
void main() {
  [1, 2].forEach((outer) {
    for (final inner in [1, 2]) {
      print(outer + inner);
      if (inner == 1) continue;
      break;
    }
  });
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 3, 4, 'after']));
    });

    test('native concurrent modification is caught outside iteration', () async {
      const source = '''
void main() {
  final values = [1, 2];
  try {
    for (final value in values) {
      print(value);
      values.add(3);
    }
  } catch (error) {
    print('caught');
  } finally {
    print('finally');
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 'caught', 'finally']));
    });

    test('typed native iterator members are available directly', () async {
      const source = '''
void main() {
  Iterator<int> iterator = [1, 2].iterator;
  print(iterator.moveNext());
  print(iterator.current);
  print(iterator.moveNext());
  print(iterator.current);
  print(iterator.moveNext());
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true, 1, true, 2, false]));
    });

    test('script iterator follows the protocol call order', () async {
      const source = '''
class Values implements Iterable<int>, Iterator<int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  int index = 0;
  String failure = '';
  Iterator<int> get iterator {
    print('iterator');
    if (failure == 'iterator') throw 'iterator error';
    return this;
  }
  bool moveNext() {
    print('moveNext');
    if (failure == 'moveNext') throw 'moveNext error';
    index++;
    return index <= 2;
  }
  int get current {
    print('current');
    if (failure == 'current') throw 'current error';
    return index;
  }
}
void main() {
  for (final value in Values()) print(value);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['iterator', 'moveNext', 'current', 1, 'moveNext', 'current', 2, 'moveNext']),
      );
    });

    test('break does not advance or read the script iterator again', () async {
      const source = '''
class Values implements Iterable<int>, Iterator<int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  int index = 0;
  String failure = '';
  Iterator<int> get iterator {
    print('iterator');
    if (failure == 'iterator') throw 'iterator error';
    return this;
  }
  bool moveNext() {
    print('moveNext');
    if (failure == 'moveNext') throw 'moveNext error';
    index++;
    return index <= 2;
  }
  int get current {
    print('current');
    if (failure == 'current') throw 'current error';
    return index;
  }
}
void main() {
  for (final value in Values()) {
    print(value);
    break;
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['iterator', 'moveNext', 'current', 1]));
    });

    test('iterator failures execute enclosing finally', () async {
      const source = '''
class Values implements Iterable<int>, Iterator<int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  int index = 0;
  String failure = '';
  Iterator<int> get iterator {
    print('iterator');
    if (failure == 'iterator') throw 'iterator error';
    return this;
  }
  bool moveNext() {
    print('moveNext');
    if (failure == 'moveNext') throw 'moveNext error';
    index++;
    return index <= 2;
  }
  int get current {
    print('current');
    if (failure == 'current') throw 'current error';
    return index;
  }
}
void main() {
  final values = Values();
  values.failure = 'iterator';
  try {
    for (final value in values) print('unreachable');
  } catch (error) {
    print(error);
  } finally {
    print('finally');
  }
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['iterator', 'iterator error', 'finally', 'after']));
    });

    test('moveNext failures execute enclosing finally', () async {
      const source = '''
class Values implements Iterable<int>, Iterator<int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  int index = 0;
  String failure = '';
  Iterator<int> get iterator {
    print('iterator');
    if (failure == 'iterator') throw 'iterator error';
    return this;
  }
  bool moveNext() {
    print('moveNext');
    if (failure == 'moveNext') throw 'moveNext error';
    index++;
    return index <= 2;
  }
  int get current {
    print('current');
    if (failure == 'current') throw 'current error';
    return index;
  }
}
void main() {
  final values = Values();
  values.failure = 'moveNext';
  try {
    for (final value in values) print('unreachable');
  } catch (error) {
    print(error);
  } finally {
    print('finally');
  }
  print('after');
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['iterator', 'moveNext', 'moveNext error', 'finally', 'after']),
      );
    });

    test('current failures execute enclosing finally', () async {
      const source = '''
class Values implements Iterable<int>, Iterator<int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  int index = 0;
  String failure = '';
  Iterator<int> get iterator {
    print('iterator');
    if (failure == 'iterator') throw 'iterator error';
    return this;
  }
  bool moveNext() {
    print('moveNext');
    if (failure == 'moveNext') throw 'moveNext error';
    index++;
    return index <= 2;
  }
  int get current {
    print('current');
    if (failure == 'current') throw 'current error';
    return index;
  }
}
void main() {
  final values = Values();
  values.failure = 'current';
  try {
    for (final value in values) print('unreachable');
  } catch (error) {
    print(error);
  } finally {
    print('finally');
  }
  print('after');
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['iterator', 'moveNext', 'current', 'current error', 'finally', 'after']),
      );
    });

    test('body errors close captured loop bindings after finally', () async {
      const source = '''
void main() {
  final callbacks = [];
  try {
    for (var value in [1, 2]) {
      callbacks.add(() => value);
      try {
        throw 'body error';
      } finally {
        value++;
        print('finally');
      }
    }
  } catch (error) {
    print(error);
  }
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['finally', 'body error', 2]));
    });

    test('for-in and ordinary loops keep their own exit targets', () async {
      const source = '''
void main() {
  final callbacks = [];
  for (final outer in [1, 2]) {
    for (var inner = 1; inner < 3; inner++) {
      callbacks.add(() => outer + inner);
      continue;
    }
  }
  for (var outer = 1; outer < 3; outer++) {
    for (final inner in [1, 2]) {
      callbacks.add(() => outer + inner);
      break;
    }
  }
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 3, 4, 2, 3]));
    });

    test('await for is rejected by the compiler', () {
      const source = '''
Future<void> main() async {
  print('unreachable');
  await for (final value in Stream<int>.empty()) print(value);
}
      ''';
      final parsed = parseString(content: source);
      final compiler = Compiler(debugLineInfo: parsed.lineInfo);
      final function = parsed.unit.declarations.single as FunctionDeclaration;
      final body = function.functionExpression.body as BlockFunctionBody;
      expect(
        () => compiler.compile(node: body.block.statements.last),
        throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('await for'))),
      );
    });

    test('for-in patterns are rejected before execution', () async {
      const source = '''
void main() {
  print('unreachable');
  for (var [value] in [[1]]) print(value);
}
      ''';
      await expectLater(
        () =>
            expectLater(eval(source), throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('pattern')))),
        prints(''),
      );
    });

    test('collection-for is rejected before execution', () async {
      const source = '''
void main() {
  print('unreachable');
  print([for (final value in [1, 2]) value]);
}
      ''';
      await expectLater(
        () => expectLater(
          eval(source),
          throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('collection-for'))),
        ),
        prints(''),
      );
    });
  });
}
