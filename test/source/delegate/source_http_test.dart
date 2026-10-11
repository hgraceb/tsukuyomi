import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/source/declaration/declaration.dart';
import 'package:tsukuyomi/source/delegate/source_http.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Sources from the same script class bind callbacks to their own host', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example extends HttpSource {
  String name = '';
  final String baseUrl = 'https://example.com';

  int readId() => id;

  Future<String?> store(String value) async {
    await null;
    setStorage('value', value);
    return getStorage('value', null);
  }

  dynamic decode(String value) => parseJson(value);
}

dynamic main() {
  final first = Example();
  final second = Example();
  first.name = 'First';
  second.name = 'Second';
  return <dynamic>[first, second];
}
    ''';
    final instances = (await eval(source, libraries: evalLibraries) as List).cast<ObjInstance>();
    final preferences = await SharedPreferences.getInstance();
    final first = IsolateDioHttpSource(delegate: instances.first, preferences: preferences);
    final second = IsolateDioHttpSource(delegate: instances.last, preferences: preferences);
    expect(first.delegate.clazz, same(second.delegate.clazz));
    expect(first.name, 'First');
    expect(second.name, 'Second');
    expect(first.id, isNot(second.id));
    expect(await first.delegate.invoke('readId', null), first.id);
    expect(await second.delegate.invoke('readId', null), second.id);
    await expectLater(first.delegate.invoke('store', ['first']), completion('first'));
    await expectLater(second.delegate.invoke('store', ['second']), completion('second'));
    expect(first.storage, {'value': 'first'});
    expect(second.storage, {'value': 'second'});
    expect(await first.delegate.invoke('decode', ['{"value":"JSON"}']), {'value': 'JSON'});
    expect(first.delegate.clazz.props['parseJson'], isNull);
  });

  test('Host injection preserves methods declared by the script', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example extends HttpSource {
  final String name = 'Script implementation';
  final String baseUrl = 'https://example.com';

  String? getStorage(String key, String? defaultValue) => 'script';

  String? load() => getStorage('value', null);
}

Example main() => Example();
    ''';
    final instance = await eval(source, libraries: evalLibraries) as ObjInstance;
    final property = instance.props['getStorage'];
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    expect(instance.props['getStorage'], same(property));
    expect(await host.delegate.invoke('load', null), 'script');
  });

  test('Script sources recognize bridged ancestors while casts preserve the delegate', () async {
    const source = '''
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class Example extends HttpSource {
  final String name = 'Example';
  final String baseUrl = 'https://example.com';
}

class Child extends Example {}

dynamic main() {
  final value = Child();
  final base = value as Source;
  try {
    throw value;
  } on Source catch (error) {
    return <String, dynamic>{
      'checks': <bool>[
        value is Child,
        value is Example,
        value is HttpSource,
        value is Source,
        (value as HttpSource) == value,
        base == value,
        base is Child,
        error == value,
      ],
      'delegate': value,
    };
  }
}
    ''';
    final result = await eval(source, libraries: evalLibraries) as Map;
    expect(result['checks'], [true, true, true, true, true, true, true, true]);
    final instance = result['delegate'] as ObjInstance;
    final host = IsolateDioHttpSource(delegate: instance, preferences: await SharedPreferences.getInstance());
    expect(host.name, 'Example');
    expect(instance.clazz.name, 'Child');
  });
}
