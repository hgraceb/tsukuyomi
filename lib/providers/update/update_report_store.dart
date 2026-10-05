import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';

import 'update_state.dart';

part 'update_report_store.g.dart';

@Riverpod(keepAlive: true)
class UpdateReportStore extends _$UpdateReportStore {
  static const reportKey = 'update.latestReport';

  late SharedPreferences _preferences;

  Future<void> _pendingSave = Future.value();

  @override
  UpdateReport? build() {
    _preferences = ref.watch(sharedPreferencesProvider);
    final json = _preferences.getString(reportKey);
    return json == null ? null : UpdateReport.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// 保存最近的更新报告
  Future<void> save(UpdateReport report) {
    state = report;
    final save = _pendingSave.then((_) async {
      if (!await _preferences.setString(reportKey, jsonEncode(report.toJson()))) {
        throw StateError('Failed to save update report');
      }
    });
    _pendingSave = save.then((_) {}, onError: (_, _) {});
    return save;
  }
}
