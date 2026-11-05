import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/providers/error/error_handler_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';

import 'update_state.dart';

part 'update_report_store.g.dart';

@Riverpod(keepAlive: true)
class UpdateReportStore extends _$UpdateReportStore {
  late SharedPreferences _preferences;

  Future<void> _pendingSave = Future.value();

  @override
  UpdateReport? build() {
    _preferences = ref.watch(sharedPreferencesProvider);
    try {
      final json = _preferences.getString(Keys.updateReportLatest);
      if (json == null) return null;
      final report = UpdateReport.fromJson(jsonDecode(json) as Map<String, dynamic>);
      final restored = report.phase == UpdatePhase.running ? report.copyWith(phase: UpdatePhase.interrupted) : report;
      return restored.markUnchecked();
    } catch (error, stackTrace) {
      ref.read(errorHandlerProvider).print(error, stackTrace);
      return null;
    }
  }

  /// 保存最近的更新报告
  Future<void> save(UpdateReport report) {
    final value = report.phase == UpdatePhase.running ? report : report.markUnchecked();
    state = value;
    final save = _pendingSave.then((_) async {
      if (!await _preferences.setString(Keys.updateReportLatest, jsonEncode(value.toJson()))) {
        throw StateError('Failed to save update report');
      }
    });
    _pendingSave = save.then((_) {}, onError: (_, _) {});
    return save;
  }

  /// 在当前轮次的最新报告上应用修改
  Future<void> update(String sessionId, UpdateReport Function(UpdateReport report) update) {
    final report = state;
    if (report == null || report.sessionId != sessionId) return Future.value();
    final updated = update(report);
    return identical(updated, report) ? Future.value() : save(updated);
  }

  /// 替换当前轮次已有的单部结果，保留其余条目及扫描信息
  Future<void> replaceItem(String sessionId, UpdateReportItem item) {
    return update(sessionId, (report) {
      if (!report.items.any((existing) => existing.mangaId == item.mangaId)) return report;
      return report.copyWith(
        items: [
          for (final existing in report.items) existing.mangaId == item.mangaId ? item : existing,
        ],
      );
    });
  }
}
