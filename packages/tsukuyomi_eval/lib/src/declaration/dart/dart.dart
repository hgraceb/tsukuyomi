import 'package:tsukuyomi_eval/src/property.dart';

import 'async/async.dart';
import 'convert/convert.dart';
import 'core/core.dart';
import 'internal/internal.dart';
import 'typed_data/typed_data.dart';
import 'ui/ui.dart';

List<DartLibrary> get dartLibraries {
  return [
    dartAsyncLibrary,
    dartConvertLibrary,
    dartCoreLibrary,
    dartInternalLibrary,
    dartTypedDataLibrary,
    dartUiLibrary,
  ];
}
