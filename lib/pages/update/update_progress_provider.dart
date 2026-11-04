import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/error/error_handler_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

part 'update_progress_provider.freezed.dart';
part 'update_progress_provider.g.dart';

/// 当前报告内的轻量进度结果，不持有章节列表或数据订阅
class UpdateProgressCache {
  UpdateProgressCache(this.sessionId);

  final String? sessionId;

  final _items = <int, UpdateProgress>{};

  Set<int> _mangaIds = {};

  /// 重新读取时保留已确认的计数，读取失败仍需更新错误反馈
  UpdateProgress update(int mangaId, UpdateProgress progress) {
    final previous = _items[mangaId];
    final snapshot = previous != null && previous.hasValue ? previous : progress;
    final value = progress.hasValue ? progress : snapshot.copyWith(hasError: previous?.hasError == true || progress.hasError);
    if (_mangaIds.contains(mangaId) && (value.hasValue || value.hasError)) _items[mangaId] = value;
    return value;
  }

  /// 按完整报告清理已移除条目，筛选和排序不影响保留范围
  void retain(UpdateReport? report) {
    _mangaIds = report != null && report.sessionId == sessionId ? report.items.map((item) => item.mangaId).toSet() : {};
    _items.removeWhere((mangaId, _) => !_mangaIds.contains(mangaId));
  }

  void clear() {
    _items.clear();
    _mangaIds.clear();
  }
}

/// 由更新页持有当前轮次的结果，旧轮次只能写入自己的实例
@riverpod
UpdateProgressCache updateProgressCache(UpdateProgressCacheRef ref, String? sessionId) {
  final cache = UpdateProgressCache(sessionId);
  ref.listen(updateReportStoreProvider, (_, report) => cache.retain(report), fireImmediately: true);
  ref.onDispose(cache.clear);
  return cache;
}

/// 行在屏幕内时监听数据，离屏后只在报告中保留最后一次统计结果
@riverpod
UpdateProgress updateProgress(UpdateProgressRef ref, UpdateProgressCache cache, int mangaId) {
  final chapters = ref.watch(chaptersStreamByMangaProvider(mangaId));
  final downloaded = ref.watch(updateDownloadedChaptersProvider(mangaId));
  final publicChapters = (chapters.valueOrNull ?? []).where((chapter) => chapter.public);
  final completed = publicChapters.where((chapter) => downloaded.valueOrNull?.contains(chapter.title) == true).length;
  final hasError = chapters.hasError || downloaded.hasError;
  final hasValue = !chapters.isLoading && !downloaded.isLoading && !hasError;
  final progress = UpdateProgress(completed: completed, total: publicChapters.length, hasValue: hasValue, hasError: hasError);
  final failed = chapters.hasError && !chapters.isLoading || downloaded.hasError && !downloaded.isLoading;
  final sessionId = cache.sessionId;
  if (failed && sessionId != null) {
    final store = ref.read(updateReportStoreProvider.notifier);
    final handler = ref.read(errorHandlerProvider);
    var active = true;
    ref.onDispose(() => active = false);
    scheduleMicrotask(() {
      if (active) unawaited(store.markProgressError(sessionId, mangaId).catchError(handler.show));
    });
  }
  return cache.update(mangaId, progress);
}

/// 按漫画 id 监听本地已下载章节
@riverpod
Future<Set<String>> updateDownloadedChapters(UpdateDownloadedChaptersRef ref, int mangaId) async {
  final link = ref.keepAlive();
  try {
    final manga = await ref.watch(mangaStreamByIdProvider(mangaId).future);
    final source = await ref.watch(sourceByIdProvider(manga.source).future);
    return await ref.watch(downloadedByMangaProvider(source, manga).future);
  } finally {
    link.close();
  }
}

@freezed
class UpdateProgress with _$UpdateProgress {
  const factory UpdateProgress({
    @Default(0) int completed,
    @Default(0) int total,
    @Default(false) bool hasValue,
    @Default(false) bool hasError,
  }) = _UpdateProgress;
}
