import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseChapter;
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

import '../../fixtures/update_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('First reads retain the default display and count only downloaded public chapters', () async {
    final chapters = Completer<void>();
    final downloads = Completer<void>();
    final input = _Input(1, downloaded: {'chapter-title-1', 'chapter-title-5', 'chapter-title-6', 'removed-chapter'})
      ..chaptersPending = chapters.future
      ..downloadsPending = downloads.future;
    final harness = await _Harness.create([input]);
    final row = harness.watch(1);
    expect(row.read(), const UpdateProgress());

    chapters.complete();
    await harness.container.read(chaptersStreamByMangaProvider(1).future);
    await harness.container.pump();
    expect(row.read(), const UpdateProgress(total: 5));
    downloads.complete();
    await harness.settle(1);
    expect(row.read(), const UpdateProgress(completed: 2, total: 5, hasValue: true));
  });

  test('An unfinished first read is not retained when its row leaves and returns', () async {
    final firstDownloads = Completer<void>();
    final input = _Input(1)..downloadsPending = firstDownloads.future;
    final harness = await _Harness.create([input]);
    final first = harness.watch(1);
    await harness.container.read(chaptersStreamByMangaProvider(1).future);
    await harness.container.pump();
    expect(first.read(), const UpdateProgress(total: 5));
    first.close();
    await harness.container.pump();

    final nextRead = Completer<void>();
    input
      ..chaptersPending = nextRead.future
      ..downloadsPending = nextRead.future;
    final returned = harness.watch(1);
    expect(returned.read(), const UpdateProgress());
    firstDownloads.complete();
    await harness.container.pump();
    expect(returned.read(), const UpdateProgress());
    nextRead.complete();
    await harness.settle(1);
    expect(returned.read(), const UpdateProgress(completed: 2, total: 5, hasValue: true));
  });

  for (final chaptersFirst in [true, false]) {
    test('Returning retains both counts until both reads finish: chaptersFirst=$chaptersFirst', () async {
      final input = _Input(1);
      final harness = await _Harness.create([input]);
      final first = harness.watch(1);
      await harness.settle(1);
      final previous = first.read();
      first.close();
      await harness.container.pump();
      expect(harness.container.exists(updateProgressProvider(harness.cache, 1)), isFalse);
      expect(harness.container.exists(chaptersStreamByMangaProvider(1)), isFalse);
      expect(harness.container.exists(updateDownloadedChaptersProvider(1)), isFalse);
      expect(input.chapterDisposals, 1);
      expect(input.downloadDisposals, 1);

      final chapters = Completer<void>();
      final downloads = Completer<void>();
      input
        ..chapters = chaptersFixture(1, total: 10, publicCount: 8)
        ..downloaded = {'chapter-title-1', 'chapter-title-2', 'chapter-title-3'}
        ..chaptersPending = chapters.future
        ..downloadsPending = downloads.future;
      final returned = harness.watch(1);
      expect(returned.read(), previous);
      expect(input.chapterReads, 2);
      expect(input.downloadReads, 2);

      if (chaptersFirst) {
        chapters.complete();
        await harness.container.read(chaptersStreamByMangaProvider(1).future);
      } else {
        downloads.complete();
        await harness.container.read(updateDownloadedChaptersProvider(1).future);
      }
      await harness.container.pump();
      expect(returned.read(), previous);
      if (chaptersFirst) {
        downloads.complete();
      } else {
        chapters.complete();
      }
      await harness.settle(1);
      expect(returned.read(), const UpdateProgress(completed: 3, total: 8, hasValue: true));
    });
  }

  for (final failingInput in ['chapters', 'downloads']) {
    test('A $failingInput reload retains complete counts, exposes failure and recovers', () async {
      final input = _Input(1, downloaded: {for (var id = 1; id <= 5; id++) 'chapter-title-$id'});
      final harness = await _Harness.create([input]);
      final row = harness.watch(1);
      await harness.settle(1);
      const previous = UpdateProgress(completed: 5, total: 5, hasValue: true);
      expect(row.read(), previous);

      final pending = Completer<void>();
      final error = StateError('$failingInput-read-error');
      if (failingInput == 'chapters') {
        input
          ..chaptersPending = pending.future
          ..chaptersError = error;
        harness.container.invalidate(chaptersStreamByMangaProvider(1));
      } else {
        input
          ..downloadsPending = pending.future
          ..downloadsError = error;
        harness.container.invalidate(updateDownloadedChaptersProvider(1));
      }
      expect(row.read(), previous);
      pending.complete();
      final read = failingInput == 'chapters'
          ? harness.container.read(chaptersStreamByMangaProvider(1).future)
          : harness.container.read(updateDownloadedChaptersProvider(1).future);
      await expectLater(read, throwsA(same(error)));
      await harness.container.pump();
      expect(row.read(), previous.copyWith(hasError: true));

      input
        ..chaptersPending = null
        ..downloadsPending = null
        ..chaptersError = null
        ..downloadsError = null;
      if (failingInput == 'chapters') {
        harness.container.invalidate(chaptersStreamByMangaProvider(1));
      } else {
        harness.container.invalidate(updateDownloadedChaptersProvider(1));
      }
      await harness.settle(1);
      expect(row.read(), previous);
    });
  }

  test('A failed first read has no confirmed result and can recover to a genuine empty result', () async {
    final error = StateError('initial-error');
    final input = _Input(1)..downloadsError = error;
    final harness = await _Harness.create([input]);
    final row = harness.watch(1);
    await expectLater(harness.container.read(updateDownloadedChaptersProvider(1).future), throwsA(same(error)));
    await harness.container.read(chaptersStreamByMangaProvider(1).future);
    await harness.container.pump();
    expect(row.read().hasValue, isFalse);
    expect(row.read().hasError, isTrue);

    input
      ..downloadsError = null
      ..chapters = []
      ..downloaded = {};
    harness.container.invalidate(chaptersStreamByMangaProvider(1));
    harness.container.invalidate(updateDownloadedChaptersProvider(1));
    await harness.settle(1);
    expect(row.read(), const UpdateProgress(hasValue: true));
  });

  test('Download changes update their manga without changing another row or the saved report', () async {
    final inputs = [
      _Input(1),
      _Input(2, downloaded: {'chapter-title-5'}),
    ];
    final harness = await _Harness.create(inputs);
    final first = harness.watch(1);
    var secondNotifications = 0;
    final second = harness.container.listen(updateProgressProvider(harness.cache, 2), (_, _) => secondNotifications++);
    await Future.wait([harness.settle(1), harness.settle(2)]);
    final previousSecond = second.read();
    final previousNotifications = secondNotifications;
    final saved = harness.container.read(sharedPreferencesProvider).getString(Keys.updateReportLatest);

    inputs.first.downloaded = {for (var id = 1; id <= 5; id++) 'chapter-title-$id'};
    harness.container.invalidate(updateDownloadedChaptersProvider(1));
    await harness.settle(1);

    expect(first.read(), const UpdateProgress(completed: 5, total: 5, hasValue: true));
    expect(second.read(), previousSecond);
    expect(secondNotifications, previousNotifications);
    expect(harness.container.read(updateReportStoreProvider), harness.report);
    expect(harness.container.read(sharedPreferencesProvider).getString(Keys.updateReportLatest), saved);
  });

  test('Chapter reading-position changes do not notify unchanged progress', () async {
    final input = _Input(1);
    final harness = await _Harness.create([input]);
    var notifications = 0;
    final row = harness.container.listen(updateProgressProvider(harness.cache, 1), (_, _) => notifications++);
    await harness.settle(1);
    final previous = row.read();
    final previousNotifications = notifications;

    input.chapters = input.chapters.map((chapter) => chapter.copyWith(progress: 42, images: 100)).toList();
    harness.container.invalidate(chaptersStreamByMangaProvider(1));
    await harness.settle(1);

    expect(row.read(), previous);
    expect(notifications, previousNotifications);
  });

  test('Confirmed empty chapters replace a previous nonzero result', () async {
    final input = _Input(1);
    final harness = await _Harness.create([input]);
    final row = harness.watch(1);
    await harness.settle(1);
    expect(row.read().completed, 2);

    input.chapters = [];
    harness.container.invalidate(chaptersStreamByMangaProvider(1));
    await harness.settle(1);
    expect(row.read(), const UpdateProgress(hasValue: true));
  });

  test('Report metadata, appended items and filter changes preserve cached progress', () async {
    final input = _Input(1);
    final harness = await _Harness.create([input, _Input(2)]);
    final row = harness.watch(1);
    await harness.settle(1);
    final previous = row.read();
    final cache = harness.cache;
    row.close();
    await harness.container.pump();

    harness.container.listen(updateControllerProvider, (_, _) {});
    harness.container.read(updateControllerProvider.notifier).onFilterChanged(UpdateFilter.failure);
    final changed = harness.report.copyWith(
      phase: UpdatePhase.running,
      totalTargets: 3,
      items: [
        harness.report.items.first.copyWith(sourceName: 'renamed-source'),
        harness.report.items.last,
        updateReportItemFixture(3),
      ],
    );
    await harness.container.read(updateReportStoreProvider.notifier).save(changed);
    expect(harness.cache, same(cache));
    expect(harness.container.read(updateControllerProvider), UpdateFilter.failure);

    final pending = Completer<void>();
    input
      ..chaptersPending = pending.future
      ..downloadsPending = pending.future;
    final returned = harness.watch(1);
    expect(returned.read(), previous);
    pending.complete();
    await harness.settle(1);
    expect(harness.container.read(updateReportStoreProvider), changed);
  });

  test('Removing a report item prunes its result while other manga remain cached', () async {
    final input = _Input(1);
    final harness = await _Harness.create([input, _Input(2)]);
    final first = harness.watch(1);
    final second = harness.watch(2);
    await Future.wait([harness.settle(1), harness.settle(2)]);
    final previousSecond = second.read();
    first.close();
    await harness.container.pump();

    final store = harness.container.read(updateReportStoreProvider.notifier);
    await store.save(harness.report.copyWith(items: [harness.report.items.last]));
    await store.save(harness.report);
    final pending = Completer<void>();
    input
      ..chaptersPending = pending.future
      ..downloadsPending = pending.future;
    final returned = harness.watch(1);
    expect(returned.read(), const UpdateProgress());
    expect(second.read(), previousSecond);
    pending.complete();
    await harness.settle(1);
  });

  test('Late reads from an old report cannot seed the new report cache for the same manga', () async {
    final pending = Completer<void>();
    final input = _Input(1)
      ..chaptersPending = pending.future
      ..downloadsPending = pending.future;
    final harness = await _Harness.create([input]);
    final oldRow = harness.watch(1);
    final next = harness.report.copyWith(sessionId: 'next-session');
    await harness.container.read(updateReportStoreProvider.notifier).save(next);
    final nextOwner = harness.container.listen(updateProgressCacheProvider(next.sessionId), (_, _) {});
    final nextCache = nextOwner.read();
    expect(nextCache, isNot(same(harness.cache)));

    pending.complete();
    await harness.settle(1);
    oldRow.close();
    await harness.container.pump();
    final nextPending = Completer<void>();
    input
      ..chaptersPending = nextPending.future
      ..downloadsPending = nextPending.future;
    final nextRow = harness.watch(1, cache: nextCache);
    expect(nextRow.read(), const UpdateProgress());
    nextPending.complete();
    await harness.settle(1);
    expect(nextRow.read(), const UpdateProgress(completed: 2, total: 5, hasValue: true));
  });

  test('Disposing the page owner releases its cached results', () async {
    final input = _Input(1);
    final harness = await _Harness.create([input]);
    final row = harness.watch(1);
    await harness.settle(1);
    final previousCache = harness.cache;
    row.close();
    harness.owner.close();
    await harness.container.pump();
    expect(harness.container.exists(updateProgressCacheProvider(harness.report.sessionId)), isFalse);

    final pending = Completer<void>();
    input
      ..chaptersPending = pending.future
      ..downloadsPending = pending.future;
    final owner = harness.container.listen(updateProgressCacheProvider(harness.report.sessionId), (_, _) {});
    expect(owner.read(), isNot(same(previousCache)));
    final returned = harness.watch(1, cache: owner.read());
    expect(returned.read(), const UpdateProgress());
    pending.complete();
    await harness.settle(1);
  });

  test('Releasing an update row preserves raw data still used by another consumer', () async {
    final input = _Input(1);
    final harness = await _Harness.create([input]);
    final other = harness.container.listen(updateDownloadedChaptersProvider(1), (_, _) {});
    final row = harness.watch(1);
    await harness.settle(1);
    row.close();
    await harness.container.pump();
    expect(harness.container.exists(updateProgressProvider(harness.cache, 1)), isFalse);
    expect(harness.container.exists(chaptersStreamByMangaProvider(1)), isFalse);
    expect(harness.container.exists(updateDownloadedChaptersProvider(1)), isTrue);
    expect(input.downloadDisposals, 0);
    expect(other.read().requireValue, input.downloaded);
    other.close();
    await harness.container.pump();
    expect(input.downloadDisposals, 1);
  });

  test('Visiting 1000 manga retains small results while releasing every row and raw subscription', () async {
    final inputs = [
      for (var id = 1; id <= 1000; id++)
        _Input(
          id,
          chapters: chaptersFixture(id, total: 16, publicCount: id % 13 + 2),
          downloaded: {'chapter-title-1'},
        ),
    ];
    final harness = await _Harness.create(inputs);
    for (final input in inputs) {
      final row = harness.watch(input.id);
      await harness.settle(input.id);
      expect(row.read(), UpdateProgress(completed: 1, total: input.id % 13 + 2, hasValue: true));
      row.close();
      await harness.container.pump();
      expect(harness.container.exists(updateProgressProvider(harness.cache, input.id)), isFalse);
      expect(harness.container.exists(chaptersStreamByMangaProvider(input.id)), isFalse);
      expect(harness.container.exists(updateDownloadedChaptersProvider(input.id)), isFalse);
    }
    expect(inputs.every((input) => input.chapterReads == 1 && input.chapterDisposals == 1), isTrue);
    expect(inputs.every((input) => input.downloadReads == 1 && input.downloadDisposals == 1), isTrue);

    for (final id in [1, 500, 1000]) {
      final pending = Completer<void>();
      inputs[id - 1]
        ..chaptersPending = pending.future
        ..downloadsPending = pending.future;
      final row = harness.watch(id);
      expect(row.read(), UpdateProgress(completed: 1, total: id % 13 + 2, hasValue: true));
      pending.complete();
      await harness.settle(id);
      row.close();
    }
  });
}

class _Harness {
  _Harness(this.container, this.report) : owner = container.listen(updateProgressCacheProvider(report.sessionId), (_, _) {});

  final ProviderContainer container;
  final UpdateReport report;
  final ProviderSubscription<UpdateProgressCache> owner;

  UpdateProgressCache get cache => owner.read();

  static Future<_Harness> create(List<_Input> inputs) async {
    final report = updateReportFixture(totalTargets: inputs.length, items: [for (final input in inputs) updateReportItemFixture(input.id)]);
    SharedPreferences.setMockInitialValues({Keys.updateReportLatest: jsonEncode(report.toJson())});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        for (final input in inputs) ...[
          chaptersStreamByMangaProvider(input.id).overrideWith((ref) {
            input.chapterReads++;
            ref.onDispose(() => input.chapterDisposals++);
            return input.readChapters();
          }),
          updateDownloadedChaptersProvider(input.id).overrideWith((ref) {
            input.downloadReads++;
            ref.onDispose(() => input.downloadDisposals++);
            return input.readDownloads();
          }),
        ],
      ],
    );
    addTearDown(container.dispose);
    return _Harness(container, report);
  }

  ProviderSubscription<UpdateProgress> watch(int mangaId, {UpdateProgressCache? cache}) {
    return container.listen(updateProgressProvider(cache ?? this.cache, mangaId), (_, _) {});
  }

  Future<void> settle(int mangaId) async {
    await Future.wait<Object>([
      container.read(chaptersStreamByMangaProvider(mangaId).future),
      container.read(updateDownloadedChaptersProvider(mangaId).future),
    ]);
    await container.pump();
  }
}

class _Input {
  _Input(this.id, {List<DatabaseChapter>? chapters, Set<String>? downloaded})
    : chapters = chapters ?? chaptersFixture(id),
      downloaded = downloaded ?? {'chapter-title-1', 'chapter-title-2'};

  final int id;
  List<DatabaseChapter> chapters;
  Set<String> downloaded;
  Future<void>? chaptersPending;
  Future<void>? downloadsPending;
  Object? chaptersError;
  Object? downloadsError;
  int chapterReads = 0;
  int downloadReads = 0;
  int chapterDisposals = 0;
  int downloadDisposals = 0;

  Stream<List<DatabaseChapter>> readChapters() async* {
    final value = List<DatabaseChapter>.of(chapters);
    final error = chaptersError;
    await chaptersPending;
    if (error != null) throw error;
    yield value;
  }

  Future<Set<String>> readDownloads() async {
    final value = Set<String>.of(downloaded);
    final error = downloadsError;
    await downloadsPending;
    if (error != null) throw error;
    return value;
  }
}
