part of 'core.dart';

DartClass get _$Pattern => DartClass<Pattern>(($) => '''
abstract interface class Pattern {}
''');

DartClass get _$Match => DartClass<Match>(($) => '''
abstract interface class Match {
  // ${$.debug('[]', ($, $$) => $[$$])}
  String? operator [](int group);
}
''');

List<DartDeclaration> get $pattern {
  return [
    _$Pattern,
    _$Match,
  ];
}
