import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/core/exception/tsukuyomi_exception.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseManga;
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

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

const _chapter = HttpSourceChapter(url: 'chapter-url', name: 'chapter-title', date: 'chapter-date');

const _unchanged = ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 1, sourceCount: 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Unchanged chapters can enqueue downloads and save the complete result', () async {
    final source = _Source();
    final sync = _Sync(_unchanged);
    final downloads = _Downloads(
      const DownloadEnqueueResult(
        enqueuedCount: 2,
        skippedDownloaded: 3,
        skippedQueued: 4,
        skippedUnavailable: 5,
      ),
    );
    final container = await _createContainer(source, sync, downloads);

    final item = await container.read(updateServiceProvider).updateAndSaveManga(source, _manga);
    expect(source.calls, 1);
    expect(sync.chapters, [_chapter]);
    expect(downloads.calls, 1);
    expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt.keys, [_manga.id]);
    expect(item.outcome, UpdateOutcome.updated);
    expect(item.insertCount, 0);
    expect(item.updateCount, 1);
    expect(item.sourceCount, 1);
    expect(item.enqueuedCount, 2);
    expect(item.skippedDownloaded, 3);
    expect(item.skippedQueued, 4);
    expect(item.skippedUnavailable, 5);
    expect(item.sourceName, 'source-name');
    expect(item.mangaTitle, 'manga-title');

    final report = container.read(updateReportStoreProvider)!;
    expect(report.phase, UpdatePhase.finished);
    expect(report.scanKind, UpdateScanKind.partial);
    expect(report.totalTargets, 1);
    expect(report.items, [item]);
    expect(report.startedAt, isNotNull);
    expect(report.finishedAt, item.updatedAt);
    final preferences = container.read(sharedPreferencesProvider);
    final json = jsonDecode(preferences.getString(UpdateReportStore.reportKey)!) as Map<String, dynamic>;
    expect(UpdateReport.fromJson(json), report);
  });

  test('Manga outside favorite and auto still sync without enqueueing', () async {
    for (final (manga, result, outcome) in [
      (_manga.copyWith(favorite: false), _unchanged, UpdateOutcome.noUpdate),
      (
        _manga.copyWith(auto: false),
        const ChapterSyncResult(insertCount: 1, deleteCount: 0, updateCount: 0, sourceCount: 1),
        UpdateOutcome.updated,
      ),
    ]) {
      final source = _Source();
      final sync = _Sync(result);
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
      final container = await _createContainer(source, sync, downloads, manga: manga);

      final item = await container.read(updateServiceProvider).updateManga(source, manga);
      expect(source.calls, 1);
      expect(sync.chapters, [_chapter]);
      expect(downloads.calls, 0);
      expect(item.outcome, outcome);
      expect(item.insertCount, result.insertCount);
      expect(item.enqueuedCount, 0);
    }
  });

  test('Empty and reduced chapter lists retain warnings and download counts', () async {
    for (final (result, outcome) in [
      (const ChapterSyncResult(insertCount: 0, deleteCount: 2, updateCount: 0, sourceCount: 0), UpdateOutcome.chaptersEmpty),
      (const ChapterSyncResult(insertCount: 0, deleteCount: 2, updateCount: 1, sourceCount: 1), UpdateOutcome.chaptersReduced),
    ]) {
      final source = _Source();
      final sync = _Sync(result);
      final downloads = _Downloads(DownloadEnqueueResult(enqueuedCount: result.sourceCount));
      final container = await _createContainer(source, sync, downloads);

      final item = await container.read(updateServiceProvider).updateManga(source, _manga);
      expect(item.outcome, outcome);
      expect(item.deleteCount, 2);
      expect(item.enqueuedCount, result.sourceCount);
      expect(downloads.calls, 1);
      expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt.keys, [_manga.id]);
    }
  });

  test('Enqueue failures retain successful downloads, sync counts and error details', () async {
    final source = _Source();
    final sync = _Sync(const ChapterSyncResult(insertCount: 0, deleteCount: 2, updateCount: 1, sourceCount: 1));
    final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1, failedChapters: {'chapter-url': 'insert-error'}));
    final container = await _createContainer(source, sync, downloads);

    final item = await container.read(updateServiceProvider).updateManga(source, _manga);
    expect(item.outcome, UpdateOutcome.enqueueFailed);
    expect(item.deleteCount, 2);
    expect(item.updateCount, 1);
    expect(item.enqueuedCount, 1);
    expect(item.enqueueFailedCount, 1);
    expect(item.failedChapters, ['chapter-url']);
    expect(item.message, 'chapter-url: insert-error');
    expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt.keys, [_manga.id]);
  });

  test('Enqueue errors retain sync counts and save a failed report', () async {
    final source = _Source();
    final sync = _Sync(_unchanged);
    final error = StateError('enqueue-error');
    final downloads = _Downloads(const DownloadEnqueueResult(), errors: {_manga.id: error});
    final container = await _createContainer(source, sync, downloads);

    final item = await container.read(updateServiceProvider).updateAndSaveManga(source, _manga);

    expect(item.outcome, UpdateOutcome.enqueueFailed);
    expect(item.updateCount, 1);
    expect(item.sourceCount, 1);
    expect(item.message, error.toString());
    expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt.keys, [_manga.id]);
    final report = container.read(updateReportStoreProvider)!;
    expect(report.failureCount, 1);
    expect(report.items, [item]);
    final preferences = container.read(sharedPreferencesProvider);
    final json = jsonDecode(preferences.getString(UpdateReportStore.reportKey)!) as Map<String, dynamic>;
    expect(UpdateReport.fromJson(json), report);
  });

  test('Scan continues to the next manga after an enqueue error', () async {
    final nextManga = _manga.copyWith(id: 2, url: 'next-manga-url', title: 'next-manga-title');
    final source = _Source();
    final sync = _Sync(_unchanged);
    final error = StateError('enqueue-error');
    final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1), errors: {_manga.id: error});
    final container = await _createContainer(
      source,
      sync,
      downloads,
      overrides: [
        libraryRepositoryProvider.overrideWithValue(_Library([_manga, nextManga])),
        sourceByIdProvider(_manga.source).overrideWith((ref) async => source),
        chapterSyncWithSourceProvider(source, nextManga).overrideWithValue(sync),
      ],
    );

    await container.read(updateManagerProvider.notifier).scan();

    final report = container.read(updateReportStoreProvider)!;
    expect(source.calls, 2);
    expect(downloads.calls, 2);
    expect(report.items.map((item) => item.mangaId), [_manga.id, nextManga.id]);
    expect(report.items.map((item) => item.outcome), [UpdateOutcome.enqueueFailed, UpdateOutcome.updated]);
    expect(report.items.first.updateCount, 1);
    expect(report.items.first.message, error.toString());
    expect(report.items.last.enqueuedCount, 1);
    expect(report.failureCount, 1);
    expect(report.phase, UpdatePhase.finished);
    expect(report.message, isNull);
    expect(container.read(updateManagerProvider).hasError, isFalse);
    final preferences = container.read(sharedPreferencesProvider);
    final json = jsonDecode(preferences.getString(UpdateReportStore.reportKey)!) as Map<String, dynamic>;
    expect(UpdateReport.fromJson(json), report);
  });

  test('Source failures are classified and saved without syncing or enqueueing', () async {
    for (final (error, outcome) in [
      (const TsukuyomiSourceException.notInstalled(1), UpdateOutcome.sourceUnavailable),
      (TimeoutException('network-error'), UpdateOutcome.networkError),
      (const FormatException('parse-error'), UpdateOutcome.parseError),
    ]) {
      final source = _Source(error: error);
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(const DownloadEnqueueResult());
      final container = await _createContainer(source, sync, downloads);

      final item = await container.read(updateServiceProvider).updateAndSaveManga(source, _manga);
      expect(item.outcome, outcome);
      expect(item.message, error.toString());
      expect(item.sourceCount, 0);
      expect(sync.chapters, isNull);
      expect(downloads.calls, 0);
      expect(container.read(updateReportStoreProvider)!.items, [item]);
      expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt, isEmpty);
    }
  });

  test('Local sync failures are storage errors and do not enqueue', () async {
    final source = _Source();
    final sync = _Sync(_unchanged, error: StateError('storage-error'));
    final downloads = _Downloads(const DownloadEnqueueResult());
    final container = await _createContainer(source, sync, downloads);

    final item = await container.read(updateServiceProvider).updateManga(source, _manga);
    expect(source.calls, 1);
    expect(item.outcome, UpdateOutcome.storageError);
    expect(item.message, contains('storage-error'));
    expect(downloads.calls, 0);
    expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt, isEmpty);
  });

  test('Check time write failure retains sync counts and does not enqueue', () async {
    final source = _Source();
    final sync = _Sync(_unchanged);
    final downloads = _Downloads(const DownloadEnqueueResult());
    final mangas = _Mangas(error: StateError('check-time-error'));
    final container = await _createContainer(source, sync, downloads, mangas: mangas);

    final item = await container.read(updateServiceProvider).updateManga(source, _manga);
    expect(item.outcome, UpdateOutcome.storageError);
    expect(item.sourceCount, 1);
    expect(item.updateCount, 1);
    expect(item.message, contains('check-time-error'));
    expect(downloads.calls, 0);
  });
}

Future<ProviderContainer> _createContainer(
  _Source source,
  _Sync sync,
  _Downloads downloads, {
  DatabaseManga manga = _manga,
  _Mangas? mangas,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      chapterSyncWithSourceProvider(source, manga).overrideWithValue(sync),
      downloadServiceProvider.overrideWithValue(downloads),
      mangaRepositoryProvider.overrideWithValue(mangas ?? _Mangas()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _Source extends NoInstalledSource {
  _Source({this.error}) : super(1);
  final Object? error;
  int calls = 0;

  @override
  String get name => 'source-name';

  @override
  Future<Iterable<SourceChapter>> getMangaChapters(SourceManga manga) async {
    calls++;
    if (error != null) throw error!;
    return [_chapter];
  }
}

class _Sync implements ChapterSyncWithSource {
  _Sync(this.result, {this.error});
  final ChapterSyncResult result;
  final Object? error;
  List<SourceChapter>? chapters;

  @override
  Future<ChapterSyncResult> apply(Iterable<SourceChapter> sourceChapters) async {
    chapters = sourceChapters.toList();
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Downloads implements DownloadService {
  _Downloads(this.result, {this.errors = const {}});
  final DownloadEnqueueResult result;
  final Map<int, Object> errors;
  int calls = 0;

  @override
  Future<DownloadEnqueueResult> enqueueAutoDownloads(Source source, DatabaseManga manga) async {
    calls++;
    final error = errors[manga.id];
    if (error != null) throw error;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Library implements LibraryRepository {
  _Library(this.mangas);
  final List<DatabaseManga> mangas;

  @override
  Future<List<DatabaseManga>> queryAutoMangas({List<int>? mangaIds}) async => mangas.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mangas implements MangaRepository {
  _Mangas({this.error});
  final Object? error;
  final checkedAt = <int, DateTime>{};

  @override
  Future<int> updateLastCheckAt(int mangaId, DateTime date) async {
    if (error != null) throw error!;
    checkedAt[mangaId] = date;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
