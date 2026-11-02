import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/core/exception/tsukuyomi_exception.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseManga;
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_controller.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/providers/download/download_manager_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import '../../fixtures/update_fixtures.dart';

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

  test('Detail refresh without a scan report only auto-downloads favorite auto manga', () async {
    for (final manga in [_manga, _manga.copyWith(favorite: false), _manga.copyWith(auto: false)]) {
      final source = UpdateSourceFixture();
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 2));
      final manager = _Manager();
      final container = await _createContainer(
        source,
        sync,
        downloads,
        manga: manga,
        manager: manager,
        overrides: [mangaControllerProvider(manga.id.toString()).overrideWith(() => _MangaController(source, manga))],
      );

      await _refreshManga(container, manga);

      final autoDownload = manga.favorite && manga.auto;
      expect(source.calls, 1);
      expect(sync.chapters, [_chapter]);
      expect(downloads.calls, autoDownload ? 1 : 0);
      expect(manager.wakes, autoDownload ? 1 : 0);
      expect(downloads._refreshed, [manga.id]);
      expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt.keys, [manga.id]);
      expect(container.read(updateReportStoreProvider), isNull);
      final preferences = container.read(sharedPreferencesProvider);
      expect(preferences.getString(Keys.updateReportLatest), isNull);
    }
  });

  test('Detail refresh records source failures without syncing or enqueueing', () async {
    final error = TimeoutException('network-error');
    final source = UpdateSourceFixture(error: error);
    final sync = _Sync(_unchanged);
    final downloads = _Downloads(const DownloadEnqueueResult());
    final container = await _createContainer(
      source,
      sync,
      downloads,
      report: updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]),
      overrides: [mangaControllerProvider(_manga.id.toString()).overrideWith(() => _MangaController(source, _manga))],
    );

    await _refreshManga(container, _manga);

    expect(sync.chapters, isNull);
    expect(downloads.calls, 0);
    final report = container.read(updateReportStoreProvider)!;
    expect(report.scanKind, UpdateScanKind.full);
    expect(report.failureCount, 1);
    expect(report.items.single.outcome, UpdateOutcome.networkError);
    expect(report.items.single.message, error.toString());
  });

  test('Detail refresh replaces only its existing row even after auto-download is disabled', () async {
    for (final manga in [_manga, _manga.copyWith(favorite: false), _manga.copyWith(auto: false)]) {
      final source = UpdateSourceFixture();
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 2));
      final previous = updateReportFixture(
        phase: UpdatePhase.running,
        totalTargets: 4,
        items: [
          updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.networkError, message: 'other-error'),
          updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.networkError),
          updateReportItemFixture(3),
        ],
      );
      final container = await _createContainer(source, _Sync(_unchanged), downloads, manga: manga);
      await container.read(updateReportStoreProvider.notifier).save(previous);
      final subscription = container.listen(updateControllerProvider, (_, _) {});
      addTearDown(subscription.close);
      container.read(updateControllerProvider.notifier).onFilterChanged(UpdateFilter.failure);

      final item = await container.read(updateServiceProvider).updateMangaAndSaveReport(source, manga);

      final expected = previous.copyWith(items: [previous.items.first, item, previous.items.last]);
      final report = container.read(updateReportStoreProvider)!;
      expect(report, expected);
      expect(report.failureCount, 1);
      expect(report.successCount, 2);
      expect(container.read(updateControllerProvider), UpdateFilter.failure);
      expect(downloads.calls, manga.favorite && manga.auto ? 1 : 0);
      final preferences = container.read(sharedPreferencesProvider);
      final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
      expect(UpdateReport.fromJson(json), expected);
    }
  });

  test('Concurrent detail corrections preserve both rows and persisted metadata in either order', () async {
    for (final order in [
      [0, 1],
      [1, 0],
    ]) {
      final pending = [Completer<void>(), Completer<void>()];
      final sources = [UpdateSourceFixture(pending: pending[0].future), UpdateSourceFixture(id: 2, pending: pending[1].future)];
      final mangas = [_manga, mangaFixture(2, source: 2)];
      final syncs = [_Sync(_unchanged), _Sync(_unchanged)];
      final previous = updateReportFixture(
        message: 'original-scan-message',
        items: [
          updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.networkError),
          updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.storageError),
        ],
      );
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
      final container = await _createContainer(
        sources[0],
        syncs[0],
        downloads,
        mangas: _Mangas(mangas: mangas),
        report: previous,
        overrides: [chapterSyncWithSourceProvider(sources[1], mangas[1]).overrideWithValue(syncs[1])],
      );
      final service = container.read(updateServiceProvider);
      final updates = [for (var i = 0; i < mangas.length; i++) service.updateMangaAndSaveReport(sources[i], mangas[i])];
      await Future.wait(sources.map((source) => source.requested));

      for (final index in order) {
        pending[index].complete();
      }
      final items = await Future.wait(updates);

      expect(container.read(updateReportStoreProvider), previous.copyWith(items: items));
      expect(sources.map((source) => source.calls), [1, 1]);
      expect(syncs.map((sync) => sync.calls), [1, 1]);
      expect(downloads.calls, 2);
      final preferences = container.read(sharedPreferencesProvider);
      final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
      expect(UpdateReport.fromJson(json), previous.copyWith(items: items));
    }
  });

  test('Detail refresh does not add manga outside the current report', () async {
    for (final manga in [_manga, _manga.copyWith(favorite: false), _manga.copyWith(auto: false)]) {
      final source = UpdateSourceFixture();
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
      final previous = updateReportFixture(items: [updateReportItemFixture(2), updateReportItemFixture(3)]);
      final container = await _createContainer(source, sync, downloads, manga: manga, report: previous);
      final preferences = container.read(sharedPreferencesProvider);
      final persisted = preferences.getString(Keys.updateReportLatest);

      await container.read(updateServiceProvider).updateMangaAndSaveReport(source, manga);

      expect(sync.chapters, [_chapter]);
      expect(downloads.calls, manga.favorite && manga.auto ? 1 : 0);
      expect(container.read(updateReportStoreProvider), previous);
      expect(preferences.getString(Keys.updateReportLatest), persisted);
    }
  });

  test('Late detail results cannot modify a scan report created after the refresh started', () async {
    for (final previous in [
      null,
      updateReportFixture(items: [updateReportItemFixture(1)]),
    ]) {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future, error: TimeoutException('old-detail-error'));
      final container = await _createContainer(source, _Sync(_unchanged), _Downloads(const DownloadEnqueueResult()), report: previous);
      final refresh = container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);
      await source.requested;
      final next = updateReportFixture(items: [updateReportItemFixture(1), updateReportItemFixture(2)]).copyWith(sessionId: 'next-scan');
      await container.read(updateReportStoreProvider.notifier).save(next);

      pending.complete();
      final item = await refresh;

      expect(item.outcome, UpdateOutcome.networkError);
      expect(container.read(updateReportStoreProvider), next);
      final preferences = container.read(sharedPreferencesProvider);
      final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
      expect(UpdateReport.fromJson(json), next);
    }
  });

  test('Concurrent refreshes share the same update and later attempts can run again', () async {
    for (final error in [null, TimeoutException('network-error')]) {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future, error: error);
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
      final container = await _createContainer(source, _Sync(_unchanged), downloads);
      final service = container.read(updateServiceProvider);
      final first = service.updateManga(source, _manga);
      await source.requested;
      final second = service.updateManga(source, _manga);
      final detail = service.updateMangaAndSaveReport(source, _manga);
      expect(source.calls, 1);

      pending.complete();
      final results = await Future.wait([first, second, detail]);

      expect(results[1], same(results.first));
      expect(results[2], same(results.first));
      expect(downloads.calls, error == null ? 1 : 0);
      await service.updateManga(source, _manga);
      expect(source.calls, 2);
      expect(downloads.calls, error == null ? 2 : 0);
    }
  });

  test('A rejected shared Future is cleared and the next refresh can recover', () async {
    final pending = Completer<void>();
    final source = _BrokenNameSource(pending.future);
    final sync = _Sync(_unchanged);
    final container = await _createContainer(source, sync, _Downloads(const DownloadEnqueueResult()));
    final service = container.read(updateServiceProvider);
    final first = service.updateManga(source, _manga);
    await source.requested;
    final second = service.updateManga(source, _manga);
    final failures = Future.wait([expectLater(first, throwsStateError), expectLater(second, throwsStateError)]);

    pending.complete();
    await failures;
    expect(source.calls, 1);
    source.failName = false;
    final result = await service.updateManga(source, _manga);

    expect(result.outcome, UpdateOutcome.noUpdate);
    expect(source.calls, 2);
    expect(sync.calls, 2);
  });

  test('A scan sharing a detail refresh uses newly enabled download settings', () async {
    for (final initial in [_manga.copyWith(favorite: false), _manga.copyWith(auto: false)]) {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future);
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
      final mangas = _Mangas(mangas: [initial]);
      final manager = _Manager();
      late _ObservedUpdates updates;
      final container = await _createContainer(
        source,
        sync,
        downloads,
        manga: initial,
        mangas: mangas,
        manager: manager,
        overrides: [
          updateServiceProvider.overrideWith((ref) => updates = _ObservedUpdates(updateService(ref))),
          libraryRepositoryProvider.overrideWithValue(_Library([_manga])),
          sourceByIdProvider(1).overrideWith((ref) async => source),
          chapterSyncWithSourceProvider(source, _manga).overrideWithValue(sync),
        ],
      );
      final detail = container.read(updateServiceProvider).updateMangaAndSaveReport(source, initial);
      await source.requested;
      mangas.mangas[_manga.id] = _manga;
      final scan = container.read(updateManagerProvider.notifier).scan();
      await updates.requested;

      pending.complete();
      final item = await detail;
      await scan;

      expect(source.calls, 1);
      expect(sync.calls, 1);
      expect(downloads.calls, 1);
      expect(downloads.enqueuedMangas, [_manga]);
      expect(manager.wakes, 1);
      expect(item.enqueuedCount, 1);
      final report = container.read(updateReportStoreProvider)!;
      expect(report.items, [item]);
      expect(report.phase, UpdatePhase.finished);
      final preferences = container.read(sharedPreferencesProvider);
      final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
      expect(UpdateReport.fromJson(json), report);
    }
  });

  test('A shared update skips downloads when settings are disabled during the request', () async {
    for (final latest in [_manga.copyWith(favorite: false), _manga.copyWith(auto: false)]) {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future);
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
      final mangas = _Mangas();
      final manager = _Manager();
      final container = await _createContainer(
        source,
        sync,
        downloads,
        mangas: mangas,
        manager: manager,
        overrides: [
          libraryRepositoryProvider.overrideWithValue(_Library([_manga])),
          sourceByIdProvider(1).overrideWith((ref) async => source),
          chapterSyncWithSourceProvider(source, latest).overrideWithValue(sync),
        ],
      );
      final scan = container.read(updateManagerProvider.notifier).scan();
      await source.requested;
      mangas.mangas[_manga.id] = latest;
      final detail = container.read(updateServiceProvider).updateMangaAndSaveReport(source, latest);

      pending.complete();
      final item = await detail;
      await scan;

      expect(source.calls, 1);
      expect(sync.calls, 1);
      expect(downloads.calls, 0);
      expect(manager.wakes, 0);
      expect(item.outcome, UpdateOutcome.noUpdate);
      expect(item.enqueuedCount, 0);
      expect(container.read(updateReportStoreProvider)!.items, [item]);
    }
  });

  test('Auto-download settings are reread after chapter synchronization', () async {
    final initial = _manga.copyWith(auto: false);
    final latest = _manga.copyWith(title: 'updated-title');
    final pending = Completer<void>();
    final source = UpdateSourceFixture();
    final sync = _Sync(_unchanged, pending: pending.future);
    final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
    final mangas = _Mangas(mangas: [initial]);
    final container = await _createContainer(source, sync, downloads, manga: initial, mangas: mangas);
    final update = container.read(updateServiceProvider).updateManga(source, initial);
    await sync.requested;
    expect(downloads.calls, 0);
    mangas.mangas[_manga.id] = latest;

    pending.complete();
    final item = await update;

    expect(source.calls, 1);
    expect(sync.calls, 1);
    expect(downloads.enqueuedMangas, [latest]);
    expect(item.enqueuedCount, 1);
  });

  test('Latest manga lookup failures retain sync counts and do not enqueue', () async {
    final source = UpdateSourceFixture();
    final sync = _Sync(_unchanged);
    final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
    final mangas = _Mangas(queryError: StateError('latest-manga-error'));
    final manager = _Manager();
    final container = await _createContainer(source, sync, downloads, mangas: mangas, manager: manager);

    final item = await container.read(updateServiceProvider).updateManga(source, _manga);

    expect(item.outcome, UpdateOutcome.storageError);
    expect(item.updateCount, 1);
    expect(item.sourceCount, 1);
    expect(item.message, contains('latest-manga-error'));
    expect(downloads.calls, 0);
    expect(manager.wakes, 0);
  });

  test('Detail corrections survive later scan progress and scan completion', () async {
    final pending = Completer<void>();
    final scanSource = UpdateSourceFixture(error: TimeoutException('scan-error'));
    final detailSource = UpdateSourceFixture();
    final nextSource = UpdateSourceFixture(id: 2, pending: pending.future, error: TimeoutException('other-error'));
    final sync = _Sync(_unchanged);
    final container = await _createContainer(
      scanSource,
      sync,
      _Downloads(const DownloadEnqueueResult()),
      overrides: [
        libraryRepositoryProvider.overrideWithValue(_Library([_manga, mangaFixture(2, source: 2)])),
        sourceByIdProvider(1).overrideWith((ref) async => scanSource),
        sourceByIdProvider(2).overrideWith((ref) async => nextSource),
        chapterSyncWithSourceProvider(detailSource, _manga).overrideWithValue(sync),
      ],
    );
    final recorded = Completer<void>();
    final subscription = container.listen(updateReportStoreProvider, (previous, next) {
      if (next?.items.any((item) => item.mangaId == 1) == true && !recorded.isCompleted) recorded.complete();
    });
    addTearDown(subscription.close);
    final scan = container.read(updateManagerProvider.notifier).scan();
    await Future.wait([recorded.future, nextSource.requested]);
    final before = container.read(updateReportStoreProvider)!;

    final corrected = await container.read(updateServiceProvider).updateMangaAndSaveReport(detailSource, _manga);
    expect(container.read(updateReportStoreProvider), before.copyWith(items: [corrected]));
    expect(container.read(updateManagerProvider).isLoading, isTrue);
    pending.complete();
    await scan;

    final report = container.read(updateReportStoreProvider)!;
    expect(report.sessionId, before.sessionId);
    expect(report.phase, UpdatePhase.finished);
    expect(report.totalTargets, 2);
    expect(report.items.first, corrected);
    expect(report.items.last.mangaId, 2);
    expect(report.failureCount, 1);
    expect(report.successCount, 1);
    final preferences = container.read(sharedPreferencesProvider);
    final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
    expect(UpdateReport.fromJson(json), report);
  });

  test('A new scan shares an active detail update without receiving its old report', () async {
    final pending = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1));
    final previous = updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]);
    late _ObservedUpdates updates;
    final container = await _createContainer(
      source,
      _Sync(_unchanged),
      downloads,
      report: previous,
      overrides: [
        updateServiceProvider.overrideWith((ref) => updates = _ObservedUpdates(updateService(ref))),
        libraryRepositoryProvider.overrideWithValue(_Library([_manga])),
        sourceByIdProvider(1).overrideWith((ref) async => source),
      ],
    );
    final detail = container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);
    await source.requested;
    final scan = container.read(updateManagerProvider.notifier).scan();
    await updates.requested;

    pending.complete();
    final item = await detail;
    await scan;

    final report = container.read(updateReportStoreProvider)!;
    expect(source.calls, 1);
    expect(downloads.calls, 1);
    expect(report.sessionId, isNot(previous.sessionId));
    expect(report.scanKind, UpdateScanKind.full);
    expect(report.phase, UpdatePhase.finished);
    expect(report.totalTargets, 1);
    expect(report.items, [item]);
  });

  test('Delayed offline source responses do not sync or enqueue before completion', () async {
    for (final error in [null, TimeoutException('fixture-network-error')]) {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future, error: error);
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(const DownloadEnqueueResult());
      final container = await _createContainer(source, sync, downloads);

      final update = container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);
      await source.requested;
      expect(sync.chapters, isNull);
      expect(downloads.calls, 0);
      expect(container.read(updateReportStoreProvider), isNull);

      pending.complete();
      final item = await update;
      if (error == null) {
        expect(sync.chapters, [_chapter]);
        expect(downloads.calls, 1);
        expect(item.outcome, UpdateOutcome.noUpdate);
      } else {
        expect(sync.chapters, isNull);
        expect(downloads.calls, 0);
        expect(item.outcome, UpdateOutcome.networkError);
        expect(item.message, error.toString());
      }
      expect(container.read(updateReportStoreProvider), isNull);
      expect(source.calls, 1);
    }
  });

  test('Empty offline source responses keep the chapter warning visible', () async {
    final source = UpdateSourceFixture(chapters: const []);
    final sync = _Sync(const ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 0, sourceCount: 0));
    final downloads = _Downloads(const DownloadEnqueueResult());
    final container = await _createContainer(
      source,
      sync,
      downloads,
      report: updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]),
    );

    final item = await container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);

    expect(sync.chapters, isEmpty);
    expect(item.outcome, UpdateOutcome.chaptersEmpty);
    expect(item.sourceCount, 0);
    expect(item.enqueuedCount, 0);
    expect(container.read(updateReportStoreProvider)!.warningCount, 1);
  });

  test('Unchanged chapters can enqueue downloads and save the complete result', () async {
    final source = UpdateSourceFixture();
    final sync = _Sync(_unchanged);
    final downloads = _Downloads(
      const DownloadEnqueueResult(
        enqueuedCount: 2,
        skippedDownloaded: 3,
        skippedQueued: 4,
        skippedUnavailable: 5,
      ),
    );
    final previous = updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]);
    final container = await _createContainer(source, sync, downloads, report: previous);

    final item = await container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);
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
    expect(report.scanKind, UpdateScanKind.full);
    expect(report.totalTargets, 1);
    expect(report.items, [item]);
    expect(report, previous.copyWith(items: [item]));
    final preferences = container.read(sharedPreferencesProvider);
    final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
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
      final source = UpdateSourceFixture();
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
      final source = UpdateSourceFixture();
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
    final source = UpdateSourceFixture();
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
    final source = UpdateSourceFixture();
    final sync = _Sync(_unchanged);
    final error = StateError('enqueue-error');
    final downloads = _Downloads(const DownloadEnqueueResult(), errors: {_manga.id: error});
    final container = await _createContainer(
      source,
      sync,
      downloads,
      report: updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]),
    );

    final item = await container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);

    expect(item.outcome, UpdateOutcome.enqueueFailed);
    expect(item.updateCount, 1);
    expect(item.sourceCount, 1);
    expect(item.message, error.toString());
    expect((container.read(mangaRepositoryProvider) as _Mangas).checkedAt.keys, [_manga.id]);
    final report = container.read(updateReportStoreProvider)!;
    expect(report.failureCount, 1);
    expect(report.items, [item]);
    final preferences = container.read(sharedPreferencesProvider);
    final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
    expect(UpdateReport.fromJson(json), report);
  });

  test('Start errors retain complete counts and save all error details', () async {
    for (final failedChapters in [
      <String, String>{},
      {'chapter-url': 'insert-error'},
    ]) {
      final source = UpdateSourceFixture();
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(
        DownloadEnqueueResult(
          enqueuedCount: 2,
          skippedDownloaded: 1,
          skippedQueued: 1,
          skippedUnavailable: 1,
          failedChapters: failedChapters,
        ),
      );
      final error = StateError('start-error');
      final manager = _Manager(errors: {1: error});
      final container = await _createContainer(
        source,
        sync,
        downloads,
        manager: manager,
        report: updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]),
      );

      final item = await container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);

      expect(item.outcome, UpdateOutcome.enqueueFailed);
      expect(item.enqueuedCount, 2);
      expect(item.skippedDownloaded, 1);
      expect(item.skippedQueued, 1);
      expect(item.skippedUnavailable, 1);
      expect(item.failedChapters, failedChapters.keys);
      expect(item.enqueueFailedCount, failedChapters.length);
      expect(item.updateCount, 1);
      expect(item.message, failedChapters.isEmpty ? error.toString() : 'chapter-url: insert-error\n$error');
      expect(manager.wakes, 1);
      final report = container.read(updateReportStoreProvider)!;
      expect(report.failureCount, 1);
      final preferences = container.read(sharedPreferencesProvider);
      final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
      expect(UpdateReport.fromJson(json), report);
    }
  });

  test('Queued chapters start downloads even without new entries', () async {
    final source = UpdateSourceFixture();
    final sync = _Sync(_unchanged);
    final downloads = _Downloads(const DownloadEnqueueResult(skippedQueued: 2));
    final manager = _Manager();
    final container = await _createContainer(source, sync, downloads, manager: manager);

    final item = await container.read(updateServiceProvider).updateManga(source, _manga);

    expect(manager.wakes, 1);
    expect(item.enqueuedCount, 0);
    expect(item.skippedQueued, 2);
    expect(item.outcome, UpdateOutcome.noUpdate);
  });

  test('Scan continues to the next manga after an enqueue or start error', () async {
    for (final failEnqueue in [true, false]) {
      final nextManga = _manga.copyWith(id: 2, url: 'next-manga-url', title: 'next-manga-title');
      final source = UpdateSourceFixture();
      final sync = _Sync(_unchanged);
      final error = StateError(failEnqueue ? 'enqueue-error' : 'start-error');
      final downloads = _Downloads(const DownloadEnqueueResult(enqueuedCount: 1), errors: failEnqueue ? {_manga.id: error} : {});
      final manager = _Manager(errors: failEnqueue ? {} : {1: error});
      final container = await _createContainer(
        source,
        sync,
        downloads,
        mangas: _Mangas(mangas: [_manga, nextManga]),
        manager: manager,
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
      expect(manager.wakes, failEnqueue ? 1 : 2);
      expect(report.items.map((item) => item.mangaId), [_manga.id, nextManga.id]);
      expect(report.items.map((item) => item.outcome), [UpdateOutcome.enqueueFailed, UpdateOutcome.updated]);
      expect(report.items.first.updateCount, 1);
      expect(report.items.first.enqueuedCount, failEnqueue ? 0 : 1);
      expect(report.items.first.message, error.toString());
      expect(report.items.last.enqueuedCount, 1);
      expect(report.failureCount, 1);
      expect(report.phase, UpdatePhase.finished);
      expect(report.message, isNull);
      expect(container.read(updateManagerProvider).hasError, isFalse);
      final preferences = container.read(sharedPreferencesProvider);
      final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!) as Map<String, dynamic>;
      expect(UpdateReport.fromJson(json), report);
    }
  });

  test('Source failures are classified and saved without syncing or enqueueing', () async {
    for (final (error, outcome) in [
      (const TsukuyomiSourceException.notInstalled(1), UpdateOutcome.sourceUnavailable),
      (TimeoutException('network-error'), UpdateOutcome.networkError),
      (const FormatException('parse-error'), UpdateOutcome.parseError),
    ]) {
      final source = UpdateSourceFixture(error: error);
      final sync = _Sync(_unchanged);
      final downloads = _Downloads(const DownloadEnqueueResult());
      final container = await _createContainer(
        source,
        sync,
        downloads,
        report: updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]),
      );

      final item = await container.read(updateServiceProvider).updateMangaAndSaveReport(source, _manga);
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
    final source = UpdateSourceFixture();
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
    final source = UpdateSourceFixture();
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

Future<void> _refreshManga(ProviderContainer container, DatabaseManga manga) async {
  final provider = mangaControllerProvider(manga.id.toString());
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  await container.read(provider.future);
  await container.read(provider.notifier).refreshChapters();
}

Future<ProviderContainer> _createContainer(
  UpdateSourceFixture source,
  _Sync sync,
  _Downloads downloads, {
  DatabaseManga manga = _manga,
  _Mangas? mangas,
  _Manager? manager,
  UpdateReport? report,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({if (report != null) Keys.updateReportLatest: jsonEncode(report.toJson())});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      chapterSyncWithSourceProvider(source, manga).overrideWithValue(sync),
      downloadServiceProvider.overrideWithValue(downloads),
      mangaRepositoryProvider.overrideWithValue(mangas ?? _Mangas(mangas: [manga])),
      downloadManagerProvider.overrideWithValue(manager ?? _Manager()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _BrokenNameSource extends UpdateSourceFixture {
  _BrokenNameSource(Future<void> pending) : super(pending: pending);

  bool failName = true;

  @override
  String get name {
    if (failName) throw StateError('source-name-error');
    return super.name;
  }
}

class _MangaController extends MangaController {
  _MangaController(this._source, this._manga);

  final Source _source;
  final DatabaseManga _manga;

  @override
  Future<MangaState> build(String mangaId) async => MangaState(source: _source, manga: _manga, chapters: []);
}

class _Sync implements ChapterSyncWithSource {
  _Sync(this.result, {this.error, this.pending});

  final ChapterSyncResult result;
  final Object? error;
  final Future<void>? pending;
  final _requested = Completer<void>();
  List<SourceChapter>? chapters;
  int calls = 0;

  Future<void> get requested => _requested.future;

  @override
  Future<ChapterSyncResult> apply(Iterable<SourceChapter> sourceChapters) async {
    calls++;
    chapters = sourceChapters.toList();
    if (!_requested.isCompleted) _requested.complete();
    await pending;
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
  final enqueuedMangas = <DatabaseManga>[];
  final _refreshed = <int>[];

  @override
  Future<void> refreshDownloadedByManga(Source source, DatabaseManga manga) async => _refreshed.add(manga.id);

  @override
  Future<DownloadEnqueueResult> enqueueAutoDownloads(Source source, DatabaseManga manga) async {
    calls++;
    enqueuedMangas.add(manga);
    final error = errors[manga.id];
    if (error != null) throw error;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 观察扫描何时取得真实服务返回的更新任务
class _ObservedUpdates implements UpdateService {
  _ObservedUpdates(this.service);

  final UpdateService service;
  final _requested = Completer<void>();

  Future<void> get requested => _requested.future;

  @override
  Future<UpdateReportItem> updateManga(Source source, DatabaseManga manga) {
    final result = service.updateManga(source, manga);
    if (!_requested.isCompleted) _requested.complete();
    return result;
  }

  @override
  Future<UpdateReportItem> updateMangaAndSaveReport(Source source, DatabaseManga manga) {
    return service.updateMangaAndSaveReport(source, manga);
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

class _Manager implements DownloadManager {
  _Manager({this.errors = const {}});

  final Map<int, Object> errors;
  int wakes = 0;

  @override
  Future<void> next() async {
    wakes++;
    final error = errors[wakes];
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mangas implements MangaRepository {
  _Mangas({
    Iterable<DatabaseManga> mangas = const [_manga],
    this.error,
    this.queryError,
  }) : mangas = {for (final manga in mangas) manga.id: manga};

  final Map<int, DatabaseManga> mangas;
  final Object? error;
  final Object? queryError;
  final checkedAt = <int, DateTime>{};

  @override
  Future<DatabaseManga> queryManga(int mangaId) async {
    if (queryError != null) throw queryError!;
    return mangas[mangaId]!;
  }

  @override
  Future<int> updateLastCheckAt(int mangaId, DateTime date) async {
    if (error != null) throw error!;
    checkedAt[mangaId] = date;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
