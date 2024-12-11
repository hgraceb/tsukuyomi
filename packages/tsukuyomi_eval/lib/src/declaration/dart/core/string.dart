part of declaration.dart.core;

DartClass get _$String => DartClass<String>(($) => '''
abstract final class String implements Comparable<String>, Pattern {
  // ${$.empty('String.fromCharCodes', () => String.fromCharCodes)}
  external factory String.fromCharCodes(Iterable<int> charCodes, [int start = 0, int? end]);

  // ${$.empty('String.fromCharCode', () => String.fromCharCode)}
  external factory String.fromCharCode(int charCode);

  // ${$.empty('String.fromEnvironment', () => throw EvalPermissionError('String.fromEnvironment'))}
  external const factory String.fromEnvironment(String name, {String defaultValue});

  // ${$.debug('[]', ($, $$) => $[$$])}
  String operator [](int index);

  // ${$.debug('codeUnitAt', ($, $$) => $.codeUnitAt)}
  int codeUnitAt(int index);

  // ${$.debug('length', ($, $$) => $.length)}
  int get length;

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  int get hashCode;

  // ${$.debug('==', ($, $$) => $ == $$)}
  bool operator ==(Object other);

  // ${$.debug('compareTo', ($, $$) => $.compareTo)}
  int compareTo(String other);

  // ${$.debug('endsWith', ($, $$) => $.endsWith)}
  bool endsWith(String other);

  // ${$.debug('startsWith', ($, $$) => $.startsWith)}
  bool startsWith(Pattern pattern, [int index = 0]);

  // ${$.debug('indexOf', ($, $$) => $.indexOf)}
  int indexOf(Pattern pattern, [int start = 0]);

  // ${$.debug('lastIndexOf', ($, $$) => $.lastIndexOf)}
  int lastIndexOf(Pattern pattern, [int? start]);

  // ${$.debug('isEmpty', ($, $$) => $.isEmpty)}
  bool get isEmpty;

  // ${$.debug('isNotEmpty', ($, $$) => $.isNotEmpty)}
  bool get isNotEmpty;

  // ${$.debug('+', ($, $$) => $ + $$)}
  String operator +(String other);

  // ${$.debug('substring', ($, $$) => $.substring)}
  String substring(int start, [int? end]);

  // ${$.debug('trim', ($, $$) => $.trim)}
  String trim();

  // ${$.debug('trimLeft', ($, $$) => $.trimLeft)}
  String trimLeft();

  // ${$.debug('trimRight', ($, $$) => $.trimRight)}
  String trimRight();

  // ${$.debug('*', ($, $$) => $ * $$)}
  String operator *(int times);

  // ${$.debug('padLeft', ($, $$) => $.padLeft)}
  String padLeft(int width, [String padding]);

  // ${$.debug('padRight', ($, $$) => $.padRight)}
  String padRight(int width, [String padding]);

  // ${$.debug('contains', ($, $$) => $.contains)}
  bool contains(Pattern other, [int startIndex = 0]);

  // ${$.debug('replaceFirst', ($, $$) => $.replaceFirst)}
  String replaceFirst(Pattern from, String to, [int startIndex = 0]);

  // ${$.debug('replaceFirstMapped', ($, $$) => $.replaceFirstMapped)}
  String replaceFirstMapped(Pattern from, String replace(Match match), [int startIndex = 0]);

  // ${$.debug('replaceAll', ($, $$) => $.replaceAll)}
  String replaceAll(Pattern from, String replace);

  // ${$.debug('replaceAllMapped', ($, $$) => $.replaceAllMapped)}
  String replaceAllMapped(Pattern from, String Function(Match match) replace);

  // ${$.debug('replaceRange', ($, $$) => $.replaceRange)}
  String replaceRange(int start, int? end, String replacement);

  // ${$.debug('split', ($, $$) => $.split)}
  List<String> split(Pattern pattern);

  // ${$.debug('splitMapJoin', ($, $$) => $.splitMapJoin)}
  String splitMapJoin(Pattern pattern, {String Function(Match)? onMatch, String Function(String)? onNonMatch});

  // ${$.debug('codeUnits', ($, $$) => $.codeUnits)}
  List<int> get codeUnits;

  // ${$.debug('runes', ($, $$) => $.runes)}
  Runes get runes;

  // ${$.debug('toLowerCase', ($, $$) => $.toLowerCase)}
  String toLowerCase();

  // ${$.debug('toUpperCase', ($, $$) => $.toUpperCase)}
  String toUpperCase();
}
''');

List<DartDeclaration> get $string {
  return [
    _$String,
  ];
}
