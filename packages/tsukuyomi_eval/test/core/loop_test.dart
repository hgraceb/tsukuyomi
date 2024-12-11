import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('For loop', () {
    test('with declaration', () {
      const source = '''
void main() {
  int i = 5;
  for (int i = 1; i < 4; i++) {
    print(i);
  }
  for (int i = 4; i < 5; i++) {
    int i = 2;
    print(i + 2);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with expression', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 4; i++) {
    print(i);
  }
  for (i = 4; i < 5; i++) {
    int i = 2;
    print(i + 2);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with continue', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 10; i++) {
    if (i >= 5) continue;
    print(i);
  }
  print(i - 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with break', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 10; i++) {
    if (i >= 5) break;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with return', () {
      const source = '''
void main() {
  int i;
  for (i = 1; i < 10; i++) {
    if (i > 5) return;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });

  group('While loop', () {
    test('with condition', () {
      const source = '''
void main() {
  int i = 0;
  while (i++ < 5) {
    print(i);
  }
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with continue', () {
      const source = '''
void main() {
  int i = 0;
  while (++i < 10) {
    if (i >= 5) continue;
    print(i);
  }
  print(i - 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with break', () {
      const source = '''
void main() {
  int i = 0;
  while (++i < 10) {
    if (i >= 5) break;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with return', () {
      const source = '''
void main() {
  int i = 0;
  while (++i < 10) {
    if (i > 5) return;
    print(i);
  }
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });

  group('Do-while loop', () {
    test('with condition', () {
      const source = '''
void main() {
  int i = 1;
  do {
    print(i);
  } while (i++ < 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with continue', () {
      const source = '''
void main() {
  int i = 1;
  do {
    if (i >= 5) continue;
    print(i);
  } while (++i < 10);
  print(i - 5);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with break', () {
      const source = '''
void main() {
  int i = 1;
  do {
    if (i >= 5) break;
    print(i);
  } while (++i < 10);
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });

    test('with return', () {
      const source = '''
void main() {
  int i = 1;
  do {
    if (i > 5) return;
    print(i);
  } while (++i < 10);
  print(i);
}
    ''';
      expectLater(() => eval(source), println([1, 2, 3, 4, 5]));
    });
  });
}
