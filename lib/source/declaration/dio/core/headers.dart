part of 'core.dart';

DartClass get _$Headers => DartClass<Headers>(($) => '''
class Headers {
  // ${$.empty('Headers.new', () => Headers.new)}
  Headers({this.preserveHeaderCase = false});

  // ${$.empty('Headers.fromMap', () => Headers.fromMap)}
  Headers.fromMap(Map<String, List<String>> map, {this.preserveHeaderCase = false});

  // ${$.empty('Headers.acceptHeader', () => Headers.acceptHeader)}
  static const String acceptHeader = 'accept';

  // ${$.empty('Headers.contentEncodingHeader', () => Headers.contentEncodingHeader)}
  static const String contentEncodingHeader = 'content-encoding';

  // ${$.empty('Headers.contentLengthHeader', () => Headers.contentLengthHeader)}
  static const String contentLengthHeader = 'content-length';

  // ${$.empty('Headers.contentTypeHeader', () => Headers.contentTypeHeader)}
  static const String contentTypeHeader = 'content-type';

  // ${$.empty('Headers.wwwAuthenticateHeader', () => Headers.wwwAuthenticateHeader)}
  static const String wwwAuthenticateHeader = 'www-authenticate';

  // ${$.debug('preserveHeaderCase', ($, $$) => $.preserveHeaderCase)}
  final bool preserveHeaderCase;

  // ${$.debug('map', ($, $$) => $.map)}
  external Map<String, List<String>> get map;

  // ${$.debug('[]', ($, $$) => $[$$])}
  external List<String>? operator [](String name);

  // ${$.debug('value', ($, $$) => $.value)}
  external String? value(String name);

  // ${$.debug('add', ($, $$) => $.add)}
  external void add(String name, String value);

  // ${$.debug('set', ($, $$) => $.set)}
  external void set(String name, dynamic value);

  // ${$.debug('remove', ($, $$) => $.remove)}
  external void remove(String name, String value);

  // ${$.debug('removeAll', ($, $$) => $.removeAll)}
  external void removeAll(String name);

  // ${$.debug('clear', ($, $$) => $.clear)}
  external void clear();

  // ${$.debug('isEmpty', ($, $$) => $.isEmpty)}
  external bool get isEmpty;

  // ${$.debug('forEach', ($, $$) => $.forEach)}
  external void forEach(void Function(String name, List<String> values) f);
}
''');

List<DartDeclaration> get $headers {
  return [
    // Headers.fromMap 的映射字面量需要具体的值类型
    DartClass<List<String>>.type(),
    _$Headers,
  ];
}
