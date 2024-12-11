abstract class Proxy {}

abstract class ObjectProxy extends Proxy {
  abstract final Object? value;
}

abstract class FunctionProxy extends Proxy {
  abstract final Function function;

  dynamic apply(
    List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments,
  );
}

abstract class ClassProxy extends Proxy {
  abstract final ClassProxy? parent;

  abstract final Map<String, Proxy> props;

  bool match(dynamic instance);

  Proxy? get(String prop, {int level = 0, bool setter = false}) {
    assert(level >= 0);
    if (level == 0) {
      final name = setter ? '$prop.set' : prop;
      for (final entry in props.entries) {
        if (entry.key == name) {
          return entry.value;
        }
      }
    }
    return parent?.get(prop, level: level - 1, setter: setter);
  }
}

class RuntimeFunctionProxy extends FunctionProxy {
  RuntimeFunctionProxy(this.function);

  @override
  final Function function;

  @override
  dynamic apply(
    List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments,
  ) {
    return Function.apply(function, positionalArguments, namedArguments);
  }
}

class RuntimeClassProxy<T> extends ClassProxy {
  RuntimeClassProxy(Map<String, Function> props, {this.parent}) {
    for (final entry in props.entries) {
      this.props.addAll({entry.key: RuntimeFunctionProxy(entry.value)});
    }
  }

  @override
  final ClassProxy? parent;

  @override
  final Map<String, Proxy> props = {};

  @override
  bool match(dynamic instance) => instance is T;
}

class EvalFunctionProxy extends FunctionProxy {
  EvalFunctionProxy(this.function);

  @override
  final dynamic Function(
    List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments,
  ) function;

  @override
  dynamic apply(
    List<dynamic> positionalArguments,
    Map<Symbol, dynamic> namedArguments,
  ) {
    return function(positionalArguments, namedArguments);
  }
}
