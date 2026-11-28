import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart' show Headers;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart'; // ignore: depend_on_referenced_packages
import 'package:tsukuyomi/core/cache/tsukuyomi_cache_manager.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/chapter/chapter_service.dart';
import 'package:tsukuyomi/pages/download/download_repository.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/download/providers/download_path_provider.dart';
import 'package:tsukuyomi/pages/download/providers/downloaded_info_provider.dart';
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

DatabaseChapter _chapter(int id, {bool public = true, String? title}) => DatabaseChapter(
  id: id,
  manga: 1,
  index: 0,
  title: title ?? 'chapter-title-$id',
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

  for (final completed in [true, false]) {
    final scenario = completed ? 'Completed chapters leave the queue without fetching images' : 'Temporary chapters still fetch images';
    test(scenario, () async {
      if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
      final root = await Directory.systemTemp.createTemp('tsukuyomi-download-');
      final database = _Database();
      final source = _HttpSource();
      final chapter = _chapter(1);
      var requests = 0;
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          downloadMangaPathProvider(source, _manga).overrideWith(() => _MangaPath(root)),
          chapterImagesProvider(source, _manga, chapter).overrideWith((ref) async {
            requests++;
            return [];
          }),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
        await root.delete(recursive: true);
      });
      await database.into(database.mangaTable).insert(_manga);
      await database.into(database.chapterTable).insert(chapter);
      final service = container.listen(downloadServiceProvider, (_, _) {}).read();
      final downloaded = container.listen(downloadedChaptersProvider(root.path), (_, _) {});
      expect(downloaded.read(), isEmpty);
      final result = await service.enqueueAutoDownloads(source, _manga);
      expect(result, const DownloadEnqueueResult(enqueuedCount: 1));

      final temp = await service.createTempChapterDir(source, _manga, chapter);
      await File('${temp.path}/001.jpg').writeAsBytes([1, 2, 3]);
      final directory = await service.getChapterDir(source, _manga, chapter);
      if (completed) await temp.rename(directory.path);
      final download = await database.select(database.downloadTable).getSingle();
      final manager = container.read(downloadManagerProvider);
      final task = DownloadTask(ref: manager.ref, source: source, manga: _manga, chapter: chapter, download: download);
      final finished = Completer<void>();
      task.start(finished.complete);
      await finished.future;

      final rows = await database.select(database.downloadTable).get();
      if (completed) {
        expect(rows, isEmpty);
        expect(requests, 0);
        expect(downloaded.read(), {chapter.title});
        expect(await File('${directory.path}/001.jpg').readAsBytes(), [1, 2, 3]);
      } else {
        expect(requests, 1);
        expect(rows.single.error, contains('imagesNotFound'));
        expect(downloaded.read(), isEmpty);
      }
    });
  }

  group('Resume chapter downloads', () {
    late DatabaseChapter chapter;
    late _Database database;
    late _HttpSource source;
    late ProviderContainer container;
    late Directory root;
    late Directory temp;
    late Directory directory;

    setUpAll(() async {
      final messenger = TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final cache = await Directory.systemTemp.createTemp('tsukuyomi-resume-cache-');
      messenger.setMockMethodCallHandler(channel, (_) async => cache.path);
      addTearDown(() async {
        await TsukuyomiCacheManager(_HttpSource(), const HttpSourceImage(url: 'page')).dispose();
        messenger.setMockMethodCallHandler(channel, null);
        await cache.delete(recursive: true);
      });
    });

    setUp(() async {
      if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
      root = await Directory.systemTemp.createTemp('tsukuyomi-resume-');
      source = _HttpSource();
      database = _Database();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          downloadMangaPathProvider(source, _manga).overrideWith(() => _MangaPath(root)),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
        await root.delete(recursive: true);
      });
      await database.into(database.mangaTable).insert(_manga);
    });

    Future<void> startTask(DatabaseDownload download) async {
      final manager = container.read(downloadManagerProvider);
      final task = DownloadTask(ref: manager.ref, source: source, manga: _manga, chapter: chapter, download: download);
      final finished = Completer<void>();
      task.start(finished.complete);
      await finished.future;
    }

    Future<void> resume({required int progress, required int total, required List<String> files, String? title}) async {
      chapter = _chapter(1, title: title);
      await database.into(database.chapterTable).insert(chapter);
      final service = container.listen(downloadServiceProvider, (_, _) {}).read();
      temp = await service.createTempChapterDir(source, _manga, chapter);
      directory = await service.getChapterDir(source, _manga, chapter);
      for (final name in files) {
        await File(p.join(temp.path, name)).writeAsBytes([0]);
      }
      final download = _download(1).copyWith(progress: progress, total: total);
      await database.into(database.downloadTable).insert(download);
      await startTask(download);
    }

    test('Keep a saved page and fetch only the remaining page', () async {
      await resume(progress: 1, total: 2, files: ['1.webp']);
      expect(source.requests, [2]);
      expect(await File(p.join(directory.path, '1.webp')).readAsBytes(), [0]);
      expect(await File(p.join(directory.path, '2.jpg')).readAsBytes(), [2]);
      expect(await database.select(database.downloadTable).get(), isEmpty);
    });

    test('Resume and finish when only the temporary directory needs a Windows long path', () async {
      // 正式目录为 250 个字符，临时目录加上枚举用的通配符后达到 260 个字符
      final title = 'c' * (250 - root.path.length - 1);
      await resume(progress: 1, total: 2, files: ['1.webp', '3.jpg'], title: title);
      expect(directory.path.length, 250);
      expect(temp.path.length, 258);
      expect(await database.select(database.downloadTable).get(), isEmpty);
      expect(source.requests, [2]);
      expect(directory.listSync().map((file) => p.basename(file.path)), unorderedEquals(['1.webp', '2.jpg']));
      expect(await File(p.join(directory.path, '1.webp')).readAsBytes(), [0]);
      expect(await File(p.join(directory.path, '2.jpg')).readAsBytes(), [2]);
    }, skip: !Platform.isWindows);

    test('Fetch the first page again when the file is missing', () async {
      await resume(progress: 1, total: 2, files: []);
      expect(source.requests, [1, 2]);
      expect(await File(p.join(directory.path, '1.jpg')).readAsBytes(), [1]);
      expect(await database.select(database.downloadTable).get(), isEmpty);
    });

    for (final (reason, secondPage) in [
      ('missing', <String>[]),
      ('duplicate', ['2.jpg', '2.webp']),
    ]) {
      test('Resume at the first $reason page and keep preceding pages', () async {
        source.pages = 3;
        await resume(progress: 3, total: 3, files: ['1.webp', ...secondPage, '3.jpg']);
        expect(source.requests, [2, 3]);
        expect(await File(p.join(directory.path, '1.webp')).readAsBytes(), [0]);
        expect(await File(p.join(directory.path, '2.jpg')).readAsBytes(), [2]);
        expect(directory.listSync().map((file) => p.basename(file.path)), unorderedEquals(['1.webp', '2.jpg', '3.jpg']));
      });
    }

    test('A shorter chapter contains only its current pages', () async {
      await resume(progress: 3, total: 4, files: ['1.jpg', '2.webp', '3.jpg']);
      expect(source.requests, [1, 2]);
      expect(directory.listSync().map((file) => p.basename(file.path)), unorderedEquals(['1.jpg', '2.jpg']));
    });

    for (final (oldTotal, newTotal, oldName, newName) in [(8, 9, '1', '01'), (98, 99, '01', '001')]) {
      test('Keep old filenames until the download from $oldTotal to $newTotal pages finishes', () async {
        source.pages = newTotal;
        source.onRequest = (page) {
          if (page == 2) throw StateError('interrupted');
        };
        await resume(progress: 1, total: oldTotal, files: ['$oldName.jpg']);
        expect(directory.existsSync(), isFalse);
        expect(await File(p.join(temp.path, '$oldName.jpg')).readAsBytes(), [0]);
        expect(await File(p.join(temp.path, '$newName.jpg')).readAsBytes(), [1]);
        final download = await database.select(database.downloadTable).getSingle();
        expect(download.progress, 1);
        expect(download.error, contains('interrupted'));

        source.onRequest = null;
        source.requests.clear();
        await startTask(download);
        expect(source.requests, [for (var i = 2; i <= newTotal; i++) i]);
        final names = [for (var i = 1; i <= newTotal; i++) '${i.toString().padLeft(newName.length, '0')}.jpg'];
        expect(directory.listSync().map((file) => p.basename(file.path)), unorderedEquals(names));
      });
    }

    test('A page lost during the download keeps the task in the queue', () async {
      source.onRequest = (_) => File(p.join(temp.path, '1.jpg')).deleteSync();
      await resume(progress: 1, total: 2, files: ['1.jpg', '3.jpg']);
      expect(directory.existsSync(), isFalse);
      expect(await File(p.join(temp.path, '3.jpg')).readAsBytes(), [0]);
      expect((await database.select(database.downloadTable).getSingle()).error, contains('imagesNotFound'));
    });
  }, skip: !Platform.isWindows && !Platform.isLinux);

  for (final failed in [null, _download(1, error: 'failed')]) {
    final action = failed == null ? 'queued' : 'resumed';
    test('Auto enqueue skips a chapter $action manually during the scan and preserves its progress', () async {
      if (Platform.isWindows) open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
      final database = _Database();
      final chapter = _chapter(1);
      final queued = _download(1).copyWith(progress: 7);
      late final DownloadService service;
      DatabaseDownload? afterManualAction;

      Future<bool> enqueueDuringDirectoryCheck() async {
        if (failed == null) {
          await service.insertDownload(_source.id, chapter);
          await service.updateDownload(queued);
        } else {
          await service.updateDownload(queued.copyWith(error: failed.error));
          await service.resumeDownload(failed);
        }
        afterManualAction = await database.select(database.downloadTable).getSingle();
        return false;
      }

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(database),
          downloadManagerProvider.overrideWithValue(_Manager()),
          downloadChapterPathProvider(_source, _manga, chapter).overrideWith(() => _ChapterPath(enqueueDuringDirectoryCheck)),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
      });
      await database.into(database.mangaTable).insert(_manga);
      await database.into(database.chapterTable).insert(chapter);
      if (failed != null) await database.into(database.downloadTable).insert(failed);
      service = container.read(downloadServiceProvider);

      final result = await service.enqueueAutoDownloads(_source, _manga);

      expect(afterManualAction, queued, reason: 'Progress after the manual download action');
      expect(await database.select(database.downloadTable).getSingle(), queued, reason: 'Progress after the automatic scan');
      expect(result, const DownloadEnqueueResult(skippedQueued: 1));
    });
  }

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

class _Database extends TsukuyomiDatabase {
  _Database() : super.forTesting(NativeDatabase.memory());

  @override
  MigrationStrategy get migration => MigrationStrategy(beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'));
}

class _HttpSource extends Fake implements DioHttpSource {
  int pages = 2;
  final requests = <int>[];
  void Function(int)? onRequest;

  @override
  int get id => 1;

  @override
  Future<HttpSourceChapterImages> getChapterImages(HttpSourceChapter chapter) async {
    return HttpSourceChapterImages(images: [for (var i = 1; i <= pages; i++) HttpSourceImage(url: '$i')]);
  }

  @override
  Future<HttpSourceImageBytes> getImageBytes(HttpSourceImage image) async {
    final page = int.parse(image.url);
    requests.add(page);
    onRequest?.call(page);
    return HttpSourceImageBytes(type: 'jpg', data: [page], statusCode: 200, responseHeaders: Headers());
  }

  @override
  Future<HttpSourceImageBytes> getRepaintBytes(HttpSourceImageBytes bytes) async => bytes;
}

class _MangaPath extends DownloadMangaPath {
  _MangaPath(this.directory);
  final Directory directory;

  @override
  Future<Directory> build(Source source, DatabaseManga manga) async => directory;
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
