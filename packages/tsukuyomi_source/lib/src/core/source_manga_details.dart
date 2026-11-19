import 'package:freezed_annotation/freezed_annotation.dart';

import 'source_chapter.dart';

part 'package:tsukuyomi_source/src/http/source_http_manga.dart';
part 'package:tsukuyomi_source/src/http/source_http_manga_details.dart';
part 'source_manga.dart';
part 'source_manga_details.freezed.dart';
part 'source_manga_details.g.dart';

/// 漫画源漫画详情
sealed class SourceMangaDetails<T extends SourceChapter> extends SourceManga {
  const SourceMangaDetails({
    required super.url,
    required super.name,
    required super.cover,
    required this.chapters,
    this.status,
    this.description,
    this.authors,
    this.tags,
    this.languages,
  });

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
  final List<T> chapters;
}

/// 连载状态
@JsonEnum(alwaysCreate: true)
enum SourceMangaStatus {
  /// 状态未知
  @JsonValue('unknown')
  unknown,

  /// 连载中
  @JsonValue('ongoing')
  ongoing,

  /// 已完结
  @JsonValue('completed')
  completed,

  /// 休刊中
  @JsonValue('hiatus')
  hiatus,

  /// 已中止
  @JsonValue('cancelled')
  cancelled
  ;

  static SourceMangaStatus fromJson(String value) => $enumDecode(_$SourceMangaStatusEnumMap, value);

  String toJson() => _$SourceMangaStatusEnumMap[this]!;
}

/// 标签分类
@JsonEnum(alwaysCreate: true)
enum SourceMangaTagType {
  /// 标签
  @JsonValue('tag')
  tag,

  /// 角色
  @JsonValue('character')
  character,

  /// 分类
  @JsonValue('category')
  category,

  /// 其他
  @JsonValue('other')
  other
  ;

  static SourceMangaTagType fromJson(String value) => $enumDecode(_$SourceMangaTagTypeEnumMap, value);

  String toJson() => _$SourceMangaTagTypeEnumMap[this]!;
}

/// 漫画作者
@freezed
class SourceMangaAuthor with _$SourceMangaAuthor {
  const factory SourceMangaAuthor({
    /// 作者名称
    required String name,

    /// 作者角色
    String? role,

    /// 作者链接
    String? url,
  }) = _SourceMangaAuthor;

  factory SourceMangaAuthor.fromJson(Map<String, dynamic> json) => _$SourceMangaAuthorFromJson(json);
}

/// 漫画标签
@freezed
class SourceMangaTag with _$SourceMangaTag {
  const factory SourceMangaTag({
    /// 标签分类
    required SourceMangaTagType type,

    /// 标签名称
    required String name,

    /// 标签链接
    String? url,
  }) = _SourceMangaTag;

  factory SourceMangaTag.fromJson(Map<String, dynamic> json) => _$SourceMangaTagFromJson(json);
}

/// 校验漫画作者并去重
List<SourceMangaAuthor> normalizeMangaAuthors(Iterable<SourceMangaAuthor> values) {
  final authors = <SourceMangaAuthor>{};
  for (final value in values) {
    final name = value.name.trim();
    if (name.isEmpty) throw const FormatException('Empty manga author name');
    authors.add(value.copyWith(name: name));
  }
  return List.unmodifiable(authors);
}

/// 校验漫画标签并去重
List<SourceMangaTag> normalizeMangaTags(Iterable<SourceMangaTag> values) {
  final tags = <SourceMangaTag>{};
  for (final value in values) {
    final name = value.name.trim();
    if (name.isEmpty) throw const FormatException('Empty manga tag name');
    tags.add(value.copyWith(name: name));
  }
  return List.unmodifiable(tags);
}

/// 校验内容语言并去重排序
List<String> normalizeMangaLanguages(Iterable<String> values) {
  final pattern = RegExp(r'^[a-z]{2,3}(?:-[A-Z][a-z]{3})?(?:-(?:[A-Z]{2}|[0-9]{3}))?(?:-(?:[a-z0-9]{5,8}|[0-9][a-z0-9]{3}))*$');
  final languages = <String>{};
  for (final value in values) {
    if (pattern.stringMatch(value) != value) {
      throw FormatException('Invalid manga content language format; expected zh-Hans or pt-BR', value);
    }
    languages.add(value);
  }
  return List.unmodifiable(languages.toList()..sort());
}
