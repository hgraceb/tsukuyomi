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

  test('Detail responses require chapters and search entries contain only basic fields', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

Future<SourceMangaDetails> readDetails(Source source, SourceManga manga) => source.getMangaDetails(manga);
Future<HttpSourceMangaDetails> readHttpDetails(HttpSource source, HttpSourceManga manga) => source.getMangaDetails(manga);

main() {
  HttpSourceMangaDetails(url: '/manga', name: 'Title', cover: '');
  HttpSourceManga(url: '/manga', name: 'Title', cover: '').status;
}
''';
    final resolved = await resolve(source, [...dartLibraries, ...evalLibraries]);
    final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
    expect(errors.map((error) => error.errorCode.name.toLowerCase()), unorderedEquals(['missing_required_argument', 'undefined_getter']));
  });

  test('Details expose the same chapter through HTTP and core declarations', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final details = HttpSourceMangaDetails(
    url: '/manga', name: 'Title', cover: '', chapters: [HttpSourceChapter(url: '/chapter', name: 'Chapter')],
  );
  final HttpSourceChapter httpChapter = details.chapters.single;
  final SourceMangaDetails core = details;
  final SourceChapter chapter = core.chapters.single;
  return [httpChapter.url, chapter.name];
}
''';
    expect(await evalValidSource(source), ['/chapter', 'Chapter']);
  });

  test('Prefixed source details preserve omitted values, explicit empty values and special language codes', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart' as source;

main() {
  final absent = source.HttpSourceMangaDetails(url: '/manga', name: 'Title', cover: '/cover', chapters: []);
  final empty = source.HttpSourceMangaDetails(
    url: '/manga', name: 'Title', cover: '/cover',
    status: source.SourceMangaStatus.unknown, description: '', authors: [], tags: [], languages: [], chapters: [],
  );
  final normalize = source.normalizeMangaLanguages;
  final parseStatus = source.SourceMangaStatus.fromJson;
  return <dynamic>[
    absent.status, absent.description, absent.authors, absent.tags, absent.languages, absent.chapters,
    empty.status == parseStatus('unknown'), empty.description, empty.authors, empty.tags, empty.languages, empty.chapters,
    normalize(['all', 'und-Latn', 'und', 'mul', 'zxx']),
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
      ['all', 'mul', 'und', 'und-Latn', 'zxx'],
      true,
    ]);
  });

  test('Manga details construct, normalize and read through the source bridge', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final SourceMangaDetails manga = HttpSourceMangaDetails(
    url: '/manga', name: 'Title', cover: '/cover',
    status: SourceMangaStatus.ongoing, description: 'First paragraph\\nSecond paragraph',
    authors: normalizeMangaAuthors(<SourceMangaAuthor>[
      SourceMangaAuthor(name: ' Author ', role: 'Writer', url: 'https://example.com/authors/1'),
      SourceMangaAuthor.fromJson({'name': 'Author', 'role': 'Writer', 'url': 'https://example.com/authors/1'}),
    ]),
    tags: normalizeMangaTags(<SourceMangaTag>[
      SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', url: 'https://example.com/categories/1'),
      SourceMangaTag.fromJson({'type': 'tag', 'name': 'Space'}),
    ]),
    languages: normalizeMangaLanguages(<String>['zh-Hans', 'ja']), chapters: [],
  );
  final dynamic author = manga.authors!.first;
  return <dynamic>[
    manga.status!.toJson(), manga.description,
    manga.authors!.first.name, manga.authors!.first.role, author.role, manga.authors!.first.url, manga.authors!.first.toJson(),
    manga.tags!.first.name, manga.tags!.first.type.toJson(), manga.tags!.first.url, manga.tags!.last.toJson(), manga.tags!.last.url,
    manga.authors!.first is SourceMangaAuthor, manga.tags!.first is SourceMangaTag,
    manga.languages,
  ];
}
''';
    expect(await evalValidSource(source), [
      'ongoing',
      'First paragraph\nSecond paragraph',
      'Author',
      'Writer',
      'Writer',
      'https://example.com/authors/1',
      {'name': 'Author', 'role': 'Writer', 'url': 'https://example.com/authors/1'},
      'Adventure',
      'category',
      'https://example.com/categories/1',
      {'type': 'tag', 'name': 'Space', 'url': null},
      null,
      true,
      true,
      ['ja', 'zh-Hans'],
    ]);
  });

  test('Source language validation rejects noncanonical codes through the bridge', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

main() {
  final rejected = <String>[];
  for (final value in <String>['zh_Hans', 'zh-hans', 'ja ']) {
    try {
      normalizeMangaLanguages(<String>[value]);
    } on FormatException {
      rejected.add(value);
    }
  }
  return rejected;
}
''';
    expect(await evalValidSource(source), ['zh_Hans', 'zh-hans', 'ja ']);
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
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourceBytes> getImageBytes(HttpSourceImage image) async {
    final bytes = await fetchBytes(image.url);
    return bytes.copyWith(extra: image.extra);
  }

  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) => throw 'unused';
  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) => throw 'unused';
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

  test('Image bytes construct and copy all declared response fields', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

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
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourceBytes> getImageBytes(HttpSourceImage image) async {
    return HttpSourceBytes(type: 'png', data: [0], statusCode: 200, responseHeaders: image.extra);
  }

  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) => throw 'unused';
  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) => throw 'unused';
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
