import 'package:archive/archive.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

DartClass get _$archiveFile => DartClass<ArchiveFile>(($) => '''
class ArchiveFile {
  // ${$.empty('ArchiveFile.STORE', () => ArchiveFile.STORE)}
  static const int STORE = 0;

  // ${$.empty('ArchiveFile.DEFLATE', () => ArchiveFile.DEFLATE)}
  static const int DEFLATE = 8;

  // ${$.debug('name', ($, $$) => $.name = $$)}
  String name;

  // ${$.debug('size', ($, $$) => $.size = $$)}
  int size = 0;

  // ${$.debug('mode', ($, $$) => $.mode = $$)}
  external int mode;

  // ${$.debug('ownerId', ($, $$) => $.ownerId = $$)}
  external int ownerId;

  // ${$.debug('groupId', ($, $$) => $.groupId = $$)}
  external int groupId;

  // ${$.debug('lastModTime', ($, $$) => $.lastModTime = $$)}
  external int lastModTime;

  // ${$.debug('isFile', ($, $$) => $.isFile = $$)}
  external bool isFile;

  // ${$.debug('isSymbolicLink', ($, $$) => $.isSymbolicLink = $$)}
  external bool isSymbolicLink;

  // ${$.debug('nameOfLinkedFile', ($, $$) => $.nameOfLinkedFile = $$)}
  external String nameOfLinkedFile;

  // ${$.debug('crc32', ($, $$) => $.crc32 = $$)}
  external int? crc32;

  // ${$.debug('comment', ($, $$) => $.comment = $$)}
  external String? comment;

  // ${$.debug('compress', ($, $$) => $.compress = $$)}
  external bool compress;

  // ${$.debug('unixPermissions', ($, $$) => $.unixPermissions)}
  external int get unixPermissions;

  // ${$.empty('ArchiveFile.new', () => ArchiveFile.new)}
  ArchiveFile(this.name, this.size, dynamic content, [this._compressionType = STORE]);

  // ${$.empty('ArchiveFile.string', () => ArchiveFile.string)}
  ArchiveFile.string(this.name, String content, [this._compressionType = STORE]);

  // ${$.empty('ArchiveFile.noCompress', () => ArchiveFile.noCompress)}
  ArchiveFile.noCompress(this.name, this.size, dynamic content);

  // ${$.empty('ArchiveFile.stream', () => ArchiveFile.stream)}
  ArchiveFile.stream(this.name, this.size, InputStreamBase contentStream);

  // ${$.debug('writeContent', ($, $$) => $.writeContent)}
  external void writeContent(OutputStreamBase output, {bool freeMemory = true});

  // ${$.debug('content', ($, $$) => $.content)}
  external dynamic get content;

  // ${$.debug('clear', ($, $$) => $.clear)}
  external void clear();

  // ${$.debug('close', ($, $$) => $.close)}
  external Future<void> close();

  // ${$.debug('closeSync', ($, $$) => $.closeSync)}
  external void closeSync();

  // ${$.debug('decompress', ($, $$) => $.decompress)}
  external void decompress([OutputStreamBase? output]);

  // ${$.debug('isCompressed', ($, $$) => $.isCompressed)}
  external bool get isCompressed;

  // ${$.debug('compressionType', ($, $$) => $.compressionType)}
  external int? get compressionType;

  // ${$.debug('rawContent', ($, $$) => $.rawContent)}
  external InputStreamBase? get rawContent;

  // ${$.debug('lastModDateTime', ($, $$) => $.lastModDateTime)}
  external DateTime get lastModDateTime;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();

  int? _compressionType;
}
''');

List<DartDeclaration> get $archiveFile {
  return [
    _$archiveFile,
  ];
}
