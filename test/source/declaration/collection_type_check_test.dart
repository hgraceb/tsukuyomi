import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/source/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/declaration/declaration.dart';
import 'package:tsukuyomi_eval/src/resolver.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

void main() {
  test('JSON objects support the typed Map used by source metadata', () async {
    const source = '''
import 'dart:convert';
dynamic main() {
  final json = jsonDecode('{"body":{"works":{"chapter":{"title":"chapter"}}}}');
  final works = json['body']['works'] as Map<String, dynamic>;
  return [works == json['body']['works'], works['chapter']['title']];
}
''';
    expect(await evalChecked(source), [true, 'chapter']);
  });

  test('decoded ZIP image content remains a native integer list', () async {
    final bytes = Uint8List.fromList([0, 1]);
    final archive = Archive()..addFile(ArchiveFile('frame', bytes.length, bytes));
    final file = ZipDecoder().decodeBytes(ZipEncoder().encode(archive)!).findFile('frame')!;
    const source = '''
import 'package:values/values.dart';
dynamic main() {
  final original = file.content;
  final image = original as List<int>;
  return [image == original, image];
}
''';
    final result = await evalChecked(source, declarations: [DartVariable('file', file, 'external dynamic get file;')]) as List;
    expect(result.first, isTrue);
    expect(result.last, isA<List<int>>());
    expect(result.last, [0, 1]);
  });

  test('protobuf lists retain dynamic arguments rather than acquiring their element type', () async {
    final message = SourceProtoMessage({'items': SourceProtoField.repeatedMessage(1, {})});
    final items = message.get('items') as List;
    items.add(SourceProtoMessage({}));
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';
import 'package:values/values.dart';
dynamic main() {
  final original = message.get('items');
  final items = original as List<dynamic>;
  return [items == original, items is List<SourceProtoMessage>, items];
}
''';
    final declarations = [DartVariable('message', message, 'external dynamic get message;')];
    final result = await evalChecked(source, declarations: declarations) as List;
    expect(result.first, isTrue);
    expect(result[1], isFalse);
    expect(result.last, same(items));
  });

  test('source model collections share their type and identity through casts and catches', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';
dynamic main() {
  dynamic value = <HttpSourceChapter>[HttpSourceChapter(url: '/chapter', name: 'chapter')];
  final chapters = value as List<HttpSourceChapter>;
  try { throw chapters; } on List<HttpSourceChapter> catch (error) {
    return [chapters == value, error == value, chapters];
  }
}
''';
    final result = await evalChecked(source) as List;
    expect(result.take(2), [true, true]);
    expect(result.last, isA<List<HttpSourceChapter>>());
    expect((result.last as List<HttpSourceChapter>).single.name, 'chapter');
  });
}

Future<dynamic> evalChecked(String source, {List<DartDeclaration> declarations = const []}) async {
  final libraries = [
    ...evalLibraries,
    if (declarations.isNotEmpty) DartLibrary('values', path: 'values.dart', declarations: declarations),
  ];
  final resolved = await resolve(source, [...dartLibraries, ...libraries]);
  final errors = resolved.errors.where((error) => error.errorCode.errorSeverity.name == 'ERROR');
  expect(errors.map((error) => error.message), isEmpty);
  return eval(source, libraries: libraries);
}
