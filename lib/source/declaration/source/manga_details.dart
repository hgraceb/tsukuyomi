import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

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

DartClass get _$SourceMangaCreator => DartClass<SourceMangaCreator>(($) => '''
class SourceMangaCreator {
  // ${$.empty('SourceMangaCreator.new', () => SourceMangaCreator.new)}
  const SourceMangaCreator({required this.name, this.role, this.url});

  // ${$.empty('SourceMangaCreator.fromJson', () => SourceMangaCreator.fromJson)}
  external factory SourceMangaCreator.fromJson(Map<String, dynamic> json);

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
  const SourceMangaTag({required this.type, required this.name, this.url});

  // ${$.empty('SourceMangaTag.fromJson', () => SourceMangaTag.fromJson)}
  external factory SourceMangaTag.fromJson(Map<String, dynamic> json);

  // ${$.debug('type', ($, $$) => $.type)}
  final SourceMangaTagType type;

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('url', ($, $$) => $.url)}
  final String? url;

  // ${$.debug('toJson', ($, $$) => $.toJson)}
  external Map<String, dynamic> toJson();
}
''');

DartFunction get _$normalizeMangaCreators => DartFunction('normalizeMangaCreators', normalizeMangaCreators, '''
external List<SourceMangaCreator> normalizeMangaCreators(Iterable<SourceMangaCreator> values);
''');

DartFunction get _$normalizeMangaTags => DartFunction('normalizeMangaTags', normalizeMangaTags, '''
external List<SourceMangaTag> normalizeMangaTags(Iterable<SourceMangaTag> values);
''');

DartFunction get _$normalizeMangaLanguages => DartFunction('normalizeMangaLanguages', normalizeMangaLanguages, '''
external List<String> normalizeMangaLanguages(Iterable<String> values);
''');

List<DartDeclaration> get $mangaDetails {
  return [
    _$SourceMangaStatus,
    _$SourceMangaTagType,
    _$SourceMangaCreator,
    _$SourceMangaTag,
    _$normalizeMangaCreators,
    _$normalizeMangaTags,
    _$normalizeMangaLanguages,
  ];
}
