import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_state.freezed.dart';

/// 扫描会话状态机
enum UpdatePhase { idle, running, cancelled, finished }

/// 扫描方式：full 全量扫描（更新页刷新）；partial 仅重扫失败项
enum UpdateScanKind { full, partial }

/// 单部检查结局（20261004 口径：基线机制已撤销，无 baseline/rebaseline）
enum UpdateOutcome {
  /// 发现未下载章节并入队（含重排队覆盖的失败/取消行）
  updated,

  /// 无任何变化（新增 0、删除 0、无可入队章节）
  noUpdate,

  /// 源返回 0 章：章节已随同步清空（记录可弃），警告供人工确认
  emptyChapters,

  /// 部分章节从源中消失且无新增，已随同步删除
  chaptersReduced,

  /// 源未安装/被禁用（孤儿漫画）
  sourceUnavailable,

  /// 网络请求失败（超时/连接拒绝/4xx-5xx），可重试
  networkError,

  /// 源码解析失效（站点可能已改版）
  parseError,

  /// 本地写库/存储异常
  storageError,

  /// 发现章节但加入下载失败（failedChapters 承载明细）
  enqueueFailed,
}

extension UpdateOutcomeX on UpdateOutcome {
  bool get isFailure =>
      this == UpdateOutcome.sourceUnavailable ||
      this == UpdateOutcome.networkError ||
      this == UpdateOutcome.parseError ||
      this == UpdateOutcome.storageError ||
      this == UpdateOutcome.enqueueFailed;

  bool get isWarning => this == UpdateOutcome.emptyChapters || this == UpdateOutcome.chaptersReduced;
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
