import 'package:tsukuyomi/providers/update/update_state.dart';

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
