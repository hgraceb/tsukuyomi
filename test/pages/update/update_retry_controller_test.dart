import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_controller.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/pages/update/update_retry_controller.dart';
import 'package:tsukuyomi/providers/error/error_handler_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

import '../../fixtures/update_fixtures.dart';
import '../../fixtures/update_retry_fixtures.dart';

final _failed = updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.networkError, message: 'previous-error');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Retry replaces only the selected failure and retains scan metadata, filter and persisted results', () async {
    final previous = updateReportFixture(totalTargets: 4, items: [_failed, updateReportItemFixture(2)]);
    final downloads = UpdateDownloadsFixture();
    final container = await createUpdateRetryContainer(report: previous, downloads: downloads);
    final subscription = container.listen(updateControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    container.read(updateControllerProvider.notifier).onFilterChanged(UpdateFilter.failure);

    await container.read(updateRetryControllerProvider(1).notifier).retry();

    final report = container.read(updateReportStoreProvider)!;
    expect(report.items.first.outcome, UpdateOutcome.updated);
    expect(report.items.first.message, isNull);
    expect(report.items.first.enqueuedCount, 1);
    expect(report.items.first.updatedAt, isNotNull);
    expect(report, previous.copyWith(items: [report.items.first, previous.items.last]));
    expect(report.failureCount, 0);
    expect(report.successCount, 2);
    expect(downloads.mangas.map((manga) => manga.id), [1]);
    expect(container.read(updateControllerProvider), UpdateFilter.failure);
    expect(readUpdateReportFixture(container), report);
  });

  test('Retry still checks manga excluded from automatic updates without enqueueing downloads', () async {
    for (final manga in [mangaFixture(1).copyWith(auto: false), mangaFixture(1).copyWith(favorite: false)]) {
      final source = UpdateSourceFixture();
      final downloads = UpdateDownloadsFixture();
      final container = await createUpdateRetryContainer(source: source, mangas: UpdateMangasFixture([manga]), downloads: downloads);

      await container.read(updateRetryControllerProvider(1).notifier).retry();

      expect(source.calls, 1);
      expect(downloads.mangas, isEmpty);
      expect(container.read(updateReportStoreProvider)!.items.single.outcome, UpdateOutcome.updated);
    }
  });

  test('Repeated retry clicks and detail-controller refreshes share one real update task', () async {
    final pending = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final downloads = UpdateDownloadsFixture();
    final detailProvider = mangaControllerProvider('1');
    final container = await createUpdateRetryContainer(
      source: source,
      downloads: downloads,
      overrides: [
        detailProvider.overrideWith(() => _DetailController(source)),
      ],
    );
    final detailSubscription = container.listen(detailProvider, (_, _) {});
    addTearDown(detailSubscription.close);
    await container.read(detailProvider.future);
    final provider = updateRetryControllerProvider(1);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);

    final retry = controller.retry();
    expect(container.read(provider), isTrue);
    await controller.retry();
    await source.requested;
    await controller.retry();
    final detailController = container.read(detailProvider.notifier);
    final detail = detailController.refreshChapters();
    final repeatedDetail = detailController.refreshChapters();
    expect(source.calls, 1);
    pending.complete();
    await Future.wait([retry, detail, repeatedDetail]);

    expect(container.read(provider), isFalse);
    expect(source.calls, 1);
    expect(downloads.mangas, hasLength(1));
    expect(downloads.refreshed, [1, 1]);
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  for (final stopScan in [false, true]) {
    test('A real scan shares a pending retry and owns the new report: stop=$stopScan', () async {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future);
      final previous = updateReportFixture(items: [_failed, updateReportItemFixture(2)]);
      final downloads = UpdateDownloadsFixture();
      late UpdateServiceCallsFixture updates;
      final container = await createUpdateRetryContainer(
        report: previous,
        source: source,
        downloads: downloads,
        mangas: UpdateMangasFixture([mangaFixture(1), mangaFixture(2)]),
        overrides: [updateServiceProvider.overrideWith((ref) => updates = UpdateServiceCallsFixture(updateService(ref)))],
      );
      final retry = container.read(updateRetryControllerProvider(1).notifier).retry();
      await source.requested;
      final manager = container.read(updateManagerProvider.notifier);
      final scan = manager.scan();
      await updates.waitForCall(2);
      expect(source.calls, 1);
      if (stopScan) manager.stop();

      pending.complete();
      await Future.wait([retry, scan]);

      final report = container.read(updateReportStoreProvider)!;
      expect(report.sessionId, isNot(previous.sessionId));
      expect(report.phase, stopScan ? UpdatePhase.cancelled : UpdatePhase.finished);
      expect(report.totalTargets, 2);
      expect(report.items.map((item) => item.mangaId), [1, 2]);
      expect(report.items.map((item) => item.outcome), [
        UpdateOutcome.updated,
        stopScan ? UpdateOutcome.unchecked : UpdateOutcome.updated,
      ]);
      expect(downloads.mangas.map((manga) => manga.id), stopScan ? [1] : [1, 2]);
      expect(source.calls, stopScan ? 1 : 2);
      expect(readUpdateReportFixture(container), report);
    });
  }

  test('A scan reaching the manga after retry completion checks again without inheriting its old result', () async {
    final pending = Completer<void>();
    final preparation = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final library = UpdateLibraryFixture([mangaFixture(1)], pending: preparation.future);
    final sync = UpdateSyncFixture();
    final downloads = UpdateDownloadsFixture();
    final container = await createUpdateRetryContainer(
      source: source,
      downloads: downloads,
      syncs: {1: sync},
      overrides: [libraryRepositoryProvider.overrideWithValue(library)],
    );
    final retry = container.read(updateRetryControllerProvider(1).notifier).retry();
    await source.requested;
    final scan = container.read(updateManagerProvider.notifier).scan();
    await library.requested;

    pending.complete();
    await retry;
    expect(source.calls, 1);
    expect(container.read(updateReportStoreProvider)!.items, isEmpty);
    sync.result = const ChapterSyncResult(updateCount: 0, insertCount: 0, deleteCount: 0, sourceCount: 1);
    downloads.result = const DownloadEnqueueResult(skippedQueued: 1);
    preparation.complete();
    await scan;

    final report = readUpdateReportFixture(container)!;
    expect(source.calls, 2);
    expect(sync.calls, 2);
    expect(report.items.single.outcome, UpdateOutcome.noUpdate);
    expect(report.items.single.enqueuedCount, 0);
    expect(report.items.single.skippedQueued, 1);
    expect(report.phase, UpdatePhase.finished);
  });

  test('An unexpected shared Future exception releases the retry and allows another real update', () async {
    final source = _BrokenNameSource();
    final downloads = UpdateDownloadsFixture()..result = const DownloadEnqueueResult();
    final container = await createUpdateRetryContainer(source: source, downloads: downloads);
    final provider = updateRetryControllerProvider(1);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(provider.notifier).retry();
    expect(container.read(provider), isFalse);
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.parseError);
    expect(readUpdateReportFixture(container)!.items.single.message, contains('source-name-error'));

    source.failName = false;
    await container.read(provider.notifier).retry();
    expect(source.calls, 2);
    expect(container.read(provider), isFalse);
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Different retries merge with results appended by a running scan', () async {
    final pending = [Completer<void>(), Completer<void>()];
    final syncs = {1: UpdateSyncFixture(pending[0].future), 2: UpdateSyncFixture(pending[1].future)};
    final container = await createUpdateRetryContainer(
      report: updateReportFixture(
        items: [
          _failed,
          _failed.copyWith(mangaId: 2, mangaTitle: 'manga-title-2'),
        ],
      ),
      mangas: UpdateMangasFixture([mangaFixture(1), mangaFixture(2)]),
      syncs: syncs,
    );
    final store = container.read(updateReportStoreProvider.notifier);
    final previous = container.read(updateReportStoreProvider)!;
    final retries = [
      for (final id in [1, 2]) container.read(updateRetryControllerProvider(id).notifier).retry(),
    ];
    await Future.wait(syncs.values.map((sync) => sync.requested));
    await store.update(
      previous.sessionId,
      (report) => report.copyWith(
        phase: UpdatePhase.running,
        totalTargets: 3,
        items: [
          ...report.items,
          updateReportItemFixture(3),
        ],
      ),
    );

    for (final gate in pending.reversed) {
      gate.complete();
    }
    await Future.wait(retries);

    final report = container.read(updateReportStoreProvider)!;
    expect(report.items.map((item) => item.mangaId), [1, 2, 3]);
    expect(report.successCount, 3);
    expect(report.phase, UpdatePhase.running);
    expect(report.totalTargets, 3);
    expect(readUpdateReportFixture(container), report);
  });

  for (final stage in ['database', 'source', 'chapters']) {
    test('A new scan ignores an old retry blocked at $stage', () async {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: stage == 'chapters' ? pending.future : null);
      final sourceRequested = Completer<void>();
      final mangas = UpdateMangasFixture([mangaFixture(1)], pending: stage == 'database' ? pending.future : null);
      final container = await createUpdateRetryContainer(
        source: source,
        mangas: mangas,
        loadSource: () async {
          sourceRequested.complete();
          if (stage == 'source') await pending.future;
          return source;
        },
      );
      final retry = container.read(updateRetryControllerProvider(1).notifier).retry();
      await switch (stage) {
        'database' => mangas.requested,
        'source' => sourceRequested.future,
        _ => source.requested,
      };
      final next = updateReportFixture(items: [_failed.copyWith(message: 'new-scan-error')]).copyWith(sessionId: 'new-scan');
      await container.read(updateReportStoreProvider.notifier).save(next);
      pending.complete();
      await retry;

      expect(container.read(updateReportStoreProvider), next);
      expect(readUpdateReportFixture(container), next);
    });
  }

  test('Retry finishes and persists after its row stops listening', () async {
    final pending = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final container = await createUpdateRetryContainer(source: source);
    final provider = updateRetryControllerProvider(1);
    final subscription = container.listen(provider, (_, _) {});
    final retry = container.read(provider.notifier).retry();
    await source.requested;
    subscription.close();
    await container.pump();
    expect(container.exists(provider), isTrue);

    pending.complete();
    await retry;
    await container.pump();

    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
    expect(container.exists(provider), isFalse);
  });

  test('Leaving while source initialization is pending still lets the retry finish', () async {
    final pending = Completer<void>();
    final requested = Completer<void>();
    final source = UpdateSourceFixture();
    final container = await createUpdateRetryContainer(
      source: source,
      overrides: [
        sourceByIdProvider(1).overrideWith((ref) async {
          requested.complete();
          await pending.future;
          ref.read(sharedPreferencesProvider);
          return source;
        }),
      ],
    );
    final provider = updateRetryControllerProvider(1);
    final retrySubscription = container.listen(provider, (_, _) {});
    final sourceSubscription = container.listen(sourceByIdProvider(1), (_, _) {});
    final retry = container.read(provider.notifier).retry();
    await requested.future;
    retrySubscription.close();
    sourceSubscription.close();
    await container.pump();

    pending.complete();
    await retry.timeout(const Duration(seconds: 2));

    expect(source.calls, 1);
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Database failure is recorded and can be retried after recovery', () async {
    final mangas = UpdateMangasFixture([mangaFixture(1)])..error = StateError('query-error');
    final container = await createUpdateRetryContainer(mangas: mangas);
    final provider = updateRetryControllerProvider(1);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(provider.notifier).retry();
    final failed = readUpdateReportFixture(container)!.items.single;
    expect(failed.outcome, UpdateOutcome.storageError);
    expect(failed.message, contains('query-error'));
    expect(failed.sourceCount, 0);
    expect(failed.enqueuedCount, 0);
    expect(container.read(provider), isFalse);

    mangas.error = null;
    await container.read(provider.notifier).retry();
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Retry reloads a cached source initialization error', () async {
    var failSource = true;
    var loads = 0;
    final source = UpdateSourceFixture();
    final container = await createUpdateRetryContainer(
      source: source,
      loadSource: () async {
        loads++;
        if (failSource) throw TimeoutException('source-init-error');
        return source;
      },
    );
    final subscription = container.listen(sourceByIdProvider(1), (_, _) {});
    addTearDown(subscription.close);
    await expectLater(container.read(sourceByIdProvider(1).future), throwsA(isA<TimeoutException>()));
    expect(loads, 1);

    await container.read(updateRetryControllerProvider(1).notifier).retry();
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.networkError);
    expect(readUpdateReportFixture(container)!.items.single.message, contains('source-init-error'));
    failSource = false;
    await container.read(updateRetryControllerProvider(1).notifier).retry();

    expect(loads, 3);
    expect(source.calls, 1);
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Retry reloads a missing source after installation', () async {
    var installed = false;
    final source = UpdateSourceFixture();
    final container = await createUpdateRetryContainer(source: source, loadSource: () async => installed ? source : NoInstalledSource(1));
    final subscription = container.listen(sourceByIdProvider(1), (_, _) {});
    addTearDown(subscription.close);

    await container.read(updateRetryControllerProvider(1).notifier).retry();
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.sourceUnavailable);
    installed = true;
    await container.read(updateRetryControllerProvider(1).notifier).retry();

    expect(source.calls, 1);
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Missing reports and successful, pending or missing rows do not start an update', () async {
    final source = UpdateSourceFixture();
    final mangas = UpdateMangasFixture([mangaFixture(1)]);
    final container = await createUpdateRetryContainer(source: source, mangas: mangas);
    final store = container.read(updateReportStoreProvider.notifier);
    for (final items in [
      <UpdateReportItem>[],
      [updateReportItemFixture(1)],
      [_failed.copyWith(outcome: UpdateOutcome.pending)],
      [_failed.copyWith(outcome: UpdateOutcome.checking)],
    ]) {
      await store.save(updateReportFixture(phase: UpdatePhase.running, items: items));
      await container.read(updateRetryControllerProvider(1).notifier).retry();
    }
    SharedPreferences.setMockInitialValues({});
    final empty = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance())]);
    addTearDown(empty.dispose);
    await empty.read(updateRetryControllerProvider(1).notifier).retry();

    expect(source.calls, 0);
    expect(mangas.queries, 0);
    expect(empty.read(updateReportStoreProvider), isNull);
  });

  for (final fail in [false, true]) {
    test('Retry resolves local progress without a visible row and only persists the scan result: error=$fail', () async {
      final pending = Completer<void>();
      final requested = Completer<void>();
      final container = await createUpdateRetryContainer(
        overrides: [
          chaptersStreamByMangaProvider(1).overrideWith((ref) => Stream.value(chaptersFixture(1))),
          updateDownloadedChaptersProvider(1).overrideWith((ref) async {
            if (!requested.isCompleted) requested.complete();
            await pending.future;
            if (fail) throw StateError('local-progress-error');
            return {'chapter-title-1'};
          }),
        ],
      );
      final display = container.listen(updateDisplayReportProvider, (_, _) {});
      addTearDown(display.close);
      final retry = container.read(updateRetryControllerProvider(1).notifier).retry();
      await requested.future;
      expect(container.read(updateRetryControllerProvider(1)), isTrue);

      pending.complete();
      await retry;
      await container.pump();

      expect(display.read()!.items.single.outcome, fail ? UpdateOutcome.progressError : UpdateOutcome.updated);
      expect(display.read()!.warningCount, fail ? 1 : 0);
      expect(display.read()!.successCount, fail ? 0 : 1);
      expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
    });
  }

  test('A report persistence failure is shown and releases the retry state', () async {
    final errors = _Errors();
    final container = await createUpdateRetryContainer(
      overrides: [
        updateReportStoreProvider.overrideWith(_FailingStore.new),
        errorHandlerProvider.overrideWithValue(errors),
      ],
    );
    final provider = updateRetryControllerProvider(1);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(provider.notifier).retry();

    expect(errors.errors.single.toString(), contains('report-save-error'));
    expect(container.read(provider), isFalse);
  });
}

class _FailingStore extends UpdateReportStore {
  @override
  UpdateReport? build() => updateReportFixture(items: [_failed]);

  @override
  Future<void> save(UpdateReport report) async => throw StateError('report-save-error');
}

class _DetailController extends MangaController {
  _DetailController(this._source);

  final Source _source;

  @override
  Future<MangaState> build(String mangaId) async => MangaState(source: _source, manga: mangaFixture(int.parse(mangaId)), chapters: []);
}

class _BrokenNameSource extends UpdateSourceFixture {
  bool failName = true;

  @override
  String get name {
    if (failName) throw StateError('source-name-error');
    return super.name;
  }
}

class _Errors implements ErrorHandler {
  final errors = <Object>[];

  @override
  void show(Object error, [StackTrace? stackTrace]) => errors.add(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
