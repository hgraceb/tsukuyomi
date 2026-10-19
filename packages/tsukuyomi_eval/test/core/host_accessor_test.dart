// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host script accessors', () {
    test('host reads instance getters repeatedly without sharing instance state', () async {
      const source = '''
class Example {
  int value = 0;
  int get count => ++value;
}

dynamic main() => <dynamic>[Example(), Example()];
      ''';
      await expectLater(() async {
        final instances = await eval(source) as List;
        final first = instances.first as ObjInstance;
        final second = instances.last as ObjInstance;
        print(first.get('count'));
        print(second.get('count'));
        print(first.get('count'));
        print(second.get('value'));
      }, println([1, 1, 2, 1]));
    });

    test('host methods execute global static and instance accessors in the calling VM', () async {
      const source = '''
int stored = 0;
int get globalCount => stored;
set globalCount(int value) { stored = value; }

class Example {
  static int stored = 0;
  static int get count => stored;
  static set count(int value) { stored = value; }

  int value = 0;
  int get current => value;
  set current(int value) { this.value = value; }

  dynamic read() {
    final global = globalCount = 1;
    final local = current = globalCount;
    final shared = Example.count = current;
    return <dynamic>[global, local, shared, globalCount, current, Example.count];
  }
}

dynamic main() => Example();
      ''';
      await expectLater(
        () async {
          final instance = await eval(source) as ObjInstance;
          print(instance.invoke('read', []));
          print(instance.invoke('read', null));
        },
        println([
          [1, 1, 1, 1, 1, 1],
          [1, 1, 1, 1, 1, 1],
        ]),
      );
    });

    test('inherited accessors and super retain their receiver', () async {
      const source = '''
class Parent {
  int stored = 0;
  int get value => stored;
  set value(int value) { stored = value; }
}

class Child extends Parent {
  int get value => super.value;
  set value(int value) { super.value = value; }

  int update() => value = 1;
}

dynamic main() => Child();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(instance.get('value'));
        print(instance.invoke('update', []));
        print(instance.get('value'));
        print(instance.get('stored'));
      }, println([0, 1, 1, 1]));
    });

    test('nested getters return function values without calling them', () async {
      const source = '''
class Example {
  int calls = 0;
  int get count => 1;
  int get nested => count;
  dynamic get callback => () { calls++; return nested; };
  dynamic read() {
    final function = callback;
    print(calls);
    return function();
  }
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(instance.get('nested'));
        print(instance.get('callback') is ObjClosure);
        print(instance.get('calls'));
        print(instance.invoke('read', []));
        print(instance.get('calls'));
      }, println([1, true, 0, 0, 1, 1]));
    });

    test('getter and setter failures unwind through the calling method', () async {
      const source = '''
class Example {
  int finalizations = 0;
  int get value => throw 'getter';
  set value(int value) { throw 'setter'; }

  void read() {
    try { print(value); }
    catch (error) { print(error); }
    finally { finalizations++; }
  }

  void write() {
    try { value = 1; }
    catch (error) { print(error); }
    finally { finalizations++; }
  }
}

dynamic main() => Example();
      ''';
      final instance = await eval(source) as ObjInstance;
      await expectLater(() => instance.get('value'), throwsA('getter'));
      await expectLater(() {
        instance.invoke('read', []);
        instance.invoke('write', []);
        print(instance.get('finalizations'));
      }, println(['getter', 'setter', 2]));
      await expectLater(() => instance.get('value'), throwsA('getter'));
    });

    test('async methods resume with working script accessors', () async {
      const source = '''
int get count => 1;
class Example {
  int value = 0;
  int get current => value;
  set current(int value) { this.value = value; }

  Future<int> read() async {
    await null;
    current = count;
    await null;
    return current;
  }
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(await instance.invoke('read', []));
        print(instance.get('current'));
        print(await instance.invoke('read', []));
      }, println([1, 1, 1]));
    });

    test('instances transferred through compute still execute their getters', () async {
      const source = '''
int get count => 1;
class Example {
  int get value => count;
  int read() => value;
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await compute((source) => eval(source), source) as ObjInstance;
        print(instance.get('value'));
        print(instance.invoke('read', []));
        final value = await compute((instance) => instance.get('value'), instance);
        print(value);
      }, println([1, 1, 1]));
    });

    test('host reads asynchronous getters as futures', () async {
      const source = '''
class Example {
  int get count => 1;
  Future<int> get value async {
    await null;
    return count;
  }
}

dynamic main() => Example();
      ''';
      await expectLater(() async {
        final instance = await eval(source) as ObjInstance;
        print(await instance.get('value'));
        print(await instance.get('value'));
      }, println([1, 1]));
    });

    test('recursive getters retain the VM stack overflow guard', () async {
      const source = '''
class Example {
  int get value => value;
  int get count => 1;
}

dynamic main() => Example();
      ''';
      final instance = await eval(source) as ObjInstance;
      await expectLater(
        () => instance.get('value'),
        throwsA(isA<EvalRuntimeError>().having((error) => error.toString(), 'message', 'EvalRuntimeError: Stack overflow.')),
      );
      await expectLater(() => print(instance.get('count')), println([1]));
    });
  });
}
