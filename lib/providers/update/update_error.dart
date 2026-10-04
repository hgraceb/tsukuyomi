import 'dart:async';

import 'package:dio/dio.dart';
import 'package:tsukuyomi/core/exception/tsukuyomi_exception.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

/// 源侧异常分类（仅 L1/L2：源加载与章节获取）。
/// 宿主/存储异常（写库失败、磁盘等）不经过本函数，
/// 在调用点直接定为 [UpdateOutcome.storageError]。
UpdateOutcome classifySourceError(Object error) {
  if (error is TsukuyomiSourceException) return UpdateOutcome.sourceUnavailable;
  if (error is DioException || error is TimeoutException) return UpdateOutcome.networkError;
  return UpdateOutcome.parseError;
}
