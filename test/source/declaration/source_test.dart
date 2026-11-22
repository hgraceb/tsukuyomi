import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/source/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/resolver.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  test('Manga entries expose typed mangas and continuation through HTTP and core declarations', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

Future<SourceMangaEntries> readEntries(Source source, SourceQuery query) => source.getMangaEntries(query);
Future<HttpSourceMangaEntries> readHttpEntries(HttpSource source, HttpSourceQuery query) => source.getMangaEntries(query);

main() {
  final query = HttpSourceQuery(keyword: 'more', page: 3);
  final entries = HttpSourceMangaEntries(
    mangas: [HttpSourceManga(url: '/manga', name: 'Title', cover: '/cover')],
    nextQuery: query.nextPage,
  );
  final HttpSourceManga manga = entries.mangas.single;
  final HttpSourceQuery? next = entries.nextQuery;
  final SourceMangaEntries core = entries;
  return [manga.url, query.page, next!.page, core.mangas.single.name, core.nextQuery!.keyword];
}
''';
    expect(await evalValidSource(source), ['/manga', 3, 4, 'Title', 'more']);
  });

  test('Chapter image results expose typed images through HTTP, core and dynamic declarations', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

Future<SourceChapterImages> readImages(Source source, SourceChapter chapter) => source.getChapterImages(chapter);
Future<HttpSourceChapterImages> readHttpImages(HttpSource source, HttpSourceChapter chapter) => source.getChapterImages(chapter);

main() {
  final result = HttpSourceChapterImages(images: [HttpSourceImage(url: '/page')]);
  final HttpSourceImage httpImage = result.images.single;
  final SourceChapterImages core = result;
  final SourceImage image = core.images.single;
  final dynamic empty = HttpSourceChapterImages(images: []);
  return [httpImage.url, image.url, empty.images.isEmpty];
}
''';
    expect(await evalValidSource(source), ['/page', '/page', true]);
  });

  test('Detail responses require chapters and search entries contain only basic fields', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

Future<SourceMangaDetails> readDetails(Source source, SourceManga manga) => source.getMangaDetails(manga);
Future<HttpSourceMangaDetails> readHttpDetails(HttpSource source, HttpSourceManga manga) => source.getMangaDetails(manga);

main() {
  HttpSourceMangaDetails(url: '/manga', name: 'Title', cover: '');
  HttpSourceManga(url: '/manga', name: 'Title', cover: '').status;
  final details = HttpSourceMangaDetails(url: '/manga', name: 'Title', cover: '', chapters: []);
  HttpSourceMangaEntries(mangas: [details]);
}
''';
    final resolved = await resolve(source, [...dartLibraries, ...evalLibraries]);
    final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
    expect(
      errors.map((error) => error.errorCode.name.toLowerCase()),
      unorderedEquals(['missing_required_argument', 'undefined_getter', 'list_element_type_not_assignable']),
    );
  });

  test('HTTP and core detail list literals preserve their chapter types', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final details = HttpSourceMangaDetails(
    url: '/manga', name: 'Title', cover: '', chapters: [HttpSourceChapter(url: '/chapter', name: 'Chapter')],
  );
  final httpDetails = <HttpSourceMangaDetails>[details];
  final coreDetails = <SourceMangaDetails>[details];
  final HttpSourceChapter httpChapter = httpDetails.single.chapters.single;
  final SourceChapter chapter = coreDetails.single.chapters.single;
  return [httpChapter.url, chapter.name];
}
''';
    expect(await evalValidSource(source), ['/chapter', 'Chapter']);
  });

  test('Prefixed source details preserve omitted and explicit empty values', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart' as source;

main() {
  final absent = source.HttpSourceMangaDetails(url: '/manga', name: 'Title', cover: '/cover', chapters: []);
  final empty = source.HttpSourceMangaDetails(
    url: '/manga', name: 'Title', cover: '/cover',
    status: source.SourceMangaStatus.unknown, description: '', authors: [], tags: [], languages: [], chapters: [],
  );
  final parseStatus = source.SourceMangaStatus.fromJson;
  return <dynamic>[
    absent.status, absent.description, absent.authors, absent.tags, absent.languages, absent.chapters,
    empty.status == parseStatus('unknown'), empty.description, empty.authors, empty.tags, empty.languages, empty.chapters,
    source.SourceMangaStatus.values.first == empty.status,
  ];
}
''';
    expect(await evalValidSource(source), [
      null,
      null,
      null,
      null,
      null,
      [],
      true,
      '',
      [],
      [],
      [],
      [],
      true,
    ]);
  });

  test('Manga details preserve source field values through the bridge', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final SourceMangaDetails manga = HttpSourceMangaDetails(
    url: '/manga', name: 'Title', cover: '/cover',
    status: SourceMangaStatus.ongoing, description: 'First paragraph\\nSecond paragraph',
    authors: <SourceMangaAuthor>[
      SourceMangaAuthor(name: ' Author ', role: 'Writer', url: 'https://example.com/authors/1'),
      SourceMangaAuthor.fromJson({'name': 'Author', 'role': 'Writer', 'url': 'https://example.com/authors/1'}),
    ],
    tags: <SourceMangaTag>[
      SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', id: '1', url: 'https://example.com/categories/1'),
      SourceMangaTag.fromJson({'type': 'tag', 'name': 'Space'}),
    ],
    languages: <String>['zh-Hans', 'ja'], chapters: [],
  );
  final dynamic author = manga.authors!.first;
  return <dynamic>[
    manga.status!.toJson(), manga.description,
    manga.authors!.first.name, manga.authors!.first.role, author.role, manga.authors!.first.url, manga.authors!.last.toJson(),
    manga.tags!.first.name, manga.tags!.first.type.toJson(), manga.tags!.first.id, manga.tags!.first.url,
    manga.tags!.last.toJson(), manga.tags!.last.url,
    manga.authors!.first is SourceMangaAuthor, manga.tags!.first is SourceMangaTag,
    manga.languages,
  ];
}
''';
    expect(await evalValidSource(source), [
      'ongoing',
      'First paragraph\nSecond paragraph',
      ' Author ',
      'Writer',
      'Writer',
      'https://example.com/authors/1',
      {'name': 'Author', 'role': 'Writer', 'url': 'https://example.com/authors/1'},
      'Adventure',
      'category',
      '1',
      'https://example.com/categories/1',
      {'type': 'tag', 'name': 'Space', 'id': null, 'url': null},
      null,
      true,
      true,
      ['zh-Hans', 'ja'],
    ]);
  });

  test('Source enum values retain their host identity and JSON codes', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final status = SourceMangaStatus.fromJson('hiatus');
  final type = SourceMangaTagType.fromJson('character');
  return <dynamic>[
    status, type,
    status == SourceMangaStatus.hiatus,
    status is SourceMangaStatus,
    type == SourceMangaTagType.character,
    type is SourceMangaTagType,
    SourceMangaStatus.values.map((value) => value.toJson()).toList(),
    SourceMangaTagType.values.map((value) => value.toJson()).toList(),
  ];
}
''';
    expect(await evalValidSource(source), [
      SourceMangaStatus.hiatus,
      SourceMangaTagType.character,
      true,
      true,
      true,
      true,
      ['unknown', 'ongoing', 'completed', 'hiatus', 'cancelled'],
      ['tag', 'character', 'category', 'other'],
    ]);
  });

  test('Source requests accept method and headers', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<dynamic> request() {
    return fetchJson('/chapter', method: 'POST', headers: {'x-source': 'chapter'});
  }

  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) => throw 'unused';
  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) => throw 'unused';
  Future<HttpSourceChapterImages> getChapterImages(HttpSourceChapter chapter) => throw 'unused';
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
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourceImageBytes> getImageBytes(HttpSourceImage image) async {
    final bytes = await fetchBytes(image.url);
    return HttpSourceImageBytes.fromBytes(bytes, extra: image.extra);
  }

  Future<SourceImageBytes> readImage(Source source, SourceImage image) => source.getImageBytes(image);

  List<dynamic> readFields(SourceImageBytes result) => <dynamic>[result.type, result.data, result.extra];

  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) => throw 'unused';
  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) => throw 'unused';
  Future<HttpSourceChapterImages> getChapterImages(HttpSourceChapter chapter) => throw 'unused';
}

main() => Example();
''';
    final instance = await evalValidSource(source) as ObjInstance;
    final bytes = HttpSourceBytes(type: 'png', data: [0, 1], statusCode: 200, responseHeaders: Headers.fromMap({}));
    Future<HttpSourceBytes> fetchBytes(String url, {String? method}) async => bytes;
    instance.props['fetchBytes'] = EvalProperty.getter((_) => fetchBytes);
    final image = HttpSourceImage(url: '/chapter', extra: {'frame': 'chapter'});
    final result = await instance.invoke('readImage', [instance, image]) as HttpSourceImageBytes;
    expect(result.data, same(bytes.data));
    expect(result.statusCode, bytes.statusCode);
    expect(result.responseHeaders, same(bytes.responseHeaders));
    expect(result.extra, same(image.extra));
    expect(await instance.invoke('readFields', [result]), [bytes.type, bytes.data, image.extra]);
  });

  test('Image metadata is available through SourceImage', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

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

  test('Scripts can use Dio content type constants in response headers', () async {
    const source = '''
import 'package:dio/dio.dart';

main() {
  final types = [
    Headers.jsonContentType,
    Headers.formUrlEncodedContentType,
    Headers.textPlainContentType,
    Headers.multipartFormDataContentType,
  ];
  return [for (final type in types) Headers.fromMap({Headers.contentTypeHeader: [type]}).value(Headers.contentTypeHeader)];
}
''';
    final expected = [
      Headers.jsonContentType,
      Headers.formUrlEncodedContentType,
      Headers.textPlainContentType,
      Headers.multipartFormDataContentType,
    ];
    expect(await evalValidSource(source), expected);
  });

  test('HTTP bytes construct and copy all declared response fields', () async {
    const source = '''
import 'package:dio/dio.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final headers = Headers.fromMap({Headers.contentTypeHeader: ['image/png']});
  final bytes = HttpSourceBytes(type: 'png', data: [0], statusCode: 200, responseHeaders: headers);
  final copiedHeaders = Headers();
  copiedHeaders.set(Headers.contentTypeHeader, 'image/gif');
  final copied = bytes.copyWith(type: 'gif', data: [1], statusCode: 201, responseHeaders: copiedHeaders);
  return <HttpSourceBytes>[bytes, copied];
}
''';
    final [bytes, copied] = await evalValidSource(source) as List<HttpSourceBytes>;
    expect(bytes.type, 'png');
    expect(bytes.data, [0]);
    expect(bytes.statusCode, 200);
    expect(bytes.responseHeaders.value(Headers.contentTypeHeader), 'image/png');
    expect(copied.type, 'gif');
    expect(copied.data, [1]);
    expect(copied.statusCode, 201);
    expect(copied.responseHeaders.value(Headers.contentTypeHeader), 'image/gif');
  });

  test('Image bytes preserve omitted fields and allow replacing or clearing extra from a script', () async {
    const source = '''
import 'package:dio/dio.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example {
  List<HttpSourceImageBytes> repaint(HttpSourceImageBytes bytes) {
    final jpeg = bytes.copyWith(type: 'jpg', data: [1, 2]);
    final replaced = jpeg.copyWith(statusCode: 202, responseHeaders: Headers(), extra: false);
    return [jpeg, replaced, replaced.copyWith(extra: null)];
  }
}

main() => Example();
''';
    final instance = await evalValidSource(source) as ObjInstance;
    final bytes = HttpSourceImageBytes(type: 'png', data: [0], statusCode: 200, responseHeaders: Headers(), extra: 'seed');
    expect(bytes.copyWith(extra: kNoDefaultValue).extra, 'seed');
    final copies = await instance.invoke('repaint', [bytes]) as List<HttpSourceImageBytes>;
    expect(copies.map((copy) => copy.extra), ['seed', false, null]);
    expect(copies.map((copy) => copy.statusCode), [200, 202, 202]);
    expect(copies.first.responseHeaders, same(bytes.responseHeaders));
    expect(copies[1].responseHeaders, isNot(same(bytes.responseHeaders)));
    expect(copies.last.responseHeaders, same(copies[1].responseHeaders));
    expect(copies.last.type, 'jpg');
    expect(copies.last.data, [1, 2]);
    expect(copies.last.data, same(copies.first.data));
    expect(bytes.type, 'png');
    expect(bytes.data, [0]);
    expect(bytes.extra, 'seed');
  });

  test('HTTP byte constructors and copies reject invalid response headers during script analysis', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final bytes = HttpSourceBytes(type: 'png', data: [], statusCode: 200, responseHeaders: 'invalid');
  final image = HttpSourceImageBytes(type: 'png', data: [], statusCode: 200, responseHeaders: 'invalid');
  bytes.copyWith(responseHeaders: 'invalid');
  image.copyWith(responseHeaders: 'invalid');
}
''';
    final resolved = await resolve(source, [...dartLibraries, ...evalLibraries]);
    final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
    expect(errors.map((error) => error.errorCode.name.toLowerCase()), List.filled(4, 'argument_type_not_assignable'));
  });

  test('Image byte overrides survive compute initialization', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourceImageBytes> getImageBytes(HttpSourceImage image) async {
    return HttpSourceImageBytes(type: 'png', data: [0], statusCode: 200, responseHeaders: image.extra);
  }

  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) => throw 'unused';
  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) => throw 'unused';
  Future<HttpSourceChapterImages> getChapterImages(HttpSourceChapter chapter) => throw 'unused';
}

main() => Example();
''';
    await expectValidSource(source);
    final instance = await compute((source) async => await eval(source, libraries: evalLibraries) as ObjInstance, source);
    final headers = Headers.fromMap({});
    final result = await instance.invoke('getImageBytes', [HttpSourceImage(url: '/chapter', extra: headers)]) as HttpSourceImageBytes;
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
