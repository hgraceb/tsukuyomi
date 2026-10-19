// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host invocation arguments', () {
    test('omitted optional positional arguments use defaults for null and empty lists', () async {
      const source = '''
class Example {
  int read([int value = 1]) => value;
}

dynamic main() {
  print(Example().read());
  return Example();
}
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(instance.invoke('read', null));
        print(instance.invoke('read', []));
        print(instance.invoke('read', [0]));
        print(instance.invoke('read', []));
      }, println([1, 1, 1, 0, 1]));
    });

    test('required and optional parameters keep their declaration order', () async {
      const source = '''
class Example {
  dynamic read(String required, [String value = 'default', String? last]) => <dynamic>[required, value, last];
}

dynamic main() => Example();
      ''';
      await expectLater(
        () async {
          final instance = await eval(source) as ObjInstance;
          print(instance.invoke('read', ['required']));
          print(instance.invoke('read', ['required', 'provided']));
          print(instance.invoke('read', ['required', 'provided', 'last']));
        },
        println([
          ['required', 'default', null],
          ['required', 'provided', null],
          ['required', 'provided', 'last'],
        ]),
      );
    });

    test('explicit null is preserved instead of replaced by a default', () async {
      const source = '''
class Example {
  String? read([String? value = 'default']) => value;
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(instance.invoke('read', []));
        print(instance.invoke('read', [null]));
        print(instance.invoke('read', ['provided']));
      }, println(['default', null, 'provided']));
    });

    test('missing required parameters report the declaration and allow later calls', () async {
      const source = '''
class Example {
  String read(String value, [String suffix = 'default']) => '\$value:\$suffix';
}

dynamic main() => Example();
      ''';
      final instance = await eval(source) as ObjInstance;
      for (final arguments in <List<dynamic>?>[null, []]) {
        await expectLater(
          () => instance.invoke('read', arguments),
          throwsA(
            isA<EvalRuntimeError>().having(
              (error) => error.toString(),
              'message',
              "EvalRuntimeError: Positional parameter 'value' is required for function 'Example.read'.",
            ),
          ),
        );
      }
      await expectLater(() => print(instance.invoke('read', ['required'])), println(['required:default']));
    });

    test('inherited methods use defaults with the actual receiver', () async {
      const source = '''
class Parent {
  int count = 0;
  int read([int value = 1]) => count += value;
}
class Child extends Parent {}

dynamic main() => <dynamic>[Child(), Child()];
      ''';
      await expectLater(() async {
        final instances = await eval(source) as List;
        final first = instances.first as ObjInstance;
        final second = instances.last as ObjInstance;
        print(first.invoke('read', []));
        print(first.invoke('read', [0]));
        print(second.invoke('read', null));
        print(first.get('count'));
      }, println([1, 1, 1, 1]));
    });

    test('async methods retain default parameters across await', () async {
      const source = '''
class Example {
  Future<int> read([int value = 1]) async {
    await null;
    return value;
  }
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(await instance.invoke('read', []));
        print(await instance.invoke('read', [0]));
        print(await instance.invoke('read', null));
      }, println([1, 0, 1]));
    });

    test('omitted named parameters use defaults without expanding the host API', () async {
      const source = '''
class Example {
  String read({String value = 'default'}) => value;
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(instance.invoke('read', []));
        print(instance.invoke('read', null));
      }, println(['default', 'default']));
    });

    test('getter-returned closures receive defaults through the same host entry', () async {
      const source = '''
class Example {
  dynamic get callback => ([int value = 1]) => value;
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(instance.invoke('callback', []));
        print(instance.invoke('callback', [0]));
      }, println([1, 0]));
    });

    test('compute-transferred instances keep optional argument defaults', () async {
      const source = '''
class Example {
  int read([int value = 1]) => value;
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await compute((source) => eval(source), source) as ObjInstance;
        print(instance.invoke('read', null));
        print(await compute((instance) => instance.invoke('read', []), instance));
      }, println([1, 1]));
    });
  });
}
