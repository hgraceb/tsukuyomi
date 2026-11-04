import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/source/source_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';

import 'update_error.dart';
import 'update_report_store.dart';
import 'update_service.dart';
import 'update_state.dart';

part 'update_manager.g.dart';

@Riverpod(keepAlive: true)
class UpdateManager extends _$UpdateManager {
  bool _stopped = false;
  late String _sessionId;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 扫描开启自动下载的收藏漫画
  Future<void> scan() async {
    if (state.isLoading) return;
    _stopped = false;
    state = const AsyncLoading();
    final startedAt = DateTime.now();
    final report = UpdateReport(
      version: UpdateReport.currentVersion,
      phase: UpdatePhase.running,
      scanKind: UpdateScanKind.full,
      sessionId: startedAt.microsecondsSinceEpoch.toString(),
      totalTargets: 0,
      items: [],
      startedAt: startedAt,
    );
    _sessionId = report.sessionId;
    final result = await AsyncValue.guard(() => _scan(report));
    final saved = await AsyncValue.guard(
      () => _update(
        (report) => report.copyWith(
          phase: !result.hasError && _stopped ? UpdatePhase.cancelled : UpdatePhase.finished,
          finishedAt: DateTime.now(),
          message: result.error?.toString(),
        ),
      ),
    );
    state = saved.hasError ? saved : result;
  }

  /// 当前漫画完成后停止扫描
  void stop() {
    if (state.isLoading) _stopped = true;
  }

  Future<void> _scan(UpdateReport report) async {
    await ref.read(updateReportStoreProvider.notifier).save(report);
    final mangas = await ref.read(libraryRepositoryProvider).queryAutoMangas();
    if (mangas.isEmpty) return;
    mangas.sort((a, b) => a.id.compareTo(b.id));
    final sourceNames = await ref.read(sourceRepositoryProvider).querySourceNames(mangas.map((manga) => manga.source).toSet());
    await _update(
      (report) => report.copyWith(
        totalTargets: mangas.length,
        items: [for (final manga in mangas) _pendingItem(manga, sourceNames[manga.source])],
      ),
    );
    final groups = groupBy(mangas, (manga) => manga.source).values.iterator;
    await Future.wait([_scanGroups(groups), _scanGroups(groups)]);
  }

  Future<void> _scanGroups(Iterator<List<DatabaseManga>> groups) async {
    try {
      while (!_stopped && groups.moveNext()) {
        await _scanSource(groups.current);
      }
    } catch (_) {
      _stopped = true;
      rethrow;
    }
  }

  Future<void> _scanSource(List<DatabaseManga> mangas) async {
    final source = await AsyncValue.guard(() => ref.read(sourceByIdProvider(mangas.first.source).future));
    final service = ref.read(updateServiceProvider);
    for (final manga in mangas) {
      if (_stopped) break;
      // 详情刷新可能已经完成此项，使用当前报告避免重复检查
      final target = _pendingTarget(manga.id);
      if (target == null) continue;
      await _replaceItem(target.copyWith(outcome: UpdateOutcome.checking));
      if (_stopped) break;
      final lookup = await AsyncValue.guard(() => ref.read(mangaRepositoryProvider).queryMangaByIdOrNull(manga.id));
      if (_stopped) break;
      if (_pendingTarget(manga.id) == null) continue;

      final latest = lookup.valueOrNull;
      final UpdateReportItem item;
      if (lookup.hasError) {
        item = target.copyWith(outcome: UpdateOutcome.storageError, message: lookup.error.toString(), updatedAt: DateTime.now());
      } else if (latest == null || !latest.favorite || !latest.auto) {
        item = target.copyWith(outcome: UpdateOutcome.skipped, updatedAt: DateTime.now());
      } else if (source.hasError) {
        final error = source.error!;
        item = target.copyWith(outcome: classifySourceError(error), message: error.toString(), updatedAt: DateTime.now());
      } else {
        item = await service.updateManga(source.requireValue, latest);
      }
      await _replaceItem(item.copyWith(sourceName: target.sourceName, mangaTitle: target.mangaTitle));
    }
  }

  Future<void> _replaceItem(UpdateReportItem item) {
    return ref.read(updateReportStoreProvider.notifier).replaceItem(_sessionId, item);
  }

  UpdateReportItem? _pendingTarget(int mangaId) {
    final report = ref.read(updateReportStoreProvider);
    if (report?.sessionId != _sessionId) return null;
    return report?.items.firstWhereOrNull((item) => item.mangaId == mangaId && item.outcome.isPending);
  }

  Future<void> _update(UpdateReport Function(UpdateReport report) update) {
    return ref.read(updateReportStoreProvider.notifier).update(_sessionId, update);
  }

  UpdateReportItem _pendingItem(DatabaseManga manga, String? sourceName) {
    return UpdateReportItem(
      sourceId: manga.source,
      sourceName: sourceName ?? manga.source.toString(),
      mangaId: manga.id,
      mangaTitle: manga.title,
      outcome: UpdateOutcome.pending,
    );
  }
}
