import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_state.freezed.dart';

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

  /// 源章节为空
  emptySources,

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
  bool get isFailure =>
      this == UpdateOutcome.sourceUnavailable || this == UpdateOutcome.networkError || this == UpdateOutcome.parseError || this == UpdateOutcome.storageError || this == UpdateOutcome.enqueueFailed;

  bool get isWarning => this == UpdateOutcome.emptySources || this == UpdateOutcome.chaptersReduced;
}

/// 单部漫画的检查结局条目
@freezed
class UpdateReportItem with _$UpdateReportItem {
  const factory UpdateReportItem({
    required int mangaId,
    required String mangaTitle,
    required int sourceId,
    required String sourceName,
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
    DateTime? startedAt,
    DateTime? finishedAt,
    required int totalTargets,
    required List<UpdateReportItem> items,
  }) = _UpdateReport;

  static const int currentVersion = 1;

  int get failureCount => items.where((item) => item.outcome.isFailure).length;

  int get warningCount => items.where((item) => item.outcome.isWarning).length;

  /// 手写序列化：enum 存 name 字符串、DateTime 存 ISO8601；未知枚举名跳过（升级容错）
  factory UpdateReport.fromJson(Map<String, dynamic> json) {
    UpdatePhase phaseOf(String? name) => UpdatePhase.values.where((v) => v.name == name).firstOrNull ?? UpdatePhase.idle;
    UpdateScanKind kindOf(String? name) => UpdateScanKind.values.where((v) => v.name == name).firstOrNull ?? UpdateScanKind.full;
    UpdateOutcome? outcomeOf(String? name) => UpdateOutcome.values.where((v) => v.name == name).firstOrNull;

    return UpdateReport(
      version: (json['version'] as int?) ?? currentVersion,
      phase: phaseOf(json['phase'] as String?),
      scanKind: kindOf(json['scanKind'] as String?),
      sessionId: (json['sessionId'] as String?) ?? '',
      startedAt: DateTime.tryParse((json['startedAt'] as String?) ?? ''),
      finishedAt: DateTime.tryParse((json['finishedAt'] as String?) ?? ''),
      totalTargets: (json['totalTargets'] as int?) ?? 0,
      items: [
        for (final item in (json['items'] as List? ?? []))
          if (item is Map<String, dynamic>)
            if (outcomeOf(item['outcome'] as String?) case final outcome?)
              UpdateReportItem(
                mangaId: (item['mangaId'] as int?) ?? 0,
                mangaTitle: (item['mangaTitle'] as String?) ?? '',
                sourceId: (item['sourceId'] as int?) ?? 0,
                sourceName: (item['sourceName'] as String?) ?? '',
                outcome: outcome,
                insertCount: (item['insertCount'] as int?) ?? 0,
                deleteCount: (item['deleteCount'] as int?) ?? 0,
                updateCount: (item['updateCount'] as int?) ?? 0,
                sourceCount: (item['sourceCount'] as int?) ?? 0,
                enqueuedCount: (item['enqueuedCount'] as int?) ?? 0,
                enqueueFailedCount: (item['enqueueFailedCount'] as int?) ?? 0,
                skippedDownloaded: (item['skippedDownloaded'] as int?) ?? 0,
                skippedQueued: (item['skippedQueued'] as int?) ?? 0,
                failedChapters: ((item['failedChapters'] as List?) ?? []).cast<String>(),
                updatedAt: DateTime.tryParse((item['updatedAt'] as String?) ?? ''),
                message: item['message'] as String?,
              ),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'phase': phase.name,
      'scanKind': scanKind.name,
      'sessionId': sessionId,
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
      'totalTargets': totalTargets,
      'items': [
        for (final item in items)
          {
            'mangaId': item.mangaId,
            'mangaTitle': item.mangaTitle,
            'sourceId': item.sourceId,
            'sourceName': item.sourceName,
            'outcome': item.outcome.name,
            'insertCount': item.insertCount,
            'deleteCount': item.deleteCount,
            'updateCount': item.updateCount,
            'sourceCount': item.sourceCount,
            'enqueuedCount': item.enqueuedCount,
            'enqueueFailedCount': item.enqueueFailedCount,
            'skippedDownloaded': item.skippedDownloaded,
            'skippedQueued': item.skippedQueued,
            'failedChapters': item.failedChapters,
            if (item.updatedAt != null) 'updatedAt': item.updatedAt!.toIso8601String(),
            if (item.message != null) 'message': item.message,
          },
      ],
    };
  }
}
