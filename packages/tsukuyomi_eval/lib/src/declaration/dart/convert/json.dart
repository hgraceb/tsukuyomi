part of declaration.dart.convert;

DartFunction get _$jsonEncode => DartFunction('jsonEncode', jsonEncode, '''
external String jsonEncode(Object? object, {Object? toEncodable(Object? nonEncodable)?});
''');

DartFunction get _$jsonDecode => DartFunction('jsonDecode', jsonDecode, '''
external dynamic jsonDecode(String source, {Object? reviver(Object? key, Object? value)?});
''');

List<DartDeclaration> get $json {
  return [
    _$jsonEncode,
    _$jsonDecode,
  ];
}
