import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/providers/download/download_manager_provider.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import 'update_error.dart';
import 'update_report_store.dart';
import 'update_state.dart';

part 'update_service.g.dart';

class UpdateService {
  UpdateService._({required this.ref});

  final UpdateServiceRef ref;

  /// 更新漫画章节并加入下载队列
  Future<UpdateReportItem> updateManga(Source source, DatabaseManga manga) async {
    var sync = const ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 0, sourceCount: 0);
    var downloads = const DownloadEnqueueResult();
    Iterable<SourceChapter> chapters;
    try {
      chapters = await source.getMangaChapters(manga.toHttpSourceManga());
    } catch (error) {
      return _result(source, manga, sync, downloads, classifySourceError(error), message: error.toString());
    }
    try {
      sync = await ref.read(chapterSyncWithSourceProvider(source, manga)).apply(chapters);
      await ref.read(mangaRepositoryProvider).updateLastCheckAt(manga.id, DateTime.now());
    } catch (error) {
      return _result(source, manga, sync, downloads, UpdateOutcome.storageError, message: error.toString());
    }
    if (manga.favorite && manga.auto) {
      try {
        downloads = await ref.read(downloadServiceProvider).enqueueAutoDownloads(source, manga);
        if (downloads.enqueuedCount > 0 || downloads.skippedQueued > 0) {
          await ref.read(downloadManagerProvider).next();
        }
      } catch (error) {
        return _result(source, manga, sync, downloads, UpdateOutcome.enqueueFailed, message: error.toString());
      }
    }
    var outcome = UpdateOutcome.noUpdate;
    if (sync.insertCount > 0 || downloads.enqueuedCount > 0) outcome = UpdateOutcome.updated;
    if (sync.deleteCount > 0 && sync.insertCount == 0) outcome = UpdateOutcome.chaptersReduced;
    if (sync.sourceCount == 0) outcome = UpdateOutcome.chaptersEmpty;
    if (downloads.failedChapters.isNotEmpty) outcome = UpdateOutcome.enqueueFailed;
    return _result(source, manga, sync, downloads, outcome);
  }

  /// 更新单部漫画并保存检查报告
  Future<UpdateReportItem> updateMangaAndSaveReport(Source source, DatabaseManga manga) async {
    final startedAt = DateTime.now();
    final item = await updateManga(source, manga);
    final report = UpdateReport(
      version: UpdateReport.currentVersion,
      phase: UpdatePhase.finished,
      scanKind: UpdateScanKind.partial,
      sessionId: startedAt.microsecondsSinceEpoch.toString(),
      totalTargets: 1,
      items: [item],
      startedAt: startedAt,
      finishedAt: item.updatedAt,
    );
    await ref.read(updateReportStoreProvider.notifier).save(report);
    return item;
  }

  UpdateReportItem _result(
    Source source,
    DatabaseManga manga,
    ChapterSyncResult sync,
    DownloadEnqueueResult downloads,
    UpdateOutcome outcome, {
    String? message,
  }) {
    final messages = [
      ...downloads.failedChapters.entries.map((entry) => '${entry.key}: ${entry.value}'),
      if (message != null) message,
    ];
    return UpdateReportItem(
      sourceId: source.id,
      sourceName: source.name,
      mangaId: manga.id,
      mangaTitle: manga.title,
      outcome: outcome,
      insertCount: sync.insertCount,
      deleteCount: sync.deleteCount,
      updateCount: sync.updateCount,
      sourceCount: sync.sourceCount,
      enqueuedCount: downloads.enqueuedCount,
      enqueueFailedCount: downloads.failedChapters.length,
      skippedDownloaded: downloads.skippedDownloaded,
      skippedQueued: downloads.skippedQueued,
      skippedUnavailable: downloads.skippedUnavailable,
      failedChapters: downloads.failedChapters.keys.toList(growable: false),
      updatedAt: DateTime.now(),
      message: messages.isEmpty ? null : messages.join('\n'),
    );
  }
}

@Riverpod(keepAlive: true)
UpdateService updateService(UpdateServiceRef ref) {
  return UpdateService._(ref: ref);
}
