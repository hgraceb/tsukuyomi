part of 'package:tsukuyomi_sources/src/core/source_image.dart';

/// 网络漫画源图片数据
class HttpSourceImage extends SourceImage {
  const HttpSourceImage({
    super.extra,
    required super.url,
  });
}
