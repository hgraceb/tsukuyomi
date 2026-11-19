import 'source_image.dart';

part 'package:tsukuyomi_source/src/http/source_http_chapter_images.dart';

/// 漫画源章节图片
sealed class SourceChapterImages {
  const SourceChapterImages();

  /// 按阅读顺序排列的图片
  abstract final List<SourceImage> images;
}
