part of declaration.dart.core;

DartClass get _$StackTrace => DartClass<StackTrace>(($) => '''
abstract interface class StackTrace {
  StackTrace();

  // ${$.empty('StackTrace.empty', () => StackTrace.empty)}
  static const empty = const _StringStackTrace("");

  // ${$.empty('StackTrace.fromString', () => StackTrace.fromString)}
  factory StackTrace.fromString(String stackTraceString) = _StringStackTrace;

  // ${$.empty('StackTrace.current', () => StackTrace.current)}
  external static StackTrace get current;

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();
}

class _StringStackTrace implements StackTrace {
  final String _stackTrace;
  const _StringStackTrace(this._stackTrace);
  String toString() => _stackTrace;
}
''');

List<DartDeclaration> get $stacktrace {
  return [
    _$StackTrace,
  ];
}
