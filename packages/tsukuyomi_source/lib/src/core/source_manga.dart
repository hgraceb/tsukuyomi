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

  /// 连载状态，null 表示源未提供，unknown 表示明确未知
  final String? status;

  /// 保留段落换行的纯文本简介，空字符串表示清空
  final String? description;

  /// 创作者，null 表示源未提供，空列表表示清空
  final List<SourceMangaCreator>? creators;

  /// 标签，null 表示源未提供，空列表表示清空
  final List<SourceMangaTag>? tags;

  /// 当前源中该漫画已知的内容语言，null 表示未提供，空列表表示未知
  final List<String>? languages;
}
