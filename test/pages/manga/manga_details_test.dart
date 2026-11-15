import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart'; // ignore: depend_on_referenced_packages
import 'package:tsukuyomi/constants/assets.dart';
import 'package:tsukuyomi/constants/mock.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  setUpAll(() {
    if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  });

  test('Index details persist as separate columns and survive source conversion', () async {
    final container = await _seed();
    final database = container.read(databaseProvider);
    final manga = await _read(container);
    expect(database.schemaVersion, 1);
    expect(manga.status, SourceMangaStatus.ongoing);
    expect(manga.description, contains('\n\n'));
    expect(manga.creators, [const SourceMangaCreator(name: '星野灯'), const SourceMangaCreator(name: '月见凪')]);
    expect(manga.tags.first, const SourceMangaTag(name: '奇幻', type: SourceMangaTagType.category));
    expect(manga.languages, ['ja', 'zh-Hans']);
    expect(manga.favorite, isTrue);
    expect(manga.auto, isTrue);
    final source = manga.toHttpSourceManga();
    expect(source.status, manga.status);
    expect(source.description, manga.description);
    expect(source.creators, manga.creators);
    expect(source.tags, manga.tags);
    expect(source.languages, manga.languages);
    final row = await database.customSelect('SELECT * FROM manga').getSingle();
    expect(row.data.containsKey('metadata'), isFalse);
    expect(row.read<String>('status'), 'ongoing');
    expect(jsonDecode(row.read<String>('creators')), [
      {'name': '星野灯'},
      {'name': '月见凪'},
    ]);
    expect(jsonDecode(row.read<String>('tags')), [
      {'name': '奇幻', 'type': 'category'},
      {'name': '冒险', 'type': 'tag'},
    ]);
    expect(jsonDecode(row.read<String>('languages')), ['ja', 'zh-Hans']);
  });

  test('Source patches preserve omitted details and independently updated user state', () async {
    final container = await _seed();
    final service = container.read(mangaServiceProvider);
    final repository = container.read(mangaRepositoryProvider);
    final original = await _read(container);
    final checked = DateTime.utc(2026, 11, 15);
    await repository.updateLastCheckAt(original.id, checked);
    await repository.updateManga(MangaTableCompanion(id: Value(original.id), auto: const Value(false)));
    await service.updateFavorite(original.id, false);
    await service.insertSourceManga(original.source, HttpSourceManga(url: original.url, name: 'New title', cover: 'new-cover'));
    final updated = await _read(container);
    expect(updated.title, 'New title');
    expect(updated.cover, 'new-cover');
    expect(updated.creators, original.creators);
    expect(updated.tags, original.tags);
    expect(updated.languages, original.languages);
    expect(updated.description, original.description);
    expect(updated.status, original.status);
    expect(updated.favorite, isFalse);
    expect(updated.auto, isFalse);
    expect(updated.lastCheckAt?.toUtc(), checked);

    await service.insertSourceManga(
      original.source,
      HttpSourceManga(
        url: original.url,
        name: updated.title,
        cover: updated.cover,
        status: SourceMangaStatus.unknown,
        description: '',
        creators: [],
        tags: [],
        languages: [],
      ),
    );
    final cleared = await _read(container);
    _expectEmptyDetails(cleared);
    expect(cleared.favorite, isFalse);
    expect(cleared.auto, isFalse);
    expect(cleared.lastCheckAt?.toUtc(), checked);
  });

  test('Favorite changes from an older snapshot retain newly fetched details', () async {
    final container = await _seed();
    final service = container.read(mangaServiceProvider);
    final original = await _read(container);
    await service.insertSourceManga(
      original.source,
      HttpSourceManga(
        url: original.url,
        name: 'New title',
        cover: 'new-cover',
        status: SourceMangaStatus.completed,
        description: 'New description',
        creators: [const SourceMangaCreator(name: '新作者')],
        tags: [const SourceMangaTag(name: '新标签', type: SourceMangaTagType.other)],
        languages: ['zxx'],
      ),
    );
    final fetched = await _read(container);
    await service.updateFavorite(original.id, !original.favorite);
    expect(await _read(container), fetched.copyWith(favorite: false));
  });

  for (final explicitNull in [false, true]) {
    test('Repeated index imports preserve omitted details and user state, explicitNull=$explicitNull', () async {
      final container = await _seed();
      final database = container.read(databaseProvider);
      final repository = container.read(mangaRepositoryProvider);
      final checked = DateTime.utc(2026, 11, 15);
      await repository.updateManga(
        const MangaTableCompanion(id: Value(1600), favorite: Value(false), auto: Value(false), description: Value('Fetched description')),
      );
      await repository.updateLastCheckAt(1600, checked);
      final previous = await _read(container);
      await database.seedDatabase(await _index(omitDetails: true, explicitNull: explicitNull));
      expect(await _read(container), previous);

      await database.seedDatabase(await _index());
      final refreshed = await _read(container);
      expect(refreshed.description, startsWith('穿越星海'));
      expect(refreshed.favorite, isFalse);
      expect(refreshed.auto, isFalse);
      expect(refreshed.lastCheckAt?.toUtc(), checked);
      expect(await database.select(database.mangaTable).get(), hasLength(1));
    });
  }

  test('An index can explicitly clear details without resetting user settings', () async {
    final container = await _seed();
    final database = container.read(databaseProvider);
    await container.read(mangaServiceProvider).updateFavorite(1600, false);
    final json = _json();
    _mangaJson(json).addAll({'status': 'unknown', 'description': '', 'creators': [], 'tags': [], 'languages': [], 'auto': false});
    await database.seedDatabase(await _load(json));
    final manga = await _read(container);
    _expectEmptyDetails(manga);
    expect(manga.favorite, isFalse);
    expect(manga.auto, isTrue);
  });

  test('New source records and index records without details use database defaults', () async {
    final container = await _seed(omitDetails: true);
    final database = container.read(databaseProvider);
    final original = await _read(container);
    _expectEmptyDetails(original);
    final id = await container
        .read(mangaServiceProvider)
        .insertSourceManga(
          original.source,
          const HttpSourceManga(url: 'new-url', name: 'New title', cover: 'new-cover'),
        );
    final inserted = await container.read(mangaRepositoryProvider).queryManga(id);
    _expectEmptyDetails(inserted);
    expect(inserted.favorite, isFalse);
    expect(inserted.auto, isFalse);
    expect(inserted.lastCheckAt, null);
    expect(await _read(container), original);
    expect(await database.select(database.mangaTable).get(), hasLength(2));
  });

  test('Every status and tag type retain stable JSON codes in SQLite', () async {
    final container = await _seed();
    final database = container.read(databaseProvider);
    final original = await _read(container);
    final service = container.read(mangaServiceProvider);
    final tags = [for (final type in SourceMangaTagType.values) SourceMangaTag(name: '同名标签', type: type)];
    for (final status in SourceMangaStatus.values) {
      await service.insertSourceManga(
        original.source,
        HttpSourceManga(url: original.url, name: original.title, cover: original.cover, status: status, tags: tags),
      );
      final manga = await _read(container);
      expect(manga.status, status);
      expect(manga.tags, tags);
      final row = await database.customSelect('SELECT status, tags FROM manga').getSingle();
      expect(row.read<String>('status'), status.toJson());
      expect(jsonDecode(row.read<String>('tags')), tags.map((tag) => tag.toJson()).toList());
    }
  });

  test('Invalid details leave existing rows unchanged and cannot be inserted', () async {
    final container = await _seed();
    final original = await _read(container);
    final service = container.read(mangaServiceProvider);
    for (final url in [original.url, 'new-url']) {
      await expectLater(
        service.insertSourceManga(
          original.source,
          HttpSourceManga(url: url, name: 'Invalid update', cover: 'new-cover', description: 'New description', languages: ['zh_hans']),
        ),
        throwsFormatException,
      );
    }
    await expectLater(
      container.read(mangaRepositoryProvider).updateManga(const MangaTableCompanion(id: Value(1600), languages: Value(['pt-br']))),
      throwsFormatException,
    );
    expect(await _read(container), original);
    final database = container.read(databaseProvider);
    expect(await database.select(database.mangaTable).get(), hasLength(1));
  });

  test('Invalid index details report configuration errors instead of an empty catalog', () async {
    for (final entry in <(String, Object)>[
      ('id', 1600.5),
      ('status', '连载中'),
      ('languages', ['chinese']),
      ('languages', ['zh_Hans']),
      ('languages', ['pt-br']),
      ('languages', [' ja ']),
      ('languages', [1]),
      ('description', 1),
      (
        'creators',
        [
          {'name': ''},
        ],
      ),
      (
        'tags',
        [
          {'name': '冒险', 'type': 'genre'},
        ],
      ),
      ('auto', 'true'),
    ]) {
      final json = _json();
      _mangaJson(json)[entry.$1] = entry.$2;
      await expectLater(
        _load(json),
        throwsA(isA<FormatException>().having((error) => error.message, 'message', contains('assets/sources/index.json'))),
      );
    }
    for (final index in ['{', '{}', 'null']) {
      await expectLater(getMockDatabase(bundle: _Assets({'assets/sources/index.json': index})), throwsFormatException);
    }
  });

  test('Missing source files surface their path instead of falling back to example data', () async {
    final json = _json();
    await expectLater(
      getMockDatabase(bundle: _Assets({'assets/sources/index.json': jsonEncode(json)})),
      throwsA(isA<FlutterError>().having((error) => error.toString(), 'message', contains('assets/sources/example.dart'))),
    );
  });

  test('Only a missing index uses example data and disabled sources do not load scripts', () async {
    final fallback = await getMockDatabase(bundle: _Assets({Assets.sourceExample: 'main() => null;'}));
    final container = _container();
    final database = container.read(databaseProvider);
    await database.seedDatabase(fallback);
    final manga = await database.select(database.mangaTable).getSingle();
    expect(manga.title, 'Example Manga');
    _expectEmptyDetails(manga);

    final json = _json();
    json.single['enabled'] = false;
    final disabled = await getMockDatabase(bundle: _Assets({'assets/sources/index.json': jsonEncode(json)}));
    expect(disabled.sources, isEmpty);
    expect(disabled.mangas, isEmpty);
  });

  for (final entry in [
    (column: 'status', value: 'invalid', matcher: throwsArgumentError),
    (column: 'creators', value: '{}', matcher: throwsA(isA<TypeError>())),
    (column: 'tags', value: '[{"name":"冒险","type":"genre"}]', matcher: throwsArgumentError),
    (column: 'languages', value: '["zh_hans"]', matcher: throwsFormatException),
  ]) {
    test('Malformed stored ${entry.column} reports an error instead of returning an empty value', () async {
      final container = await _seed();
      await container.read(databaseProvider).customStatement('UPDATE manga SET ${entry.column} = ? WHERE id = ?', [entry.value, 1600]);
      await expectLater(_read(container), entry.matcher);
    });
  }
}

const _detailFields = ['status', 'description', 'creators', 'tags', 'languages'];

List<dynamic> _json() => jsonDecode(File('test/fixtures/manga_index.json').readAsStringSync()) as List<dynamic>;

Map<String, dynamic> _mangaJson(List<dynamic> json) => (json.single['mangas'] as List<dynamic>).single as Map<String, dynamic>;

Future<MockDatabase> _load(List<dynamic> json) {
  return getMockDatabase(
    bundle: _Assets({'assets/sources/index.json': jsonEncode(json), 'assets/sources/example.dart': 'main() => null;'}),
  );
}

Future<MockDatabase> _index({bool omitDetails = false, bool explicitNull = false}) {
  final json = _json();
  if (omitDetails) {
    final manga = _mangaJson(json);
    for (final key in _detailFields) {
      if (explicitNull) {
        manga[key] = null;
      } else {
        manga.remove(key);
      }
    }
  }
  return _load(json);
}

Future<ProviderContainer> _seed({bool omitDetails = false}) async {
  final container = _container();
  await container.read(databaseProvider).seedDatabase(await _index(omitDetails: omitDetails));
  return container;
}

ProviderContainer _container() {
  final database = _Database();
  final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(database)]);
  addTearDown(() async {
    container.dispose();
    await database.close();
  });
  return container;
}

Future<DatabaseManga> _read(ProviderContainer container) => container.read(mangaRepositoryProvider).queryManga(1600);

void _expectEmptyDetails(DatabaseManga manga) {
  expect(manga.status, SourceMangaStatus.unknown);
  expect(manga.description, isEmpty);
  expect(manga.creators, isEmpty);
  expect(manga.tags, isEmpty);
  expect(manga.languages, isEmpty);
}

class _Database extends TsukuyomiDatabase {
  _Database() : super.forTesting(NativeDatabase.memory());

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'));
}

class _Assets extends CachingAssetBundle {
  _Assets(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}
