import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/providers/error/error_handler_provider.dart';
import 'package:tsukuyomi/providers/update/update_error.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/source/source.dart';

part 'update_retry_controller.g.dart';

/// 更新页单部漫画的重试状态
@riverpod
class UpdateRetryController extends _$UpdateRetryController {
  @override
  bool build(int mangaId) => false;

  /// 统一重新检查漫画并刷新本地进度，仅替换当前轮次的对应结果
  Future<void> retry() async {
    if (state) return;
    final report = ref.read(updateReportStoreProvider);
    final item = report?.items.firstWhereOrNull((item) => item.mangaId == mangaId);
    if (report == null || item == null) return;
    final cache = ref.read(updateProgressCacheProvider(report.sessionId));
    if (!cache.outcomeFor(item).canRetry) return;
    // 条目被筛选隐藏或离开页面时，仍需完成重试和报告保存
    final link = ref.keepAlive();
    state = true;
    try {
      final result = await _retry(item);
      await ref.read(updateReportStoreProvider.notifier).replaceItem(report.sessionId, result);
      final current = ref.read(updateReportStoreProvider);
      if (current?.sessionId == report.sessionId && result.outcome.canReadProgress) await _refreshProgress(report.sessionId);
    } catch (error, stackTrace) {
      ref.read(errorHandlerProvider).show(error, stackTrace);
    } finally {
      state = false;
      link.close();
    }
  }

  Future<UpdateReportItem> _retry(UpdateReportItem item) async {
    UpdateOutcome? failureOutcome = UpdateOutcome.storageError;
    try {
      final manga = await ref.read(mangaRepositoryProvider).queryMangaByIdOrNull(mangaId);
      if (manga == null) return item.copyWith(outcome: UpdateOutcome.skipped, updatedAt: DateTime.now(), message: null);
      failureOutcome = null;
      final provider = sourceByIdProvider(manga.source);
      final cached = ref.read(provider);
      // 重试失败或尚未安装的源时重新加载，保留正在加载的任务
      if (!cached.isLoading && (cached.hasError || cached.valueOrNull is NoInstalledSource)) {
        ref.invalidate(provider);
      }
      final source = await ref.read(provider.future);
      // 本地读取失败由进度状态展示，不中断章节检查
      await AsyncValue.guard(() => ref.read(downloadServiceProvider).refreshDownloadedByManga(source, manga));
      return await ref.read(updateServiceProvider).updateManga(source, manga);
    } catch (error) {
      return UpdateReportItem(
        sourceId: item.sourceId,
        sourceName: item.sourceName,
        mangaId: item.mangaId,
        mangaTitle: item.mangaTitle,
        outcome: failureOutcome ?? classifySourceError(error),
        updatedAt: DateTime.now(),
        message: error.toString(),
      );
    }
  }

  Future<void> _refreshProgress(String sessionId) async {
    // 正常查询由数据库变更通知，只重新订阅已失败的流
    final queries = <AutoDisposeStreamProvider<Object>>[
      mangaStreamByIdProvider(mangaId),
      chaptersStreamByMangaProvider(mangaId),
    ];
    for (final provider in queries) {
      if (!ref.exists(provider)) continue;
      final value = ref.read(provider);
      if (value.hasError && !value.isLoading) ref.invalidate(provider);
    }
    final cache = ref.listen(updateProgressCacheProvider(sessionId), (_, _) {});
    final provider = updateProgressProvider(cache.read(), mangaId);
    final subscription = ref.listen(provider, (_, _) {});
    try {
      await AsyncValue.guard(
        () => Future.wait<Object>([
          ref.read(chaptersStreamByMangaProvider(mangaId).future),
          ref.read(updateDownloadedChaptersProvider(mangaId).future),
        ]),
      );
      ref.read(provider);
    } finally {
      subscription.close();
      cache.close();
    }
  }
}
