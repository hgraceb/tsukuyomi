part 'package:tsukuyomi_sources/src/http/source_http_image.dart';
part 'package:tsukuyomi_sources/src/local/source_local_image.dart';

/// 漫画源图片数据
sealed class SourceImage {
  const SourceImage({
    this.extra,
    required this.url,
  });

  /// 图片地址
  final String url;

  /// 额外数据
  final dynamic extra;
}
