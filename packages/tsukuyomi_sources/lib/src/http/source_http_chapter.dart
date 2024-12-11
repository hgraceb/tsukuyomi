part of 'package:tsukuyomi_sources/src/core/source_chapter.dart';

/// 网络漫画源章节数据
class HttpSourceChapter extends SourceChapter {
  const HttpSourceChapter({
    required super.url,
    required super.name,
    super.date,
    super.public,
  });
}
