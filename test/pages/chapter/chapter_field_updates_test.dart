import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/chapter/chapter_service.dart';
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import '../../fixtures/update_fixtures.dart';

const _chapter = DatabaseChapter(
  id: 1,
  manga: 1,
  index: 3,
  title: 'old-title',
  url: 'chapter-url',
  date: 'old-date',
  public: true,
  images: 12,
  progress: 7,
);

final _other = _chapter.copyWith(id: 2, url: 'other-url');
final _manga = mangaFixture(1);
final _source = UpdateSourceFixture(
  chapters: [
    const HttpSourceChapter(url: 'chapter-url', name: 'new-title', date: 'new-date', public: false),
    _other.toHttpSourceChapter(),
  ],
);

void main() {
  setUpAll(() {
    // 使用 Windows 自带 SQLite，测试不依赖应用构建目录中的 DLL
    if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  });

  test('Source synchronization preserves reading progress saved after its query', () async {
    final requested = Completer<void>();
    final pending = Completer<void>();
    final container = await _container(requested: requested, pending: pending.future);
    final sync = container.read(chapterSyncWithSourceProvider(_source, _manga)).sync();
    await requested.future;

    await container.read(chapterServiceProvider).updateChapterProgress(_chapter.id, images: 20, progress: 9);
    pending.complete();
    final result = await sync;

    expect(result.updateCount, 1);
    expect(await _read(container), _chapter.copyWith(title: 'new-title', date: 'new-date', public: false, images: 20, progress: 9));
    expect(await _read(container, 2), _other);
  });

  test('A reading save from an old snapshot preserves newer source metadata', () async {
    final container = await _container();
    await container.read(chapterSyncWithSourceProvider(_source, _manga)).sync();

    await container.read(chapterServiceProvider).updateChapterProgress(_chapter.id, images: 20, progress: 9);

    expect(await _read(container), _chapter.copyWith(title: 'new-title', date: 'new-date', public: false, images: 20, progress: 9));
    expect(await _read(container, 2), _other);
  });

  test('Late reading and source writes cannot recreate a deleted chapter or its queue entry', () async {
    final requested = Completer<void>();
    final pending = Completer<void>();
    final container = await _container(requested: requested, pending: pending.future);
    final database = container.read(databaseProvider);
    await database.into(database.downloadTable).insert(_chapter.toDownloadable(1));
    final sync = container.read(chapterSyncWithSourceProvider(_source, _manga)).sync();
    await requested.future;

    await (database.delete(database.chapterTable)..where((row) => row.id.equals(1))).go();
    expect(await container.read(chapterServiceProvider).updateChapterProgress(_chapter.id, images: _chapter.images, progress: 9), isFalse);
    pending.complete();
    await sync;

    expect(await (database.select(database.chapterTable)..where((row) => row.id.equals(1))).get(), isEmpty);
    expect(await database.select(database.downloadTable).get(), isEmpty);
    expect(await _read(container, 2), _other);
  });
}

Future<ProviderContainer> _container({Completer<void>? requested, Future<void>? pending}) async {
  final database = _Database();
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(database),
      if (requested != null) chapterRepositoryProvider.overrideWith((ref) => _PausedChapters(chapterRepository(ref), requested, pending!)),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await database.close();
  });
  await database.into(database.mangaTable).insert(_manga);
  await database.into(database.chapterTable).insert(_chapter);
  await database.into(database.chapterTable).insert(_other);
  return container;
}

Future<DatabaseChapter> _read(ProviderContainer container, [int id = 1]) {
  final database = container.read(databaseProvider);
  return (database.select(database.chapterTable)..where((row) => row.id.equals(id))).getSingle();
}

class _Database extends TsukuyomiDatabase {
  _Database() : super.forTesting(NativeDatabase.memory());

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'));
}

class _PausedChapters implements ChapterRepository {
  _PausedChapters(this.repository, this.requested, this.pending);

  final ChapterRepository repository;
  final Completer<void> requested;
  final Future<void> pending;

  @override
  Future<List<DatabaseChapter>> queryChaptersByMangaId(int mangaId) async {
    final snapshot = await repository.queryChaptersByMangaId(mangaId);
    if (!requested.isCompleted) requested.complete();
    await pending;
    return snapshot;
  }

  @override
  Future<bool> updateChapter(ChapterTableCompanion chapter) => repository.updateChapter(chapter);

  @override
  Future<void> batch({Iterable<int>? deletes, Iterable<ChapterTableCompanion>? inserts, Iterable<ChapterTableCompanion>? updates}) {
    return repository.batch(deletes: deletes, inserts: inserts, updates: updates);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
