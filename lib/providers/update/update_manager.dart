import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';

import 'update_error.dart';
import 'update_report_store.dart';
import 'update_service.dart';
import 'update_state.dart';

part 'update_manager.g.dart';

@Riverpod(keepAlive: true)
class UpdateManager extends _$UpdateManager {
  bool _stopped = false;
  late UpdateReport _report;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// 扫描开启自动下载的收藏漫画
  Future<void> scan() async {
    if (state.isLoading) return;
    _stopped = false;
    state = const AsyncLoading();
    final startedAt = DateTime.now();
    _report = UpdateReport(
      version: UpdateReport.currentVersion,
      phase: UpdatePhase.running,
      scanKind: UpdateScanKind.full,
      sessionId: startedAt.microsecondsSinceEpoch.toString(),
      totalTargets: 0,
      items: [],
      startedAt: startedAt,
    );
    final result = await AsyncValue.guard(_scan);
    _report = _report.copyWith(
      phase: !result.hasError && _stopped ? UpdatePhase.cancelled : UpdatePhase.finished,
      finishedAt: DateTime.now(),
      message: result.error?.toString(),
    );
    final saved = await AsyncValue.guard(_save);
    state = saved.hasError ? saved : result;
  }

  /// 当前漫画完成后停止扫描
  void stop() {
    if (state.isLoading) _stopped = true;
  }

  Future<void> _scan() async {
    await _save();
    final mangas = await ref.read(libraryRepositoryProvider).queryAutoMangas();
    mangas.sort((a, b) => a.id.compareTo(b.id));
    _report = _report.copyWith(totalTargets: mangas.length);
    await _save();
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
    final result = await AsyncValue.guard(() => ref.read(sourceByIdProvider(mangas.first.source).future));
    if (_stopped) return;
    if (result.hasError) {
      final error = result.error!;
      _report = _report.copyWith(items: [..._report.items, ...mangas.map((manga) => _sourceFailure(manga, error))]);
      await _save();
      return;
    }
    final source = result.requireValue;
    final service = ref.read(updateServiceProvider);
    for (final manga in mangas) {
      if (_stopped) break;
      final item = await service.updateManga(source, manga);
      _report = _report.copyWith(items: [..._report.items, item]);
      await _save();
    }
  }

  Future<void> _save() => ref.read(updateReportStoreProvider.notifier).save(_report);

  UpdateReportItem _sourceFailure(DatabaseManga manga, Object error) {
    return UpdateReportItem(
      sourceId: manga.source,
      sourceName: manga.source.toString(),
      mangaId: manga.id,
      mangaTitle: manga.title,
      outcome: classifySourceError(error),
      insertCount: 0,
      deleteCount: 0,
      updateCount: 0,
      sourceCount: 0,
      enqueuedCount: 0,
      enqueueFailedCount: 0,
      skippedDownloaded: 0,
      skippedQueued: 0,
      skippedUnavailable: 0,
      failedChapters: [],
      updatedAt: DateTime.now(),
      message: error.toString(),
    );
  }
}
