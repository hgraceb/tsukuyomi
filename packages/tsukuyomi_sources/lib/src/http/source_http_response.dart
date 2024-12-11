import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

/// 网络漫画源请求的响应数据
class HttpSourceResponse {
  HttpSourceResponse({
    this.error,
    this.code,
    this.data,
  }) : assert(error != null || code != null);

  /// 网络请求错误信息
  final HttpSourceException? error;

  /// 网络请求的响应码
  final int? code;

  /// 网络请求响应数据
  final dynamic data;
}
