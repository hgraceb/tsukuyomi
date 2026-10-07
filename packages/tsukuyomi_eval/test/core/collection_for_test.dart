import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/compiler.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Collection for elements', () {
    test('list for-in mixes ordinary empty and loop elements', () async {
      const source = '''
void main() {
  print(<int>[0, for (final value in [1, 2]) value, for (final value in <int>[]) value, 3]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[0, 1, 2, 3]']));
    });

    test('set loops deduplicate in insertion order', () async {
      const source = '''
void main() {
  print(<int>{0, for (var value in [1, 2, 1]) value, for (final value in {'first': 2, 'second': 3}.values) value});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{0, 1, 2, 3}']));
    });

    test('map loops evaluate entries and preserve overwritten key positions', () async {
      const source = '''
void main() {
  print(<String, int>{'first': 0, for (final name in ['first', 'second', 'first']) name: name.length, 'after': 1});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{first: 5, second: 6, after: 1}']));
    });

    test('classic declaration loops construct list set and map literals', () async {
      const source = '''
void main() {
  print(<int>[for (var value = 1; value <= 2; value++) value]);
  print(<int>{for (int value = 1; value <= 2; value++) value});
  print(<int, String>{for (var value = 1; value <= 2; value++) value: value.toString()});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '{1, 2}', '{1: 1, 2: 2}']));
    });

    test('classic expression loops update the existing variable', () async {
      const source = '''
void main() {
  var value = 0;
  print(<int>[for (value = 1; value <= 2; value++) value]);
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', 3]));
    });

    test('classic loops allow omitted initialization and updaters', () async {
      const source = '''
void main() {
  var value = 1;
  print(<int>[for (; value <= 2;) value++]);
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', 3]));
    });

    test('classic loops keep multiple declarations and updaters aligned', () async {
      const source = '''
void main() {
  print(<int>[for (var left = 1, right = 2; left <= 2; left++, right++) left + right]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[3, 5]']));
    });

    test('zero iterations preserve surrounding values and locals', () async {
      const source = '''
void main() {
  var value = 'outer';
  print(<int>[0, for (var value = 1; value < 1; value++) value, 2]);
  print(<int>{for (final item in <int>[]) item});
  print(<String, int>{for (final name in <String>[]) name: 1});
  print(value);
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[0, 2]', '{}', '{}', 'outer', 'after']));
    });

    test('loop declarations do not shadow the iterable expression', () async {
      const source = '''
void main() {
  final values = [1, 2];
  print(<int>[for (final values in values) values]);
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '[1, 2]']));
    });

    test('for-in closure elements capture each declared binding', () async {
      const source = '''
void main() {
  final callbacks = <dynamic>[for (var value in [1, 2]) () => value];
  callbacks.forEach((callback) => print(callback()));
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 'after']));
    });

    test('classic closure elements close bindings before the updater', () async {
      const source = '''
void main() {
  final callbacks = <dynamic>[for (var value = 1; value <= 2; value++) () => value];
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('closures share same-iteration writes and keep outer variables shared', () async {
      const source = '''
void main() {
  var outer = 0;
  final readers = <dynamic>[];
  final writers = <dynamic>[for (var value in [1, 2]) (() {
    readers.add(() => value + outer);
    return () => ++value;
  })()];
  print(writers[0]());
  outer = 1;
  readers.forEach((reader) => print(reader()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 3]));
    });

    test('existing variable loop closures share their enclosing binding', () async {
      const source = '''
void main() {
  var value = 0;
  final callbacks = <dynamic>[for (value in [1, 2]) () => value];
  print(value);
  value++;
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([2, 3, 3]));
    });

    test('existing global and upvalue loop variables retain assignment', () async {
      const source = '''
var global = 0;
void main() {
  var captured = 0;
  void run() {
    print(<int>[for (global in [1, 2]) global]);
    print(<int>[for (captured in [1, 2]) captured]);
  }
  run();
  print(global);
  print(captured);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '[1, 2]', 2, 2]));
    });

    test('instance field and setter loop assignments keep their receiver', () async {
      const source = '''
class Counter {
  int field = 0;
  set value(int next) {
    print('setter');
    field = next;
  }
  void run() {
    print(<int>[for (field in [1, 2]) field]);
    print(<int>[for (value in [1, 2]) field]);
    print(field);
  }
}
void main() => Counter().run();
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', 'setter', 'setter', '[1, 2]', 2]));
    });

    test('collection loops preserve function argument operands', () async {
      const source = '''
void show(String before, List<int> values, String after) {
  print(before);
  print(values);
  print(after);
}
void main() {
  var outer = 1;
  show('before', <int>[for (final value in [1, 2]) value + outer], 'after');
  print(outer);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['before', '[2, 3]', 'after', 1]));
    });

    test('collection loops preserve binary left operands and pending initializers', () async {
      const source = '''
void main() {
  final values = [0] + <int>[for (var value = 1; value <= 2; value++) value];
  print(values);
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[0, 1, 2]', 'after']));
    });

    test('map values keep their key operands around nested loops', () async {
      const source = '''
String key() {
  print('key');
  return 'items';
}
void main() {
  print(<String, dynamic>{key(): <int>[for (final value in [1, 2]) value], 'after': 3});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['key', '{items: [1, 2], after: 3}']));
    });

    test('index assignments preserve their receiver and index operands', () async {
      const source = '''
void main() {
  final values = <dynamic>[null];
  var index = 0;
  values[index++] = <int>[for (final value in [1, 2]) value];
  print(values);
  print(index);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[[1, 2]]', 1]));
    });

    test('collection loops inside interpolation preserve previous strings', () async {
      const source = r'''
void main() {
  print('before: ${<int>[for (final value in [1, 2]) value]}: after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['before: [1, 2]: after']));
    });

    test('collection loops inside cascades preserve the cascade target', () async {
      const source = '''
void main() {
  final values = <dynamic>[]..add(<int>[for (final value in [1, 2]) value])..add('after');
  print(values);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[[1, 2], after]']));
    });

    test('nested literal loops build independent typed collections', () async {
      const source = '''
void main() {
  print(<dynamic>[for (final outer in [1, 2]) <int>[for (final inner in [1, 2]) outer + inner]]);
  print(<String, dynamic>{for (final name in ['first', 'second']) name: <int>{for (final value in [1, 2, 1]) value}});
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['[[2, 3], [3, 4]]', '{first: {1, 2}, second: {1, 2}}']),
      );
    });

    test('nested for elements append to the same collection in order', () async {
      const source = '''
void main() {
  print(<int>[for (final outer in [1, 2]) for (var inner = 1; inner <= 2; inner++) outer + inner]);
  print(<String, int>{for (final name in ['first', 'second']) for (final value in [1, 2]) name: value});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[2, 3, 3, 4]', '{first: 2, second: 2}']));
    });

    test('sibling collection loops clean up their own binding slots', () async {
      const source = '''
void main() {
  var value = 'outer';
  print(<int>[for (var value in [1, 2]) value, for (var value = 1; value <= 2; value++) value]);
  print(value);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2, 1, 2]', 'outer']));
    });

    test('collection loops compose with conditions and null aware spreads', () async {
      const source = '''
void main() {
  Iterable<int>? empty;
  print(<int>[for (final value in [1, 2]) if (value == 1) ...[value, value] else ...?empty]);
  print(<int>{if (true) for (var value = 1; value <= 2; value++) ...[value, value]});
  print(<String, int>{for (final name in ['first', 'second']) if (name == 'first') ...{name: 1} else name: 2});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 1]', '{1, 2}', '{first: 1, second: 2}']));
    });

    test('lazy iterable evaluation interleaves with element evaluation', () async {
      const source = '''
void main() {
  final values = [1, 2].map((value) {
    print('source');
    print(value);
    return value;
  });
  int element(int value) {
    print('element');
    return value;
  }
  print(<int>[for (final value in values) element(value)]);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['source', 1, 'element', 'source', 2, 'element', '[1, 2]']),
      );
    });

    test('iterable expressions run once and skip unselected loops', () async {
      const source = '''
List<int> values() {
  print('source');
  return [1, 2];
}
void main() {
  print(<int>[for (final value in values()) value, if (false) for (final value in values()) value]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['source', '[1, 2]']));
    });

    test('map loop keys evaluate before values and stop on failure', () async {
      const source = '''
String key(int value) {
  print('key');
  return value.toString();
}
int result(int value) {
  print('value');
  if (value == 2) throw 'value error';
  return value;
}
void main() {
  try {
    print(<String, int>{for (final value in [1, 2]) key(value): result(value), 'unreachable': result(3)});
  } catch (error) {
    print(error);
  } finally {
    print('finally');
  }
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['key', 'value', 'key', 'value', 'value error', 'finally']),
      );
    });

    test('element errors close loop captures and restore enclosing locals', () async {
      const source = '''
void main() {
  final callbacks = <dynamic>[];
  var outer = 'outer';
  try {
    print(<int>[for (var value in [1, 2]) (() {
      callbacks.add(() => value);
      if (value == 2) throw 'body error';
      return value;
    })()]);
  } catch (error) {
    print(error);
  } finally {
    print(outer);
  }
  callbacks.forEach((callback) => print(callback()));
  print(<int>[for (final value in [1, 2]) value]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['body error', 'outer', 1, 2, '[1, 2]']));
    });

    test('invalid typed loop elements stop before later source and body effects', () async {
      const source = '''
void main() {
  dynamic values = [1, 'invalid', 2];
  dynamic element(dynamic value) {
    print('element');
    return value;
  }
  try {
    print(<int>[for (final value in values) element(value)]);
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  } finally {
    print('finally');
  }
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['element', 'element', true, 'finally', 'after']));
    });

    test('loop construction can return through host callbacks', () async {
      const source = '''
void main() {
  final values = [1, 2].map((outer) => <int>[for (var inner = 1; inner <= 2; inner++) outer + inner]);
  values.forEach((value) => print(value));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[2, 3]', '[3, 4]']));
    });

    test('global and instance initializers support collection loops', () async {
      const source = '''
final global = <int>[for (var value = 1; value <= 2; value++) value];
class Values {
  final items = <int>[for (final value in [1, 2]) value];
}
void main() {
  print(global);
  final first = Values();
  final second = Values();
  first.items.add(3);
  print(first.items);
  print(second.items);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '[1, 2, 3]', '[1, 2]']));
    });

    test('awaited for-in sources and elements preserve argument operands', () async {
      const source = '''
Future<List<int>> values() async {
  await Future.delayed(Duration.zero);
  return [1, 2];
}
Future<int> item(int value) async {
  await Future.delayed(Duration.zero);
  return value;
}
void show(String before, List<int> values, String after) {
  print(before);
  print(values);
  print(after);
}
Future<void> main() async {
  show('before', <int>[for (final value in await values()) await item(value)], 'after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['before', '[1, 2]', 'after']));
    });

    test('classic loop initialization condition and updater can await', () async {
      const source = '''
Future<int> item(int value) async {
  await Future.delayed(Duration.zero);
  return value;
}
Future<bool> include(int value) async {
  await Future.delayed(Duration.zero);
  return value <= 2;
}
Future<void> main() async {
  final callbacks = <dynamic>[for (var value = await item(1); await include(value); value = await item(value + 1)) () => value];
  callbacks.forEach((callback) => print(callback()));
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2]));
    });

    test('awaited conditions and spreads compose with collection loops', () async {
      const source = '''
Future<bool> include(int value) async {
  await Future.delayed(Duration.zero);
  return value == 1;
}
Future<List<int>> values(int value) async {
  await Future.delayed(Duration.zero);
  return [value, value];
}
Future<void> main() async {
  print(<int>[for (final value in [1, 2]) if (await include(value)) ...await values(value)]);
  print(<int>{for (var value = 1; value <= 2; value++) ...await values(value)});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 1]', '{1, 2}']));
    });

    test('map loop keys and values can await with enclosing entry operands', () async {
      const source = '''
Future<int> item(int value) async {
  await Future.delayed(Duration.zero);
  return value;
}
Future<void> main() async {
  print(<String, dynamic>{'items': <int, int>{for (final value in [1, 2]) await item(value): await item(value + 1)}, 'after': 3});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{items: {1: 2, 2: 3}, after: 3}']));
    });

    test('awaited element errors preserve finally and closed iteration captures', () async {
      const source = '''
Future<int> item(int value) async {
  await Future.delayed(Duration.zero);
  if (value == 2) throw 'await error';
  return value;
}
Future<void> main() async {
  final callbacks = <dynamic>[];
  try {
    print(<int>[for (var value in [1, 2]) await (() async {
      callbacks.add(() => value);
      return await item(value);
    })()]);
  } catch (error) {
    print(error);
  } finally {
    print('finally');
  }
  callbacks.forEach((callback) => print(callback()));
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['await error', 'finally', 1, 2, 'after']));
    });

    test('collection loops inside statement loops retain outer exit targets', () async {
      const source = '''
void main() {
  for (var outer = 1; outer <= 2; outer++) {
    print(<int>[for (final inner in [1, 2]) outer + inner]);
    try {
      if (outer == 1) continue;
      break;
    } finally {
      print('finally');
    }
  }
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[2, 3]', 'finally', '[3, 4]', 'finally', 'after']));
    });

    test('script iterators construct collection loops through existing protocol', () async {
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
  print(<int>[for (final value in Values()) value]);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['iterator', 'moveNext', 'current', 'moveNext', 'current', 'moveNext', '[1, 2]']),
      );
    });

    test('iterator errors in collection loops execute finally', () async {
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
    print(<int>[for (final value in values) value]);
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

    test('moveNext errors in collection loops execute finally', () async {
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
    print(<int>[for (final value in values) value]);
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

    test('current errors in collection loops execute finally', () async {
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
    print(<int>[for (final value in values) value]);
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

    test('for-in collection patterns are rejected before execution', () async {
      const source = '''
void main() {
  print('unreachable');
  print(<int>[for (var [value] in [[1]]) value]);
}
      ''';
      await expectLater(
        () =>
            expectLater(eval(source), throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('pattern')))),
        prints(''),
      );
    });

    test('classic collection patterns are rejected before execution', () async {
      const source = '''
void main() {
  print('unreachable');
  print(<int>[for (var [value] = [1]; value <= 2; value++) value]);
}
      ''';
      await expectLater(
        () =>
            expectLater(eval(source), throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('pattern')))),
        prints(''),
      );
    });

    test('await collection-for is rejected by the compiler', () {
      const source = '''
Future<void> main() async {
  print(<int>[await for (final value in Stream<int>.empty()) value]);
}
      ''';
      final parsed = parseString(content: source);
      final compiler = Compiler(debugLineInfo: parsed.lineInfo);
      final function = parsed.unit.declarations.single as FunctionDeclaration;
      final body = function.functionExpression.body as BlockFunctionBody;
      final statement = body.block.statements.single as ExpressionStatement;
      final invocation = statement.expression as MethodInvocation;
      final literal = invocation.argumentList.arguments.single as ListLiteral;
      expect(
        () => compiler.compile(node: literal.elements.single),
        throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('await for'))),
      );
    });
  });
}
