import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart'; // ignore: depend_on_referenced_packages
import 'package:tsukuyomi/database/connection/native.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/download/download_repository.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/download/providers/download_path_provider.dart';
import 'package:tsukuyomi/providers/download/download_manager_provider.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

final _source = NoInstalledSource(1);

const _manga = DatabaseManga(
  id: 1,
  source: 1,
  url: 'manga-url',
  title: 'manga-title',
  cover: 'manga-cover',
  favorite: true,
  auto: true,
  lastCheckAt: null,
);

DatabaseChapter _chapter(int id, {bool public = true}) => DatabaseChapter(
  id: id,
  manga: 1,
  index: 0,
  title: 'chapter-title-$id',
  url: 'chapter-url-$id',
  date: 'chapter-date',
  public: public,
  images: 0,
  progress: 0,
);

DatabaseDownload _download(int id, {String? error}) => DatabaseDownload(
  source: 1,
  manga: 1,
  chapter: id,
  total: 10,
  progress: 4,
  error: error,
);

void main() {
  setUpAll(_useSystemSqlite);

  test('Only favorite auto manga can enqueue automatically', () async {
    final chapters = _Chapters([_chapter(1)]);
    final downloads = _Downloads([]);
    final manager = _Manager();
    final container = _createContainer(chapters, downloads, manager);
    final service = container.read(downloadServiceProvider);

    expect(await service.enqueueAutoDownloads(_source, _manga.copyWith(auto: false)), const DownloadEnqueueResult());
    expect(await service.enqueueAutoDownloads(_source, _manga.copyWith(favorite: false)), const DownloadEnqueueResult());
    expect(chapters.queries, 0);
    expect(downloads.inserted, isEmpty);
    expect(manager.wakes, 0);
  });

  test('Enqueue missing chapters, skip completed and queued, resume failed progress', () async {
    final chapters = _Chapters([_chapter(5, public: false), _chapter(4), _chapter(3), _chapter(2), _chapter(1)]);
    final downloads = _Downloads([_download(3), _download(4, error: 'download-error')]);
    final manager = _Manager();
    final container = _createContainer(chapters, downloads, manager, completed: {2});
    final service = container.read(downloadServiceProvider);

    final result = await service.enqueueAutoDownloads(_source, _manga);
    expect(result, const DownloadEnqueueResult(enqueuedCount: 2, skippedDownloaded: 1, skippedQueued: 1, skippedUnavailable: 1));
    expect(downloads.inserted, [1]);
    expect(downloads.updated, [_download(4)]);
    expect(manager.wakes, 0);

    final repeated = await service.enqueueAutoDownloads(_source, _manga);
    expect(repeated, const DownloadEnqueueResult(skippedDownloaded: 1, skippedQueued: 3, skippedUnavailable: 1));
    expect(downloads.inserted, [1]);
    expect(downloads.updated, [_download(4)]);
    expect(manager.wakes, 0);
  });

  test('A chapter failure does not stop others', () async {
    final chapters = _Chapters([_chapter(1), _chapter(2)]);
    final downloads = _Downloads([], failChapter: 1);
    final manager = _Manager();
    final container = _createContainer(chapters, downloads, manager);

    final result = await container.read(downloadServiceProvider).enqueueAutoDownloads(_source, _manga);
    expect(result.enqueuedCount, 1);
    expect(downloads.inserted, [2]);
    expect(result.failedChapters.keys, ['chapter-url-1']);
    expect(result.failedChapters['chapter-url-1'], contains('insert-error'));
    expect(manager.wakes, 0);
  });

  group('Auto enqueue with SQLite', () {
    final chapter = _chapter(1);
    late ProviderContainer container;
    late _Database database;
    late DownloadService service;
    late Future<bool> Function() directoryExists;

    setUp(() async {
      database = _Database();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          downloadManagerProvider.overrideWithValue(_Manager()),
          downloadChapterPathProvider(_source, _manga, chapter).overrideWith(() => _ChapterPath(() => directoryExists())),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
      });
      await database.into(database.mangaTable).insert(_manga);
      await database.into(database.chapterTable).insert(chapter);
      service = container.listen(downloadServiceProvider, (_, _) {}).read();
    });

    for (final failed in [null, _download(1, error: 'failed')]) {
      final action = failed == null ? 'queued' : 'resumed';
      test('Skips a chapter $action manually during the scan and preserves its progress', () async {
        final queued = _download(1).copyWith(progress: 7);
        if (failed != null) await database.into(database.downloadTable).insert(failed);
        DatabaseDownload? afterManualAction;
        directoryExists = () async {
          directoryExists = () async => false;
          if (failed == null) {
            await service.insertDownload(_source.id, chapter);
            await service.updateDownload(queued);
          } else {
            await service.updateDownload(queued.copyWith(error: failed.error));
            await service.resumeDownload(failed);
          }
          afterManualAction = await database.select(database.downloadTable).getSingle();
          return false;
        };

        final result = await service.enqueueAutoDownloads(_source, _manga);

        expect(afterManualAction, queued, reason: 'Progress after the manual download action');
        expect(await database.select(database.downloadTable).getSingle(), queued, reason: 'Progress after the automatic scan');
        expect(result, const DownloadEnqueueResult(skippedQueued: 1));
      });
    }

    test('A chapter completed after the directory check stays out of the queue', () async {
      final root = await Directory.systemTemp.createTemp('tsukuyomi-enqueue-');
      addTearDown(() => root.delete(recursive: true));
      final temp = await Directory('${root.path}/temp').create();
      final directory = Directory('${root.path}/chapter');
      await File('${temp.path}/001.jpg').writeAsBytes([1, 2, 3]);

      directoryExists = () async {
        await service.insertDownload(_source.id, chapter);
        final existed = await directory.exists();
        await temp.rename(directory.path);
        await database.delete(database.downloadTable).delete(_download(1));
        directoryExists = directory.exists;
        return existed;
      };

      final result = await service.enqueueAutoDownloads(_source, _manga);

      expect(await database.select(database.downloadTable).get(), isEmpty);
      expect(await File('${directory.path}/001.jpg').readAsBytes(), [1, 2, 3]);
      expect(result, const DownloadEnqueueResult(skippedDownloaded: 1));
    });

    test('A dequeue started during the final directory check leaves the queue empty', () async {
      final download = _download(1);
      await database.into(database.downloadTable).insert(download);
      final checkingDirectory = Completer<void>();
      final deletingDownload = Completer<void>();
      final deletion = checkingDirectory.future.then((_) {
        final pending = database.delete(database.downloadTable).delete(download);
        deletingDownload.complete();
        return pending;
      });

      final repository = container.read(downloadRepositoryProvider);
      final result = await repository.insertMissingDownload(chapter.toDownloadable(_source.id), () async {
        checkingDirectory.complete();
        await deletingDownload.future;
        return false;
      });

      expect(await deletion, 1);
      expect(await database.select(database.downloadTable).get(), isEmpty);
      expect(result, DownloadEnqueueOutcome.skippedQueued);
    });
  });

  test('Another connection can finish a download during the final directory check', () async {
    final root = await Directory.systemTemp.createTemp('tsukuyomi-enqueue-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}/queue.db');
    final previous = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = previous);
    final scan = _Database(openNativeDatabase(file, isolateSetup: _useSystemSqlite));
    final worker = _Database(openNativeDatabase(file, isolateSetup: _useSystemSqlite));
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(scan)]);
    addTearDown(() async {
      container.dispose();
      await worker.close();
      await scan.close();
    });

    final chapter = _chapter(1);
    final download = _download(1);
    await scan.into(scan.mangaTable).insert(_manga);
    await scan.into(scan.chapterTable).insert(chapter);
    await worker.into(worker.downloadTable).insert(download);
    final temp = await Directory('${root.path}/temp').create();
    final directory = Directory('${root.path}/chapter');
    await File('${temp.path}/001.jpg').writeAsBytes([1, 2, 3]);

    late Future<int> deletion;
    final repository = container.read(downloadRepositoryProvider);
    final result = await repository.insertMissingDownload(chapter.toDownloadable(_source.id), () async {
      final existed = await directory.exists();
      await temp.rename(directory.path);
      deletion = worker.delete(worker.downloadTable).delete(download);
      await expectLater(deletion.timeout(const Duration(milliseconds: 200)), throwsA(isA<TimeoutException>()));
      return existed;
    });

    expect(await deletion, 1);
    expect(result, DownloadEnqueueOutcome.skippedQueued);
    expect(await scan.select(scan.downloadTable).get(), isEmpty);
    expect(await File('${directory.path}/001.jpg').readAsBytes(), [1, 2, 3]);
  });

  test('Auto enqueue skips a resumed download and reports a removed download', () async {
    final rows = [_download(1, error: 'failed'), _download(2, error: 'failed')];
    final resumed = _download(1).copyWith(progress: 7);
    final downloads = _Downloads(
      rows,
      afterQuery: () {
        rows[0] = resumed;
        rows.removeLast();
      },
    );
    final container = _createContainer(_Chapters([_chapter(1), _chapter(2)]), downloads, _Manager());

    final result = await container.read(downloadServiceProvider).enqueueAutoDownloads(_source, _manga);

    expect(result.enqueuedCount, 0);
    expect(result.skippedQueued, 1);
    expect(result.failedChapters.keys, ['chapter-url-2']);
    expect(result.failedChapters['chapter-url-2'], contains('Download no longer exists'));
    expect(rows, [resumed]);
    expect(downloads.updated, isEmpty);
  });

  test('Auto enqueue counts a resumed download that finishes during the queue check as downloaded', () async {
    final rows = [_download(1, error: 'failed')];
    final completed = <int>{};
    final downloads = _Downloads(
      rows,
      afterQuery: () => rows[0] = _download(1),
      beforeHasDownload: () {
        completed.add(1);
        rows.clear();
      },
    );
    final container = _createContainer(_Chapters([_chapter(1)]), downloads, _Manager(), completed: completed);

    final result = await container.read(downloadServiceProvider).enqueueAutoDownloads(_source, _manga);

    expect(result, const DownloadEnqueueResult(skippedDownloaded: 1));
    expect(rows, isEmpty);
  });

  test('Enqueue returns complete counts and chapter errors without starting downloads', () async {
    for (final failedChapter in <int?>[null, 6]) {
      final chapters = _Chapters([_chapter(1), _chapter(2), _chapter(3), _chapter(4), _chapter(5, public: false), _chapter(6)]);
      final downloads = _Downloads([_download(3), _download(4, error: 'download-error')], failChapter: failedChapter);
      final manager = _Manager();
      final container = _createContainer(chapters, downloads, manager, completed: {2});

      final result = await container.read(downloadServiceProvider).enqueueAutoDownloads(_source, _manga);

      expect(result.enqueuedCount, failedChapter == null ? 3 : 2);
      expect(result.skippedDownloaded, 1);
      expect(result.skippedQueued, 1);
      expect(result.skippedUnavailable, 1);
      expect(result.failedChapters.keys, failedChapter == null ? isEmpty : ['chapter-url-6']);
      expect(downloads.inserted, failedChapter == null ? [1, 6] : [1]);
      expect(downloads.updated, [_download(4)]);
      expect(manager.wakes, 0);
    }
  });

  test('Queue query errors propagate before enqueueing and scheduling', () async {
    final chapters = _Chapters([_chapter(1)]);
    final error = StateError('queue-query-error');
    final downloads = _Downloads([], queryError: error);
    final manager = _Manager();
    final container = _createContainer(chapters, downloads, manager);

    await expectLater(container.read(downloadServiceProvider).enqueueAutoDownloads(_source, _manga), throwsA(same(error)));

    expect(downloads.inserted, isEmpty);
    expect(manager.wakes, 0);
  });
}

ProviderContainer _createContainer(_Chapters chapters, _Downloads downloads, _Manager manager, {Set<int> completed = const {}}) {
  final container = ProviderContainer(
    overrides: [
      chapterRepositoryProvider.overrideWithValue(chapters),
      downloadRepositoryProvider.overrideWithValue(downloads),
      downloadManagerProvider.overrideWithValue(manager),
      for (final chapter in chapters.chapters)
        downloadChapterPathProvider(_source, _manga, chapter).overrideWith(() => _ChapterPath(() => completed.contains(chapter.id))),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void _useSystemSqlite() {
  if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
}

class _Database extends TsukuyomiDatabase {
  _Database([QueryExecutor? executor]) : super.forTesting(executor ?? NativeDatabase.memory());

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'));
}

class _Chapters implements ChapterRepository {
  _Chapters(this.chapters);
  final List<DatabaseChapter> chapters;
  int queries = 0;

  @override
  Future<List<DatabaseChapter>> queryChaptersByMangaId(int mangaId) async {
    queries++;
    return chapters.toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Downloads implements DownloadRepository {
  _Downloads(this.rows, {this.failChapter, this.queryError, this.afterQuery, this.beforeHasDownload});
  final List<DatabaseDownload> rows;
  final int? failChapter;
  final Object? queryError;
  final void Function()? afterQuery;
  final void Function()? beforeHasDownload;
  final List<int> inserted = [];
  final List<DatabaseDownload> updated = [];

  @override
  Future<List<DatabaseDownload>> queryDownloadsByManga(int mangaId) async {
    if (queryError != null) throw queryError!;
    final snapshot = rows.toList();
    afterQuery?.call();
    return snapshot;
  }

  @override
  Future<bool> insertDownload(DownloadTableCompanion value) async {
    if (value.chapter.value == failChapter) throw StateError('insert-error');
    final existing = rows.where((row) => row.chapter == value.chapter.value).firstOrNull;
    if (existing != null) return existing.error != null && await clearDownloadError(existing);
    inserted.add(value.chapter.value);
    rows.add(
      DatabaseDownload(
        source: value.source.value,
        manga: value.manga.value,
        chapter: value.chapter.value,
        total: 0,
        progress: 0,
        error: null,
      ),
    );
    return true;
  }

  @override
  Future<bool> clearDownloadError(DatabaseDownload download) async {
    final index = rows.indexWhere((row) => row.chapter == download.chapter);
    if (index == -1 || rows[index].error == null) return false;
    final row = rows[index].copyWith(error: null);
    rows[index] = row;
    updated.add(row);
    return true;
  }

  @override
  Future<DownloadEnqueueOutcome> insertMissingDownload(DownloadTableCompanion value, Future<bool> Function() isDownloaded) async {
    if (await isDownloaded()) return DownloadEnqueueOutcome.skippedDownloaded;
    return await insertDownload(value) ? DownloadEnqueueOutcome.enqueued : DownloadEnqueueOutcome.skippedQueued;
  }

  @override
  Future<bool> hasDownload(DatabaseDownload download) async {
    beforeHasDownload?.call();
    return rows.any((row) => row.chapter == download.chapter);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Manager implements DownloadManager {
  int wakes = 0;

  @override
  Future<void> next() async {
    wakes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChapterPath extends DownloadChapterPath {
  _ChapterPath(this.completed);
  final FutureOr<bool> Function() completed;

  @override
  Future<Directory> build(Source source, DatabaseManga manga, DatabaseChapter chapter) async => _Directory(completed);
}

class _Directory implements Directory {
  _Directory(this.completed);
  final FutureOr<bool> Function() completed;

  @override
  Future<bool> exists() async => completed();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
