import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi/providers/update/update_error.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'update_manager_provider.g.dart';

class _CancelledException implements Exception {}

/// 全局扫描引擎：全量同步（增/改/删落库）+ 下载该漫画全部未下载章节（20261004 口径）。
/// 编排机制（60s 预算/僵尸守卫/会话代际/组尾统一入队）仅属于扫描器；
/// 手动刷新路径只共享语义（sync + 下载全部未下载），不共享编排。
@Riverpod(keepAlive: true)
class UpdateManager extends _$UpdateManager {
  /// per-manga 在飞登记：直到底层真实 future 落定才清除（僵尸守卫）
  final Map<int, Future<void>> _inFlight = {};

  /// 当前会话 id：迟到收尾与其不一致即丢弃（会话代际校验）
  String? _sessionId;

  static const _currentKey = 'update.currentReport';
  static const _lastKey = 'update.lastReport';
  static const _lastScanAtKey = 'update.lastScanAt';

  @override
  UpdateReport? build() {
    // 启动时读到 phase == running 的持久化报告 → 判定上次中断，phase 回写 idle
    final report = _restore();
    if (report?.phase == UpdatePhase.running) {
      final restored = report!.copyWith(phase: UpdatePhase.idle);
      _write(restored);
      return restored;
    }
    return report;
  }

  UpdateReport? _restore() {
    final json = ref.read(sharedPreferencesProvider).getString(_currentKey);
    if (json == null) return null;
    try {
      return UpdateReport.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  void _write(UpdateReport report) {
    final preferences = ref.read(sharedPreferencesProvider);
    preferences.setString(_currentKey, jsonEncode(report.toJson()));
    // full 结束/取消时轮换 lastReport 并记录扫描时间
    if (report.scanKind == UpdateScanKind.full && (report.phase == UpdatePhase.finished || report.phase == UpdatePhase.cancelled)) {
      preferences.setString(_lastKey, jsonEncode(report.toJson()));
      preferences.setInt(_lastScanAtKey, (report.finishedAt ?? DateTime.now()).millisecondsSinceEpoch);
    }
  }

  bool get _running {
    final report = state;
    return report != null && report.phase == UpdatePhase.running && report.sessionId == _sessionId;
  }

  /// 发起扫描；返回 false = 已有扫描在跑。
  /// [mangaIds] 为空 → full 全量扫描；非空 → partial 仅重扫失败项。
  Future<bool> start({List<int>? mangaIds}) async {
    if (_running) return false;

    final mangas = await ref.read(libraryRepositoryProvider).queryAutoMangas(mangaIds: mangaIds);
    _sessionId = 'scan-${DateTime.now().microsecondsSinceEpoch}';
    var report = UpdateReport(
      version: UpdateReport.currentVersion,
      phase: UpdatePhase.running,
      scanKind: mangaIds == null ? UpdateScanKind.full : UpdateScanKind.partial,
      sessionId: _sessionId!,
      startedAt: DateTime.now(),
      totalTargets: mangas.length,
      items: const [],
    );
    state = report;
    _write(report);

    // 按源分组：组内严格串行、跨源并发 2
    final groups = <int, List<DatabaseManga>>{};
    for (final manga in mangas) {
      (groups[manga.source] ??= []).add(manga);
    }

    try {
      await Future.wait([for (final group in groups.values) _scanGroup(group)]);
      report = state!.copyWith(phase: UpdatePhase.finished, finishedAt: DateTime.now());
    } on _CancelledException {
      report = state!.copyWith(phase: UpdatePhase.cancelled, finishedAt: DateTime.now());
    }
    state = report;
    _write(report);
    return true;
  }

  /// 取消：跳过尚未开始的目标，已完成条目保留
  Future<void> stop() async {
    final current = state;
    if (current == null || current.phase != UpdatePhase.running) return;
    state = current.copyWith(phase: UpdatePhase.cancelled);
  }

  /// E7 直补：对报告条目中入队失败的章节重新入队（定向快速路径，免重新拉源；
  /// 20261004 口径下重扫按目标重算亦可恢复失败行，直补优势为免拉源、即时）
  Future<void> retryEnqueue(int mangaId) async {
    final report = state;
    if (report == null) return;
    final index = report.items.indexWhere((item) => item.mangaId == mangaId);
    if (index == -1) return;
    final item = report.items[index];
    if (item.failedChapters.isEmpty) return;

    final chapters = await ref.read(chapterRepositoryProvider).queryChaptersByMangaId(mangaId);
    final failedUrls = item.failedChapters.toSet();
    final targets = chapters.where((chapter) => failedUrls.contains(chapter.url)).toList();

    var enqueued = 0;
    final stillFailed = <String>[];
    for (final chapter in targets.reversed) {
      try {
        await ref.read(downloadServiceProvider).insertDownload(item.sourceId, chapter);
        enqueued++;
      } catch (_) {
        stillFailed.add(chapter.url);
      }
    }
    final unresolved = item.failedChapters.where((url) => !targets.any((chapter) => chapter.url == url));
    final updated = report.copyWith(
      items: [
        ...report.items.sublist(0, index),
        item.copyWith(
          enqueuedCount: item.enqueuedCount + enqueued,
          failedChapters: [...unresolved, ...stillFailed],
          updatedAt: DateTime.now(),
        ),
        ...report.items.sublist(index + 1),
      ],
    );
    state = updated;
    _write(updated);
  }

  /// 单个源组：组内严格串行逐部检查；组尾统一「下载全部未下载章节」并无条件触发队列调度
  Future<void> _scanGroup(List<DatabaseManga> group) async {
    Source? source;
    for (final manga in group) {
      if (!_running) throw _CancelledException();
      if (_inFlight.containsKey(manga.id)) continue; // 僵尸守卫：真实 future 未落定前跳过
      try {
        final groupSource = source ?? NoInstalledSource(manga.source);
        source = groupSource;
        await _checkManga(groupSource, manga);
        await _checkManga(source, manga);
      } on _CancelledException {
        rethrow;
      } catch (error) {
        _appendItem(
          _failureItem(
            sourceId: manga.source,
            sourceName: manga.source.toString(),
            manga: manga,
            outcome: classifySourceError(error),
            error: error,
          ),
        );
      }
    }
    // ── 组尾：等真实 future 落定后重算「全部未下载」并入队；结束后无条件 next() 触发半途行续传 ──
    for (final manga in group) {
      final future = _inFlight[manga.id];
      if (future != null) {
        try {
          await future;
        } catch (_) {}
      }
      try {
        final groupSource = source ?? NoInstalledSource(manga.source);
        source = groupSource;
        final (enqueued, failedUrls) = await ref.read(downloadServiceProvider).enqueueUndownloaded(groupSource, manga);
        // outcome 合成（20261004）：实际入队数 > 0 → 最终结局 updated（覆盖 diff 结局）
        if (enqueued > 0 && _running) {
          final report = state!;
          final index = report.items.indexWhere((item) => item.mangaId == manga.id);
          if (index != -1) {
            final item = report.items[index];
            _updateItem(
              item.copyWith(
                outcome: UpdateOutcome.updated,
                enqueuedCount: item.enqueuedCount + enqueued,
                failedChapters: [...item.failedChapters, ...failedUrls],
                updatedAt: DateTime.now(),
              ),
            );
          }
        }
      } on Object catch (error) {
        // 入队段异常（写库等）：按 storageError 落条目（§4.3 禁止空 catch）
        _appendItem(
          _failureItem(
            sourceId: manga.source,
            sourceName: manga.source.toString(),
            manga: manga,
            outcome: UpdateOutcome.storageError,
            error: error,
          ),
        );
      }
    }
    await ref.read(downloadManagerProvider).next();
  }

  /// 单部检查：全量同步（增/改/删落库）→ 计数判定结局；60s 仅放弃等待，真实 future 交守卫
  Future<void> _checkManga(Source source, DatabaseManga manga) async {
    final real = ref.read(chapterSyncWithSourceProvider(source, manga)).sync();
    _inFlight[manga.id] = real.whenComplete(() => _inFlight.remove(manga.id));
    try {
      UpdateReportItem item;
      try {
        final result = await real.timeout(const Duration(seconds: 60));
        item = _judge(source, manga, result);
      } on TimeoutException catch (error) {
        item = _failureItem(
          sourceId: source.id,
          sourceName: source.name,
          manga: manga,
          outcome: UpdateOutcome.networkError,
          error: error,
          message: '同步超时（60s）',
        );
      } on Object catch (error) {
        item = _failureItem(sourceId: source.id, sourceName: source.name, manga: manga, outcome: classifySourceError(error), error: error);
      }
      _appendItem(item.copyWith(updatedAt: DateTime.now()));
    } on Object catch (error) {
      // 会话代际校验丢弃迟到收尾等场景：无用户可见后果
      assert(() {
        print('UpdateManager 收尾丢弃: $error');
        return true;
      }());
    }
  }

  /// 计数 → 结局判定（20261004 口径：无 baseline/rebaseline；下载段与判定解耦，
  /// 下载后按「实际入队数 > 0 → updated」合成最终结局，见 DownloadService.enqueueUndownloaded 调用方）
  UpdateReportItem _judge(Source source, DatabaseManga manga, ChapterSyncResult result) {
    UpdateOutcome outcome;
    if (result.insertCount == 0 && result.deleteCount == 0) {
      outcome = UpdateOutcome.noUpdate;
    } else if (result.sourceCount == 0) {
      outcome = UpdateOutcome.emptyChapters;
    } else if (result.deleteCount > 0 && result.insertCount == 0) {
      outcome = UpdateOutcome.chaptersReduced;
    } else {
      outcome = UpdateOutcome.updated;
    }
    return UpdateReportItem(
      mangaId: manga.id,
      mangaTitle: manga.title,
      sourceId: source.id,
      sourceName: source.name,
      outcome: outcome,
      insertCount: result.insertCount,
      deleteCount: result.deleteCount,
      updateCount: result.updateCount,
      sourceCount: result.sourceCount,
      enqueuedCount: 0,
      enqueueFailedCount: 0,
      skippedDownloaded: 0,
      skippedQueued: 0,
      failedChapters: const [],
    );
  }

  UpdateReportItem _failureItem({
    required int sourceId,
    required String sourceName,
    required DatabaseManga manga,
    required UpdateOutcome outcome,
    Object? error,
    String? message,
  }) {
    return UpdateReportItem(
      mangaId: manga.id,
      mangaTitle: manga.title,
      sourceId: sourceId,
      sourceName: sourceName,
      outcome: outcome,
      insertCount: 0,
      deleteCount: 0,
      updateCount: 0,
      sourceCount: 0,
      enqueuedCount: 0,
      enqueueFailedCount: 0,
      skippedDownloaded: 0,
      skippedQueued: 0,
      failedChapters: const [],
      message: message ?? error.toString(),
    );
  }

  bool get _alive {
    final report = state;
    return report != null && report.sessionId == _sessionId && report.phase == UpdatePhase.running;
  }

  /// 会话代际校验 + 按 mangaId 原位更新条目 + 落盘：迟到收尾（会话已切换/已结束）直接丢弃
  void _updateItem(UpdateReportItem item) {
    if (!_alive) return;
    final report = state!;
    final index = report.items.indexWhere((it) => it.mangaId == item.mangaId);
    final updated = index == -1
        ? report.copyWith(items: [...report.items, item])
        : report.copyWith(items: [...report.items.sublist(0, index), item, ...report.items.sublist(index + 1)]);
    state = updated;
    _write(updated);
  }

  /// 会话代际校验 + 追加条目 + 落盘：迟到收尾（会话已切换/已结束）直接丢弃
  void _appendItem(UpdateReportItem item) {
    if (!_alive) return;
    final report = state!;
    final updated = report.copyWith(items: [...report.items, item]);
    state = updated;
    _write(updated);
  }
}
