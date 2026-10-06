import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseManga;
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

DatabaseManga _manga(int id, {int source = 1}) => DatabaseManga(
  id: id,
  source: source,
  url: 'manga-url-$id',
  title: 'manga-title-$id',
  cover: 'manga-cover',
  favorite: true,
  auto: true,
  lastCheckAt: null,
);

void main() {
  test('Empty scan saves a finished report and ignores a repeated start', () async {
    final library = _Library([]);
    final updates = _Updates();
    final preferences = _Preferences();
    final container = _createContainer(library, updates, preferences: preferences);
    final manager = container.read(updateManagerProvider.notifier);

    final scan = manager.scan();
    await manager.scan();
    await scan;

    final report = container.read(updateReportStoreProvider)!;
    expect(library.queries, 1);
    expect(updates.calls, isEmpty);
    expect(report.phase, UpdatePhase.finished);
    expect(report.scanKind, UpdateScanKind.full);
    expect(report.totalTargets, 0);
    expect(report.items, isEmpty);
    expect(report.finishedAt, isNotNull);
    final json = jsonDecode(preferences.value!) as Map<String, dynamic>;
    expect(UpdateReport.fromJson(json), report);
    expect(container.read(updateManagerProvider).hasError, isFalse);
  });

  test('Two source groups run concurrently, each group serially, with saved progress', () async {
    final library = _Library([_manga(4, source: 3), _manga(2), _manga(3, source: 2), _manga(1)]);
    final updates = _Updates(pendingIds: [1, 2, 3, 4]);
    final sourceCalls = <int>[];
    final container = _createContainer(library, updates, sourceCalls: sourceCalls);
    final manager = container.read(updateManagerProvider.notifier);

    final scan = manager.scan();
    await Future.wait([updates.waitFor(1), updates.waitFor(3)]);
    await manager.scan();
    expect(library.queries, 1);
    expect(updates.calls, [1, 3]);
    expect(sourceCalls, [1, 2]);
    expect(container.read(updateReportStoreProvider)!.totalTargets, 4);

    updates.complete(1);
    await updates.waitFor(2);
    expect(updates.calls, [1, 3, 2]);
    expect(container.read(updateReportStoreProvider)!.items.map((item) => item.mangaId), [1]);
    updates.complete(2);
    await updates.waitFor(4);
    expect(sourceCalls, [1, 2, 3]);
    updates.complete(3);
    updates.complete(4);
    await scan;

    final report = container.read(updateReportStoreProvider)!;
    expect(updates.maxActive, 2);
    expect(updates.sources[2], same(updates.sources[1]));
    expect(report.phase, UpdatePhase.finished);
    expect(report.items.map((item) => item.mangaId), unorderedEquals([1, 2, 3, 4]));
    expect(report.items.every((item) => item.enqueuedCount == 1), isTrue);
  });

  test('Stop waits for current manga and leaves remaining targets unstarted', () async {
    final library = _Library([_manga(1), _manga(2), _manga(3, source: 2), _manga(4, source: 3)]);
    final updates = _Updates(pendingIds: [1, 2, 3, 4]);
    final container = _createContainer(library, updates);
    final manager = container.read(updateManagerProvider.notifier);

    final scan = manager.scan();
    await Future.wait([updates.waitFor(1), updates.waitFor(3)]);
    manager.stop();
    expect(container.read(updateManagerProvider).isLoading, isTrue);
    updates.complete(1);
    updates.complete(3);
    await scan;

    final report = container.read(updateReportStoreProvider)!;
    expect(updates.calls, [1, 3]);
    expect(report.phase, UpdatePhase.cancelled);
    expect(report.totalTargets, 4);
    expect(report.items.length, 2);
  });

  test('Stop during target preparation does not load any source', () async {
    final library = _Library([])..pending = Completer<List<DatabaseManga>>();
    final updates = _Updates();
    final sourceCalls = <int>[];
    final container = _createContainer(library, updates, sourceCalls: sourceCalls);
    final manager = container.read(updateManagerProvider.notifier);

    final scan = manager.scan();
    await library.queried.future;
    manager.stop();
    library.pending!.complete([_manga(1)]);
    await scan;

    expect(sourceCalls, isEmpty);
    expect(updates.calls, isEmpty);
    expect(container.read(updateReportStoreProvider)!.phase, UpdatePhase.cancelled);
  });

  test('Source initialization failure records its manga and other sources continue', () async {
    final library = _Library([_manga(1), _manga(2), _manga(3, source: 2)]);
    final updates = _Updates();
    final sourceCalls = <int>[];
    final container = _createContainer(
      library,
      updates,
      sourceCalls: sourceCalls,
      sourceErrors: {1: TimeoutException('source-error')},
    );

    await container.read(updateManagerProvider.notifier).scan();

    final report = container.read(updateReportStoreProvider)!;
    expect(sourceCalls, [1, 2]);
    expect(updates.calls, [3]);
    expect(report.failureCount, 2);
    for (final item in report.items.where((item) => item.sourceId == 1)) {
      expect(item.outcome, UpdateOutcome.networkError);
      expect(item.message, contains('source-error'));
      expect(item.enqueuedCount, 0);
    }
    expect(report.phase, UpdatePhase.finished);
    expect(container.read(updateManagerProvider).hasError, isFalse);
  });

  test('Target query failure is saved and allows a new scan', () async {
    final library = _Library([])..error = StateError('query-error');
    final container = _createContainer(library, _Updates());
    final manager = container.read(updateManagerProvider.notifier);

    await manager.scan();
    expect(container.read(updateManagerProvider).hasError, isTrue);
    expect(container.read(updateReportStoreProvider)!.phase, UpdatePhase.finished);
    expect(container.read(updateReportStoreProvider)!.message, contains('query-error'));
    expect(container.read(updateReportStoreProvider)!.items, isEmpty);

    library.error = null;
    await manager.scan();
    expect(library.queries, 2);
    expect(container.read(updateManagerProvider).hasError, isFalse);
    expect(container.read(updateReportStoreProvider)!.message, isNull);
  });

  test('Progress save failure waits for active work before releasing the scan', () async {
    final library = _Library([_manga(1), _manga(2), _manga(3, source: 2)]);
    final updates = _Updates(pendingIds: [1, 2, 3]);
    final preferences = _Preferences()..failOnSave = 3;
    final container = _createContainer(library, updates, preferences: preferences);
    final manager = container.read(updateManagerProvider.notifier);
    var finished = false;

    final scan = manager.scan().then((_) {
      finished = true;
    });
    await Future.wait([updates.waitFor(1), updates.waitFor(3)]);
    updates.complete(1);
    await preferences.failed.future;
    await manager.scan();
    expect(finished, isFalse);
    expect(library.queries, 1);
    updates.complete(3);
    await scan;

    expect(updates.calls, [1, 3]);
    expect(container.read(updateManagerProvider).hasError, isTrue);
    expect(container.read(updateReportStoreProvider)!.message, contains('Failed to save update report'));
    expect(container.read(updateReportStoreProvider)!.items.length, 2);
    updates.pending.clear();
    await manager.scan();
    expect(library.queries, 2);
    expect(container.read(updateManagerProvider).hasError, isFalse);
  });
}

ProviderContainer _createContainer(
  _Library library,
  _Updates updates, {
  _Preferences? preferences,
  List<int>? sourceCalls,
  Map<int, Object> sourceErrors = const {},
}) {
  final container = ProviderContainer(
    overrides: [
      libraryRepositoryProvider.overrideWithValue(library),
      updateServiceProvider.overrideWithValue(updates),
      sharedPreferencesProvider.overrideWithValue(preferences ?? _Preferences()),
      for (final id in [1, 2, 3])
        sourceByIdProvider(id).overrideWith((ref) async {
          sourceCalls?.add(id);
          if (sourceErrors.containsKey(id)) throw sourceErrors[id]!;
          return NoInstalledSource(id);
        }),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _Library implements LibraryRepository {
  _Library(this.mangas);
  final List<DatabaseManga> mangas;
  final queried = Completer<void>();
  Completer<List<DatabaseManga>>? pending;
  Object? error;
  int queries = 0;

  @override
  Future<List<DatabaseManga>> queryAutoMangas({List<int>? mangaIds}) async {
    queries++;
    if (!queried.isCompleted) queried.complete();
    if (error != null) throw error!;
    return pending == null ? mangas.toList() : await pending!.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Updates implements UpdateService {
  _Updates({Iterable<int> pendingIds = const []}) {
    for (final id in pendingIds) {
      pending[id] = Completer<void>();
    }
  }
  final calls = <int>[];
  final sources = <int, Source>{};
  final pending = <int, Completer<void>>{};
  final _started = <int, Completer<void>>{};
  int active = 0;
  int maxActive = 0;

  Future<void> waitFor(int id) => _started.putIfAbsent(id, Completer<void>.new).future;

  void complete(int id) => pending[id]!.complete();

  @override
  Future<UpdateReportItem> updateManga(Source source, DatabaseManga manga) async {
    calls.add(manga.id);
    sources[manga.id] = source;
    final started = _started.putIfAbsent(manga.id, Completer<void>.new);
    if (!started.isCompleted) started.complete();
    if (++active > maxActive) maxActive = active;
    try {
      await pending[manga.id]?.future;
      return UpdateReportItem(
        sourceId: source.id,
        sourceName: source.name,
        mangaId: manga.id,
        mangaTitle: manga.title,
        outcome: UpdateOutcome.updated,
        insertCount: 0,
        deleteCount: 0,
        updateCount: 1,
        sourceCount: 1,
        enqueuedCount: 1,
        enqueueFailedCount: 0,
        skippedDownloaded: 0,
        skippedQueued: 0,
        skippedUnavailable: 0,
        failedChapters: [],
      );
    } finally {
      active--;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Preferences implements SharedPreferences {
  String? value;
  int saves = 0;
  int? failOnSave;
  final failed = Completer<void>();

  @override
  String? getString(String key) => value;

  @override
  Future<bool> setString(String key, String value) async {
    if (++saves == failOnSave) {
      failed.complete();
      return false;
    }
    this.value = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
