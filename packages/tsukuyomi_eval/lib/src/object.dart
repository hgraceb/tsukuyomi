import 'dart:async';

import 'chunk.dart';
import 'constant.dart';
import 'error.dart';
import 'property.dart';
import 'stack.dart';
import 'table.dart';
import 'vm.dart';

class CallFrame {
  CallFrame({
    this.ip = 0,
    this.hasReturn = true,
    required this.slot,
    required this.closure,
  });

  int ip;
  int slot;
  bool hasReturn;
  ObjClosure closure;

  Chunk get chunk => closure.function.chunk;
}

sealed class Obj {}

class ObjContinuation extends Obj {
  ObjContinuation({this.caller, int argCount = 0}) {
    if (caller?.stack case Stack stack) {
      this.stack.pushAll(stack.sublist(stack.size - argCount - 1));
      stack.removeRange(stack.size - argCount - 1, stack.size);
    }
  }

  ObjTrying? trying;

  ObjUpvalue? openUpvalues;

  ObjContinuation? caller;

  final completer = Completer();

  final stack = Stack(MAX_STACK);

  final frames = Stack<CallFrame>(MAX_FRAME);

  @override
  String toString() => '<continuation>';
}

class ObjUpvalue extends Obj {
  ObjUpvalue(this.location, {this.next, required this.get, required this.set});

  int location;

  ObjUpvalue? next;

  dynamic Function() get;

  dynamic Function(dynamic value) set;

  @override
  String toString() => '<upvalue>';
}

class ObjFunction extends Obj {
  ObjFunction(this.name, {required this.returnType}) : chunk = Chunk(name);

  int upvalueCount = 0;

  bool isAsync = false;

  final String name;

  final Chunk chunk;

  final String returnType;

  @override
  String toString() => '<fn $name>';
}

class ObjClosure extends Obj {
  ObjClosure(this.function);

  final ObjFunction function;

  final List<ObjUpvalue> upvalues = [];

  final List<ObjParameter> parameters = [];

  @override
  String toString() => function.toString();
}

class ObjClass extends Obj {
  ObjClass(this.name);

  final String name;

  final props = Table<Property>();

  @override
  String toString() => '<class $name>';
}

class ObjInstance extends Obj {
  ObjInstance({required this.clazz, required this.context});

  final ObjClass clazz;

  final ({bool debug, Map<String, Property> globals}) context;

  @override
  String toString() => '<instance ${clazz.name}>';
}

class ObjBoundMethod extends Obj {
  ObjBoundMethod({required this.receiver, required this.method});

  final Object receiver;

  final ObjClosure method;

  @override
  String toString() => '<bound ${method.function.name}>';
}

class ObjParameter extends Obj {
  ObjParameter(this.name, {required this.isPositional});

  final String name;

  final bool isPositional;

  Object? Function()? _default;

  @override
  String toString() => '<parameter>';
}

class ObjArguments extends Obj {
  ObjArguments(this.delegate);

  final Function(dynamic) delegate;

  final List<dynamic> positional = [];

  final Map<Symbol, dynamic> named = {};

  @override
  String toString() => '<arguments>';
}

class ObjTrying extends Obj {
  ObjTrying({required this.enclosing, required this.frame, required this.slot, required this.start, required this.end});

  final CallFrame frame;

  final int start;

  final int end;

  final int slot;

  final ObjTrying? enclosing;

  final List<ObjCatching> catchings = [];

  late final ObjFinally finalization;

  late final Object error;

  @override
  String toString() => '<trying>';
}

class ObjCatching extends Obj {
  ObjCatching({required this.start, required this.end, required this.match});

  final int start;

  final int end;

  final bool Function(dynamic) match;

  @override
  String toString() => '<catching>';
}

class ObjFinally extends Obj {
  ObjFinally({required this.start, required this.end});

  final int start;

  final int end;

  @override
  String toString() => '<finally>';
}

extension on Obj {
  ObjClosure? get closureOrNull {
    return switch (this) {
      ObjClosure closure => closure,
      ObjBoundMethod bound => bound.method,
      _ => null,
    };
  }
}

extension ObjInstanceExtension on ObjInstance {
  bool has(String field) {
    return clazz.props[field] != null;
  }

  dynamic get(String field) {
    return clazz.props[field]!.getter!(this);
  }

  dynamic invoke(String method, List<dynamic>? positionalArguments) {
    return VM(debug: context.debug, globals: context.globals).apply(get(method), positionalArguments);
  }
}

extension ObjParameterExtension on ObjParameter {
  set defaultValue(Object? value) => _default = () => value;

  Object? getDefaultValue(String functionName) {
    if (_default == null) {
      final parameter = "${isPositional ? 'Positional' : 'Named'} parameter '$name'";
      throw EvalRuntimeError("$parameter is required for function '$functionName'.");
    }
    return _default!();
  }
}

extension ObjArgumentsExtension on ObjArguments {
  int forEach(Obj callee, void Function(dynamic element) action) {
    final values = [];
    if (callee.closureOrNull case ObjClosure closure) {
      final parameters = closure.parameters;
      final function = closure.function.name;
      for (final parameter in parameters) {
        final dynamic value;
        if (parameter.isPositional && values.length < positional.length) {
          action(value = positional[values.length]);
        } else if (named.containsKey(Symbol(parameter.name))) {
          action(value = named[Symbol(parameter.name)]);
        } else {
          action(value = parameter.getDefaultValue(function));
        }
        values.add(value);
      }
    }
    return values.length;
  }
}
