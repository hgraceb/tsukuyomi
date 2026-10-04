import 'dart:async';

import 'package:dio/dio.dart';
import 'package:tsukuyomi/core/exception/tsukuyomi_exception.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

/// 源侧加载与章节获取相关异常分类
UpdateOutcome classifySourceError(Object error) {
  if (error is TsukuyomiSourceException) return UpdateOutcome.sourceUnavailable;
  if (error is DioException || error is TimeoutException) return UpdateOutcome.networkError;
  return UpdateOutcome.parseError;
}
