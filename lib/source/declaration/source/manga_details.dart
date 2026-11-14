import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

DartClass get _$SourceMangaCreator => DartClass<SourceMangaCreator>(($) => '''
class SourceMangaCreator {
  // ${$.empty('SourceMangaCreator.new', () => SourceMangaCreator.new)}
  const SourceMangaCreator({required this.name});

  // ${$.empty('SourceMangaCreator.fromJson', () => SourceMangaCreator.fromJson)}
  external factory SourceMangaCreator.fromJson(Map<String, dynamic> json);

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('toJson', ($, $$) => $.toJson)}
  external Map<String, dynamic> toJson();
}
''');

DartClass get _$SourceMangaTag => DartClass<SourceMangaTag>(($) => '''
class SourceMangaTag {
  // ${$.empty('SourceMangaTag.new', () => SourceMangaTag.new)}
  const SourceMangaTag({required this.name, required this.type});

  // ${$.empty('SourceMangaTag.fromJson', () => SourceMangaTag.fromJson)}
  external factory SourceMangaTag.fromJson(Map<String, dynamic> json);

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('type', ($, $$) => $.type)}
  final String type;

  // ${$.debug('toJson', ($, $$) => $.toJson)}
  external Map<String, dynamic> toJson();
}
''');

List<DartDeclaration> get $mangaDetails {
  return [
    _$SourceMangaCreator,
    _$SourceMangaTag,
    DartFunction('normalizeMangaStatus', normalizeMangaStatus, 'external String normalizeMangaStatus(String value);'),
    DartFunction(
      'normalizeMangaCreators',
      normalizeMangaCreators,
      'external List<SourceMangaCreator> normalizeMangaCreators(Iterable<SourceMangaCreator> values);',
    ),
    DartFunction(
      'normalizeMangaTags',
      normalizeMangaTags,
      'external List<SourceMangaTag> normalizeMangaTags(Iterable<SourceMangaTag> values);',
    ),
    DartFunction(
      'normalizeMangaLanguages',
      normalizeMangaLanguages,
      'external List<String> normalizeMangaLanguages(Iterable<String> values);',
    ),
  ];
}
