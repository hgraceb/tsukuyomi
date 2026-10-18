import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/source/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/resolver.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

void main() {
  test('Source requests accept method and headers', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<dynamic> request() {
    return fetchJson('/chapter', method: 'POST', headers: {'x-source': 'chapter'});
  }

  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query) => throw 'unused';
  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga) => throw 'unused';
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter) => throw 'unused';
}

main() => Example();
''';
    final instance = await evalValidSource(source) as ObjInstance;
    Future<dynamic> fetchJson(String url, {String? method, Map<String, String>? headers}) async => [url, method, headers];
    instance.props['fetchJson'] = EvalProperty.getter((_) => fetchJson);
    expect(await instance.invoke('request', null), [
      '/chapter',
      'POST',
      {'x-source': 'chapter'},
    ]);
  });

  test('Image byte overrides retain data and image metadata', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourceBytes> getImageBytes(HttpSourceImage image) async {
    final bytes = await fetchBytes(image.url);
    return bytes.copyWith(extra: image.extra);
  }

  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query) => throw 'unused';
  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga) => throw 'unused';
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter) => throw 'unused';
}

Future<HttpSourceBytes> readImage(HttpSource source, HttpSourceImage image) {
  return source.getImageBytes(image);
}

main() => Example();
''';
    final instance = await evalValidSource(source) as ObjInstance;
    final bytes = HttpSourceBytes(type: 'png', data: [0, 1], statusCode: 200, responseHeaders: Headers.fromMap({}));
    Future<HttpSourceBytes> fetchBytes(String url, {String? method}) async => bytes;
    instance.props['fetchBytes'] = EvalProperty.getter((_) => fetchBytes);
    final image = HttpSourceImage(url: '/chapter', extra: {'frame': 'chapter'});
    final result = await instance.invoke('getImageBytes', [image]) as HttpSourceBytes;
    expect(result.data, same(bytes.data));
    expect(result.type, bytes.type);
    expect(result.statusCode, bytes.statusCode);
    expect(result.responseHeaders, same(bytes.responseHeaders));
    expect(result.extra, same(image.extra));
  });

  test('Image metadata is available through SourceImage', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example {
  dynamic read(SourceImage image) => image.extra;
}

main() => Example();
''';
    final instance = await evalValidSource(source) as ObjInstance;
    final image = HttpSourceImage(url: '/chapter', extra: {'frame': 'chapter'});
    expect(await instance.invoke('read', [image]), same(image.extra));
    expect(await instance.invoke('read', [const HttpSourceImage(url: '/chapter')]), isNull);
  });

  test('Image bytes construct and copy all declared response fields', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example {
  HttpSourceBytes create(dynamic headers) {
    return HttpSourceBytes(type: 'png', data: [0], statusCode: 200, responseHeaders: headers, extra: 'original');
  }

  HttpSourceBytes copy(HttpSourceBytes bytes, dynamic headers) {
    return bytes.copyWith(type: 'gif', data: [1], statusCode: 201, responseHeaders: headers, extra: 'copied');
  }
}

main() => Example();
''';
    final instance = await evalValidSource(source) as ObjInstance;
    final headers = Headers.fromMap({
      'content-type': ['image/png'],
    });
    final bytes = await instance.invoke('create', [headers]) as HttpSourceBytes;
    expect(bytes.type, 'png');
    expect(bytes.data, [0]);
    expect(bytes.statusCode, 200);
    expect(bytes.responseHeaders, same(headers));
    expect(bytes.extra, 'original');
    final copiedHeaders = Headers.fromMap({
      'content-type': ['image/gif'],
    });
    final copied = await instance.invoke('copy', [bytes, copiedHeaders]) as HttpSourceBytes;
    expect(copied.type, 'gif');
    expect(copied.data, [1]);
    expect(copied.statusCode, 201);
    expect(copied.responseHeaders, same(copiedHeaders));
    expect(copied.extra, 'copied');
    expect(bytes.extra, 'original');
  });

  test('Image byte overrides survive compute initialization', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourceBytes> getImageBytes(HttpSourceImage image) async {
    return HttpSourceBytes(type: 'png', data: [0], statusCode: 200, responseHeaders: image.extra);
  }

  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query) => throw 'unused';
  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga) => throw 'unused';
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter) => throw 'unused';
}

main() => Example();
''';
    await expectValidSource(source);
    final instance = await compute((source) async => await eval(source, libraries: evalLibraries) as ObjInstance, source);
    final headers = Headers.fromMap({});
    final result = await instance.invoke('getImageBytes', [HttpSourceImage(url: '/chapter', extra: headers)]) as HttpSourceBytes;
    expect(result.data, [0]);
    expect(result.responseHeaders, same(headers));
  });
}

Future<dynamic> evalValidSource(String source) async {
  await expectValidSource(source);
  return eval(source, libraries: evalLibraries);
}

Future<void> expectValidSource(String source) async {
  final resolved = await resolve(source, [...dartLibraries, ...evalLibraries]);
  final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
  expect(errors.map((error) => error.message), isEmpty);
}
