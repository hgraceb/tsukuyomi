import 'package:dio/dio.dart';

part 'package:tsukuyomi_sources/src/http/source_http_bytes.dart';

/// 漫画源字节数据
sealed class SourceBytes {
  SourceBytes({
    required this.type,
    required this.data,
    required this.statusCode,
    required this.responseHeaders,
  }) : assert(!type.startsWith('.'));

  /// 数据类型
  final String type;

  /// 字节数据
  final List<int> data;

  /// 状态码
  final int statusCode;

  /// 响应头
  final Headers responseHeaders;
}
