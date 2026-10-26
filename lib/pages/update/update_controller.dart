import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';

import 'update_filter.dart';

part 'update_controller.g.dart';

/// 更新页面控制器
@riverpod
class UpdateController extends _$UpdateController {
  @override
  UpdateFilter? build() {
    // 仅在切换扫描轮次时重置选择，报告内容更新时保留
    ref.watch(updateReportStoreProvider.select((report) => report?.sessionId));
    return null;
  }

  /// 选择或取消结果筛选
  void onFilterChanged(UpdateFilter filter) {
    state = state == filter ? null : filter;
  }
}
