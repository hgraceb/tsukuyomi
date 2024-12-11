import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

DartClass get _$Source => DartClass<Source>(($) => '''
sealed class Source {
  // ${$.debug('id', ($, $$) => $.id)}
  abstract final int id;

  // ${$.debug('name', ($, $$) => $.name)}
  abstract final String name;

  // ${$.debug('getSourceMangas', ($, $$) => $.getSourceMangas)}
  Future<Iterable<SourceManga>> getSourceMangas(covariant SourceQuery query);

  // ${$.debug('getMangaChapters', ($, $$) => $.getMangaChapters)}
  Future<Iterable<SourceChapter>> getMangaChapters(covariant SourceManga manga);

  // ${$.debug('getChapterImages', ($, $$) => $.getChapterImages)}
  Future<Iterable<SourceImage>> getChapterImages(covariant SourceChapter chapter);

  // ${$.debug('getRepaintBytes', ($, $$) => $.getRepaintBytes)}
  Future<SourceBytes> getRepaintBytes(covariant SourceBytes bytes);
}
''');

DartClass get _$SourceManga => DartClass<SourceManga>(($) => '''
sealed class SourceManga {
  const SourceManga({
    required this.url,
    required this.name,
    required this.cover,
  });

  // ${$.debug('url', ($, $$) => $.url)}
  final String url;

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('cover', ($, $$) => $.cover)}
  final String cover;
}
''');

DartClass get _$SourceBytes => DartClass<SourceBytes>(($) => '''
sealed class SourceBytes {
  external SourceBytes({
    required this.type,
    required this.data,
  });

  // ${$.debug('type', ($, $$) => $.type)}
  final String type;

  // ${$.debug('data', ($, $$) => $.data)}
  final List<int> data;
}
''');

DartClass get _$SourceChapter => DartClass<SourceChapter>(($) => '''
sealed class SourceChapter {
  external const SourceChapter({
    required this.url,
    required this.name,
    this.date,
    this.public,
  });

  // ${$.debug('url', ($, $$) => $.url)}
  final String url;

  // ${$.debug('name', ($, $$) => $.name)}
  final String name;

  // ${$.debug('date', ($, $$) => $.date)}
  final String date;

  // ${$.debug('public', ($, $$) => $.public)}
  final bool public;
}
''');

DartClass get _$SourceImage => DartClass<SourceImage>(($) => '''
sealed class SourceImage {
  const SourceImage({
    this.extra,
    required this.url,
  });

  // ${$.debug('url', ($, $$) => $.url)}
  abstract final String url;
}
''');

DartClass get _$SourcePage => DartClass<SourcePage>(($) => '''
sealed class SourcePage<T> {
  external SourcePage({
    this.next,
    required Iterable<T> data,
  });

  // ${$.debug('next', ($, $$) => $.next)}
  final bool next;

  // ${$.debug('data', ($, $$) => $.data)}
  final List<T> data;
}
''');

DartClass get _$SourceQuery => DartClass<SourceQuery>(($) => '''
sealed class SourceQuery {
  external SourceQuery({
    this.page,
    required this.keyword,
  });

  // ${$.debug('page', ($, $$) => $.page)}
  final int page;

  // ${$.debug('keyword', ($, $$) => $.keyword)}
  final String keyword;
}
''');

List<DartDeclaration> get $core {
  return [
    _$Source,
    _$SourceManga,
    _$SourceBytes,
    _$SourceChapter,
    _$SourceImage,
    _$SourcePage,
    _$SourceQuery,
  ];
}
