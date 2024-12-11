part 'package:tsukuyomi_sources/src/http/source_http_chapter.dart';

/// 漫画源章节数据
sealed class SourceChapter {
  const SourceChapter({
    required this.url,
    required this.name,
    this.date = '',
    this.public = true,
  });

  /// 章节地址
  final String url;

  /// 章节名称
  final String name;

  /// 章节日期
  final String date;

  /// 是否公开
  final bool public;
}
