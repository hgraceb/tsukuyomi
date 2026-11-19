import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/source/declaration/declaration.dart';
import 'package:tsukuyomi/source/delegate/source_http.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Basic entries and manga details cross the host isolate', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) async {
    if (query.page == 4) return HttpSourceMangaEntries(mangas: []);
    final mangas = ['/manga'].map((url) => HttpSourceManga(url: url, name: 'Title', cover: '/cover'));
    return HttpSourceMangaEntries(mangas: mangas.toList(), nextQuery: HttpSourceQuery(page: 4, keyword: query.keyword));
  }

  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) async {
    return HttpSourceMangaDetails(
      url: manga.url, name: manga.name, cover: manga.cover,
      status: SourceMangaStatus.completed, description: 'Synopsis',
      authors: <SourceMangaAuthor>[SourceMangaAuthor(name: 'Author', role: 'Writer', url: 'https://example.com/authors/1')],
      tags: <SourceMangaTag>[SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', url: 'https://example.com/categories/1')],
      languages: <String>['ja', 'zh-Hans'],
      chapters: [HttpSourceChapter(url: '/chapter', name: 'Chapter')],
    );
  }
}

main() => Example();
''';
    final instance = await compute((source) => eval(source, libraries: evalLibraries), source) as ObjInstance;
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    final entries = await host.getMangaEntries(HttpSourceQuery(keyword: 'Title'));
    final nextQuery = entries.nextQuery!;
    expect(nextQuery.page, 4);
    expect(nextQuery.keyword, 'Title');
    final last = await host.getMangaEntries(nextQuery);
    expect(last.mangas, isEmpty);
    expect(last.nextQuery, isNull);
    final manga = entries.mangas.single;
    expect((manga.url, manga.name, manga.cover), ('/manga', 'Title', '/cover'));
    final details = await host.getMangaDetails(manga);
    expect((details.url, details.name, details.cover), (manga.url, manga.name, manga.cover));
    expect(details.status, SourceMangaStatus.completed);
    expect(details.description, 'Synopsis');
    expect(details.authors, [const SourceMangaAuthor(name: 'Author', role: 'Writer', url: 'https://example.com/authors/1')]);
    const tag = SourceMangaTag(type: SourceMangaTagType.category, name: 'Adventure', url: 'https://example.com/categories/1');
    expect(details.tags, [tag]);
    expect(details.languages, ['ja', 'zh-Hans']);
    expect((details.chapters.single.url, details.chapters.single.name), ('/chapter', 'Chapter'));
  });

  test('Source getters work after initialization in compute', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

String get sourceName => 'Example';
class Example extends HttpSource {
  String get name => sourceName;
  String get baseUrl => 'https://example.com';
}

dynamic main() => Example();
    ''';
    final instance = await compute((source) => eval(source, libraries: evalLibraries), source) as ObjInstance;
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    expect(host.name, 'Example');
    expect(host.baseUrl, 'https://example.com');
    expect(await compute((instance) => instance.get('name'), instance), 'Example');
  });

  test('Host request headers use optional script parameter defaults', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Map<String, String> getRequestHeaders([String token = 'default']) => <String, String>{'token': token};
}

dynamic main() => Example();
    ''';
    final instance = await eval(source, libraries: evalLibraries) as ObjInstance;
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    expect(host.getRequestHeaders(), {'token': 'default'});
    expect(instance.invoke('getRequestHeaders', ['provided']), {'token': 'provided'});
    expect(host.getRequestHeaders(), {'token': 'default'});
  });

  test('Sources from the same script class bind callbacks to their own host', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  String name = '';
  final String baseUrl = 'https://example.com';

  int readId() => id;

  Future<String?> store(String value) async {
    await null;
    setStorage('value', value);
    return getStorage('value', null);
  }

  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) async {
    await store(manga.name);
    return HttpSourceMangaDetails(url: manga.url, name: manga.name, cover: manga.cover, chapters: []);
  }

  dynamic decode(String value) => parseJson(value);
}

dynamic main() {
  final first = Example();
  final second = Example();
  first.name = 'First';
  second.name = 'Second';
  return <dynamic>[first, second];
}
    ''';
    final instances = (await eval(source, libraries: evalLibraries) as List).cast<ObjInstance>();
    final preferences = await SharedPreferences.getInstance();
    final first = IsolateDioHttpSource(delegate: instances.first, preferences: preferences);
    final second = IsolateDioHttpSource(delegate: instances.last, preferences: preferences);
    expect(first.delegate.clazz, same(second.delegate.clazz));
    expect(first.name, 'First');
    expect(second.name, 'Second');
    expect(first.id, isNot(second.id));
    expect(await first.delegate.invoke('readId', null), first.id);
    expect(await second.delegate.invoke('readId', null), second.id);
    final releaseKey = 'source.storage.${first.id}';
    await preferences.setString(releaseKey, '{"release":"keep"}');
    await expectLater(first.delegate.invoke('store', ['first']), completion('first'));
    await expectLater(second.delegate.invoke('store', ['second']), completion('second'));
    expect(first.storage, {'value': 'first'});
    expect(second.storage, {'value': 'second'});
    await first.getMangaDetails(const HttpSourceManga(url: 'first', name: 'first', cover: ''));
    await second.getMangaDetails(const HttpSourceManga(url: 'second', name: 'second', cover: ''));
    expect(jsonDecode(preferences.getString(Keys.sourceStorage(first.id))!), {'value': 'first'});
    expect(jsonDecode(preferences.getString(Keys.sourceStorage(second.id))!), {'value': 'second'});
    expect(preferences.getString(releaseKey), '{"release":"keep"}');
    expect(await first.delegate.invoke('decode', ['{"value":"JSON"}']), {'value': 'JSON'});
    expect(first.delegate.clazz.props['parseJson'], isNull);
  });

  test('Host injection preserves methods declared by the script', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Script implementation';
  final String baseUrl = 'https://example.com';

  String? getStorage(String key, String? defaultValue) => 'script';

  String? load() => getStorage('value', null);
}

Example main() => Example();
    ''';
    final instance = await eval(source, libraries: evalLibraries) as ObjInstance;
    final property = instance.props['getStorage'];
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    expect(instance.props['getStorage'], same(property));
    expect(await host.delegate.invoke('load', null), 'script');
  });

  test('Script sources recognize bridged ancestors while casts preserve the delegate', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';
}

class Child extends Example {}

dynamic main() {
  final value = Child();
  final base = value as Source;
  try {
    throw value;
  } on Source catch (error) {
    return <String, dynamic>{
      'checks': <bool>[
        value is Child,
        value is Example,
        value is HttpSource,
        value is Source,
        (value as HttpSource) == value,
        base == value,
        base is Child,
        error == value,
      ],
      'delegate': value,
    };
  }
}
    ''';
    final result = await eval(source, libraries: evalLibraries) as Map;
    expect(result['checks'], [true, true, true, true, true, true, true, true]);
    final instance = result['delegate'] as ObjInstance;
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    expect(host.name, 'Example');
    expect(instance.clazz.name, 'Child');
  });
}
