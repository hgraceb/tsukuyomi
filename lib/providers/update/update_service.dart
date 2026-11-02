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

  final Map<int, Future<UpdateReportItem>> _updating = {};

  /// 更新漫画章节并加入下载队列
  Future<UpdateReportItem> updateManga(Source source, DatabaseManga manga) {
    return _updating.putIfAbsent(
      manga.id,
      () => _updateManga(source, manga).whenComplete(() {
        _updating.remove(manga.id);
      }),
    );
  }

  /// 获取并同步章节，再按最新收藏与自动下载设置安排下载
  ///
  /// 按失败阶段记录错误，并保留已经完成的章节同步和下载入队计数
  Future<UpdateReportItem> _updateManga(Source source, DatabaseManga manga) async {
    var sync = const ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 0, sourceCount: 0);
    var downloads = const DownloadEnqueueResult();
    UpdateOutcome? failureOutcome;
    try {
      final chapters = await source.getMangaChapters(manga.toHttpSourceManga());
      failureOutcome = UpdateOutcome.storageError;
      sync = await ref.read(chapterSyncWithSourceProvider(source, manga)).apply(chapters);
      final repository = ref.read(mangaRepositoryProvider);
      await repository.updateLastCheckAt(manga.id, DateTime.now());
      final latestManga = await repository.queryManga(manga.id);
      failureOutcome = UpdateOutcome.enqueueFailed;
      if (latestManga.favorite && latestManga.auto) {
        downloads = await ref.read(downloadServiceProvider).enqueueAutoDownloads(source, latestManga);
        if (downloads.enqueuedCount > 0 || downloads.skippedQueued > 0) {
          await ref.read(downloadManagerProvider).next();
        }
      }
    } catch (error) {
      final outcome = failureOutcome ?? classifySourceError(error);
      return _result(source, manga, sync, downloads, outcome, message: error.toString());
    }
    return _result(source, manga, sync, downloads, _getOutcome(sync, downloads));
  }

  /// 更新单部漫画并修正当前报告中已有的检查结果
  Future<UpdateReportItem> updateMangaAndSaveReport(Source source, DatabaseManga manga) async {
    final sessionId = ref.read(updateReportStoreProvider)?.sessionId;
    final item = await updateManga(source, manga);
    if (sessionId != null) {
      await ref.read(updateReportStoreProvider.notifier).update(sessionId, (report) {
        if (!report.items.any((existing) => existing.mangaId == item.mangaId)) return report;
        return report.copyWith(
          items: [
            for (final existing in report.items) existing.mangaId == item.mangaId ? item : existing,
          ],
        );
      });
    }
    return item;
  }

  UpdateOutcome _getOutcome(ChapterSyncResult sync, DownloadEnqueueResult downloads) {
    if (downloads.failedChapters.isNotEmpty) return UpdateOutcome.enqueueFailed;
    if (sync.sourceCount == 0) return UpdateOutcome.chaptersEmpty;
    if (sync.deleteCount > 0 && sync.insertCount == 0) return UpdateOutcome.chaptersReduced;
    if (sync.insertCount > 0 || downloads.enqueuedCount > 0) return UpdateOutcome.updated;
    return UpdateOutcome.noUpdate;
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
