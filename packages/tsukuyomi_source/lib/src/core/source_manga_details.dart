import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_manga_details.freezed.dart';
part 'source_manga_details.g.dart';

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

/// 创作者
///
/// 仅记录显示名称，不区分角色或跨站身份
@freezed
class SourceMangaCreator with _$SourceMangaCreator {
  const factory SourceMangaCreator({
    required String name,
  }) = _SourceMangaCreator;

  factory SourceMangaCreator.fromJson(Map<String, dynamic> json) => _$SourceMangaCreatorFromJson(json);
}

/// 漫画标签
///
/// 分类由漫画源映射，无法确定分类时使用 [SourceMangaTagType.other]
@freezed
class SourceMangaTag with _$SourceMangaTag {
  const factory SourceMangaTag({
    required String name,
    required SourceMangaTagType type,
  }) = _SourceMangaTag;

  factory SourceMangaTag.fromJson(Map<String, dynamic> json) => _$SourceMangaTagFromJson(json);
}

List<SourceMangaCreator> normalizeMangaCreators(Iterable<SourceMangaCreator> values) {
  final creators = <SourceMangaCreator>{};
  for (final value in values) {
    final name = value.name.trim();
    if (name.isEmpty) throw const FormatException('Empty manga creator name');
    creators.add(SourceMangaCreator(name: name));
  }
  return List.unmodifiable(creators);
}

List<SourceMangaTag> normalizeMangaTags(Iterable<SourceMangaTag> values) {
  final tags = <SourceMangaTag>{};
  for (final value in values) {
    final name = value.name.trim();
    if (name.isEmpty) throw const FormatException('Empty manga tag name');
    tags.add(SourceMangaTag(name: name, type: value.type));
  }
  return List.unmodifiable(tags);
}

/// 规范内容语言代码
///
/// 接受语言、可选文字、地区与变体，不处理站点别名、扩展或私用标记
/// 校验代码结构，不判断语言是否存在；显示端可对未收录的代码直接回退
List<String> normalizeMangaLanguages(Iterable<String> values) {
  final pattern = RegExp(r'^[a-z]{2,3}(?:-[a-z]{4})?(?:-(?:[a-z]{2}|[0-9]{3}))?(?:-(?:[a-z0-9]{5,8}|[0-9][a-z0-9]{3}))*$');
  final languages = <String>{};
  for (final value in values) {
    final code = value.trim().replaceAll('_', '-').toLowerCase();
    final parts = code.split('-');
    if (!pattern.hasMatch(code) || const {'all', 'und', 'mul', 'zxx'}.contains(parts.first)) {
      throw FormatException('Invalid manga content language', value);
    }
    var index = 1;
    if (index < parts.length && RegExp(r'^[a-z]{4}$').hasMatch(parts[index])) {
      parts[index] = '${parts[index][0].toUpperCase()}${parts[index].substring(1)}';
      index++;
    }
    if (index < parts.length && RegExp(r'^[a-z]{2}$').hasMatch(parts[index])) parts[index] = parts[index].toUpperCase();
    languages.add(parts.join('-'));
  }
  return List.unmodifiable(languages.toList()..sort());
}
