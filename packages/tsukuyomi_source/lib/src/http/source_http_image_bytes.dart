part of 'package:tsukuyomi_source/src/core/source_bytes.dart';

/// 网络漫画源图片数据
class HttpSourceImageBytes extends SourceImageBytes {
  HttpSourceImageBytes({
    required super.type,
    required super.data,
    required this.statusCode,
    required this.responseHeaders,
    super.extra,
  });

  HttpSourceImageBytes.fromBytes(HttpSourceBytes bytes, {Object? extra})
    : this(type: bytes.type, data: bytes.data, statusCode: bytes.statusCode, responseHeaders: bytes.responseHeaders, extra: extra);

  /// 状态码
  final int statusCode;

  /// 原始 HTTP 响应头
  final Headers responseHeaders;

  /// 创建网络图片数据副本
  HttpSourceImageBytes copyWith({
    String? type,
    List<int>? data,
    int? statusCode,
    Headers? responseHeaders,
    Object? extra = _Extra.omitted,
  }) {
    return HttpSourceImageBytes(
      type: type ?? this.type,
      data: data ?? this.data,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      extra: identical(extra, _Extra.omitted) ? this.extra : extra,
    );
  }
}

enum _Extra { omitted }
