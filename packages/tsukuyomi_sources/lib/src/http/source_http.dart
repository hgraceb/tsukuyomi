part of 'package:tsukuyomi_sources/src/core/source.dart';

/// 网络漫画源
abstract class HttpSource extends Source {
  @override
  external int get id;

  /// 不包含末尾斜杠的基础 URL，如：http://example.com
  abstract final String baseUrl;

  /// 解析 JSON 格式文本
  external dynamic parseJson(String json);

  /// 解析 HTML 格式文本
  external Document parseHtml(String html);

  /// 解析 Protobuf 格式数据
  external SourceProtoMessage parseProto(List<int> buffer, SourceProtoFields fields);

  /// 请求 JSON 格式数据 TODO 判断是否需要限制访问权限
  external Future<dynamic> fetchJson(String url, {String? method});

  /// 请求 HTML 格式数据 TODO 判断是否需要限制访问权限
  external Future<Document> fetchHtml(String url, {String? method});

  /// 请求 List<int> 格式数据 TODO 判断是否需要限制访问权限
  external Future<HttpSourceBytes> fetchBytes(String url, {String? method});

  /// 请求 Protobuf 格式数据 TODO 判断是否需要限制访问权限
  external Future<SourceProtoMessage> fetchProto(String url, SourceProtoFields fields, {String? method});

  /// 解析 List<int> 格式图片数据
  external Future<Image> resolveImageBytes(List<int> bytes);

  /// 将图片转为 JPG 格式，默认质量为 90，以 100 质量保存会使图片尺寸太大并且没有明显观感区别
  external Future<List<int>> encodeJpg({required Image image, required Picture picture});

  /// 设置漫画源本地缓存值
  external String setStorage(String key, String value);

  /// 获取漫画源本地缓存值
  external String? getStorage(String key, String? defaultValue);

  /// 获取网络请求的请求头
  external Map<String, String> getRequestHeaders();

  /// 获取需要替换的请求头
  external Future<Map<String, String>> getReplaceHeaders(HttpSourceResponse response);

  /// 获取网络漫画详情列表
  @override
  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query);

  /// 获取网络漫画章节列表
  @override
  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga);

  /// 获取网络章节图片列表
  @override
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter);

  /// 获取网络章节图片数据
  @override
  external Future<HttpSourceBytes> getImageBytes(HttpSourceImage image);

  /// 获取网络章节重绘图片
  @override
  external Future<HttpSourceBytes> getRepaintBytes(HttpSourceBytes bytes);
}
