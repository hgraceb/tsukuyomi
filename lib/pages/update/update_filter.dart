import 'package:tsukuyomi/providers/update/update_state.dart';

/// 更新列表的结果筛选，全部不包含尚未产生结果的目标
enum UpdateFilter { all, failure, warning, success }

extension UpdateFilterX on UpdateFilter {
  bool matches(UpdateReportItem item) => switch (this) {
    all => true,
    failure => item.outcome.isFailure,
    warning => item.outcome.isWarning,
    success => item.outcome.isSuccess,
  };
}
