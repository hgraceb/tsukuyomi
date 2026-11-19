part of 'package:tsukuyomi_source/src/core/source_chapter_images.dart';

/// 网络漫画源章节图片
class HttpSourceChapterImages extends SourceChapterImages {
  const HttpSourceChapterImages({required this.images});

  @override
  final List<HttpSourceImage> images;
}
