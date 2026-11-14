import 'package:meta/meta.dart';

/// 创作者仅记录显示名称，不推断角色或跨站身份
@immutable
class SourceMangaCreator {
  const SourceMangaCreator({required this.name});

  factory SourceMangaCreator.fromJson(Map<String, dynamic> json) => SourceMangaCreator(name: json['name'] as String);

  final String name;

  Map<String, dynamic> toJson() => {'name': name};

  @override
  bool operator ==(Object other) => other is SourceMangaCreator && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// 标签类型由漫画源映射，无法确定分类时使用 tag
@immutable
class SourceMangaTag {
  const SourceMangaTag({required this.name, required this.type});

  factory SourceMangaTag.fromJson(Map<String, dynamic> json) => SourceMangaTag(name: json['name'] as String, type: json['type'] as String);

  final String name;

  final String type;

  Map<String, dynamic> toJson() => {'name': name, 'type': type};

  @override
  bool operator ==(Object other) => other is SourceMangaTag && name == other.name && type == other.type;

  @override
  int get hashCode => Object.hash(name, type);
}

String normalizeMangaStatus(String value) {
  const values = {'ongoing', 'completed', 'hiatus', 'cancelled', 'unknown'};
  final status = value.trim().toLowerCase();
  if (!values.contains(status)) throw FormatException('Invalid manga status', value);
  return status;
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
  const types = {'genre', 'theme', 'format', 'demographic', 'content', 'tag'};
  final tags = <SourceMangaTag>{};
  for (final value in values) {
    final name = value.name.trim();
    final type = value.type.trim().toLowerCase();
    if (name.isEmpty) throw const FormatException('Empty manga tag name');
    if (!types.contains(type)) throw FormatException('Invalid manga tag type', value.type);
    tags.add(SourceMangaTag(name: name, type: type));
  }
  return List.unmodifiable(tags);
}

/// 接受语言、可选文字、地区与变体代码，不处理站点别名、扩展或私用标记
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
