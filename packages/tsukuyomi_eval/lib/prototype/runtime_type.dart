mixin _Mixin1 {}

mixin _Mixin2 {}

mixin _Mixin12A implements _Mixin1, _Mixin2 {}

mixin _Mixin12B implements _Mixin1, _Mixin2 {}

mixin class _Class1A implements _Mixin1 {}

mixin class _Class1B implements _Mixin1 {}

mixin class _Class2A implements _Mixin2 {}

mixin class _Class2B implements _Mixin2 {}

mixin class _Class12A implements _Mixin12A {}

mixin class _Class12B implements _Mixin12B {}

mixin class _Class12C implements _Mixin1, _Mixin2 {}

mixin class _Class12D implements _Mixin1, _Mixin2 {}

mixin class _Class1$2A implements _Mixin1, _Class2A {}

void testBase() {
  final instance1A = _Class1A();
  final instance1B = _Class1B();
  final instance2A = _Class2A();
  final instance2B = _Class2B();
  final instance12A = _Class12A();
  final instance12B = _Class12B();
  final instance12C = _Class12C();
  final instance12D = _Class12D();
  final instance1$2A = _Class1$2A();

  assert(instance1A is _Mixin1);
  assert(instance1B is _Mixin1);
  assert(instance2A is! _Mixin1);
  assert(instance2B is! _Mixin1);
  assert(instance12A is _Mixin1);
  assert(instance12B is _Mixin1);
  assert(instance12C is _Mixin1);
  assert(instance12D is _Mixin1);
  assert(instance1$2A is _Mixin1);

  assert(instance1A is! _Mixin2);
  assert(instance1B is! _Mixin2);
  assert(instance2A is _Mixin2);
  assert(instance2B is _Mixin2);
  assert(instance12A is _Mixin2);
  assert(instance12B is _Mixin2);
  assert(instance12C is _Mixin2);
  assert(instance12D is _Mixin2);
  assert(instance1$2A is _Mixin2);

  assert(instance1A is! _Mixin12A);
  assert(instance1B is! _Mixin12A);
  assert(instance2A is! _Mixin12A);
  assert(instance2B is! _Mixin12A);
  assert(instance12A is _Mixin12A);
  assert(instance12B is! _Mixin12A);
  assert(instance12C is! _Mixin12A);
  assert(instance12D is! _Mixin12A);
  assert(instance1$2A is! _Mixin12A);

  assert(instance1A is! _Mixin12B);
  assert(instance1B is! _Mixin12B);
  assert(instance2A is! _Mixin12B);
  assert(instance2B is! _Mixin12B);
  assert(instance12A is! _Mixin12B);
  assert(instance12B is _Mixin12B);
  assert(instance12C is! _Mixin12B);
  assert(instance12D is! _Mixin12B);
  assert(instance1$2A is! _Mixin12B);

  assert(instance1A is _Class1A);
  assert(instance1B is! _Class1A);
  assert(instance2A is! _Class1A);
  assert(instance2B is! _Class1A);
  assert(instance12A is! _Class1A);
  assert(instance12B is! _Class1A);
  assert(instance12C is! _Class1A);
  assert(instance12D is! _Class1A);
  assert(instance1$2A is! _Class1A);

  assert(instance1A is! _Class1B);
  assert(instance1B is _Class1B);
  assert(instance2A is! _Class1B);
  assert(instance2B is! _Class1B);
  assert(instance12A is! _Class1B);
  assert(instance12B is! _Class1B);
  assert(instance12C is! _Class1B);
  assert(instance12D is! _Class1B);
  assert(instance1$2A is! _Class1B);

  assert(instance1A is! _Class2A);
  assert(instance1B is! _Class2A);
  assert(instance2A is _Class2A);
  assert(instance2B is! _Class2A);
  assert(instance12A is! _Class2A);
  assert(instance12B is! _Class2A);
  assert(instance12C is! _Class2A);
  assert(instance12D is! _Class2A);
  assert(instance1$2A is _Class2A);

  assert(instance1A is! _Class2B);
  assert(instance1B is! _Class2B);
  assert(instance2A is! _Class2B);
  assert(instance2B is _Class2B);
  assert(instance12A is! _Class2B);
  assert(instance12B is! _Class2B);
  assert(instance12C is! _Class2B);
  assert(instance12D is! _Class2B);
  assert(instance1$2A is! _Class2B);

  assert(instance1A is! _Class12A);
  assert(instance1B is! _Class12A);
  assert(instance2A is! _Class12A);
  assert(instance2B is! _Class12A);
  assert(instance12A is _Class12A);
  assert(instance12B is! _Class12A);
  assert(instance12C is! _Class12A);
  assert(instance12D is! _Class12A);
  assert(instance1$2A is! _Class12A);

  assert(instance1A is! _Class12B);
  assert(instance1B is! _Class12B);
  assert(instance2A is! _Class12B);
  assert(instance2B is! _Class12B);
  assert(instance12A is! _Class12B);
  assert(instance12B is _Class12B);
  assert(instance12C is! _Class12B);
  assert(instance12D is! _Class12B);
  assert(instance1$2A is! _Class12B);

  assert(instance1A is! _Class12C);
  assert(instance1B is! _Class12C);
  assert(instance2A is! _Class12C);
  assert(instance2B is! _Class12C);
  assert(instance12A is! _Class12C);
  assert(instance12B is! _Class12C);
  assert(instance12C is _Class12C);
  assert(instance12D is! _Class12C);
  assert(instance1$2A is! _Class12C);

  assert(instance1A is! _Class12D);
  assert(instance1B is! _Class12D);
  assert(instance2A is! _Class12D);
  assert(instance2B is! _Class12D);
  assert(instance12A is! _Class12D);
  assert(instance12B is! _Class12D);
  assert(instance12C is! _Class12D);
  assert(instance12D is _Class12D);
  assert(instance1$2A is! _Class12D);

  assert(instance1A is! _Class1$2A);
  assert(instance1B is! _Class1$2A);
  assert(instance2A is! _Class1$2A);
  assert(instance2B is! _Class1$2A);
  assert(instance12A is! _Class1$2A);
  assert(instance12B is! _Class1$2A);
  assert(instance12C is! _Class1$2A);
  assert(instance12D is! _Class1$2A);
  assert(instance1$2A is _Class1$2A);
}

mixin _$ {}

mixin _0<T> {}

mixin _1<T> {}

mixin _0$<T> implements _0<T>, _$ {}

mixin _1$<T> implements _1<T>, _$ {}

mixin _01<T1, T2> implements _0<T1>, _1<T2> {}

mixin _01$<T1, T2> implements _0$<T1>, _1$<T2> {}

mixin _Mixin<T> {}

class _Class<T> with _Mixin<T> {}

void testEval() {
  // 0$
  mixin1() => _Class<_0<_$>>();

  // 1$
  mixin2() => _Class<_1<_$>>();

  // 0$
  // 1$
  // 10$
  mixin12A() => _Class<_01<_$, _0$<_$>>>();

  // 0$
  // 1$
  // 11$
  mixin12B() => _Class<_01<_$, _1$<_$>>>();

  // 0$
  // 100$
  class1A() => _Class<_01<_$, _0<_0<_$>>>>();

  // 0$
  // 101$
  class1B() => _Class<_01<_$, _0<_1<_$>>>>();

  // 1$
  // 110$
  class2A() => _Class<_1<_1$<_0<_$>>>>();

  // 1$
  // 111$
  class2B() => _Class<_1<_1$<_1<_$>>>>();

  // 0$
  // 1$
  // 10$
  // 1000$
  class12A() => _Class<_01<_$, _0$<_0$<_0<_$>>>>>();

  // 0$
  // 1$
  // 11$
  // 1001$
  class12B() => _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>();

  // 0$
  // 1$
  // 1010$
  class12C() => _Class<_01<_$, _0$<_1<_0<_$>>>>>();

  // 0$
  // 1$
  // 1011$
  class12D() => _Class<_01<_$, _0$<_1<_1<_$>>>>>();

  // 0$
  // 1$
  // 110$
  // 1100$
  class1$2A() => _Class<_01<_$, _1$<_0<_0$<_$>>>>>();

  final instance1A = class1A();
  final instance1B = class1B();
  final instance2A = class2A();
  final instance2B = class2B();
  final instance12A = class12A();
  final instance12B = class12B();
  final instance12C = class12C();
  final instance12D = class12D();
  final instance1$2A = class1$2A();

  assert(mixin1() is _Mixin<_0<_$>>);
  assert(instance1A is _Mixin<_0<_$>>);
  assert(instance1B is _Mixin<_0<_$>>);
  assert(instance2A is! _Mixin<_0<_$>>);
  assert(instance2B is! _Mixin<_0<_$>>);
  assert(instance12A is _Mixin<_0<_$>>);
  assert(instance12B is _Mixin<_0<_$>>);
  assert(instance12C is _Mixin<_0<_$>>);
  assert(instance12D is _Mixin<_0<_$>>);
  assert(instance1$2A is _Mixin<_0<_$>>);

  assert(mixin2() is _Mixin<_1<_$>>);
  assert(instance1A is! _Mixin<_1<_$>>);
  assert(instance1B is! _Mixin<_1<_$>>);
  assert(instance2A is _Mixin<_1<_$>>);
  assert(instance2B is _Mixin<_1<_$>>);
  assert(instance12A is _Mixin<_1<_$>>);
  assert(instance12B is _Mixin<_1<_$>>);
  assert(instance12C is _Mixin<_1<_$>>);
  assert(instance12D is _Mixin<_1<_$>>);
  assert(instance1$2A is _Mixin<_1<_$>>);

  assert(mixin12A() is _Mixin<_01<_$, _0$<_$>>>);
  assert(instance1A is! _Mixin<_01<_$, _0$<_$>>>);
  assert(instance1B is! _Mixin<_01<_$, _0$<_$>>>);
  assert(instance2A is! _Mixin<_01<_$, _0$<_$>>>);
  assert(instance2B is! _Mixin<_01<_$, _0$<_$>>>);
  assert(instance12A is _Mixin<_01<_$, _0$<_$>>>);
  assert(instance12B is! _Mixin<_01<_$, _0$<_$>>>);
  assert(instance12C is! _Mixin<_01<_$, _0$<_$>>>);
  assert(instance12D is! _Mixin<_01<_$, _0$<_$>>>);
  assert(instance1$2A is! _Mixin<_01<_$, _0$<_$>>>);

  assert(mixin12B() is _Mixin<_01<_$, _1$<_$>>>);
  assert(instance1A is! _Mixin<_01<_$, _1$<_$>>>);
  assert(instance1B is! _Mixin<_01<_$, _1$<_$>>>);
  assert(instance2A is! _Mixin<_01<_$, _1$<_$>>>);
  assert(instance2B is! _Mixin<_01<_$, _1$<_$>>>);
  assert(instance12A is! _Mixin<_01<_$, _1$<_$>>>);
  assert(instance12B is _Mixin<_01<_$, _1$<_$>>>);
  assert(instance12C is! _Mixin<_01<_$, _1$<_$>>>);
  assert(instance12D is! _Mixin<_01<_$, _1$<_$>>>);
  assert(instance1$2A is! _Mixin<_01<_$, _1$<_$>>>);

  assert(class1A() is _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance1A is _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance1B is! _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance2A is! _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance2B is! _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance12A is! _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance12B is! _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance12C is! _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance12D is! _Class<_01<_$, _0<_0<_$>>>>);
  assert(instance1$2A is! _Class<_01<_$, _0<_0<_$>>>>);

  assert(class1B() is _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance1A is! _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance1B is _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance2A is! _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance2B is! _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance12A is! _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance12B is! _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance12C is! _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance12D is! _Class<_01<_$, _0<_1<_$>>>>);
  assert(instance1$2A is! _Class<_01<_$, _0<_1<_$>>>>);

  assert(class2A() is _Class<_1<_1$<_0<_$>>>>);
  assert(instance1A is! _Class<_1<_1$<_0<_$>>>>);
  assert(instance1B is! _Class<_1<_1$<_0<_$>>>>);
  assert(instance2A is _Class<_1<_1$<_0<_$>>>>);
  assert(instance2B is! _Class<_1<_1$<_0<_$>>>>);
  assert(instance12A is! _Class<_1<_1$<_0<_$>>>>);
  assert(instance12B is! _Class<_1<_1$<_0<_$>>>>);
  assert(instance12C is! _Class<_1<_1$<_0<_$>>>>);
  assert(instance12D is! _Class<_1<_1$<_0<_$>>>>);
  assert(instance1$2A is _Class<_1<_1$<_0<_$>>>>);

  assert(class2B() is _Class<_1<_1$<_1<_$>>>>);
  assert(instance1A is! _Class<_1<_1$<_1<_$>>>>);
  assert(instance1B is! _Class<_1<_1$<_1<_$>>>>);
  assert(instance2A is! _Class<_1<_1$<_1<_$>>>>);
  assert(instance2B is _Class<_1<_1$<_1<_$>>>>);
  assert(instance12A is! _Class<_1<_1$<_1<_$>>>>);
  assert(instance12B is! _Class<_1<_1$<_1<_$>>>>);
  assert(instance12C is! _Class<_1<_1$<_1<_$>>>>);
  assert(instance12D is! _Class<_1<_1$<_1<_$>>>>);
  assert(instance1$2A is! _Class<_1<_1$<_1<_$>>>>);

  assert(class12A() is _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance1A is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance1B is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance2A is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance2B is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance12A is _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance12B is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance12C is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance12D is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);
  assert(instance1$2A is! _Class<_01<_$, _0$<_0$<_0<_$>>>>>);

  assert(class12B() is _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance1A is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance1B is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance2A is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance2B is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance12A is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance12B is _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance12C is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance12D is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);
  assert(instance1$2A is! _Class<_01<_$, _01$<_0<_1<_$>>, _$>>>);

  assert(class12C() is _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance1A is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance1B is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance2A is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance2B is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance12A is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance12B is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance12C is _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance12D is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);
  assert(instance1$2A is! _Class<_01<_$, _0$<_1<_0<_$>>>>>);

  assert(class12D() is _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance1A is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance1B is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance2A is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance2B is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance12A is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance12B is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance12C is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance12D is _Class<_01<_$, _0$<_1<_1<_$>>>>>);
  assert(instance1$2A is! _Class<_01<_$, _0$<_1<_1<_$>>>>>);

  assert(class1$2A() is _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance1A is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance1B is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance2A is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance2B is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance12A is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance12B is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance12C is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance12D is! _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
  assert(instance1$2A is _Class<_01<_$, _1$<_0<_0$<_$>>>>>);
}

mixin _$1<T1> implements _$ {}

mixin _$2<T1, T2> implements _$ {}

mixin _$3<T1, T2, T3> implements _$ {}

mixin _0$1<T1, T2> implements _0<T1>, _$1<T2> {}

mixin _1$1<T1, T2> implements _1<T1>, _$1<T2> {}

mixin _1$2<T1, T2, T3> implements _1<T1>, _$2<T2, T3> {}

mixin _1$3<T1, T2, T3, T4> implements _1<T1>, _$3<T2, T3, T4> {}

mixin _01$1<T1, T2, T3> implements _0$1<T1, T3>, _1$1<T2, T3> {}

void testGeneric() {
  // 0$
  // 1$1<Object>
  // 10$2<int, double>
  // 11$3<Set, Map, List>
  _Class<_01<_$, _01$1<_$2<int, double>, _$3<Set, Map, List>, Object>>>;
}

void main() {
  testBase();
  testEval();
  testGeneric();
}
