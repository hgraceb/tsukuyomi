import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'dom.dart';
import 'parser.dart';

List<DartLibrary> get $htmlLibraries {
  return [
    htmlDomLibrary,
    htmlParserLibrary,
  ];
}
