import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

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

  // ${$.debug('fetchJson', ($, $$) => $.fetchJson)}
  external Future<dynamic> fetchJson(String url);

  // ${$.debug('fetchHtml', ($, $$) => $.fetchHtml)}
  external Future<Document> fetchHtml(String url);

  // ${$.debug('fetchBytes', ($, $$) => $.fetchBytes)}
  external Future<List<int>> fetchBytes(String url);

  // ${$.debug('resolveImageBytes', ($, $$) => $.resolveImageBytes)}
  external Future<Image> resolveImageBytes(List<int> bytes);

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

  // ${$.debug('getSourceMangas', ($, $$) => $.getSourceMangas)}
  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query);

  // ${$.debug('getMangaChapters', ($, $$) => $.getMangaChapters)}
  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga);

  // ${$.debug('getChapterImages', ($, $$) => $.getChapterImages)}
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter);

  // ${$.debug('getImageBytes', ($, $$) => $.getImageBytes)}
  external Future<List<int>> getImageBytes(HttpSourceImage image);

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
  });
}
''');

DartClass get _$HttpSourceBytes => DartClass<HttpSourceBytes>(($) => '''
class HttpSourceBytes extends SourceBytes {
  // ${$.empty('HttpSourceBytes.new', () => HttpSourceBytes.new)}
  HttpSourceBytes({
    required super.type,
    required super.data,
  });

  // ${$.debug('copyWith', ($, $$) => $.copyWith)}
  external HttpSourceBytes copyWith({
    String? type,
    List<int>? data,
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

DartClass get _$HttpSourceImage => DartClass<HttpSourceImage>(($) => '''
class HttpSourceImage extends SourceImage {
  // ${$.empty('HttpSourceImage.new', () => HttpSourceImage.new)}
  const HttpSourceImage({
    super.extra,
    required super.url,
  });
}
''');

DartClass get _$HttpSourcePage => DartClass<HttpSourcePage>(($) => '''
class HttpSourcePage<T> extends SourcePage<T> {
  // ${$.empty('HttpSourcePage.new', () => HttpSourcePage.new)}
  HttpSourcePage({
    super.next,
    required super.data,
  });
}
''');

DartClass get _$HttpSourceQuery => DartClass<HttpSourceQuery>(($) => '''
class HttpSourceQuery extends SourceQuery {
  // ${$.empty('HttpSourceQuery.new', () => HttpSourceQuery.new)}
  HttpSourceQuery({
    super.page,
    required super.keyword,
  });
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
    _$HttpSourceImage,
    _$HttpSourcePage,
    _$HttpSourceQuery,
    _$HttpSourceException,
  ];
}
