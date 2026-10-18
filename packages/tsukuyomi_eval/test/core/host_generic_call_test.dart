import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_eval/src/error.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

import '../util/print_matcher.dart';

void main() {
  group('Host generic collection calls', () {
    test('whereType filters by the explicit host type and retains typed empty results', () async {
      const source = '''
void main() {
  final values = <dynamic>[0, 'chapter', 1];
  print(values.whereType<int>().toList());
  print(values.whereType<String>().toList());
  print(isInts(values.whereType<int>().toList()));
  print(isInts(<dynamic>[].whereType<int>().toList()));
}
      ''';
      await expectLater(() => _evalWithChecks(source), println(['[0, 1]', '[chapter]', true, true]));
    });

    for (final value in ['<dynamic>[0]', '<dynamic>{0}', '<dynamic>[0].where((value) => true)']) {
      test('$value cast keeps the native collection kind and type', () async {
        final source =
            '''
void main() {
  final values = $value.cast<int>();
  print(values.first);
  print(isInts(values.toList()));
  print(values is List);
  print(values is Set);
}
        ''';
        final isList = value == '<dynamic>[0]';
        final isSet = value == '<dynamic>{0}';
        await expectLater(() => _evalWithChecks(source), println([0, true, isList, isSet]));
      });
    }

    test('cast defers failure until an incompatible element is read', () async {
      const source = '''
void main() {
  final values = <dynamic>[0, 'chapter'].cast<int>();
  print('created');
  print(values.first);
  try { print(values.last); } on TypeError { print('type error'); }
  print('recovered');
}
      ''';
      await expectLater(() => eval(source), println(['created', 0, 'type error', 'recovered']));
    });

    for (final typeArguments in ['<String>', '']) {
      test('map$typeArguments retains the actual result type including empty collections', () async {
        final source =
            '''
void main() {
  final values = <int>[0, 1].map$typeArguments((value) => 'chapter').toList();
  print(values);
  print(isStrings(values));
  print(isStrings(<int>[].map$typeArguments((value) => 'chapter').toList()));
}
        ''';
        await expectLater(() => _evalWithChecks(source), println(['[chapter, chapter]', true, true]));
      });
    }

    test('context infers cast and whereType arguments without explicit syntax', () async {
      const source = '''
void main() {
  Iterable<int> filtered = <dynamic>[0, 'chapter'].whereType();
  Iterable<int> casted = <dynamic>[0].cast();
  print(filtered.toList());
  print(isInts(filtered.toList()));
  print(isInts(casted.toList()));
}
      ''';
      await expectLater(() => _evalWithChecks(source), println(['[0]', true, true]));
    });

    for (final method in ['whereType', 'cast']) {
      test('$method supports nullable host types', () async {
        final source =
            '''
void main() {
  final values = <dynamic>[null, 0].$method<int?>().toList();
  print(values);
  print(isNullableInts(values));
}
        ''';
        await expectLater(() => _evalWithChecks(source), println(['[null, 0]', true]));
      });
    }

    test('nullable map retains the actual nullable result type', () async {
      const source = '''
void main() {
  final values = <int>[0, 1].map<int?>((value) => value == 0 ? null : value).toList();
  print(values);
  print(isNullableInts(values));
}
      ''';
      await expectLater(() => _evalWithChecks(source), println(['[null, 1]', true]));
    });

    for (final type in ['List', 'Values', 'Chain']) {
      test('$type raw type arguments are not mistaken for explicit parameterization', () async {
        final source =
            '''
typedef Values = List;
typedef Chain = Values;
void main() {
  print(<dynamic>[<int>[0], 'chapter'].whereType<$type>().toList());
}
        ''';
        await expectLater(() => eval(source), println(['[[0]]']));
      });
    }

    for (final method in ['whereType', 'cast', 'map']) {
      test('$method supports ordinary script typedefs for host types', () async {
        final invocation = method == 'map' ? '<int>[0].map<Number>((value) => value)' : '<dynamic>[0].$method<Number>()';
        final source =
            '''
typedef Number = int;
void main() { print(isInts($invocation.toList())); }
        ''';
        await expectLater(() => _evalWithChecks(source), println([true]));
      });
    }

    test('raw host types with non-dynamic bounds are not rejected as nested arguments', () async {
      const source = '''
import 'package:bounded/types.dart';
typedef Values = Bounded;
void main() {
  print(<dynamic>[hostValue, 'chapter'].whereType<Bounded>().length);
  print(<dynamic>[hostValue].cast<Values>().length);
}
      ''';
      final library = DartLibrary(
        'bounded',
        path: 'types.dart',
        declarations: [
          DartClass<_Bounded>(
            ($) =>
                '''
class Bounded<T extends num> {}
// ${$.alias('Bounded')}
        ''',
          ),
          DartVariable('hostValue', _Bounded<int>(), 'external Bounded get hostValue;'),
        ],
      );
      await expectLater(() => eval(source, libraries: [library]), println([1, 1]));
    });

    for (final registration in ['canonical', 'alias', 'both']) {
      test('$registration model registration preserves the host generic identity', () async {
        const source = '''
import 'package:generic_models/models.dart';
void main() {
  print(isModels(<dynamic>[hostModel, 'chapter'].whereType<PublicModel>().toList()));
  print(isModels(<dynamic>[hostModel].cast<PublicModel>().toList()));
  print(isModels(<int>[0].map<PublicModel>((value) => hostModel).toList()));
  print(isModels(<int>[].map((value) => hostModel).toList()));
}
        ''';
        await expectLater(() => eval(source, libraries: [_models(registration)]), println([true, true, true, true]));
      });
    }

    test('encoded library paths preserve generic model aliases', () async {
      const source = '''
import 'package:generic_models/my%20models.dart';
void main() { print(isModels(<dynamic>[hostModel].whereType<PublicModel>().toList())); }
      ''';
      final library = _models('alias', path: 'my models.dart');
      await expectLater(() => eval(source, libraries: [library]), println([true]));
    });

    test('part model aliases use the owning library for generic calls', () async {
      const source = '''
import 'package:generic_models/bridge.dart';
void main() { print(isModels(<int>[0].map<PublicModel>((value) => hostModel).toList())); }
      ''';
      final library = DartLibrary('generic_models', path: 'bridge.dart', source: "part 'models.dart';", declarations: []);
      final part = _models('alias', directives: "part of 'bridge.dart';");
      await expectLater(() => eval(source, libraries: [library, part]), println([true]));
    });

    test('same-name model aliases retain their declaring library', () async {
      const source = '''
import 'package:generic_models/models.dart';
void main() { print(isModels(<dynamic>[hostModel].cast<PublicModel>().toList())); }
      ''';
      final shadow = DartLibrary(
        'shadow_models',
        path: 'models.dart',
        declarations: [
          DartClass<String>(
            ($) =>
                '''
class InternalModel {}
typedef PublicModel = InternalModel;
// ${$.alias('PublicModel')}
        ''',
          ),
        ],
      );
      await expectLater(() => eval(source, libraries: [_models('alias'), shadow]), println([true]));
    });

    test('same-name bridges cannot replace the core int argument', () async {
      const source = '''
typedef Number = int;
void main() {
  print(<dynamic>[0, 'chapter'].whereType<Number>().toList());
  print(isInts(<dynamic>[0].map((value) => 0).toList()));
}
      ''';
      final shadow = DartLibrary(
        'shadow',
        path: 'types.dart',
        declarations: [
          DartClass<String>(
            ($) =>
                '''
class int {}
// ${$.alias('int')}
        ''',
          ),
        ],
      );
      await expectLater(() => _evalWithChecks(source, libraries: [shadow]), println(['[0]', true]));
    });

    test('ordinary script methods sharing a core method name keep their call path', () async {
      const source = '''
class Example { String map(String value) => value; String cast() => 'cast'; String whereType() => 'whereType'; }
void main() {
  final example = Example();
  print(example.map('chapter'));
  print(example.cast());
  print(example.whereType());
}
      ''';
      await expectLater(() => eval(source), println(['chapter', 'cast', 'whereType']));
    });

    test('nullable receivers short-circuit before evaluating the mapping callback', () async {
      const source = '''
dynamic mapper() { print('evaluated'); return (value) => 'chapter'; }
void main() {
  Iterable<int>? values;
  print(values?.map<String>(mapper()));
}
      ''';
      await expectLater(() => eval(source), println([null]));
    });

    test('map remains lazy and evaluates receiver and callback once', () async {
      const source = '''
Iterable<int> values() { print('receiver'); return <int>[0]; }
String convert(int value) { print('mapped'); return 'chapter'; }
void main() {
  final mapped = values().map<String>(convert);
  print('created');
  print(mapped.toList());
}
      ''';
      await expectLater(() => eval(source), println(['receiver', 'created', 'mapped', '[chapter]']));
    });

    test('captured and bound mapping callbacks retain their state across await', () async {
      const source = '''
class Example {
  String chapter = 'chapter';
  String convert(int value) => chapter;
}
Future<void> main() async {
  final example = Example();
  String chapter = 'captured';
  final captured = <int>[0].map<String>((value) => chapter);
  final bound = <int>[0].map(example.convert);
  await Future.value();
  chapter = 'updated';
  print(captured.toList());
  print(isStrings(bound.toList()));
}
      ''';
      await expectLater(() => _evalWithChecks(source), println(['[updated]', true]));
    });

    test('mapping script closures to Function retains the native callback adaptation', () async {
      const source = '''
Function make(int value) => () => value;
void main() { print(<int>[0].map<Function>(make).first()); }
      ''';
      await expectLater(() => eval(source), println([0]));
    });

    test('unregistered host arguments fail instead of falling back to dynamic', () async {
      const source = '''
import 'package:unregistered/types.dart';
void main() { <dynamic>[].whereType<Unregistered>(); }
      ''';
      final library = DartLibrary('unregistered', path: 'types.dart', source: 'class Unregistered {}', declarations: []);
      await expectLater(() => eval(source, libraries: [library]), throwsA(isA<EvalRuntimeError>()));
    });

    test('unregistered inferred native callback return types preserve the existing call path', () async {
      const source = '''
import 'package:unregistered/types.dart';
void main() { print(<int>[0].map(makeHost).length); }
      ''';
      final library = DartLibrary(
        'unregistered',
        path: 'types.dart',
        source: 'class Unregistered {}',
        declarations: [
          DartFunction('makeHost', (int value) => _HostModel(), 'external Unregistered makeHost(int value);'),
        ],
      );
      await expectLater(() => eval(source, libraries: [library]), println([1]));
    });

    for (final type in ['List<int>', 'List<dynamic>', 'Nested', 'Parameterized<int>', 'Example', 'int Function()']) {
      for (final method in ['whereType', 'cast', 'map']) {
        test('$method rejects unsupported explicit $type arguments', () async {
          final arguments = method == 'map' ? '(value) => value' : '';
          final source =
              '''
typedef Nested = List<int>;
typedef Parameterized<T> = List<T>;
class Example {}
void main() { <dynamic>[].$method<$type>($arguments); }
          ''';
          await expectLater(() => eval(source), throwsA(isA<EvalCompileError>()));
        });
      }
    }

    test('inferred nested map arguments retain the existing source call path', () async {
      const source = '''
void main() { print(<int>[0].map((value) => <int>[value]).toList()); }
      ''';
      await expectLater(() => eval(source), println(['[[0]]']));
    });

    test('parameterized type checks remain deferred independently of generic calls', () async {
      const source = '''
void main() { dynamic values = <int>[0].map((value) => value).toList(); values as List<int>; }
      ''';
      await expectLater(() => eval(source), throwsA(isA<EvalCompileError>()));
    });
  });
}

DartLibrary _checks() => DartLibrary(
  'generic_checks',
  path: 'checks.dart',
  declarations: [
    DartFunction('isInts', (dynamic value) => value is List<int>, 'external bool isInts(dynamic value);'),
    DartFunction('isStrings', (dynamic value) => value is List<String>, 'external bool isStrings(dynamic value);'),
    DartFunction('isNullableInts', (dynamic value) => value is List<int?>, 'external bool isNullableInts(dynamic value);'),
  ],
);

DartLibrary _models(String registration, {String path = 'models.dart', String directives = ''}) {
  final model = _HostModel();
  final declaration = DartClass<_HostModel>(
    ($) =>
        '''
class InternalModel {}
// ${registration != 'canonical' ? $.alias('PublicModel') : ''}
typedef PublicModel = InternalModel;
    ''',
  );
  if (registration == 'alias') declaration.props.remove('_HostModel.with');
  final matcher = declaration.props.remove('_HostModel.with');
  if (matcher != null) declaration.props['InternalModel.with'] = matcher;
  declaration.props['hostModel'] = DartProperty(getter: () => model);
  declaration.props['isModels'] = DartProperty(
    getter: () =>
        (dynamic value) => value is List<_HostModel>,
  );
  return DartLibrary(
    'generic_models',
    path: path,
    source:
        '''
$directives
external PublicModel get hostModel;
external bool isModels(dynamic value);
''',
    declarations: [declaration],
  );
}

class _HostModel {}

class _Bounded<T extends num> {}

Future<dynamic> _evalWithChecks(String source, {List<DartLibrary> libraries = const []}) {
  return eval("import 'package:generic_checks/checks.dart';\n$source", libraries: [_checks(), ...libraries]);
}
