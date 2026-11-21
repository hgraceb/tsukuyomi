import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kNoDefaultValue;

part 'package:tsukuyomi_source/src/http/source_http_bytes.dart';
part 'package:tsukuyomi_source/src/http/source_http_image_bytes.dart';
part 'source_image_bytes.dart';

/// 漫画源字节数据
sealed class SourceBytes {
  SourceBytes({
    required this.type,
    required this.data,
  }) : assert(!type.startsWith('.'));

  /// 数据格式
  final String type;

  /// 字节数据
  final List<int> data;
}
