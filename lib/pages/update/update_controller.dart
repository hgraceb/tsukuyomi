import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

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

/// 更新列表的结果筛选，全部不包含尚未产生结果的目标
enum UpdateFilter { all, failure, warning, success }

extension UpdateFilterX on UpdateFilter {
  bool matches(UpdateReportItem item) => switch (this) {
    UpdateFilter.all => true,
    UpdateFilter.failure => item.outcome.isFailure,
    UpdateFilter.warning => item.outcome.isWarning,
    UpdateFilter.success => item.outcome.isSuccess,
  };
}

/// 更新列表按漫画源、漫画名排序，同名时用 ID 确定顺序
int compareUpdateItems(UpdateReportItem a, UpdateReportItem b) {
  final sourceOrder = a.sourceName.compareTo(b.sourceName);
  if (sourceOrder != 0) return sourceOrder;
  final titleOrder = a.mangaTitle.compareTo(b.mangaTitle);
  if (titleOrder != 0) return titleOrder;
  final sourceIdOrder = a.sourceId.compareTo(b.sourceId);
  return sourceIdOrder != 0 ? sourceIdOrder : a.mangaId.compareTo(b.mangaId);
}
