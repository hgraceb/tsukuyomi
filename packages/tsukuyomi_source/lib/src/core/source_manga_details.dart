import 'package:freezed_annotation/freezed_annotation.dart';

import 'source_chapter.dart';

part 'package:tsukuyomi_source/src/http/source_http_manga.dart';
part 'package:tsukuyomi_source/src/http/source_http_manga_details.dart';
part 'source_manga.dart';
part 'source_manga_details.freezed.dart';
part 'source_manga_details.g.dart';

/// 漫画源漫画详情
sealed class SourceMangaDetails extends SourceManga {
  const SourceMangaDetails({
    required super.url,
    required super.name,
    required super.cover,
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
  abstract final List<SourceChapter> chapters;
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
