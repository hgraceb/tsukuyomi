import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

DartClass get _$HttpSource => DartClass<HttpSource>(($) => '''
// ${$.empty('HttpSource.class', () => ObjClass('HttpSource'))}
abstract class HttpSource extends Source {
  // ${$.debug('id', ($, $$) => $.id)}
  external int get id;

  // ${$.debug('baseUrl', ($, $$) => $.baseUrl)}
  abstract final String baseUrl;

  // ${$.debug('parseJson', ($, $$) => $.parseJson)}
  external dynamic parseJson(String json);

  // ${$.debug('parseHtml', ($, $$) => $.parseHtml)}
  external Document parseHtml(String html);

  // ${$.debug('parseProto', ($, $$) => $.parseProto)}
  external SourceProtoMessage parseProto(List<int> buffer, SourceProtoFields fields);

  // ${$.debug('fetchJson', ($, $$) => $.fetchJson)}
  external Future<dynamic> fetchJson(String url, {String? method, Map<String, String>? headers, Object? data});

  // ${$.debug('fetchHtml', ($, $$) => $.fetchHtml)}
  external Future<Document> fetchHtml(String url, {String? method, Map<String, String>? headers, Object? data});

  // ${$.debug('fetchBytes', ($, $$) => $.fetchBytes)}
  external Future<HttpSourceBytes> fetchBytes(String url, {String? method, Map<String, String>? headers, Object? data});

  // ${$.debug('fetchProto', ($, $$) => $.fetchProto)}
  external Future<SourceProtoMessage> fetchProto(
    String url,
    SourceProtoFields fields, {
    String? method,
    Map<String, String>? headers,
    Object? data,
  });

  // ${$.debug('resolveImageBytes', ($, $$) => $.resolveImageBytes)}
  external Future<Image> resolveImageBytes(List<int> bytes);

  // ${$.debug('resolveStringBytes', ($, $$) => $.resolveStringBytes)}
  external Future<String> resolveStringBytes(List<int> bytes, {String? charset});

  // ${$.debug('encodeGif', ($, $$) => $.encodeGif)}
  external Future<List<int>> encodeGif({required List<HttpSourceFrame> frames});

  // ${$.debug('encodeJpg', ($, $$) => $.encodeJpg)}
  external Future<List<int>> encodeJpg({required Image image, required Picture picture});

  // ${$.debug('setStorage', ($, $$) => $.setStorage)}
  external String setStorage(String key, String value);

  // ${$.debug('getStorage', ($, $$) => $.getStorage)}
  external String? getStorage(String key, String? defaultValue);

  // ${$.debug('getRequestHeaders', ($, $$) => $.getRequestHeaders)}
  external Map<String, String> getRequestHeaders();

  // ${$.debug('getReplaceHeaders', ($, $$) => $.getReplaceHeaders)}
  external Future<Map<String, String>> getReplaceHeaders(HttpSourceResponse response);

  // ${$.debug('getMangaEntries', ($, $$) => $.getMangaEntries)}
  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query);

  // ${$.debug('getMangaDetails', ($, $$) => $.getMangaDetails)}
  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga);

  // ${$.debug('getChapterImages', ($, $$) => $.getChapterImages)}
  Future<HttpSourceChapterImages> getChapterImages(HttpSourceChapter chapter);

  // ${$.debug('getImageBytes', ($, $$) => $.getImageBytes)}
  external Future<HttpSourceImageBytes> getImageBytes(HttpSourceImage image);

  // ${$.debug('getRepaintBytes', ($, $$) => $.getRepaintBytes)}
  external Future<HttpSourceImageBytes> getRepaintBytes(HttpSourceImageBytes imageBytes);
}
''');

DartClass get _$HttpSourceManga => DartClass<HttpSourceManga>(($) => '''
class HttpSourceManga extends SourceManga {
  // ${$.empty('HttpSourceManga.new', () => HttpSourceManga.new)}
  const HttpSourceManga({
    required super.url,
    required super.name,
    required super.cover,
  });
}
''');

DartClass get _$HttpSourceMangaDetails => DartClass<HttpSourceMangaDetails>(($) => '''
class HttpSourceMangaDetails extends SourceMangaDetails {
  // ${$.empty('HttpSourceMangaDetails.new', () => HttpSourceMangaDetails.new)}
  const HttpSourceMangaDetails({
    required super.url,
    required super.name,
    required super.cover,
    required this.chapters,
    super.status,
    super.description,
    super.authors,
    super.tags,
    super.languages,
  });

  // ${$.debug('chapters', ($, $$) => $.chapters)}
  final List<HttpSourceChapter> chapters;
}
''');

DartClass get _$HttpSourceBytes => DartClass<HttpSourceBytes>(($) => '''
class HttpSourceBytes extends SourceBytes {
  // ${$.empty('HttpSourceBytes.new', () => HttpSourceBytes.new)}
  HttpSourceBytes({
    required super.type,
    required super.data,
    required this.statusCode,
    required this.responseHeaders,
  });

  // ${$.debug('statusCode', ($, $$) => $.statusCode)}
  final int statusCode;

  // ${$.debug('responseHeaders', ($, $$) => $.responseHeaders)}
  final Headers responseHeaders;

  // ${$.debug('copyWith', ($, $$) => $.copyWith)}
  external HttpSourceBytes copyWith({
    String? type,
    List<int>? data,
    int? statusCode,
    Headers? responseHeaders,
  });
}
''');

DartClass get _$HttpSourceChapter => DartClass<HttpSourceChapter>(($) => '''
class HttpSourceChapter extends SourceChapter {
  // ${$.empty('HttpSourceChapter.new', () => HttpSourceChapter.new)}
  const HttpSourceChapter({
    required super.url,
    required super.name,
    super.date,
    super.public,
  });
}
''');

DartClass get _$HttpSourceChapterImages => DartClass<HttpSourceChapterImages>(($) => '''
class HttpSourceChapterImages extends SourceChapterImages {
  // ${$.empty('HttpSourceChapterImages.new', () => HttpSourceChapterImages.new)}
  const HttpSourceChapterImages({required this.images});

  // ${$.debug('images', ($, $$) => $.images)}
  final List<HttpSourceImage> images;
}
''');

DartClass get _$HttpSourceFrame => DartClass<HttpSourceFrame>(($) => '''
class HttpSourceFrame extends SourceFrame {
  // ${$.empty('HttpSourceFrame.new', () => HttpSourceFrame.new)}
  HttpSourceFrame({
    required super.image,
    required super.duration,
  });
}
''');

DartClass get _$HttpSourceImage => DartClass<HttpSourceImage>(($) => '''
class HttpSourceImage extends SourceImage {
  // ${$.empty('HttpSourceImage.new', () => HttpSourceImage.new)}
  const HttpSourceImage({
    super.extra,
    required super.url,
  });
}
''');

DartClass get _$HttpSourceImageBytes => DartClass<HttpSourceImageBytes>(($) => '''
class HttpSourceImageBytes extends SourceImageBytes {
  // ${$.empty('HttpSourceImageBytes.new', () => HttpSourceImageBytes.new)}
  const HttpSourceImageBytes({required this.bytes, super.extra});

  // ${$.debug('bytes', ($, $$) => $.bytes)}
  final HttpSourceBytes bytes;
}
''');

DartClass get _$HttpSourceMangaEntries => DartClass<HttpSourceMangaEntries>(($) => '''
class HttpSourceMangaEntries extends SourceMangaEntries {
  // ${$.empty('HttpSourceMangaEntries.new', () => HttpSourceMangaEntries.new)}
  HttpSourceMangaEntries({
    required this.mangas,
    this.nextQuery,
  });

  // ${$.debug('mangas', ($, $$) => $.mangas)}
  final List<HttpSourceManga> mangas;

  // ${$.debug('nextQuery', ($, $$) => $.nextQuery)}
  final HttpSourceQuery? nextQuery;
}
''');

DartClass get _$HttpSourceQuery => DartClass<HttpSourceQuery>(($) => '''
class HttpSourceQuery extends SourceQuery {
  // ${$.empty('HttpSourceQuery.new', () => HttpSourceQuery.new)}
  HttpSourceQuery({
    super.page,
    required super.keyword,
  });

  // ${$.debug('nextPage', ($, $$) => $.nextPage)}
  external HttpSourceQuery get nextPage;
}
''');

DartClass get _$HttpSourceException => DartClass<HttpSourceException>(($) => '''
// ${$.alias('HttpSourceException')}
typedef HttpSourceException = DioException;
''');

List<DartDeclaration> get $http {
  return [
    _$HttpSource,
    _$HttpSourceManga,
    _$HttpSourceMangaDetails,
    _$HttpSourceBytes,
    _$HttpSourceChapter,
    _$HttpSourceChapterImages,
    _$HttpSourceFrame,
    _$HttpSourceImage,
    _$HttpSourceImageBytes,
    _$HttpSourceMangaEntries,
    _$HttpSourceQuery,
    _$HttpSourceException,
  ];
}
