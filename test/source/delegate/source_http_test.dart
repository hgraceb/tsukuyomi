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

  test('Manga details survive host isolate calls in both directions', () async {
    const source = '''
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';

  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query) async {
    return HttpSourcePage<HttpSourceManga>(next: false, data: <HttpSourceManga>[
      HttpSourceManga(
        url: '/manga', name: 'Title', cover: '/cover', status: 'completed', description: 'Synopsis',
        creators: <SourceMangaCreator>[SourceMangaCreator(name: 'Author')],
        tags: <SourceMangaTag>[SourceMangaTag(name: 'Adventure', type: 'genre')],
        languages: <String>['ja', 'zh-Hans'],
      ),
    ]);
  }

  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga) async {
    return <HttpSourceChapter>[
      HttpSourceChapter(url: manga.url, name: manga.creators!.first.name,
        date: manga.status! + '/' + manga.description! + '/' + manga.tags!.first.type + '/' + manga.languages!.last),
    ];
  }
}

main() => Example();
''';
    final instance = await compute((source) => eval(source, libraries: evalLibraries), source) as ObjInstance;
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    final page = await host.getSourceMangas(HttpSourceQuery(keyword: 'Title'));
    final manga = page.data.single;
    expect(manga.creators, [const SourceMangaCreator(name: 'Author')]);
    expect(manga.tags, [const SourceMangaTag(name: 'Adventure', type: 'genre')]);
    final chapters = await host.getMangaChapters(manga);
    expect(chapters.single.name, 'Author');
    expect(chapters.single.date, 'completed/Synopsis/genre/zh-Hans');
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

  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga) async {
    await store(manga.name);
    return <HttpSourceChapter>[];
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
    await first.getMangaChapters(const HttpSourceManga(url: 'first', name: 'first', cover: ''));
    await second.getMangaChapters(const HttpSourceManga(url: 'second', name: 'second', cover: ''));
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
