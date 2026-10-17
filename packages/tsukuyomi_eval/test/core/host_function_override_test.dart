import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host function override parameter roles', () {
    for (final split in [false, true]) {
      for (final childFirst in [false, true]) {
        for (final tearOff in [false, true]) {
          for (final descendant in [false, true]) {
            test('split=$split, child-first=$childFirst, tear-off=$tearOff, descendant=$descendant', () async {
              final source =
                  '''
import 'package:function_overrides/${split ? 'child' : 'combined'}.dart';
void main() {
  final value = ({int number = 1}) => number;
  ${tearOff ? 'final convert = child.convert; final result = convert(value);' : 'final result = child.convert(value);'}
  print(result == value);
  print(result(number: 1));
}
              ''';
              final libraries = _libraries(split: split, childFirst: childFirst, descendant: descendant);
              await expectLater(() => eval(source, libraries: libraries), println([true, 1]));
            });
          }
        }
      }
    }

    for (final tearOff in [false, true]) {
      test('parent methods still validate callback signatures, tear-off=$tearOff', () async {
        final source =
            '''
import 'package:function_overrides/child.dart';
import 'package:function_overrides/parent.dart';
void main() {
  dynamic value = ({int number = 1}) => number;
  ${tearOff ? 'final convert = parent.convert; convert(value);' : 'parent.convert(value);'}
}
        ''';
        await expectLater(
          eval(source, libraries: _libraries(split: true, childFirst: true)),
          throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', contains('with named parameters'))),
        );
      });
    }

    for (final isolated in [false, true]) {
      test('cross-library override roles survive a new VM, compute=$isolated', () async {
        final instance = isolated ? await compute(_createInstance, _instanceSource) : await _createInstance(_instanceSource);
        expect(instance.invoke('convert', []), 1);
      });
    }
  });
}

List<DartLibrary> _libraries({required bool split, required bool childFirst, bool descendant = false}) {
  final parent = DartClass<_Parent>(
    ($) =>
        '''
// ${$.alias('Parent')}
class Parent {
  // ${$.debug('convert', ($, $$) => $.convert)}
  external Function convert(int callback(int value));
}
  ''',
  );
  final child = DartClass<_Child>(
    ($) =>
        '''
// ${$.alias('PublicChild')}
class Child extends Parent {
  // ${$.debug('convert', ($, $$) => $.convert)}
  external Function convert(Function value);
}
typedef PublicChild = Child;
class Descendant extends Child {}
  ''',
  );
  final parentValue = DartVariable('parent', _Parent(), 'external Parent get parent;');
  final childValue = DartVariable('child', descendant ? _Descendant() : _Child(), 'external PublicChild get child;');
  if (!split) {
    return [
      DartLibrary(
        'function_overrides',
        path: 'combined.dart',
        declarations: childFirst ? [child, parent, childValue, parentValue] : [parent, child, childValue, parentValue],
      ),
    ];
  }
  final parentLibrary = DartLibrary('function_overrides', path: 'parent.dart', declarations: [parent, parentValue]);
  final childLibrary = DartLibrary(
    'function_overrides',
    path: 'child.dart',
    source: "import 'parent.dart';",
    declarations: [child, childValue],
  );
  return childFirst ? [childLibrary, parentLibrary] : [parentLibrary, childLibrary];
}

Future<ObjInstance> _createInstance(String source) async {
  return await eval(source, libraries: _libraries(split: true, childFirst: true)) as ObjInstance;
}

const _instanceSource = '''
import 'package:function_overrides/child.dart';
class Example {
  dynamic convert() {
    final value = ({int number = 1}) => number;
    return child.convert(value)(number: 1);
  }
}
main() => Example();
''';

class _Parent {
  Function convert(int Function(int) callback) => callback;
}

class _Child extends _Parent {
  @override
  Function convert(Function value) => value;
}

class _Descendant extends _Child {}
