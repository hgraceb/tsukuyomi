part of 'source_bytes.dart';

/// 漫画源图片数据
sealed class SourceImageBytes extends SourceBytes {
  SourceImageBytes({
    required super.type,
    required super.data,
    this.extra,
  });

  /// 图片处理参数
  final Object? extra;
}
