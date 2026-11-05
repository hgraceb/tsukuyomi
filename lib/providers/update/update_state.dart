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

  /// 停止或中断后尚未检查
  unchecked,

  progressError,

  /// 章节数据有变化或已安排下载
  updated,

  /// 无需变更章节或安排下载
  noUpdate,

  /// 源未返回任何章节
  chaptersEmpty,

  /// 漫画源不可用
  sourceUnavailable,

  /// 网络请求失败
  networkError,

  /// 源执行失败
  parseError,

  /// 数据读写失败
  storageError,

  /// 下载入队或启动失败
  enqueueFailed,
}

extension UpdateOutcomeX on UpdateOutcome {
  /// 尚未完成检查
  bool get isPending => this == UpdateOutcome.pending || this == UpdateOutcome.checking;

  /// 已完成章节检查和下载安排
  bool get isSuccess => this == UpdateOutcome.updated || this == UpdateOutcome.noUpdate;

  /// 需要关注的检查状态
  bool get isWarning => switch (this) {
    UpdateOutcome.skipped || UpdateOutcome.unchecked || UpdateOutcome.progressError => true,
    _ => false,
  };

  /// 失败和可重新处理的警告允许手动重试
  bool get canRetry => isFailure || isWarning;

  /// 已取得章节检查结果时才读取本地下载进度
  bool get canReadProgress {
    if (isSuccess) return true;
    return this == UpdateOutcome.enqueueFailed || this == UpdateOutcome.progressError;
  }

  /// 检查或安排下载失败，不包含等待和跳过的条目
  bool get isFailure => switch (this) {
    UpdateOutcome.chaptersEmpty ||
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
    @Default(0) int insertCount,
    @Default(0) int deleteCount,
    @Default(0) int updateCount,
    @Default(0) int sourceCount,
    @Default(0) int enqueuedCount,
    @Default(0) int enqueueFailedCount,
    @Default(0) int skippedDownloaded,
    @Default(0) int skippedQueued,
    @Default(0) int skippedUnavailable,
    @Default([]) List<String> failedChapters,
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

  int get pendingCount => items.where((item) => item.outcome.isPending || item.outcome == UpdateOutcome.unchecked).length;

  int get skippedCount => items.where((item) => item.outcome == UpdateOutcome.skipped).length;

  UpdateReport markUnchecked() {
    if (!items.any((item) => item.outcome.isPending)) return this;
    return copyWith(items: [for (final item in items) item.outcome.isPending ? item.copyWith(outcome: UpdateOutcome.unchecked) : item]);
  }
}
