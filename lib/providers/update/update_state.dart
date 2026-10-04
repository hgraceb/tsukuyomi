import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_state.freezed.dart';
part 'update_state.g.dart';

/// 扫描状态
enum UpdatePhase { idle, running, cancelled, finished }

/// 扫描方式
enum UpdateScanKind { full, partial }

/// 单部检查结局
enum UpdateOutcome {
  /// 有可下载章节
  updated,

  /// 没有章节变化
  noUpdate,

  /// 返回章节为空
  chaptersEmpty,

  /// 减少且无新增
  chaptersReduced,

  /// 漫画源不可用
  sourceUnavailable,

  /// 网络请求失败
  networkError,

  /// 源码解析失效
  parseError,

  /// 信息存储异常
  storageError,

  /// 加入下载失败
  enqueueFailed,
}

extension UpdateOutcomeX on UpdateOutcome {
  /// 有可下载章节或没有章节变化
  bool get isSuccess => this == UpdateOutcome.updated || this == UpdateOutcome.noUpdate;

  /// 章节为空或减少
  bool get isWarning => this == UpdateOutcome.chaptersEmpty || this == UpdateOutcome.chaptersReduced;

  /// 不成功且不是警告
  bool get isFailure => !isSuccess && !isWarning;
}

/// 单部漫画的检查结局条目
@freezed
class UpdateReportItem with _$UpdateReportItem {
  const factory UpdateReportItem({
    required int sourceId,
    required String sourceName,
    required int mangaId,
    required String mangaTitle,
    required UpdateOutcome outcome,
    required int insertCount,
    required int deleteCount,
    required int updateCount,
    required int sourceCount,
    required int enqueuedCount,
    required int enqueueFailedCount,
    required int skippedDownloaded,
    required int skippedQueued,
    required List<String> failedChapters,
    DateTime? updatedAt,
    String? message,
  }) = _UpdateReportItem;

  factory UpdateReportItem.fromJson(Map<String, dynamic> json) => _$UpdateReportItemFromJson(json);
}

/// 一次扫描会话的持久化报告
@freezed
class UpdateReport with _$UpdateReport {
  const UpdateReport._();

  const factory UpdateReport({
    required int version,
    required UpdatePhase phase,
    required UpdateScanKind scanKind,
    required String sessionId,
    required int totalTargets,
    required List<UpdateReportItem> items,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) = _UpdateReport;

  factory UpdateReport.fromJson(Map<String, dynamic> json) => _$UpdateReportFromJson(json);

  static const int currentVersion = 1;

  int get failureCount => items.where((item) => item.outcome.isFailure).length;

  int get warningCount => items.where((item) => item.outcome.isWarning).length;
}
