class Scope {
  Future<Proxy?> get(String name) async => null;

  Object? set(String name, Object? value) => null;
}

class ClassScope extends Scope {
  StaticScope? _staticScope;

  StaticScope get staticScope => _staticScope ??= StaticScope(parent: this);

  InstanceScope get instanceScope => InstanceScope(parent: staticScope);
}

class StaticScope extends Scope {
  StaticScope({required this.parent});

  final ClassScope parent;
}

class InstanceScope extends Scope {
  InstanceScope({required this.parent});

  final StaticScope parent;
}

class Proxy {}

class EvalClassProxy extends Proxy {}

class EvalFunctionProxy extends Proxy {
  EvalFunctionProxy(this.function);

  final Function function;
}

Future evaluate(dynamic node, Scope scope) async {}

final classScope = ClassScope();

final evalClass = <String, Object>{
  'Class': EvalFunctionProxy(() async {
    return InstanceScope(parent: classScope.staticScope);
  }),
  'Class.method': EvalFunctionProxy(() async {
    return await classScope.staticScope.get('Class.method');
  }),
  'Class.field': EvalFunctionProxy(() async {
    return classScope.staticScope.get('Class.field');
  }),
  'Class.field.set': EvalFunctionProxy((value) async {
    return classScope.staticScope.set('Class.field', value);
  }),
  'method': EvalFunctionProxy((InstanceScope instance) async {
    return await instance.get('method');
  }),
  'field': EvalFunctionProxy((InstanceScope instance) async {
    return await instance.get('field');
  }),
  'field.set': EvalFunctionProxy((InstanceScope instance, value) async {
    return instance.set('Class.field', value);
  }),
};
