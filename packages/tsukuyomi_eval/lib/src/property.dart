import 'object.dart';

typedef PropertyGetter = Function;

typedef PropertySetter = Function;

typedef DynamicProperties = Map<String, (Function(dynamic), Function(dynamic, dynamic))>;

abstract class Property {
  PropertyGetter? get getter;

  PropertySetter? get setter;
}

class EvalProperty extends Property {
  EvalProperty.setter(this.setter, [Property? property]) {
    assert(property is EvalProperty?, property);
    getter = property?.getter;
  }

  EvalProperty.getter(this.getter, [Property? property]) {
    assert(property is EvalProperty?, property);
    setter = property?.setter;
  }

  EvalProperty.method(ObjClosure method) {
    getter = (instance) => ObjBoundMethod(receiver: instance, method: method);
  }

  EvalProperty.variable(Object? variable, {required bool isStatic}) {
    if (isStatic) {
      getter = () => variable;
      setter = (value) => variable = value;
    } else {
      getter = (instance) => variable;
      setter = (instance, value) => variable = value;
    }
  }

  @override
  PropertyGetter? getter;

  @override
  PropertySetter? setter;
}

class DartProperty extends Property {
  DartProperty({this.getter, this.setter});

  @override
  PropertyGetter? getter;

  @override
  PropertySetter? setter;
}

sealed class DartDeclaration {
  String get source;

  final Map<String, DartProperty> props = {};
}

class DartLibrary extends DartDeclaration {
  DartLibrary(this.name, {required this.path, String source = '', required List<DartDeclaration> declarations}) {
    final sourceBuffer = StringBuffer(source);
    for (final declaration in declarations) {
      assert(() {
        if (declaration is DartClass) {
          debugProps.addAll(declaration.debugProps);
        }
        return true;
      }());
      props.addAll(declaration.props);
      sourceBuffer.writeln(declaration.source);
    }
    this.source = sourceBuffer.toString();
  }

  final String name;

  final String path;

  @override
  late final String source;

  late final Set<String> debugProps = {};
}

class DartClass<T> extends DartDeclaration {
  DartClass(String Function(DartClassRegister<T> $) declare) {
    assert(<dynamic>[] is! List<T>, T);
    source = declare(DartClassRegister<T>(this));
    props['${'$T'.split('<').first}.with'] ??= DartProperty(getter: (Function<T>() $) => $<T>());
  }

  DartClass.operator(Iterable<dynamic> Function(DartOperatorRegister $) declare) : source = '' {
    assert(<dynamic>[] is List<T>, T);
    declare(DartOperatorRegister(this));
  }

  DartClass.dynamic(DynamicProperties props) : source = '' {
    assert(<dynamic>[] is List<T>, T);
    for (final entry in props.entries) {
      assert(entry.key.isNotEmpty && !entry.key.contains('.') && !this.props.containsKey('.${entry.key}'), entry.key);
      this.props['.${entry.key}'] = DartProperty(getter: entry.value.$1, setter: entry.value.$2);
    }
    this.props['dynamic.with'] ??= DartProperty(getter: (Function<T>() $) => $<T>());
  }

  @override
  late final String source;

  late final Set<String> debugProps = {};
}

class DartVariable<T> extends DartDeclaration {
  DartVariable(this.name, Object variable, this.source) {
    assert(name.isNotEmpty && !name.contains('.'), name);
    props[name] = DartProperty(getter: () => variable);
  }

  final String name;

  @override
  final String source;
}

class DartFunction<T> extends DartDeclaration {
  DartFunction(this.name, Function function, this.source) {
    assert(name.isNotEmpty && !name.contains('.'), name);
    props[name] = DartProperty(getter: () => function);
  }

  final String name;

  @override
  final String source;
}

class DartClassRegister<T> {
  DartClassRegister(this.clazz);

  final DartClass<T> clazz;

  String alias(String alias) {
    assert(alias.isNotEmpty && !alias.contains('.') && clazz.props['$alias.with']?.getter == null, alias);
    clazz.props['$alias.with'] = DartProperty(getter: (Function<T>() $) => $<T>());
    return '';
  }

  String empty(String prop, dynamic Function() getter) {
    assert(prop.isNotEmpty && prop.contains('.') && clazz.props[prop]?.getter == null, prop);
    clazz.props[prop] = DartProperty(getter: getter, setter: clazz.props[prop]?.setter);
    return '';
  }

  String debug(String prop, dynamic Function(T $, dynamic $$) property) {
    assert(() {
      clazz.debugProps.add(RegExp(r'^[a-zA-Z$]').hasMatch(prop) ? '.$prop' : prop);
      return prop.isNotEmpty && !prop.contains('.');
    }(), prop);
    return '';
  }
}

class DartOperatorRegister {
  DartOperatorRegister(this.clazz);

  final DartClass clazz;

  dynamic unary(String operator, Function(dynamic $) function) {
    assert(!operator.contains('.') && operator.contains('#') && !clazz.props.containsKey(operator), operator);
    clazz.props[operator] = DartProperty(getter: function);
  }

  dynamic binary(String operator, Function(dynamic $, dynamic $$) function) {
    assert(operator.isNotEmpty && !operator.contains('.') && !clazz.props.containsKey(operator), operator);
    clazz.props[operator] = DartProperty(getter: function);
  }

  dynamic ternary(String operator, Function(dynamic $, dynamic $$, dynamic $$$) function) {
    assert(operator.isNotEmpty && !operator.contains('.') && !clazz.props.containsKey(operator), operator);
    clazz.props[operator] = DartProperty(getter: function);
  }
}

extension DartLibrariesExtension on Iterable<DartLibrary> {
  Map<String, Property> get props {
    final props = <String, Property>{
      for (final declaration in this) ...declaration.props,
    };
    late final missingProps = <String>{};
    assert(() {
      missingProps.addAll([
        for (final library in this) ...library.debugProps.where((e) => !props.containsKey(e)),
      ]);
      return missingProps.isEmpty;
    }(), '$missingProps');
    return props;
  }
}
