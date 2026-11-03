import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
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

  UpdateProgress? read(int mangaId) => _items[mangaId];

  UpdateProgress save(int mangaId, UpdateProgress progress) {
    if (_mangaIds.contains(mangaId)) _items[mangaId] = progress;
    return progress;
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
  final previous = cache.read(mangaId);
  final hasError = chapters.hasError || downloaded.hasError;
  final ready = chapters.hasValue && downloaded.hasValue && !chapters.isLoading && !downloaded.isLoading && !hasError;
  // 两路数据重新读取期间沿用完整结果，避免先归零或只更新分母
  if (!ready && previous != null) {
    return hasError ? cache.save(mangaId, previous.copyWith(hasError: true)) : previous;
  }

  final downloadedChapters = downloaded.valueOrNull;
  var completed = 0;
  var total = 0;
  for (final chapter in chapters.valueOrNull ?? []) {
    if (!chapter.public) continue;
    total++;
    if (downloadedChapters?.contains(chapter.title) == true) completed++;
  }
  final progress = UpdateProgress(completed: completed, total: total, hasValue: ready, hasError: hasError);
  // 首次读取保留原来的默认显示，完整结果或错误状态才进入缓存
  return ready || hasError ? cache.save(mangaId, progress) : progress;
}

/// 按漫画 id 监听本地已下载章节
@riverpod
Future<Set<String>> updateDownloadedChapters(UpdateDownloadedChaptersRef ref, int mangaId) async {
  final manga = await ref.watch(mangaStreamByIdProvider(mangaId).future);
  final source = await ref.watch(sourceByIdProvider(manga.source).future);
  return ref.watch(downloadedByMangaProvider(source, manga).future);
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
