part of declaration.dart.core;

DartClass get _$Exception => DartClass<Exception>(($) => '''
abstract interface class Exception {
  // ${$.empty('Exception.new', () => Exception.new)}
  external factory Exception([var message]);
}
''');

DartClass get _$FormatException => DartClass<FormatException>(($) => '''
class FormatException implements Exception {
  // ${$.debug('message', ($, $$) => $.message)}
  final String message;

  // ${$.debug('source', ($, $$) => $.source)}
  final dynamic source;

  // ${$.debug('offset', ($, $$) => $.offset)}
  final int? offset;

  // ${$.empty('FormatException.new', () => FormatException.new)}
  const FormatException([this.message = "", this.source, this.offset]);

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

List<DartDeclaration> get $exceptions {
  return [
    _$Exception,
    _$FormatException,
  ];
}
