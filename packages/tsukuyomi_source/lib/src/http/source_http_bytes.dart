import 'package:dio/dio.dart';
import 'package:tsukuyomi_source/src/core/source_bytes.dart';

/// 网络漫画源字节数据
class HttpSourceBytes extends SourceBytes {
  HttpSourceBytes({
    required super.type,
    required super.data,
    required this.statusCode,
    required this.responseHeaders,
    super.extra,
  });

  /// 状态码
  final int statusCode;

  /// 原始 HTTP 响应头
  final Headers responseHeaders;

  @override
  HttpSourceBytes copyWith({
    String? type,
    List<int>? data,
    int? statusCode,
    Headers? responseHeaders,
    dynamic extra,
  }) {
    return HttpSourceBytes(
      type: type ?? this.type,
      data: data ?? this.data,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      extra: extra ?? this.extra,
    );
  }
}
