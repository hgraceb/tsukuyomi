part of declaration.dio.core;

DartClass get _$DioException => DartClass<DioException>(($) => '''
class DioException implements Exception {
  external DioException._();

  // ${$.debug('requestOptions', ($, $$) => $.requestOptions)}
  final RequestOptions requestOptions;

  // ${$.debug('response', ($, $$) => $.response)}
  final Response? response;

  // ${$.debug('type', ($, $$) => $.type)}
  final DioExceptionType type;

  // ${$.debug('error', ($, $$) => $.error)}
  final Object? error;

  // ${$.debug('stackTrace', ($, $$) => $.stackTrace)}
  final StackTrace stackTrace;

  // ${$.debug('message', ($, $$) => $.message)}
  final String? message;

  // ${$.debug('copyWith', ($, $$) => $.copyWith)}
  external DioException copyWith({
    RequestOptions? requestOptions,
    Response? response,
    DioExceptionType? type,
    Object? error,
    StackTrace? stackTrace,
    String? message,
  });

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();
}
''');

List<DartDeclaration> get $dioException {
  return [
    _$DioException,
  ];
}
