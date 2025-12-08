part 'package:tsukuyomi_sources/src/http/source_http_frame.dart';

/// 漫画源动图帧数据
sealed class SourceFrame {
  SourceFrame({
    required this.image,
    required this.duration,
  }) : assert(image.isNotEmpty),
       assert(duration > Duration.zero);

  /// 图片数据
  final List<int> image;

  /// 图片时长
  final Duration duration;
}
