part of declaration.dio.core;

DartClass get _$Response => DartClass<Response>(($) => '''
class Response<T> {
  external Response._();

  // ${$.debug('data', ($, $$) => $.data)}
  T? data;

  // ${$.debug('requestOptions', ($, $$) => $.requestOptions)}
  RequestOptions requestOptions;

  // ${$.debug('statusCode', ($, $$) => $.statusCode)}
  int? statusCode;

  // ${$.debug('statusMessage', ($, $$) => $.statusMessage)}
  String? statusMessage;

  // ${$.debug('headers', ($, $$) => $.headers)}
  Headers headers;

  // ${$.debug('isRedirect', ($, $$) => $.isRedirect)}
  bool isRedirect;

  // ${$.debug('redirects', ($, $$) => $.redirects)}
  List<RedirectRecord> redirects;

  // ${$.debug('realUri', ($, $$) => $.realUri)}
  external Uri get realUri;

  // ${$.debug('extra', ($, $$) => $.extra)}
  Map<String, dynamic> extra;

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();
}
''');

List<DartDeclaration> get $response {
  return [
    _$Response,
  ];
}
