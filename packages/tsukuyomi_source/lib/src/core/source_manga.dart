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
    this.creators,
    this.tags,
    this.languages,
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

  /// 创作者列表
  final List<SourceMangaCreator>? creators;

  /// 标签列表
  final List<SourceMangaTag>? tags;

  /// 内容语言
  final List<String>? languages;
}
