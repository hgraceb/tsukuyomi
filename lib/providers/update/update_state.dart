import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_state.freezed.dart';
part 'update_state.g.dart';

/// 扫描状态
enum UpdatePhase { idle, running, cancelled, finished, interrupted }

/// 扫描方式
enum UpdateScanKind { full, partial }

/// 单部检查状态与结局
enum UpdateOutcome {
  /// 等待开始检查
  pending,

  /// 正在检查章节
  checking,

  /// 已不符合本轮扫描条件
  skipped,

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
  /// 尚未完成检查
  bool get isPending => this == UpdateOutcome.pending || this == UpdateOutcome.checking;

  /// 有可下载章节或没有章节变化
  bool get isSuccess => this == UpdateOutcome.updated || this == UpdateOutcome.noUpdate;

  /// 章节为空、减少或扫描已跳过
  bool get isWarning => this == UpdateOutcome.chaptersEmpty || this == UpdateOutcome.chaptersReduced || this == UpdateOutcome.skipped;

  /// 失败和跳过的条目允许手动重试
  bool get canRetry => isFailure || this == UpdateOutcome.skipped;

  /// 检查或安排下载失败，不包含等待和跳过的条目
  bool get isFailure => switch (this) {
    UpdateOutcome.sourceUnavailable ||
    UpdateOutcome.networkError ||
    UpdateOutcome.parseError ||
    UpdateOutcome.storageError ||
    UpdateOutcome.enqueueFailed => true,
    _ => false,
  };
}

/// 单部漫画的检查状态与结果条目
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
    required int skippedUnavailable,
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
    String? message,
  }) = _UpdateReport;

  static const int currentVersion = 1;

  factory UpdateReport.fromJson(Map<String, dynamic> json) => _$UpdateReportFromJson(json);

  int get failureCount => items.where((item) => item.outcome.isFailure).length;

  int get warningCount => items.where((item) => item.outcome.isWarning).length;

  int get successCount => items.where((item) => item.outcome.isSuccess).length;

  int get pendingCount => items.where((item) => item.outcome.isPending).length;

  int get skippedCount => items.where((item) => item.outcome == UpdateOutcome.skipped).length;
}
