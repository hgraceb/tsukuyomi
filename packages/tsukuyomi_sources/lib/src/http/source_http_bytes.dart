part of 'package:tsukuyomi_sources/src/core/source_bytes.dart';

/// 网络漫画源字节数据
class HttpSourceBytes extends SourceBytes {
  HttpSourceBytes({
    required super.type,
    required super.data,
    required super.statusCode,
    required super.responseHeaders,
    super.extra,
  });

  /// 创建网络字节数据副本
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
