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
  SourceBytes({
    required this.type,
    required this.data,
    required this.statusCode,
    required this.responseHeaders,
    this.extra,
  });

  // ${$.debug('type', ($, $$) => $.type)}
  final String type;

  // ${$.debug('data', ($, $$) => $.data)}
  final List<int> data;

  // ${$.debug('statusCode', ($, $$) => $.statusCode)}
  final int statusCode;

  // ${$.debug('responseHeaders', ($, $$) => $.responseHeaders)}
  final Headers responseHeaders;

  // ${$.debug('extra', ($, $$) => $.extra)}
  final dynamic extra;
}
''');

DartClass get _$SourceChapter => DartClass<SourceChapter>(($) => '''
sealed class SourceChapter {
  const SourceChapter({
    required this.url,
    required this.name,
    this.date = '',
    this.public = true,
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

DartClass get _$SourceFrame => DartClass<SourceFrame>(($) => '''
sealed class SourceFrame {
  SourceFrame({
    required this.image,
    required this.duration,
  });

  // ${$.debug('image', ($, $$) => $.image)}
  final List<int> image;

  // ${$.debug('duration', ($, $$) => $.duration)}
  final Duration duration;
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
  SourcePage({
    this.next = false,
    required Iterable<T> data,
  }) : data = data.toList(growable: false);

  // ${$.debug('next', ($, $$) => $.next)}
  final bool next;

  // ${$.debug('data', ($, $$) => $.data)}
  final List<T> data;

  // ${$.debug('query', ($, $$) => $.query)}
  late final SourceQuery query;
}
''');

DartClass get _$SourceProtoFields => DartClass<SourceProtoFields>(($) => '''
// ${$.alias('SourceProtoFields')}
typedef SourceProtoFields = Map<String, SourceProtoField>;
''');

DartClass get _$SourceProtoField => DartClass<SourceProtoField>(($) => '''
class SourceProtoField {
  // ${$.empty('SourceProtoField.optionalBool', () => SourceProtoField.optionalBool)}
  SourceProtoField.optionalBool(this.tagNumber) : type = PbFieldType.OB;

  // ${$.empty('SourceProtoField.optionalBytes', () => SourceProtoField.optionalBytes)}
  SourceProtoField.optionalBytes(this.tagNumber) : type = PbFieldType.OY;

  // ${$.empty('SourceProtoField.optionalString', () => SourceProtoField.optionalString)}
  SourceProtoField.optionalString(this.tagNumber) : type = PbFieldType.OS;

  // ${$.empty('SourceProtoField.optionalFloat', () => SourceProtoField.optionalFloat)}
  SourceProtoField.optionalFloat(this.tagNumber) : type = PbFieldType.OF;

  // ${$.empty('SourceProtoField.optionalDouble', () => SourceProtoField.optionalDouble)}
  SourceProtoField.optionalDouble(this.tagNumber) : type = PbFieldType.OD;

  // ${$.empty('SourceProtoField.optionalEnum', () => SourceProtoField.optionalEnum)}
  SourceProtoField.optionalEnum(this.tagNumber) : type = PbFieldType.OE;

  // ${$.empty('SourceProtoField.optionalGroup', () => SourceProtoField.optionalGroup)}
  SourceProtoField.optionalGroup(this.tagNumber) : type = PbFieldType.OG;

  // ${$.empty('SourceProtoField.optionalInt32', () => SourceProtoField.optionalInt32)}
  SourceProtoField.optionalInt32(this.tagNumber) : type = PbFieldType.O3;

  // ${$.empty('SourceProtoField.optionalInt64', () => SourceProtoField.optionalInt64)}
  SourceProtoField.optionalInt64(this.tagNumber) : type = PbFieldType.O6;

  // ${$.empty('SourceProtoField.optionalSInt32', () => SourceProtoField.optionalSInt32)}
  SourceProtoField.optionalSInt32(this.tagNumber) : type = PbFieldType.OS3;

  // ${$.empty('SourceProtoField.optionalSInt64', () => SourceProtoField.optionalSInt64)}
  SourceProtoField.optionalSInt64(this.tagNumber) : type = PbFieldType.OS6;

  // ${$.empty('SourceProtoField.optionalUint32', () => SourceProtoField.optionalUint32)}
  SourceProtoField.optionalUint32(this.tagNumber) : type = PbFieldType.OU3;

  // ${$.empty('SourceProtoField.optionalUint64', () => SourceProtoField.optionalUint64)}
  SourceProtoField.optionalUint64(this.tagNumber) : type = PbFieldType.OU6;

  // ${$.empty('SourceProtoField.optionalFixed32', () => SourceProtoField.optionalFixed32)}
  SourceProtoField.optionalFixed32(this.tagNumber) : type = PbFieldType.OF3;

  // ${$.empty('SourceProtoField.optionalFixed64', () => SourceProtoField.optionalFixed64)}
  SourceProtoField.optionalFixed64(this.tagNumber) : type = PbFieldType.OF6;

  // ${$.empty('SourceProtoField.optionalSFixed32', () => SourceProtoField.optionalSFixed32)}
  SourceProtoField.optionalSFixed32(this.tagNumber) : type = PbFieldType.OSF3;

  // ${$.empty('SourceProtoField.optionalSFixed64', () => SourceProtoField.optionalSFixed64)}
  SourceProtoField.optionalSFixed64(this.tagNumber) : type = PbFieldType.OSF6;

  // ${$.empty('SourceProtoField.optionalMessage', () => SourceProtoField.optionalMessage)}
  SourceProtoField.optionalMessage(this.tagNumber, SourceProtoFields fields) : type = PbFieldType.OM;

  // ${$.empty('SourceProtoField.repeatedBool', () => SourceProtoField.repeatedBool)}
  SourceProtoField.repeatedBool(this.tagNumber) : type = PbFieldType.PB;

  // ${$.empty('SourceProtoField.repeatedBytes', () => SourceProtoField.repeatedBytes)}
  SourceProtoField.repeatedBytes(this.tagNumber) : type = PbFieldType.PY;

  // ${$.empty('SourceProtoField.repeatedString', () => SourceProtoField.repeatedString)}
  SourceProtoField.repeatedString(this.tagNumber) : type = PbFieldType.PS;

  // ${$.empty('SourceProtoField.repeatedFloat', () => SourceProtoField.repeatedFloat)}
  SourceProtoField.repeatedFloat(this.tagNumber) : type = PbFieldType.PF;

  // ${$.empty('SourceProtoField.repeatedDouble', () => SourceProtoField.repeatedDouble)}
  SourceProtoField.repeatedDouble(this.tagNumber) : type = PbFieldType.PD;

  // ${$.empty('SourceProtoField.repeatedEnum', () => SourceProtoField.repeatedEnum)}
  SourceProtoField.repeatedEnum(this.tagNumber) : type = PbFieldType.PE;

  // ${$.empty('SourceProtoField.repeatedGroup', () => SourceProtoField.repeatedGroup)}
  SourceProtoField.repeatedGroup(this.tagNumber) : type = PbFieldType.PG;

  // ${$.empty('SourceProtoField.repeatedInt32', () => SourceProtoField.repeatedInt32)}
  SourceProtoField.repeatedInt32(this.tagNumber) : type = PbFieldType.P3;

  // ${$.empty('SourceProtoField.repeatedInt64', () => SourceProtoField.repeatedInt64)}
  SourceProtoField.repeatedInt64(this.tagNumber) : type = PbFieldType.P6;

  // ${$.empty('SourceProtoField.repeatedSInt32', () => SourceProtoField.repeatedSInt32)}
  SourceProtoField.repeatedSInt32(this.tagNumber) : type = PbFieldType.PS3;

  // ${$.empty('SourceProtoField.repeatedSInt64', () => SourceProtoField.repeatedSInt64)}
  SourceProtoField.repeatedSInt64(this.tagNumber) : type = PbFieldType.PS6;

  // ${$.empty('SourceProtoField.repeatedUint32', () => SourceProtoField.repeatedUint32)}
  SourceProtoField.repeatedUint32(this.tagNumber) : type = PbFieldType.PU3;

  // ${$.empty('SourceProtoField.repeatedUint64', () => SourceProtoField.repeatedUint64)}
  SourceProtoField.repeatedUint64(this.tagNumber) : type = PbFieldType.PU6;

  // ${$.empty('SourceProtoField.repeatedFixed32', () => SourceProtoField.repeatedFixed32)}
  SourceProtoField.repeatedFixed32(this.tagNumber) : type = PbFieldType.PF3;

  // ${$.empty('SourceProtoField.repeatedFixed64', () => SourceProtoField.repeatedFixed64)}
  SourceProtoField.repeatedFixed64(this.tagNumber) : type = PbFieldType.PF6;

  // ${$.empty('SourceProtoField.repeatedSFixed32', () => SourceProtoField.repeatedSFixed32)}
  SourceProtoField.repeatedSFixed32(this.tagNumber) : type = PbFieldType.PSF3;

  // ${$.empty('SourceProtoField.repeatedSFixed64', () => SourceProtoField.repeatedSFixed64)}
  SourceProtoField.repeatedSFixed64(this.tagNumber) : type = PbFieldType.PSF6;

  // ${$.empty('SourceProtoField.repeatedMessage', () => SourceProtoField.repeatedMessage)}
  SourceProtoField.repeatedMessage(this.tagNumber, SourceProtoFields fields) : type = PbFieldType.PM;

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
  SourceProtoMessage.fromBuffer(this.fields, List<int> buffer);

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
  SourceQuery({
    this.page = 1,
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
    _$SourceFrame,
    _$SourceImage,
    _$SourcePage,
    _$SourceProtoFields,
    _$SourceProtoField,
    _$SourceProtoMessage,
    _$SourceQuery,
  ];
}
