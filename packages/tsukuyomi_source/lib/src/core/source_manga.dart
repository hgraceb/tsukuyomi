import 'source_manga_details.dart';

part 'package:tsukuyomi_source/src/http/source_http_manga.dart';

/// 漫画源漫画数据
///
/// 可选详情字段为 `null` 时表示源未提供，更新时保留已有值
/// 空字符串、空列表和 [SourceMangaStatus.unknown] 都是明确提供的值，更新时替换已有值
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
  ///
  /// 状态由源映射为 [SourceMangaStatus]，无法确定时使用 [SourceMangaStatus.unknown]
  final SourceMangaStatus? status;

  /// 漫画简介
  ///
  /// 使用纯文本，保留段落换行
  final String? description;

  /// 创作者列表
  ///
  /// 只记录显示名称，不区分作者、画师等角色
  final List<SourceMangaCreator>? creators;

  /// 标签列表
  ///
  /// 名称保留源站原文，类型由源映射为统一分类
  final List<SourceMangaTag>? tags;

  /// 内容语言
  ///
  /// 当前漫画在该源中已知的正文语言代码，例如 `ja`、`zh-Hans`
  /// 已知的多语言版本分别列出，未确定语言时可使用空列表
  /// 保留标准特殊代码，例如 `zxx` 表示无语言内容
  /// 站点原始标记由源映射，代码格式由 [normalizeMangaLanguages] 统一规范
  final List<String>? languages;
}
