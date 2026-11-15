import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart'; // ignore: depend_on_referenced_packages
import 'package:tsukuyomi/constants/mock.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  });

  test('Index details persist as separate columns and survive source conversion', () async {
    final container = await _seed();
    final database = container.read(databaseProvider);
    final manga = await _read(container);
    expect(manga.status, SourceMangaStatus.ongoing);
    expect(manga.description, contains('\n\n'));
    expect(manga.creators, [
      const SourceMangaCreator(name: '星野灯（原作）', url: 'https://example.com/authors/1'),
      const SourceMangaCreator(name: '月见凪'),
    ]);
    const tag = SourceMangaTag(type: SourceMangaTagType.category, name: '奇幻', url: 'https://example.com/categories/1');
    expect(manga.tags.first, tag);
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
      {'name': '星野灯（原作）', 'url': 'https://example.com/authors/1'},
      {'name': '月见凪'},
    ]);
    expect(jsonDecode(row.read<String>('tags')), [
      {'type': 'category', 'name': '奇幻', 'url': 'https://example.com/categories/1'},
      {'type': 'tag', 'name': '冒险'},
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
        creators: [const SourceMangaCreator(name: '新作者', url: 'https://example.com/authors/2')],
        tags: [const SourceMangaTag(type: SourceMangaTagType.other, name: '新标签', url: 'https://example.com/tags/2')],
        languages: ['zxx'],
      ),
    );
    final fetched = await _read(container);
    expect(fetched.creators.single.url, 'https://example.com/authors/2');
    expect(fetched.tags.single.url, 'https://example.com/tags/2');
    await service.updateFavorite(original.id, !original.favorite);
    expect(await _read(container), fetched.copyWith(favorite: false));
  });

  test('New source records and index records without details use database defaults', () async {
    final container = await _seed(omitDetails: true);
    final database = container.read(databaseProvider);
    final original = await _read(container);
    _expectEmptyDetails(original);
    final service = container.read(mangaServiceProvider);
    const sourceManga = HttpSourceManga(url: 'new-url', name: 'New title', cover: 'new-cover');
    final id = await service.insertSourceManga(original.source, sourceManga);
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
    final tags = [for (final type in SourceMangaTagType.values) SourceMangaTag(type: type, name: '同名标签')];
    for (final status in SourceMangaStatus.values) {
      final sourceManga = HttpSourceManga(url: original.url, name: original.title, cover: original.cover, status: status, tags: tags);
      await service.insertSourceManga(original.source, sourceManga);
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
      final sourceManga = HttpSourceManga(
        url: url,
        name: 'Invalid update',
        cover: 'new-cover',
        description: 'New description',
        languages: ['zh_hans'],
      );
      await expectLater(service.insertSourceManga(original.source, sourceManga), throwsFormatException);
    }
    const update = MangaTableCompanion(id: Value(1600), languages: Value(['pt-br']));
    await expectLater(container.read(mangaRepositoryProvider).updateManga(update), throwsFormatException);
    expect(await _read(container), original);
    final database = container.read(databaseProvider);
    expect(await database.select(database.mangaTable).get(), hasLength(1));
  });

  test('Mock parsing rejects unsupported tag types such as invalid_type', () {
    final json = _mangaJson(_json());
    json['tags'] = [
      {'type': 'invalid_type', 'name': '冒险'},
    ];
    expect(() => MockManga.fromJson(json), throwsArgumentError);
  });

  for (final entry in [
    (column: 'status', value: 'invalid', matcher: throwsArgumentError),
    (column: 'creators', value: '{}', matcher: throwsA(isA<TypeError>())),
    (column: 'tags', value: '[{"type":"invalid_type","name":"冒险"}]', matcher: throwsArgumentError),
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

Future<ProviderContainer> _seed({bool omitDetails = false}) async {
  final json = _json();
  if (omitDetails) {
    final manga = _mangaJson(json);
    for (final key in _detailFields) {
      manga.remove(key);
    }
  }
  final assets = {'assets/sources/index.json': jsonEncode(json), 'assets/sources/example.dart': 'main() => null;'};
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  rootBundle.clear();
  messenger.setMockMessageHandler('flutter/assets', (message) async {
    final key = utf8.decode(message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
    final content = assets[key];
    return content == null ? null : ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  });

  final database = TsukuyomiDatabase.forTesting(NativeDatabase.memory());
  final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(database)]);
  addTearDown(() async {
    container.dispose();
    await database.close();
    rootBundle.clear();
    messenger.setMockMessageHandler('flutter/assets', null);
  });
  await database.select(database.sourceTable).get();
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
