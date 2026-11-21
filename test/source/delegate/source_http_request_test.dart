import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart'; // ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqflite.dart'; // ignore: depend_on_referenced_packages
import 'package:sqflite_common/src/factory.dart'; // ignore: depend_on_referenced_packages, implementation_imports
import 'package:tsukuyomi/core/cache/tsukuyomi_cache_manager.dart';
import 'package:tsukuyomi/source/declaration/declaration.dart';
import 'package:tsukuyomi/source/delegate/source_http.dart';
import 'package:tsukuyomi_eval/src/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/resolver.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('JSON requests send nested data and merge request headers', () async {
    final server = await serve(body: utf8.encode('{"title":"Chapter"}'), contentType: 'application/json');
    final source = await loadRequestSource(server.baseUrl, '''
    final json = await fetchJson(
      '/search?page=2',
      method: 'POST',
      headers: {'X-Source': 'search'},
      data: {'keyword': '漫画 & +', 'paging': {'page': 2}, 'genres': ['action', 'comedy']},
    );
    return HttpSourceMangaDetails(url: manga.url, name: manga.name, cover: manga.cover, chapters: [HttpSourceChapter(url: '/chapter', name: json['title'])]);
''');
    expect((await source.getMangaDetails(manga)).chapters.single.name, 'Chapter');
    final request = server.requests.single;
    expect(request.method, 'POST');
    expect(request.uri.toString(), '/search?page=2');
    expect(request.headers.contentType?.mimeType, 'application/json');
    expect(request.headers.value('referer'), server.baseUrl);
    expect(request.headers.value('x-source'), 'search');
    expect(jsonDecode(utf8.decode(request.body)), {
      'keyword': '漫画 & +',
      'paging': {'page': 2},
      'genres': ['action', 'comedy'],
    });
  });

  test('HTML requests encode PHP form fields and keep headers local to the request', () async {
    final server = await serve(body: utf8.encode('<h1>Chapter</h1>'), contentType: 'text/html');
    final source = await loadRequestSource(server.baseUrl, '''
    final html = await fetchHtml(
      '/wp-admin/admin-ajax.php',
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded', 'X-Source': 'chapters'},
      data: {'action': 'manga_get_chapters', 'manga': '42', 'vars[s]': '漫画 & +', 'empty': ''},
    );
    await fetchHtml('/next');
    return HttpSourceMangaDetails(url: manga.url, name: manga.name, cover: manga.cover, chapters: [HttpSourceChapter(url: '/chapter', name: html.querySelector('h1')!.text)]);
''');
    expect((await source.getMangaDetails(manga)).chapters.single.name, 'Chapter');
    expect(server.requests, hasLength(2));
    final request = server.requests.first;
    expect(request.method, 'POST');
    expect(request.uri.path, '/wp-admin/admin-ajax.php');
    expect(request.headers.contentType?.mimeType, 'application/x-www-form-urlencoded');
    expect(request.headers.value('referer'), server.baseUrl);
    expect(request.headers.value('x-source'), 'chapters');
    expect(Uri.splitQueryString(utf8.decode(request.body)), {
      'action': 'manga_get_chapters',
      'manga': '42',
      'vars[s]': '漫画 & +',
      'empty': '',
    });
    final next = server.requests.last;
    expect(next.method, 'GET');
    expect(next.uri.path, '/next');
    expect(next.body, isEmpty);
    expect(next.headers.value('x-source'), 'default');
    expect(next.headers.contentType, isNull);
  });

  test('Byte responses preserve metadata while sending a raw string body', () async {
    final server = await serve(body: [0, 127, 255], contentType: 'image/png');
    final source = await loadRequestSource(server.baseUrl, '''
    final bytes = await fetchBytes(
      '/image',
      method: 'POST',
      headers: {'Content-Type': 'application/x-www-form-urlencoded', 'X-Source': 'image'},
      data: 'token=a%2Bb&empty=',
    );
    return HttpSourceMangaDetails(url: manga.url, name: manga.name, cover: manga.cover, chapters: [HttpSourceChapter(url: bytes.type, name: '\${bytes.statusCode}:\${bytes.data.join(",")}')]);
''');
    final chapter = (await source.getMangaDetails(manga)).chapters.single;
    expect(chapter.url, 'png');
    expect(chapter.name, '200:0,127,255');
    final request = server.requests.single;
    expect(request.method, 'POST');
    expect(request.headers.contentType?.mimeType, 'application/x-www-form-urlencoded');
    expect(request.headers.value('x-source'), 'image');
    expect(utf8.decode(request.body), 'token=a%2Bb&empty=');
  });

  test('The cache reports the final image format and length after repainting', () async {
    const imageMethods = '''
  Future<HttpSourceImageBytes> getImageBytes(HttpSourceImage image) async {
    final bytes = await fetchImageBytes(image);
    return bytes.copyWith(extra: bytes.data.last);
  }

  Future<HttpSourceImageBytes> getRepaintBytes(HttpSourceImageBytes bytes) async {
    return bytes.copyWith(type: 'gif', data: [bytes.extra as int], extra: null);
  }
''';
    final server = await serve(body: [1, 2, 3], contentType: 'image/png');
    final source = await loadRequestSource(server.baseUrl, "    throw 'unused';", imageMethods: imageMethods);
    const image = HttpSourceImage(url: '/page.png', extra: 'request parameter');
    await useTemporaryCache();
    final cache = TsukuyomiCacheManager(source, image);
    addTearDown(cache.store.dispose);
    final response = await cache.webHelper.fileFetcher.get(image.url);
    expect(response.fileExtension, '.gif');
    expect(response.contentLength, 1);
    expect(await response.content.expand((chunk) => chunk).toList(), [3]);
    expect(server.requests, hasLength(1));
  });

  test('Default image requests pass the page metadata to repainting', () async {
    final server = await serve(body: [0, 1], contentType: 'image/png');
    final source = await loadRequestSource(server.baseUrl, "    throw 'unused';");
    for (final extra in [null, false, 'seed', [1, 0]]) {
      final imageBytes = await source.getImageBytes(HttpSourceImage(url: '/page.png', extra: extra));
      expect(imageBytes.type, 'png');
      expect(imageBytes.data, [0, 1]);
      expect(imageBytes.statusCode, 200);
      expect(imageBytes.extra, extra);
      expect(await source.getRepaintBytes(imageBytes), same(imageBytes));
    }
    expect(server.requests, hasLength(4));
  });

  test('Image requests can choose the repaint metadata and HTTP options', () async {
    const imageMethods = '''
  Future<HttpSourceImageBytes> getImageBytes(HttpSourceImage image) {
    return fetchImageBytes(
      HttpSourceImage(url: image.url, extra: image.url == '/raw' ? null : 'new seed'),
      method: 'POST',
      headers: {'X-Source': 'page'},
      data: 'body',
    );
  }
''';
    final server = await serve(body: [0, 1], contentType: 'image/png');
    final source = await loadRequestSource(server.baseUrl, "    throw 'unused';", imageMethods: imageMethods);
    final replaced = await source.getImageBytes(const HttpSourceImage(url: '/page', extra: 'original'));
    final cleared = await source.getImageBytes(const HttpSourceImage(url: '/raw', extra: 'original'));
    expect(replaced.extra, 'new seed');
    expect(cleared.extra, isNull);
    expect(server.requests.map((request) => request.uri.path), ['/page', '/raw']);
    for (final request in server.requests) {
      expect(request.method, 'POST');
      expect(request.headers.value('x-source'), 'page');
      expect(utf8.decode(request.body), 'body');
    }
  });

  test('Protobuf responses accept binary request bodies and request headers', () async {
    final server = await serve(body: [8, 42], contentType: 'application/x-protobuf');
    final source = await loadRequestSource(server.baseUrl, '''
    final proto = await fetchProto(
      '/viewer',
      {'id': SourceProtoField.optionalInt32(1)},
      method: 'POST',
      headers: {'Content-Type': 'application/x-protobuf', 'X-Source': 'viewer'},
      data: Uint8List.fromList([8, 7]),
    );
    return HttpSourceMangaDetails(url: manga.url, name: manga.name, cover: manga.cover, chapters: [HttpSourceChapter(url: '/chapter', name: proto.get('id').toString())]);
''');
    expect((await source.getMangaDetails(manga)).chapters.single.name, '42');
    final request = server.requests.single;
    expect(request.method, 'POST');
    expect(request.headers.contentType?.mimeType, 'application/x-protobuf');
    expect(request.headers.value('referer'), server.baseUrl);
    expect(request.headers.value('x-source'), 'viewer');
    expect(request.body, [8, 7]);
  });

  test('Existing GET and bodyless POST and PUT requests keep their behavior', () async {
    final server = await serve(body: [], contentType: 'application/octet-stream');
    final source = await loadRequestSource(server.baseUrl, '''
    await fetchBytes('/get');
    await fetchBytes('/post', method: 'POST');
    await fetchProto('/put', {}, method: 'PUT');
    return HttpSourceMangaDetails(url: manga.url, name: manga.name, cover: manga.cover, chapters: <HttpSourceChapter>[]);
''');
    expect((await source.getMangaDetails(manga)).chapters, isEmpty);
    expect(server.requests.map((request) => request.method), ['GET', 'POST', 'PUT']);
    expect(server.requests.every((request) => request.body.isEmpty), isTrue);
  });

  for (final contentType in ['application/json', 'application/x-www-form-urlencoded']) {
    test('Header replacement retries retain $contentType request bodies', () async {
      final server = await serve(body: utf8.encode('{"title":"Chapter"}'), contentType: 'application/json', firstStatusCode: 401);
      final source = await loadRequestSource(server.baseUrl, '''
    final json = await fetchJson(
      '/chapters',
      method: 'POST',
      headers: {'Content-Type': '$contentType', 'X-Source': 'retry'},
      data: {'manga': '42', 'keyword': '漫画 & +'},
    );
    return HttpSourceMangaDetails(url: manga.url, name: manga.name, cover: manga.cover, chapters: [HttpSourceChapter(url: '/chapter', name: json['title'])]);
''', retry: true);
      expect((await source.getMangaDetails(manga)).chapters.single.name, 'Chapter');
      expect(server.requests, hasLength(2));
      final first = server.requests.first;
      final second = server.requests.last;
      expect(second.method, 'POST');
      expect(second.uri, first.uri);
      expect(second.body, first.body);
      expect(second.body, isNotEmpty);
      expect(second.headers.contentType?.mimeType, contentType);
      expect(second.headers.value('x-source'), 'retry');
      expect(first.headers.value('authorization'), isNull);
      expect(second.headers.value('authorization'), 'Bearer renewed');
    });
  }
}

const manga = HttpSourceManga(url: '/manga', name: 'Manga', cover: '');

Future<void> useTemporaryCache() async {
  final directory = await Directory.systemTemp.createTemp('tsukuyomi-cache-');
  final paths = PathProviderPlatform.instance;
  final factory = databaseFactoryOrNull;
  PathProviderPlatform.instance = _CachePaths(directory.path);
  databaseFactoryOrNull = _CacheDatabaseFactory(directory.path);
  addTearDown(() async {
    PathProviderPlatform.instance = paths;
    databaseFactoryOrNull = factory;
    await directory.delete(recursive: true);
  });
}

class _CachePaths extends PathProviderPlatform {
  _CachePaths(this.path);

  final String path;

  @override
  Future<String> getApplicationSupportPath() async => path;

  @override
  Future<String> getTemporaryPath() async => path;
}

class _CacheDatabaseFactory extends Fake implements SqfliteDatabaseFactory {
  _CacheDatabaseFactory(this.path);

  final String path;

  @override
  Future<String> getDatabasesPath() async => path;

  @override
  Future<Database> openDatabase(String path, {OpenDatabaseOptions? options}) async => _CacheDatabase();
}

class _CacheDatabase extends Fake implements Database {
  @override
  Future<void> close() async {}
}

Future<IsolateDioHttpSource> loadRequestSource(String baseUrl, String request, {bool retry = false, String imageMethods = ''}) async {
  final replacement = retry
      ? '''
  Future<Map<String, String>> getReplaceHeaders(dynamic response) async {
    return {'Authorization': 'Bearer renewed'};
  }
'''
      : '';
  final source =
      '''
import 'dart:typed_data';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = '$baseUrl';

  Map<String, String> getRequestHeaders() => {'Referer': baseUrl, 'X-Source': 'default'};

$replacement
$imageMethods

  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) async {
$request
  }

  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) => throw 'unused';
  Future<HttpSourceChapterImages> getChapterImages(HttpSourceChapter chapter) => throw 'unused';
}

main() => Example();
''';
  final resolved = await resolve(source, [...dartLibraries, ...evalLibraries]);
  final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
  expect(errors.map((error) => error.message), isEmpty);
  final instance = await eval(source, libraries: evalLibraries) as ObjInstance;
  return IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
}

Future<RequestServer> serve({required List<int> body, required String contentType, int? firstStatusCode}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final result = RequestServer(server);
  final subscription = server.listen((request) async {
    final data = await request.fold(<int>[], (data, chunk) => data..addAll(chunk));
    result.requests.add((method: request.method, uri: request.uri, headers: request.headers, body: data));
    request.response.statusCode = result.requests.length == 1 ? firstStatusCode ?? 200 : 200;
    request.response.headers.contentType = ContentType.parse(contentType);
    request.response.contentLength = body.length;
    request.response.add(body);
    await request.response.close();
  });
  addTearDown(() async {
    await server.close(force: true);
    await subscription.cancel();
  });
  return result;
}

class RequestServer {
  RequestServer(this.server);

  final HttpServer server;

  final List<({String method, Uri uri, HttpHeaders headers, List<int> body})> requests = [];

  String get baseUrl => 'http://127.0.0.1:${server.port}';
}
