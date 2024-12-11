part of declaration.dart.core;

DartClass get _$Uri => DartClass<Uri>(($) => '''
abstract interface class Uri {
  // ${$.empty('Uri.base', () => Uri.base)}
  external static Uri get base;

  // ${$.empty('Uri.new', () => Uri.new)}
  external factory Uri({
    String? scheme,
    String? userInfo,
    String? host,
    int? port,
    String? path,
    Iterable<String>? pathSegments,
    String? query,
    Map<String, dynamic /*String?|Iterable<String>*/ >? queryParameters,
    String? fragment,
  });

  // ${$.empty('Uri.http', () => Uri.http)}
  external factory Uri.http(
    String authority, [
    String unencodedPath,
    Map<String, dynamic /*String?|Iterable<String>*/ >? queryParameters,
  ]);

  // ${$.empty('Uri.https', () => Uri.https)}
  external factory Uri.https(
    String authority, [
    String unencodedPath,
    Map<String, dynamic>? queryParameters,
  ]);

  // ${$.empty('Uri.file', () => Uri.file)}
  external factory Uri.file(String path, {bool? windows});

  // ${$.empty('Uri.directory', () => Uri.directory)}
  external factory Uri.directory(String path, {bool? windows});

  // ${$.empty('Uri.dataFromString', () => Uri.dataFromString)}
  external factory Uri.dataFromString(
    String content, {
    String? mimeType,
    Encoding? encoding,
    Map<String, String>? parameters,
    bool base64 = false,
  });

  // ${$.empty('Uri.dataFromBytes', () => Uri.dataFromBytes)}
  external factory Uri.dataFromBytes(
    List<int> bytes, {
    String mimeType = "application/octet-stream",
    Map<String, String>? parameters,
    bool percentEncoded = false,
  });

  // ${$.debug('scheme', ($, $$) => $.scheme)}
  String get scheme;

  // ${$.debug('authority', ($, $$) => $.authority)}
  String get authority;

  // ${$.debug('userInfo', ($, $$) => $.userInfo)}
  String get userInfo;

  // ${$.debug('host', ($, $$) => $.host)}
  String get host;

  // ${$.debug('port', ($, $$) => $.port)}
  int get port;

  // ${$.debug('path', ($, $$) => $.path)}
  String get path;

  // ${$.debug('query', ($, $$) => $.query)}
  String get query;

  // ${$.debug('fragment', ($, $$) => $.fragment)}
  String get fragment;

  // ${$.debug('pathSegments', ($, $$) => $.pathSegments)}
  List<String> get pathSegments;

  // ${$.debug('queryParameters', ($, $$) => $.queryParameters)}
  Map<String, String> get queryParameters;

  // ${$.debug('queryParametersAll', ($, $$) => $.queryParametersAll)}
  Map<String, List<String>> get queryParametersAll;

  // ${$.debug('isAbsolute', ($, $$) => $.isAbsolute)}
  bool get isAbsolute;

  // ${$.debug('hasScheme', ($, $$) => $.hasScheme)}
  bool get hasScheme => scheme.isNotEmpty;

  // ${$.debug('hasAuthority', ($, $$) => $.hasAuthority)}
  bool get hasAuthority;

  // ${$.debug('hasPort', ($, $$) => $.hasPort)}
  bool get hasPort;

  // ${$.debug('hasQuery', ($, $$) => $.hasQuery)}
  bool get hasQuery;

  // ${$.debug('hasFragment', ($, $$) => $.hasFragment)}
  bool get hasFragment;

  // ${$.debug('hasEmptyPath', ($, $$) => $.hasEmptyPath)}
  bool get hasEmptyPath;

  // ${$.debug('hasAbsolutePath', ($, $$) => $.hasAbsolutePath)}
  bool get hasAbsolutePath;

  // ${$.debug('origin', ($, $$) => $.origin)}
  String get origin;

  // ${$.debug('isScheme', ($, $$) => $.isScheme)}
  bool isScheme(String scheme);

  // ${$.debug('toFilePath', ($, $$) => $.toFilePath)}
  String toFilePath({bool? windows});

  // ${$.debug('data', ($, $$) => $.data)}
  UriData? get data;

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  int get hashCode;

  // ${$.debug('==', ($, $$) => $ == $$)}
  bool operator ==(Object other);

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();

  // ${$.debug('replace', ($, $$) => $.replace)}
  Uri replace({
    String? scheme,
    String? userInfo,
    String? host,
    int? port,
    String? path,
    Iterable<String>? pathSegments,
    String? query,
    Map<String, dynamic /*String?|Iterable<String>*/ >? queryParameters,
    String? fragment,
  });

  // ${$.debug('removeFragment', ($, $$) => $.removeFragment)}
  Uri removeFragment();

  // ${$.debug('resolve', ($, $$) => $.resolve)}
  Uri resolve(String reference);

  // ${$.debug('resolveUri', ($, $$) => $.resolveUri)}
  Uri resolveUri(Uri reference);

  // ${$.debug('normalizePath', ($, $$) => $.normalizePath)}
  Uri normalizePath();

  // ${$.empty('Uri.parse', () => Uri.parse)}
  external static Uri parse(String uri, [int start = 0, int? end]);

  // ${$.empty('Uri.tryParse', () => Uri.tryParse)}
  external static Uri? tryParse(String uri, [int start = 0, int? end]);

  // ${$.empty('Uri.encodeComponent', () => Uri.encodeComponent)}
  external static String encodeComponent(String component);

  // ${$.empty('Uri.encodeQueryComponent', () => Uri.encodeQueryComponent)}
  external static String encodeQueryComponent(String component, {Encoding encoding = utf8});

  // ${$.empty('Uri.decodeComponent', () => Uri.decodeComponent)}
  external static String decodeComponent(String encodedComponent);

  // ${$.empty('Uri.decodeQueryComponent', () => Uri.decodeQueryComponent)}
  external static String decodeQueryComponent(String encodedComponent, {Encoding encoding = utf8});

  // ${$.empty('Uri.encodeFull', () => Uri.encodeFull)}
  external static String encodeFull(String uri);

  // ${$.empty('Uri.decodeFull', () => Uri.decodeFull)}
  external static String decodeFull(String uri);

  // ${$.empty('Uri.splitQueryString', () => Uri.splitQueryString)}
  external static Map<String, String> splitQueryString(String query, {Encoding encoding = utf8});

  // ${$.empty('Uri.parseIPv4Address', () => Uri.parseIPv4Address)}
  external static List<int> parseIPv4Address(String host);

  // ${$.empty('Uri.parseIPv6Address', () => Uri.parseIPv6Address)}
  external static List<int> parseIPv6Address(String host, [int start = 0, int? end]);
}
''');

DartClass get _$UriData => DartClass<UriData>(($) => '''
final class UriData {
  // ${$.empty('UriData.fromString', () => UriData.fromString)}
  external factory UriData.fromString(
    String content, {
    String? mimeType,
    Encoding? encoding,
    Map<String, String>? parameters,
    bool base64 = false,
  });

  // ${$.empty('UriData.fromBytes', () => UriData.fromBytes)}
  external factory UriData.fromBytes(
    List<int> bytes, {
    String mimeType = "application/octet-stream",
    Map<String, String>? parameters,
    bool percentEncoded = false,
  });

  // ${$.empty('UriData.fromUri', () => UriData.fromUri)}
  external factory UriData.fromUri(Uri uri);

  // ${$.empty('UriData.parse', () => UriData.parse)}
  external static UriData parse(String uri);

  // ${$.debug('uri', ($, $$) => $.uri)}
  external Uri get uri;

  // ${$.debug('mimeType', ($, $$) => $.mimeType)}
  external String get mimeType;

  // ${$.debug('isMimeType', ($, $$) => $.isMimeType)}
  external bool isMimeType(String mimeType);

  // ${$.debug('charset', ($, $$) => $.charset)}
  external String get charset;

  // ${$.debug('isCharset', ($, $$) => $.isCharset)}
  external bool isCharset(String charset);

  // ${$.debug('isEncoding', ($, $$) => $.isEncoding)}
  external bool isEncoding(Encoding encoding);

  // ${$.debug('isBase64', ($, $$) => $.isBase64)}
  external bool get isBase64;

  // ${$.debug('contentText', ($, $$) => $.contentText)}
  external String get contentText;

  // ${$.debug('contentAsBytes', ($, $$) => $.contentAsBytes)}
  external Uint8List contentAsBytes();

  // ${$.debug('contentAsString', ($, $$) => $.contentAsString)}
  external String contentAsString({Encoding? encoding});

  // ${$.debug('parameters', ($, $$) => $.parameters)}
  external Map<String, String> get parameters;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

List<DartDeclaration> get $uri {
  return [
    _$Uri,
    _$UriData,
  ];
}
