import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart'; // ignore: depend_on_referenced_packages
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import '../../fixtures/update_fixtures.dart';

const _chapter = DatabaseChapter(
  id: 1,
  manga: 1,
  index: 3,
  title: 'old-title',
  url: 'chapter-url',
  date: 'old-date',
  public: false,
  images: 12,
  progress: 7,
);

final _manga = mangaFixture(1);

void main() {
  setUpAll(() {
    if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  });

  test('Repeated URLs retain the first source entry and remain stable across synchronizations', () async {
    final container = await _container();
    final database = container.read(databaseProvider);
    const first = HttpSourceChapter(url: 'chapter-url', name: 'first-title', date: 'first-date');
    const duplicate = HttpSourceChapter(url: 'chapter-url', name: 'second-title', date: 'second-date', public: false);
    const sameTitle = HttpSourceChapter(url: 'other-url', name: 'first-title', date: 'first-date');
    final source = UpdateSourceFixture(chapters: [first, duplicate, sameTitle]);
    final sync = container.read(chapterSyncWithSourceProvider(source, _manga));

    final inserted = await sync.sync();
    final rows = await database.select(database.chapterTable).get();
    expect(inserted, const ChapterSyncResult(insertCount: 2, deleteCount: 0, updateCount: 0, sourceCount: 2));
    expect(rows.length, 2);
    final chapter = rows.singleWhere((row) => row.url == first.url);
    expect(chapter.title, first.name);
    expect(chapter.date, first.date);
    expect(chapter.public, first.public);
    expect(chapter.index, 0);
    expect(rows.singleWhere((row) => row.url == sameTitle.url).title, first.name);
    expect(rows.singleWhere((row) => row.url == sameTitle.url).index, 1);

    final unchanged = await sync.sync();
    expect(unchanged, const ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 0, sourceCount: 2));
    expect(await database.select(database.chapterTable).get(), unorderedEquals(rows));
  });

  test('Watched chapters follow source order after synchronization and later updates', () async {
    final container = await _container();
    final chapters = StreamIterator(container.read(mangaRepositoryProvider).watchChapters(_manga.id));
    addTearDown(chapters.cancel);
    expect(await chapters.moveNext(), isTrue);
    expect(chapters.current, isEmpty);
    const first = HttpSourceChapter(url: 'chapter/1', name: 'chapter-1');
    const second = HttpSourceChapter(url: 'chapter/2', name: 'chapter-2');
    const tenth = HttpSourceChapter(url: 'chapter/10', name: 'chapter-10');
    final source = UpdateSourceFixture(chapters: [first, second, tenth]);
    final sync = container.read(chapterSyncWithSourceProvider(source, _manga));

    await sync.sync();

    expect(await chapters.moveNext(), isTrue);
    expect(chapters.current.map((chapter) => chapter.url), [first.url, second.url, tenth.url]);

    const added = HttpSourceChapter(url: 'chapter/0', name: 'new-chapter');
    const renamed = HttpSourceChapter(url: 'chapter/2', name: 'renamed-chapter', public: false);
    await sync.apply([added, first, renamed, tenth]);

    expect(await chapters.moveNext(), isTrue);
    expect(chapters.current.map((chapter) => chapter.url), [added.url, first.url, second.url, tenth.url]);
    expect(chapters.current.map((chapter) => chapter.index), [0, 1, 2, 3]);
    expect(chapters.current[2].title, renamed.name);
    expect(chapters.current[2].public, isFalse);
  });

  for (final (scenario, urls, inserts, deletes) in [
    ('a chapter inserted in the middle', ['chapter/1', 'chapter/2', 'chapter/10'], 1, 0),
    ('a source reorder', ['chapter/10', 'chapter/1'], 0, 0),
    ('a removed chapter', ['chapter/10'], 0, 1),
  ]) {
    test('Source order preserves identity and user state after $scenario', () async {
      final container = await _container();
      final database = container.read(databaseProvider);
      final repository = container.read(mangaRepositoryProvider);
      final source = UpdateSourceFixture(
        chapters: [
          for (final url in ['chapter/1', 'chapter/10']) HttpSourceChapter(url: url, name: url),
        ],
      );
      final sync = container.read(chapterSyncWithSourceProvider(source, _manga));
      await sync.sync();
      final original = await repository.watchChapters(_manga.id).first;
      final tenth = original.last.copyWith(images: 12, progress: 7);
      final progress = ChapterTableCompanion(id: Value(tenth.id), images: const Value(12), progress: const Value(7));
      await container.read(chapterRepositoryProvider).updateChapter(progress);
      await database.into(database.downloadTable).insert(tenth.toDownloadable(1));
      final queued = await database.select(database.downloadTable).getSingle();
      final updated = [for (final url in urls) HttpSourceChapter(url: url, name: url)];

      final result = await sync.apply(updated);

      expect(result, ChapterSyncResult(insertCount: inserts, deleteCount: deletes, updateCount: 0, sourceCount: urls.length));
      final rows = await repository.watchChapters(_manga.id).first;
      expect(rows.map((chapter) => chapter.url), urls);
      expect(rows.map((chapter) => chapter.index), List.generate(urls.length, (index) => index));
      for (final chapter in original.where((chapter) => urls.contains(chapter.url))) {
        expect(rows.singleWhere((row) => row.url == chapter.url).id, chapter.id);
      }
      expect(rows.singleWhere((chapter) => chapter.url == tenth.url), tenth.copyWith(index: urls.indexOf(tenth.url)));
      expect(await database.select(database.downloadTable).getSingle(), queued);

      final unchanged = await sync.apply(updated);
      expect(unchanged, ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 0, sourceCount: urls.length));
      await sync.apply([]);
      expect(await repository.watchChapters(_manga.id).first, rows);
    });
  }

  test('Chapters with equal positions use ID order until source positions are synchronized', () async {
    final container = await _container();
    final database = container.read(databaseProvider);
    final repository = container.read(mangaRepositoryProvider);
    final first = _chapter.copyWith(index: 0, url: 'z');
    final second = _chapter.copyWith(id: 2, index: 0, url: 'a');
    await database.into(database.chapterTable).insert(first);
    await database.into(database.chapterTable).insert(second);
    expect(await repository.watchChapters(_manga.id).first, [first, second]);
    final source = UpdateSourceFixture(chapters: [second.toHttpSourceChapter(), first.toHttpSourceChapter()]);

    final result = await container.read(chapterSyncWithSourceProvider(source, _manga)).sync();

    expect(result, const ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 0, sourceCount: 2));
    expect(await repository.watchChapters(_manga.id).first, [second, first.copyWith(index: 1)]);
  });

  test('Metadata changes preserve the chapter identity, reading progress and queued download', () async {
    final container = await _container();
    final database = container.read(databaseProvider);
    await database.into(database.chapterTable).insert(_chapter);
    await database.into(database.downloadTable).insert(_chapter.toDownloadable(1));
    final queued = await database.select(database.downloadTable).getSingle();
    const renamed = HttpSourceChapter(url: 'chapter-url', name: 'new-title', date: 'new-date');
    final source = UpdateSourceFixture(chapters: [renamed, renamed]);

    final result = await container.read(chapterSyncWithSourceProvider(source, _manga)).sync();

    expect(result, const ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 1, sourceCount: 1));
    final expected = _chapter.copyWith(index: 0, title: renamed.name, date: renamed.date, public: true);
    expect(await database.select(database.chapterTable).getSingle(), expected);
    expect(await database.select(database.downloadTable).getSingle(), queued);
  });

  test('The database scopes URL uniqueness to a manga and rolls back conflicting batches', () async {
    final container = await _container();
    final database = container.read(databaseProvider);
    final otherMangaChapter = _chapter.copyWith(id: 2, manga: 2);
    await database.into(database.mangaTable).insert(mangaFixture(2));
    await database.into(database.chapterTable).insert(_chapter);
    await database.into(database.chapterTable).insert(otherMangaChapter);
    const added = HttpSourceChapter(url: 'new-url', name: 'new-title');
    const duplicate = HttpSourceChapter(url: 'chapter-url', name: 'different-title');

    await expectLater(
      container.read(chapterRepositoryProvider).batch(inserts: [added.toInsertable(1, index: 1), duplicate.toInsertable(1, index: 2)]),
      throwsA(isA<SqliteException>()),
    );

    expect(await database.select(database.chapterTable).get(), unorderedEquals([_chapter, otherMangaChapter]));
  });

  test('Concurrent synchronization cannot insert two rows for the same manga and URL', () async {
    final container = await _container(concurrentReads: true);
    final source = UpdateSourceFixture();
    final sync = container.read(chapterSyncWithSourceProvider(source, _manga));

    final results = await Future.wait(List.generate(2, (_) => AsyncValue.guard(sync.sync)));

    expect(results.where((result) => result.hasValue).single.requireValue.insertCount, 1);
    expect(results.where((result) => result.hasError).single.error, isA<SqliteException>());
    final database = container.read(databaseProvider);
    final row = await database.select(database.chapterTable).getSingle();
    expect(row.manga, _manga.id);
    expect(row.url, source.chapters.single.url);
  });
}

Future<ProviderContainer> _container({bool concurrentReads = false}) async {
  final database = _Database();
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      if (concurrentReads) chapterRepositoryProvider.overrideWith((ref) => _ConcurrentReads(chapterRepository(ref))),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await database.close();
  });
  await database.into(database.mangaTable).insert(_manga);
  return container;
}

class _Database extends TsukuyomiDatabase {
  _Database() : super.forTesting(NativeDatabase.memory());

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'));
}

class _ConcurrentReads implements ChapterRepository {
  _ConcurrentReads(this.repository);

  final ChapterRepository repository;

  final _ready = Completer<void>();

  int _reads = 0;

  @override
  Future<List<DatabaseChapter>> queryChaptersByMangaId(int mangaId) async {
    final snapshot = await repository.queryChaptersByMangaId(mangaId);
    if (++_reads == 2) _ready.complete();
    await _ready.future;
    return snapshot;
  }

  @override
  Future<void> batch({Iterable<int>? deletes, Iterable<ChapterTableCompanion>? inserts, Iterable<ChapterTableCompanion>? updates}) {
    return repository.batch(deletes: deletes, inserts: inserts, updates: updates);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
