import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_html/parser.dart';

DartFunction get _$parse => DartFunction('parse', parse, '''
external Document parse(dynamic input, {String? encoding, bool generateSpans = false, String? sourceUrl});
''');

DartLibrary get htmlParserLibrary {
  return DartLibrary('html', path: 'parser.dart', source: '''
library parser;

import 'dom.dart';
''', declarations: [
    _$parse,
  ]);
}
