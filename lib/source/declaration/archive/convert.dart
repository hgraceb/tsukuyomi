import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import 'src/zip_decoder.dart';

List<DartLibrary> get $archiveLibraries {
  return [
    DartLibrary('archive', path: 'archive.dart', source: 'library archive;', declarations: [
      ...$zipDecoder,
    ]),
  ];
}
