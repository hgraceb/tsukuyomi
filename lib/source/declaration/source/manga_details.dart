import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

DartClass get _$SourceMangaDetails => DartClass<SourceMangaDetails>(($) => '''
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

  // ${$.debug('status', ($, $$) => $.status)}
  final SourceMangaStatus? status;

  // ${$.debug('description', ($, $$) => $.description)}
  final String? description;

  // ${$.debug('authors', ($, $$) => $.authors)}
  final List<SourceMangaAuthor>? authors;

  // ${$.debug('tags', ($, $$) => $.tags)}
  final List<SourceMangaTag>? tags;

  // ${$.debug('languages', ($, $$) => $.languages)}
  final List<String>? languages;

  // ${$.debug('chapters', ($, $$) => $.chapters)}
  abstract final List<SourceChapter> chapters;
}
''');

DartClass get _$SourceMangaStatus => DartClass<SourceMangaStatus>(($) => '''
// ${$.empty('SourceMangaStatus.values', () => SourceMangaStatus.values)}
enum SourceMangaStatus {
  // ${$.empty('SourceMangaStatus.unknown', () => SourceMangaStatus.unknown)}
  unknown,
  // ${$.empty('SourceMangaStatus.ongoing', () => SourceMangaStatus.ongoing)}
  ongoing,
  // ${$.empty('SourceMangaStatus.completed', () => SourceMangaStatus.completed)}
  completed,
  // ${$.empty('SourceMangaStatus.hiatus', () => SourceMangaStatus.hiatus)}
  hiatus,
  // ${$.empty('SourceMangaStatus.cancelled', () => SourceMangaStatus.cancelled)}
  cancelled;

  // ${$.empty('SourceMangaStatus.fromJson', () => SourceMangaStatus.fromJson)}
  external static SourceMangaStatus fromJson(String value);

  // ${$.debug('toJson', ($, $$) => $.toJson)}
  external String toJson();
}
''');

DartClass get _$SourceMangaTagType => DartClass<SourceMangaTagType>(($) => '''
// ${$.empty('SourceMangaTagType.values', () => SourceMangaTagType.values)}
enum SourceMangaTagType {
  // ${$.empty('SourceMangaTagType.tag', () => SourceMangaTagType.tag)}
  tag,
  // ${$.empty('SourceMangaTagType.character', () => SourceMangaTagType.character)}
  character,
  // ${$.empty('SourceMangaTagType.category', () => SourceMangaTagType.category)}
  category,
  // ${$.empty('SourceMangaTagType.other', () => SourceMangaTagType.other)}
  other;

  // ${$.empty('SourceMangaTagType.fromJson', () => SourceMangaTagType.fromJson)}
  external static SourceMangaTagType fromJson(String value);

  // ${$.debug('toJson', ($, $$) => $.toJson)}
  external String toJson();
}
''');

DartClass get _$SourceMangaAuthor => DartClass<SourceMangaAuthor>(($) => '''
class SourceMangaAuthor {
  // ${$.empty('SourceMangaAuthor.new', () => SourceMangaAuthor.new)}
  const SourceMangaAuthor({required this.name, this.role, this.url});

  // ${$.empty('SourceMangaAuthor.fromJson', () => SourceMangaAuthor.fromJson)}
  external factory SourceMangaAuthor.fromJson(Map<String, dynamic> json);

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('role', ($, $$) => $.role)}
  final String? role;

  // ${$.debug('url', ($, $$) => $.url)}
  final String? url;

  // ${$.debug('toJson', ($, $$) => $.toJson)}
  external Map<String, dynamic> toJson();
}
''');

DartClass get _$SourceMangaTag => DartClass<SourceMangaTag>(($) => '''
class SourceMangaTag {
  // ${$.empty('SourceMangaTag.new', () => SourceMangaTag.new)}
  const SourceMangaTag({required this.type, required this.name, this.id, this.url});

  // ${$.empty('SourceMangaTag.fromJson', () => SourceMangaTag.fromJson)}
  external factory SourceMangaTag.fromJson(Map<String, dynamic> json);

  // ${$.debug('type', ($, $$) => $.type)}
  final SourceMangaTagType type;

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('id', ($, $$) => $.id)}
  final String? id;

  // ${$.debug('url', ($, $$) => $.url)}
  final String? url;

  // ${$.debug('toJson', ($, $$) => $.toJson)}
  external Map<String, dynamic> toJson();
}
''');

List<DartDeclaration> get $mangaDetails {
  return [
    _$SourceMangaDetails,
    _$SourceMangaStatus,
    _$SourceMangaTagType,
    _$SourceMangaAuthor,
    _$SourceMangaTag,
  ];
}
