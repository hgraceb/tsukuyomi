import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/core/exception/tsukuyomi_exception.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseManga;
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
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
  });
}

Future<ProviderContainer> _createContainer(_Source source, _Sync sync, _Downloads downloads, {DatabaseManga manga = _manga}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      chapterSyncWithSourceProvider(source, manga).overrideWithValue(sync),
      downloadServiceProvider.overrideWithValue(downloads),
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
  _Downloads(this.result);
  final DownloadEnqueueResult result;
  int calls = 0;

  @override
  Future<DownloadEnqueueResult> enqueueAutoDownloads(Source source, DatabaseManga manga) async {
    calls++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
