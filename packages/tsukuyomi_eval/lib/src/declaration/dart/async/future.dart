part of declaration.dart.async;

DartClass get _$FutureOr => DartClass<FutureOr<Never>>(($) => '''
abstract class FutureOr<T> {
  FutureOr._();
}
''');

DartClass get _$Future => DartClass<Future>(($) => '''
abstract interface class Future<T> {
  // ${$.empty('Future.new', () => Future.new)}
  external factory Future(FutureOr<T> computation());

  // ${$.empty('Future.microtask', () => Future.microtask)}
  external factory Future.microtask(FutureOr<T> computation());

  // ${$.empty('Future.sync', () => Future.sync)}
  external factory Future.sync(FutureOr<T> computation());

  // ${$.empty('Future.value', () => Future.value)}
  external factory Future.value([FutureOr<T>? value]);

  // ${$.empty('Future.error', () => Future.error)}
  external factory Future.error(Object error, [StackTrace? stackTrace]);

  // ${$.empty('Future.delayed', () => Future.delayed)}
  external factory Future.delayed(Duration duration, [FutureOr<T> computation()?]);

  // ${$.empty('Future.wait', () => Future.wait)}
  external static Future<List<T>> wait<T>(Iterable<Future<T>> futures, {bool eagerError = false, void cleanUp(T successValue)?});

  // ${$.empty('Future.any', () => Future.any)}
  external static Future<T> any<T>(Iterable<Future<T>> futures);

  // ${$.empty('Future.forEach', () => Future.forEach)}
  external static Future<void> forEach<T>(Iterable<T> elements, FutureOr action(T element));

  // ${$.empty('Future.doWhile', () => Future.doWhile)}
  external static Future<void> doWhile(FutureOr<bool> action());

  // ${$.debug('then', ($, $$) => $.then)}
  Future<R> then<R>(FutureOr<R> onValue(T value), {Function? onError});

  // ${$.debug('catchError', ($, $$) => $.catchError)}
  Future<T> catchError(Function onError, {bool test(Object error)?});

  // ${$.debug('whenComplete', ($, $$) => $.whenComplete)}
  Future<T> whenComplete(FutureOr<void> action());

  // ${$.debug('asStream', ($, $$) => $.asStream)}
  Stream<T> asStream();

  // ${$.debug('timeout', ($, $$) => $.timeout)}
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()?});
}
''');

List<DartDeclaration> get $future {
  return [
    _$FutureOr,
    _$Future,
  ];
}
