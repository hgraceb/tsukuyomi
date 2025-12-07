import 'package:archive/archive.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$archive => DartClass<Archive>(($) => '''
// ${$.empty('Archive.new', () => Archive.new)}
class Archive extends IterableBase<ArchiveFile> {
  // ${$.debug('comment', ($, $$) => $.comment)}
  String? comment;

  // ${$.debug('files', ($, $$) => $.files)}
  external List<ArchiveFile> get files;

  // ${$.debug('addFile', ($, $$) => $.addFile)}
  external void addFile(ArchiveFile file);

  // ${$.debug('removeFile', ($, $$) => $.removeFile)}
  external void removeFile(ArchiveFile file);

  // ${$.debug('removeAt', ($, $$) => $.removeAt)}
  external void removeAt(int index);

  // ${$.debug('clear', ($, $$) => $.clear)}
  external Future<void> clear();

  // ${$.debug('clearSync', ($, $$) => $.clearSync)}
  external void clearSync();

  // ${$.debug('length', ($, $$) => $.length)}
  external int get length;

  // ${$.debug('[]', ($, $$) => $[$$])}
  external ArchiveFile operator [](int index);

  // ${$.debug('[]=', ($, $$) => $[$$] = $$)}
  external void operator []=(int index, ArchiveFile file);

  // ${$.debug('findFile', ($, $$) => $.findFile)}
  external ArchiveFile? findFile(String name);

  // ${$.debug('numberOfFiles', ($, $$) => $.numberOfFiles)}
  external int numberOfFiles();

  // ${$.debug('fileName', ($, $$) => $.fileName)}
  external String fileName(int index);

  // ${$.debug('fileSize', ($, $$) => $.fileSize)}
  external int fileSize(int index);

  // ${$.debug('fileData', ($, $$) => $.fileData)}
  external List<int> fileData(int index);

  // ${$.debug('first', ($, $$) => $.first)}
  external ArchiveFile get first;

  // ${$.debug('last', ($, $$) => $.last)}
  external ArchiveFile get last;

  // ${$.debug('isEmpty', ($, $$) => $.isEmpty)}
  external bool get isEmpty;

  // ${$.debug('isNotEmpty', ($, $$) => $.isNotEmpty)}
  external bool get isNotEmpty;

  // ${$.debug('iterator', ($, $$) => $.iterator)}
  external Iterator<ArchiveFile> get iterator;
}
''');

List<DartDeclaration> get $archive {
  return [
    _$archive,
  ];
}
