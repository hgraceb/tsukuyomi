import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
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
