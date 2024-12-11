part of declaration.dart.core;

DartClass get _$RegExp => DartClass<RegExp>(($) => '''
abstract interface class RegExp implements Pattern {
  // ${$.empty('RegExp.new', () => RegExp.new)}
  external factory RegExp(
    String source, {
    bool multiLine,
    bool caseSensitive,
    bool unicode,
    bool dotAll,
  });

  // ${$.empty('RegExp.escape', () => RegExp.escape)}
  external static String escape(String text);

  // ${$.debug('firstMatch', ($, $$) => $.firstMatch)}
  RegExpMatch? firstMatch(String input);

  // ${$.debug('allMatches', ($, $$) => $.allMatches)}
  Iterable<RegExpMatch> allMatches(String input, [int start = 0]);

  // ${$.debug('hasMatch', ($, $$) => $.hasMatch)}
  bool hasMatch(String input);

  // ${$.debug('stringMatch', ($, $$) => $.stringMatch)}
  String? stringMatch(String input);

  // ${$.debug('pattern', ($, $$) => $.pattern)}
  String get pattern;

  // ${$.debug('isMultiLine', ($, $$) => $.isMultiLine)}
  bool get isMultiLine;

  // ${$.debug('isCaseSensitive', ($, $$) => $.isCaseSensitive)}
  bool get isCaseSensitive;

  // ${$.debug('isUnicode', ($, $$) => $.isUnicode)}
  bool get isUnicode;

  // ${$.debug('isDotAll', ($, $$) => $.isDotAll)}
  bool get isDotAll;
}
''');

DartClass get _$RegExpMatch => DartClass<RegExpMatch>(($) => '''
abstract interface class RegExpMatch implements Match {
  // ${$.debug('namedGroup', ($, $$) => $.namedGroup)}
  String? namedGroup(String name);

  // ${$.debug('groupNames', ($, $$) => $.groupNames)}
  Iterable<String> get groupNames;

  // ${$.debug('pattern', ($, $$) => $.pattern)}
  RegExp get pattern;
}
''');

List<DartDeclaration> get $regexp {
  return [
    _$RegExp,
    _$RegExpMatch,
  ];
}
