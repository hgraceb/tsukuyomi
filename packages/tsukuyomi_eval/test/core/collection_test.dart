import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Collection elements', () {
    test('list spread mixes ordinary empty and expanded elements', () async {
      const source = '''
void main() {
  print(<int>[0, ...[1, 2], ...<int>[], 3]);
  print(<int>[...[1], ...[2, 3]]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[0, 1, 2, 3]', '[1, 2, 3]']));
    });

    test('set spread deduplicates while preserving insertion order', () async {
      const source = '''
void main() {
  print(<int>{1, ...[2, 1], ...{3, 2}, ...<int>[]});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{1, 2, 3}']));
    });

    test('map spread overwrites values without moving existing keys', () async {
      const source = '''
void main() {
  print(<String, int>{'first': 1, ...{'first': 2, 'second': 2}, 'third': 3, ...<String, int>{}, 'first': 3});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{first: 3, second: 2, third: 3}']));
    });

    test('list conditions include only the selected branch', () async {
      const source = '''
void main() {
  print(<int>[if (false) 1, 2, if (true) 3]);
  print(<int>[if (true) 1 else 2, if (false) 1 else 2]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[2, 3]', '[1, 2]']));
    });

    test('set conditions and duplicate values preserve set semantics', () async {
      const source = '''
void main() {
  print(<int>{if (true) 1 else 2, if (false) 2, 1, if (false) 2 else 3});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{1, 3}']));
    });

    test('map conditions emit complete entries and selected overrides', () async {
      const source = '''
void main() {
  print(<String, int>{if (false) 'skip': 1, 'first': 1, if (true) 'first': 2 else 'skip': 3, if (false) 'skip': 2 else 'second': 3});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{first: 2, second: 3}']));
    });

    test('nested conditions bind else to the correct branch', () async {
      const source = '''
void main() {
  print(<int>[if (true) if (false) 1 else 2, if (false) if (true) 1 else 2 else 3]);
  print(<String, int>{if (true) if (false) 'skip': 1 else 'first': 2, if (false) 'skip': 2 else if (true) 'second': 3});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[2, 3]', '{first: 2, second: 3}']));
    });

    test('conditions can select spreads of different lengths', () async {
      const source = '''
void main() {
  print(<int>[if (true) ...[1, 2] else ...[3], if (false) ...[1] else ...[3]]);
  print(<int>{if (true) ...[1, 2] else ...[3], if (false) ...[1] else ...[3]});
  print(<String, int>{if (true) ...{'first': 1, 'second': 2} else ...{'skip': 3}});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2, 3]', '{1, 2, 3}', '{first: 1, second: 2}']));
    });

    test('null aware list and set spreads skip null sources', () async {
      const source = '''
void main() {
  List<int>? values;
  print(<int>[1, ...?values, 2]);
  print(<int>{1, ...?values, 2});
  values = [2, 3];
  print(<int>[1, ...?values]);
  print(<int>{1, ...?values});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '{1, 2}', '[1, 2, 3]', '{1, 2, 3}']));
    });

    test('null aware map spreads skip null and overwrite when present', () async {
      const source = '''
void main() {
  Map<String, int>? values;
  print(<String, int>{'first': 1, ...?values});
  values = {'first': 2, 'second': 3};
  print(<String, int>{'first': 1, ...?values});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{first: 1}', '{first: 2, second: 3}']));
    });

    test('null aware spread expressions are still evaluated once', () async {
      const source = '''
List<int>? values() {
  print('source');
  return null;
}
Map<String, int>? entries() {
  print('map source');
  return null;
}
void main() {
  print(<int>[1, ...?values(), 2]);
  print(<String, int>{...?entries(), 'first': 1});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['source', '[1, 2]', 'map source', '{first: 1}']));
    });

    test('skipped branches do not evaluate their expressions or map keys', () async {
      const source = '''
int value() {
  print('unreachable value');
  return 1;
}
String key() {
  print('unreachable key');
  return 'skip';
}
void main() {
  print(<int>[if (false) value(), if (true) 2 else value()]);
  print(<String, int>{if (false) key(): value(), if (true) 'first': 2 else key(): value()});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[2]', '{first: 2}']));
    });

    test('literal and condition evaluation follows source order', () async {
      const source = '''
int value(int value) {
  print(value);
  return value;
}
bool condition() {
  print('condition');
  return true;
}
List<int> values() {
  print('spread');
  return [2];
}
void main() {
  print(<int>[value(1), if (condition()) ...values(), value(3)]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 'condition', 'spread', 3, '[1, 2, 3]']));
    });

    test('map key evaluation precedes its value and spread source', () async {
      const source = '''
String key(String key) {
  print(key);
  return key;
}
int value(int value) {
  print(value);
  return value;
}
Map<String, int> values() {
  print('spread');
  return {'second': 2};
}
void main() {
  print(<String, int>{key('first'): value(1), ...values(), key('third'): value(3)});
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['first', 1, 'spread', 'third', 3, '{first: 1, second: 2, third: 3}']),
      );
    });

    test('lazy spread iterates once before evaluating the next element', () async {
      const source = '''
void main() {
  final values = [1, 2].map((value) {
    print(value);
    return value;
  });
  int last() {
    print('last');
    return 3;
  }
  print(<int>[...values, last()]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 'last', '[1, 2, 3]']));
    });

    test('dynamic iterable elements are checked individually for typed collections', () async {
      const source = '''
void main() {
  dynamic values = <dynamic>[1, 2];
  print(<int>[...values]);
  print(<int>{...values});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '{1, 2}']));
    });

    test('dynamic map keys and values are checked individually', () async {
      const source = '''
void main() {
  dynamic values = <dynamic, dynamic>{'first': 1, 'second': 2};
  print(<String, int>{...values});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['{first: 1, second: 2}']));
    });

    test('nested literals keep independent construction state', () async {
      const source = '''
void main() {
  print(<dynamic>[<int>[1, ...[2]], if (true) <int>{...{2}, 3}, <String, int>{if (true) 'first': 1, ...{'second': 2}}]);
  print(<String, dynamic>{'values': <int>[if (true) ...[1, 2]], if (true) ...<String, dynamic>{'other': <int>{1, 2}}});
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['[[1, 2], {2, 3}, {first: 1, second: 2}]', '{values: [1, 2], other: {1, 2}}']),
      );
    });

    test('collection construction preserves surrounding arguments and locals', () async {
      const source = r'''
String join(String before, Object values, String after) => '$before/$values/$after';
void main() {
  print(join('before', <int>[if (true) ...[1, 2]], 'after'));
  final first = <String, int>{if (false) 'skip': 1, ...{'first': 1}};
  var next = 'next';
  print(first);
  print(next);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['before/[1, 2]/after', '{first: 1}', 'next']));
    });

    test('constructed collections keep their declared types and remain growable', () async {
      const source = '''
void main() {
  final values = <int>[...[1], if (true) 2];
  final items = <int>{...[1], if (true) 2};
  final entries = <String, int>{...{'first': 1}};
  values.add(3);
  items.add(3);
  entries['second'] = 2;
  print(values.runtimeType.toString().contains('<int>'));
  print(items.runtimeType.toString().contains('<int>'));
  print(entries.runtimeType.toString().contains('<String, int>'));
  print(values);
  print(items);
  print(entries);
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([true, true, true, '[1, 2, 3]', '{1, 2, 3}', '{first: 1, second: 2}']),
      );
    });

    test('spread copies elements into an independent collection', () async {
      const source = '''
void main() {
  final source = [1, 2];
  final values = <int>[...source];
  final map = {'first': 1};
  final entries = <String, int>{...map};
  source.add(3);
  map['second'] = 2;
  print(values);
  print(entries);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '{first: 1}']));
    });

    test('conditions resume after await without losing the collection', () async {
      const source = '''
Future<bool> condition() async {
  print('condition');
  await null;
  return true;
}
Future<void> main() async {
  print(<int>[1, if (await condition()) 2 else 3]);
  print(<String, int>{'first': 1, if (await condition()) 'second': 2});
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['condition', '[1, 2]', 'condition', '{first: 1, second: 2}']),
      );
    });

    test('spread sources and ordinary elements resume after await', () async {
      const source = '''
Future<List<int>> values() async {
  print('source');
  await null;
  return [1, 2];
}
Future<int> last() async {
  await null;
  return 3;
}
Future<void> main() async {
  print(<int>[...await values(), await last()]);
  print(<int>{...await values(), await last()});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['source', '[1, 2, 3]', 'source', '{1, 2, 3}']));
    });

    test('map keys values and spread sources can await independently', () async {
      const source = '''
Future<String> key() async {
  print('key');
  await null;
  return 'first';
}
Future<int> value() async {
  print('value');
  await null;
  return 1;
}
Future<Map<String, int>> entries() async {
  print('spread');
  await null;
  return {'second': 2};
}
Future<void> main() async {
  print(<String, int>{await key(): await value(), ...await entries()});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['key', 'value', 'spread', '{first: 1, second: 2}']));
    });

    test('null aware awaited spreads skip null but continue later elements', () async {
      const source = '''
Future<List<int>?> values() async {
  print('source');
  await null;
  return null;
}
Future<void> main() async {
  print(<int>[1, ...?await values(), 2]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['source', '[1, 2]']));
    });

    test('host callbacks can build nested collections and return normally', () async {
      const source = '''
void main() {
  final values = [1, 2].map((value) => <int>[value, if (true) ...[value + 1]]);
  values.forEach((value) => print(value));
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['[1, 2]', '[2, 3]', 'after']));
    });

    test('lazy iteration errors stop before the next element and execute finally', () async {
      const source = '''
void main() {
  final values = [1, 2, 3].map((value) {
    print(value);
    if (value == 2) throw 'iterator';
    return value;
  });
  int last() {
    print('unreachable');
    return 3;
  }
  try {
    print(<int>[...values, last()]);
  } catch (error) {
    print(error);
  } finally {
    print('finally');
  }
  print(<int>[...[1, 2]]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([1, 2, 'iterator', 'finally', '[1, 2]']));
    });

    test('awaited element errors preserve catch and finally state', () async {
      const source = '''
Future<int> fail() async {
  await null;
  throw 'element';
}
Future<void> main() async {
  try {
    print(<int>[1, if (true) await fail(), 3]);
  } catch (error) {
    print(error);
  } finally {
    await null;
    print('finally');
  }
  var after = 'after';
  print(after);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['element', 'finally', 'after']));
    });

    test('map value errors do not evaluate later entries', () async {
      const source = '''
void main() {
  String key() {
    print('key');
    return 'first';
  }
  int value() => throw 'value';
  String last() {
    print('unreachable');
    return 'last';
  }
  try {
    print(<String, int>{key(): value(), last(): 3});
  } catch (error) {
    print(error);
  }
  print(<String, int>{...{'after': 1}});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['key', 'value', '{after: 1}']));
    });

    test('invalid ordinary elements fail before later side effects', () async {
      const source = '''
int last() {
  print('unreachable');
  return 2;
}
void main() {
  dynamic invalid = 'invalid';
  try {
    print(<int>[invalid, last()]);
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true]));
    });

    test('invalid spread elements fail at the first incompatible element', () async {
      const source = '''
void main() {
  dynamic values = <dynamic>[1, 'invalid', 3];
  int last() {
    print('unreachable');
    return 3;
  }
  try {
    print(<int>[...values, last()]);
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
  try {
    print(<int>{...values, last()});
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true, true]));
    });

    test('invalid map key and value types stop before later entries', () async {
      const source = '''
void main() {
  dynamic keys = <dynamic, dynamic>{1: 1};
  dynamic values = <dynamic, dynamic>{'first': 'invalid'};
  String last() {
    print('unreachable');
    return 'last';
  }
  try {
    print(<String, int>{...keys, last(): 2});
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
  try {
    print(<String, int>{...values, last(): 2});
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true, true]));
    });

    test('non iterable spread sources fail before later side effects', () async {
      const source = '''
void main() {
  dynamic invalid = 1;
  int last() {
    print('unreachable');
    return 2;
  }
  try {
    print(<int>[...invalid, last()]);
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
  try {
    print(<int>{...?invalid, last()});
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true, true]));
    });

    test('ordinary null spreads fail while null aware spreads skip', () async {
      const source = '''
void main() {
  dynamic values = null;
  try {
    print(<int>[...values]);
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
  try {
    print(<String, int>{...values});
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
  print(<int>[...?values]);
  print(<String, int>{...?values});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true, true, '[]', '{}']));
    });

    test('non map sources cannot be spread into maps', () async {
      const source = '''
void main() {
  dynamic values = [1, 2];
  try {
    print(<String, int>{...values});
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  }
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println([true]));
    });

    test('script iterator spreads preserve protocol calls and typed output', () async {
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
  print(<int>[...Values()]);
  print(<int>{...Values()});
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println([
          'iterator',
          'moveNext',
          'current',
          'moveNext',
          'current',
          'moveNext',
          '[1, 2]',
          'iterator',
          'moveNext',
          'current',
          'moveNext',
          'current',
          'moveNext',
          '{1, 2}',
        ]),
      );
    });

    test('iterator failures in spreads execute enclosing finally', () async {
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
    print(<int>[...values]);
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

    test('moveNext failures in spreads execute enclosing finally', () async {
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
    print(<int>[...values]);
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

    test('current failures in spreads execute enclosing finally', () async {
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
    print(<int>[...values]);
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

    test('script map spreads use forEach instead of entries', () async {
      const source = '''
class Values implements Map<String, int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  Iterable<MapEntry<String, int>> get entries => throw 'unused entries';
  void forEach(Function action) {
    print('forEach');
    action('first', 1);
    action('second', 2);
  }
}
void main() {
  print(<String, int>{...Values()});
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['forEach', '{first: 1, second: 2}']));
    });

    test('script map enumeration errors execute inner and outer finally', () async {
      const source = '''
class Values implements Map<String, int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  void forEach(Function action) {
    try {
      action('first', 1);
      throw 'map error';
    } finally {
      print('source finally');
    }
  }
}
void main() {
  try {
    print(<String, int>{...Values()});
  } catch (error) {
    print(error);
  } finally {
    print('outer finally');
  }
  print(<String, int>{...{'after': 2}});
}
      ''';
      await expectLater(
        () => expectLater(eval(source), completion(isNull)),
        println(['source finally', 'map error', 'outer finally', '{after: 2}']),
      );
    });

    test('script map callback type errors stop enumeration and execute finally', () async {
      const source = '''
class Values implements Map<String, int> {
  dynamic noSuchMethod(Invocation invocation) => throw 'unused';
  void forEach(Function action) {
    try {
      action('first', 1);
      action('second', 'invalid');
      print('unreachable');
    } finally {
      print('source finally');
    }
  }
}
void main() {
  try {
    print(<String, int>{...Values()});
  } catch (error) {
    print(error.runtimeType.toString().contains('TypeError'));
  } finally {
    print('outer finally');
  }
  print('after');
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['source finally', true, 'outer finally', 'after']));
    });

    test('spread operands are evaluated once even with script getters', () async {
      const source = '''
class Holder {
  Iterable<int> get values {
    print('getter');
    return [1, 2];
  }
}
void main() {
  print(<int>[...Holder().values]);
}
      ''';
      await expectLater(() => expectLater(eval(source), completion(isNull)), println(['getter', '[1, 2]']));
    });

    test('collection if-case is rejected before execution', () async {
      const source = '''
void main() {
  print('unreachable');
  print([if (1 case int value) value]);
}
      ''';
      await expectLater(
        () => expectLater(
          eval(source),
          throwsA(isA<EvalCompileError>().having((error) => error.toString(), 'message', contains('collection-if'))),
        ),
        prints(''),
      );
    });
  });
}
