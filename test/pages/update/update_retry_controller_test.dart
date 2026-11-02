import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseManga;
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/pages/update/update_retry_controller.dart';
import 'package:tsukuyomi/providers/download/download_manager_provider.dart';
import 'package:tsukuyomi/providers/error/error_handler_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import '../../fixtures/update_fixtures.dart';

final _failed = updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.networkError, message: 'previous-error');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Retry replaces only the selected failure and retains scan metadata, filter and persisted results', () async {
    final previous = updateReportFixture(totalTargets: 4, items: [_failed, updateReportItemFixture(2)]);
    final downloads = _Downloads();
    final container = await _createContainer(report: previous, downloads: downloads);
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
    expect(_persisted(container), report);
  });

  test('Retry still checks manga excluded from automatic updates without enqueueing downloads', () async {
    for (final manga in [mangaFixture(1).copyWith(auto: false), mangaFixture(1).copyWith(favorite: false)]) {
      final source = UpdateSourceFixture();
      final downloads = _Downloads();
      final container = await _createContainer(source: source, mangas: _Mangas([manga]), downloads: downloads);

      await container.read(updateRetryControllerProvider(1).notifier).retry();

      expect(source.calls, 1);
      expect(downloads.mangas, isEmpty);
      expect(container.read(updateReportStoreProvider)!.items.single.outcome, UpdateOutcome.updated);
    }
  });

  test('Repeated retry clicks and a detail refresh share one real update task', () async {
    final pending = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final downloads = _Downloads();
    final container = await _createContainer(source: source, downloads: downloads);
    final provider = updateRetryControllerProvider(1);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    final controller = container.read(provider.notifier);

    final retry = controller.retry();
    expect(container.read(provider), isTrue);
    await controller.retry();
    await source.requested;
    await controller.retry();
    final detail = container.read(updateServiceProvider).updateMangaAndSaveReport(source, mangaFixture(1));
    expect(source.calls, 1);
    pending.complete();
    await Future.wait([retry, detail]);

    expect(container.read(provider), isFalse);
    expect(source.calls, 1);
    expect(downloads.mangas, hasLength(1));
    expect(_persisted(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Different retries merge with results appended by a running scan', () async {
    final pending = [Completer<void>(), Completer<void>()];
    final syncs = {1: _Sync(pending[0].future), 2: _Sync(pending[1].future)};
    final container = await _createContainer(
      report: updateReportFixture(
        items: [
          _failed,
          _failed.copyWith(mangaId: 2, mangaTitle: 'manga-title-2'),
        ],
      ),
      mangas: _Mangas([mangaFixture(1), mangaFixture(2)]),
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
    expect(_persisted(container), report);
  });

  for (final stage in ['database', 'source', 'chapters']) {
    test('A new scan ignores an old retry blocked at $stage', () async {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: stage == 'chapters' ? pending.future : null);
      final sourceRequested = Completer<void>();
      final mangas = _Mangas([mangaFixture(1)], pending: stage == 'database' ? pending.future : null);
      final container = await _createContainer(
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
      expect(_persisted(container), next);
    });
  }

  test('Retry finishes and persists after its row stops listening', () async {
    final pending = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final container = await _createContainer(source: source);
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

    expect(_persisted(container)!.items.single.outcome, UpdateOutcome.updated);
    expect(container.exists(provider), isFalse);
  });

  test('Database failure is recorded and can be retried after recovery', () async {
    final mangas = _Mangas([mangaFixture(1)])..error = StateError('query-error');
    final container = await _createContainer(mangas: mangas);
    final provider = updateRetryControllerProvider(1);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(provider.notifier).retry();
    final failed = _persisted(container)!.items.single;
    expect(failed.outcome, UpdateOutcome.storageError);
    expect(failed.message, contains('query-error'));
    expect(failed.sourceCount, 0);
    expect(failed.enqueuedCount, 0);
    expect(container.read(provider), isFalse);

    mangas.error = null;
    await container.read(provider.notifier).retry();
    expect(_persisted(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Retry reloads a cached source initialization error', () async {
    var failSource = true;
    var loads = 0;
    final source = UpdateSourceFixture();
    final container = await _createContainer(
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
    expect(_persisted(container)!.items.single.outcome, UpdateOutcome.networkError);
    expect(_persisted(container)!.items.single.message, contains('source-init-error'));
    failSource = false;
    await container.read(updateRetryControllerProvider(1).notifier).retry();

    expect(loads, 3);
    expect(source.calls, 1);
    expect(_persisted(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Retry reloads a missing source after installation', () async {
    var installed = false;
    final source = UpdateSourceFixture();
    final container = await _createContainer(source: source, loadSource: () async => installed ? source : NoInstalledSource(1));
    final subscription = container.listen(sourceByIdProvider(1), (_, _) {});
    addTearDown(subscription.close);

    await container.read(updateRetryControllerProvider(1).notifier).retry();
    expect(_persisted(container)!.items.single.outcome, UpdateOutcome.sourceUnavailable);
    installed = true;
    await container.read(updateRetryControllerProvider(1).notifier).retry();

    expect(source.calls, 1);
    expect(_persisted(container)!.items.single.outcome, UpdateOutcome.updated);
  });

  test('Missing reports and non-failure or missing rows do not start an update', () async {
    final source = UpdateSourceFixture();
    final mangas = _Mangas([mangaFixture(1)]);
    final container = await _createContainer(source: source, mangas: mangas);
    final store = container.read(updateReportStoreProvider.notifier);
    for (final items in [
      <UpdateReportItem>[],
      [updateReportItemFixture(1)],
      [_failed.copyWith(outcome: UpdateOutcome.chaptersEmpty)],
    ]) {
      await store.save(updateReportFixture(items: items));
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

  test('A report persistence failure is shown and releases the retry state', () async {
    final errors = _Errors();
    final container = await _createContainer(
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

Future<ProviderContainer> _createContainer({
  UpdateReport? report,
  UpdateSourceFixture? source,
  Future<Source> Function()? loadSource,
  _Mangas? mangas,
  _Downloads? downloads,
  Map<int, _Sync> syncs = const {},
  List<Override> overrides = const [],
}) async {
  final currentSource = source ?? UpdateSourceFixture();
  final repository = mangas ?? _Mangas([mangaFixture(1)]);
  SharedPreferences.setMockInitialValues({
    Keys.updateReportLatest: jsonEncode((report ?? updateReportFixture(items: [_failed])).toJson()),
  });
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
      mangaRepositoryProvider.overrideWithValue(repository),
      sourceByIdProvider(1).overrideWith((ref) => loadSource?.call() ?? Future.value(currentSource)),
      for (final manga in repository.mangas.values) ...[
        chapterSyncWithSourceProvider(currentSource, manga).overrideWithValue(syncs[manga.id] ?? _Sync()),
      ],
      downloadServiceProvider.overrideWithValue(downloads ?? _Downloads()),
      downloadManagerProvider.overrideWithValue(_Manager()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

UpdateReport? _persisted(ProviderContainer container) {
  final json = container.read(sharedPreferencesProvider).getString(Keys.updateReportLatest);
  return json == null ? null : UpdateReport.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

class _Mangas implements MangaRepository {
  _Mangas(List<DatabaseManga> mangas, {this.pending}) : mangas = {for (final manga in mangas) manga.id: manga};

  final Map<int, DatabaseManga> mangas;
  final Future<void>? pending;
  final _requested = Completer<void>();
  Object? error;
  int queries = 0;

  Future<void> get requested => _requested.future;

  @override
  Future<DatabaseManga> queryManga(int mangaId) async {
    queries++;
    if (!_requested.isCompleted) _requested.complete();
    await pending;
    if (error != null) throw error!;
    return mangas[mangaId]!;
  }

  @override
  Future<int> updateLastCheckAt(int mangaId, DateTime date) async => 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sync implements ChapterSyncWithSource {
  _Sync([this.pending]);

  final Future<void>? pending;
  final _requested = Completer<void>();

  Future<void> get requested => _requested.future;

  @override
  Future<ChapterSyncResult> apply(Iterable<SourceChapter> sourceChapters) async {
    _requested.complete();
    await pending;
    return const ChapterSyncResult(insertCount: 1, deleteCount: 0, updateCount: 0, sourceCount: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Downloads implements DownloadService {
  final mangas = <DatabaseManga>[];

  @override
  Future<DownloadEnqueueResult> enqueueAutoDownloads(Source source, DatabaseManga manga) async {
    mangas.add(manga);
    return const DownloadEnqueueResult(enqueuedCount: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Manager implements DownloadManager {
  @override
  Future<void> next() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingStore extends UpdateReportStore {
  @override
  UpdateReport? build() => updateReportFixture(items: [_failed]);

  @override
  Future<void> save(UpdateReport report) async => throw StateError('report-save-error');
}

class _Errors implements ErrorHandler {
  final errors = <Object>[];

  @override
  void show(Object error, [StackTrace? stackTrace]) => errors.add(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
