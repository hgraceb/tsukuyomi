import 'source_chapter.dart';
import 'source_manga_details.dart';

part 'package:tsukuyomi_source/src/http/source_http_manga.dart';

/// 漫画源漫画数据
sealed class SourceManga {
  const SourceManga({
    required this.url,
    required this.name,
    required this.cover,
    this.status,
    this.description,
    this.authors,
    this.tags,
    this.languages,
    this.chapters,
  });

  /// 漫画地址
  final String url;

  /// 漫画名称
  final String name;

  /// 漫画封面
  final String cover;

  /// 连载状态
  final SourceMangaStatus? status;

  /// 漫画简介
  final String? description;

  /// 作者列表
  final List<SourceMangaAuthor>? authors;

  /// 标签列表
  final List<SourceMangaTag>? tags;

  /// 内容语言
  final List<String>? languages;

  /// 章节列表
  final List<SourceChapter>? chapters;
}
