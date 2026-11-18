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
  Future<HttpSourceManga> getMangaDetails(HttpSourceManga manga);

  // ${$.debug('getChapterImages', ($, $$) => $.getChapterImages)}
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter);

  // ${$.debug('getImageBytes', ($, $$) => $.getImageBytes)}
  external Future<HttpSourceBytes> getImageBytes(HttpSourceImage image);

  // ${$.debug('getRepaintBytes', ($, $$) => $.getRepaintBytes)}
  external Future<HttpSourceBytes> getRepaintBytes(HttpSourceBytes bytes);
}
''');

DartClass get _$HttpSourceManga => DartClass<HttpSourceManga>(($) => '''
class HttpSourceManga extends SourceManga {
  // ${$.empty('HttpSourceManga.new', () => HttpSourceManga.new)}
  const HttpSourceManga({
    required super.url,
    required super.name,
    required super.cover,
    super.status,
    super.description,
    super.authors,
    super.tags,
    super.languages,
    super.chapters,
  });
}
''');

DartClass get _$HttpSourceBytes => DartClass<HttpSourceBytes>(($) => '''
class HttpSourceBytes extends SourceBytes {
  // ${$.empty('HttpSourceBytes.new', () => HttpSourceBytes.new)}
  HttpSourceBytes({
    required super.type,
    required super.data,
    required super.statusCode,
    required super.responseHeaders,
    super.extra,
  });

  // ${$.debug('copyWith', ($, $$) => $.copyWith)}
  external HttpSourceBytes copyWith({
    String? type,
    List<int>? data,
    int? statusCode,
    Headers? responseHeaders,
    dynamic extra,
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

HttpSourceMangaEntries _httpSourceMangaEntries({required Iterable<dynamic> mangas, HttpSourceQuery? nextQuery}) {
  return HttpSourceMangaEntries(mangas: mangas.cast<HttpSourceManga>(), nextQuery: nextQuery);
}

DartClass get _$HttpSourceMangaEntries => DartClass<HttpSourceMangaEntries>(($) => '''
class HttpSourceMangaEntries extends SourceMangaEntries {
  // ${$.empty('HttpSourceMangaEntries.new', () => _httpSourceMangaEntries)}
  HttpSourceMangaEntries({
    required Iterable<HttpSourceManga> mangas,
    this.nextQuery,
  }) : mangas = List.unmodifiable(mangas);

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
    _$HttpSourceBytes,
    _$HttpSourceChapter,
    _$HttpSourceFrame,
    _$HttpSourceImage,
    _$HttpSourceMangaEntries,
    _$HttpSourceQuery,
    _$HttpSourceException,
  ];
}
