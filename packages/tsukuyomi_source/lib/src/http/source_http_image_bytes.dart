part of 'package:tsukuyomi_source/src/core/source_image_bytes.dart';

/// 网络漫画源图片数据
class HttpSourceImageBytes extends SourceImageBytes {
  const HttpSourceImageBytes({required this.bytes, super.extra});

  @override
  final HttpSourceBytes bytes;
}
