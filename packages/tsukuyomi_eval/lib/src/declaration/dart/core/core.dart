library declaration.dart.core;

import 'package:tsukuyomi_eval/src/declaration/dynamic.dart';
import 'package:tsukuyomi_eval/src/declaration/operator.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/src/property.dart';

part 'annotations.dart';
part 'bool.dart';
part 'date_time.dart';
part 'double.dart';
part 'duration.dart';
part 'exceptions.dart';
part 'int.dart';
part 'iterable.dart';
part 'list.dart';
part 'map.dart';
part 'never.dart';
part 'null.dart';
part 'num.dart';
part 'object.dart';
part 'print.dart';
part 'regexp.dart';
part 'set.dart';
part 'stacktrace.dart';
part 'string.dart';
part 'symbol.dart';
part 'type.dart';
part 'uri.dart';

DartLibrary get dartCoreLibrary {
  return DartLibrary('dart:core', path: 'core/core.dart', source: '''
library dart.core;

import 'dart:_internal' hide Symbol, LinkedList, LinkedListEntry;

export 'dart:async' show Future, Stream;
''', declarations: [
    ...$annotations,
    ...$operator,
    ...$dynamic,
    ...$bool,
    ...$double,
    ...$duration,
    ...$exceptions,
    ...$dateTime,
    ...$int,
    ...$iterable,
    ...$list,
    ...$map,
    ...$never,
    ...$null,
    ...$num,
    ...$object,
    ...$print,
    ...$regexp,
    ...$set,
    ...$stacktrace,
    ...$string,
    ...$symbol,
    ...$type,
    ...$uri,
  ]);
}
