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

DartClass get _$SourceProtoFields => DartClass<SourceProtoFields>(($) => '''
// ${$.alias('SourceProtoFields')}
typedef SourceProtoFields = Map<String, SourceProtoField>;
''');

DartClass get _$SourceProtoField => DartClass<SourceProtoField>(($) => '''
class SourceProtoField {
  // ${$.empty('SourceProtoField.optionalBool', () => SourceProtoField.optionalBool)}
  external SourceProtoField.optionalBool(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalBytes', () => SourceProtoField.optionalBytes)}
  external SourceProtoField.optionalBytes(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalString', () => SourceProtoField.optionalString)}
  external SourceProtoField.optionalString(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalFloat', () => SourceProtoField.optionalFloat)}
  external SourceProtoField.optionalFloat(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalDouble', () => SourceProtoField.optionalDouble)}
  external SourceProtoField.optionalDouble(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalEnum', () => SourceProtoField.optionalEnum)}
  external SourceProtoField.optionalEnum(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalGroup', () => SourceProtoField.optionalGroup)}
  external SourceProtoField.optionalGroup(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalInt32', () => SourceProtoField.optionalInt32)}
  external SourceProtoField.optionalInt32(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalInt64', () => SourceProtoField.optionalInt64)}
  external SourceProtoField.optionalInt64(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalSInt32', () => SourceProtoField.optionalSInt32)}
  external SourceProtoField.optionalSInt32(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalSInt64', () => SourceProtoField.optionalSInt64)}
  external SourceProtoField.optionalSInt64(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalUint32', () => SourceProtoField.optionalUint32)}
  external SourceProtoField.optionalUint32(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalUint64', () => SourceProtoField.optionalUint64)}
  external SourceProtoField.optionalUint64(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalFixed32', () => SourceProtoField.optionalFixed32)}
  external SourceProtoField.optionalFixed32(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalFixed64', () => SourceProtoField.optionalFixed64)}
  external SourceProtoField.optionalFixed64(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalSFixed32', () => SourceProtoField.optionalSFixed32)}
  external SourceProtoField.optionalSFixed32(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalSFixed64', () => SourceProtoField.optionalSFixed64)}
  external SourceProtoField.optionalSFixed64(this.tagNumber);

  // ${$.empty('SourceProtoField.optionalMessage', () => SourceProtoField.optionalMessage)}
  external SourceProtoField.optionalMessage(this.tagNumber, SourceProtoFields fields);

  // ${$.empty('SourceProtoField.repeatedBool', () => SourceProtoField.repeatedBool)}
  external SourceProtoField.repeatedBool(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedBytes', () => SourceProtoField.repeatedBytes)}
  external SourceProtoField.repeatedBytes(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedString', () => SourceProtoField.repeatedString)}
  external SourceProtoField.repeatedString(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedFloat', () => SourceProtoField.repeatedFloat)}
  external SourceProtoField.repeatedFloat(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedDouble', () => SourceProtoField.repeatedDouble)}
  external SourceProtoField.repeatedDouble(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedEnum', () => SourceProtoField.repeatedEnum)}
  external SourceProtoField.repeatedEnum(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedGroup', () => SourceProtoField.repeatedGroup)}
  external SourceProtoField.repeatedGroup(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedInt32', () => SourceProtoField.repeatedInt32)}
  external SourceProtoField.repeatedInt32(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedInt64', () => SourceProtoField.repeatedInt64)}
  external SourceProtoField.repeatedInt64(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedSInt32', () => SourceProtoField.repeatedSInt32)}
  external SourceProtoField.repeatedSInt32(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedSInt64', () => SourceProtoField.repeatedSInt64)}
  external SourceProtoField.repeatedSInt64(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedUint32', () => SourceProtoField.repeatedUint32)}
  external SourceProtoField.repeatedUint32(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedUint64', () => SourceProtoField.repeatedUint64)}
  external SourceProtoField.repeatedUint64(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedFixed32', () => SourceProtoField.repeatedFixed32)}
  external SourceProtoField.repeatedFixed32(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedFixed64', () => SourceProtoField.repeatedFixed64)}
  external SourceProtoField.repeatedFixed64(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedSFixed32', () => SourceProtoField.repeatedSFixed32)}
  external SourceProtoField.repeatedSFixed32(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedSFixed64', () => SourceProtoField.repeatedSFixed64)}
  external SourceProtoField.repeatedSFixed64(this.tagNumber);

  // ${$.empty('SourceProtoField.repeatedMessage', () => SourceProtoField.repeatedMessage)}
  external SourceProtoField.repeatedMessage(this.tagNumber, SourceProtoFields fields);

  // ${$.debug('tagNumber', ($, $$) => $.tagNumber)}
  final int tagNumber;

  // ${$.debug('type', ($, $$) => $.type)}
  final int type;
}
''');

DartClass get _$SourceProtoMessage => DartClass<SourceProtoMessage>(($) => '''
class SourceProtoMessage extends GeneratedMessage {
  // ${$.empty('SourceProtoMessage.new', () => SourceProtoMessage.new)}
  SourceProtoMessage(this.fields);

  // ${$.empty('SourceProtoMessage.fromBuffer', () => SourceProtoMessage.fromBuffer)}
  external SourceProtoMessage.fromBuffer(this.fields, List<int> buffer);

  // ${$.debug('fields', ($, $$) => $.fields)}
  final SourceProtoFields fields;

  // ${$.debug('get', ($, $$) => $.get)}
  external dynamic get(String fieldName);

  // ${$.debug('getOrNull', ($, $$) => $.getOrNull)}
  external dynamic getOrNull(String fieldName);
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
    _$SourceProtoFields,
    _$SourceProtoField,
    _$SourceProtoMessage,
    _$SourceQuery,
  ];
}
