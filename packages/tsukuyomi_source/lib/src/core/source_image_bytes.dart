import 'source_bytes.dart';

part 'package:tsukuyomi_source/src/http/source_http_image_bytes.dart';

/// 漫画源图片数据
sealed class SourceImageBytes {
  const SourceImageBytes({this.extra});

  /// 当前图片字节
  abstract final SourceBytes bytes;

  /// 图片处理参数
  final Object? extra;
}
