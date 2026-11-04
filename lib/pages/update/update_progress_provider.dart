import 'dart:async';

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

  final _errors = StreamController<Set<int>>.broadcast();

  Set<int> _mangaIds = {};

  Set<int> get errors => _items.entries.where((entry) => entry.value.hasError).map((entry) => entry.key).toSet();

  /// 重新读取时保留已确认的计数，读取失败仍需更新错误反馈
  UpdateProgress update(int mangaId, UpdateProgress progress) {
    final previous = _items[mangaId];
    final snapshot = previous != null && previous.hasValue ? previous : progress;
    final value = progress.hasValue ? progress : snapshot.copyWith(hasError: previous?.hasError == true || progress.hasError);
    if (_mangaIds.contains(mangaId) && (value.hasValue || value.hasError)) {
      _items[mangaId] = value;
      if ((previous?.hasError ?? false) != value.hasError) _notifyErrors();
    }
    return value;
  }

  /// 按完整报告清理已移除条目，筛选和排序不影响保留范围
  void retain(UpdateReport? report) {
    _mangaIds = report != null && report.sessionId == sessionId ? report.items.map((item) => item.mangaId).toSet() : {};
    var removedError = false;
    _items.removeWhere((mangaId, progress) {
      if (_mangaIds.contains(mangaId)) return false;
      removedError |= progress.hasError;
      return true;
    });
    if (removedError) _notifyErrors();
  }

  void clear() {
    final hadErrors = _items.values.any((progress) => progress.hasError);
    _items.clear();
    _mangaIds.clear();
    if (hadErrors) _notifyErrors();
  }

  void _notifyErrors() {
    if (!_errors.isClosed) _errors.add(errors);
  }

  void dispose() {
    clear();
    unawaited(_errors.close());
  }
}

/// 由更新页持有当前轮次的结果，旧轮次只能写入自己的实例
@riverpod
UpdateProgressCache updateProgressCache(UpdateProgressCacheRef ref, String? sessionId) {
  final cache = UpdateProgressCache(sessionId);
  ref.listen(updateReportStoreProvider, (_, report) => cache.retain(report), fireImmediately: true);
  ref.onDispose(cache.dispose);
  return cache;
}

/// 只广播错误漫画的 ID，汇总与筛选不持有每本漫画的数据订阅
@riverpod
Stream<Set<int>> updateProgressErrors(UpdateProgressErrorsRef ref, UpdateProgressCache cache) {
  return Stream<Set<int>>.multi((controller) {
    final subscription = cache._errors.stream.listen(controller.add, onError: controller.addError, onDone: controller.close);
    controller.add(cache.errors);
    controller.onCancel = subscription.cancel;
  });
}

/// 展示警告不改写扫描报告，本地进度恢复后回到原检查结果
@riverpod
UpdateReport? updateDisplayReport(UpdateDisplayReportRef ref) {
  final report = ref.watch(updateReportStoreProvider);
  if (report == null) return null;
  final cache = ref.watch(updateProgressCacheProvider(report.sessionId));
  final errors = ref.watch(updateProgressErrorsProvider(cache)).valueOrNull ?? cache.errors;
  return report.copyWith(
    items: [
      for (final item in report.items) ...[
        if (report.phase != UpdatePhase.running && item.outcome.isPending)
          item.copyWith(outcome: UpdateOutcome.unchecked)
        else if (errors.contains(item.mangaId) && item.outcome.canReadProgress && !item.outcome.isFailure)
          item.copyWith(outcome: UpdateOutcome.progressError)
        else
          item,
      ],
    ],
  );
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
