import 'dart:async';

import 'package:collection/collection.dart';

import 'constant.dart';
import 'debug.dart';
import 'error.dart';
import 'object.dart';
import 'ops.dart';
import 'property.dart';
import 'stack.dart';

abstract class VM {
  factory VM({required bool debug, required Map<String, Property> globals}) = _VM;

  dynamic apply(ObjBoundMethod bound, List<dynamic>? positionalArguments);

  dynamic interpret(ObjFunction fn);
}

class _VM implements VM {
  _VM({required this.debug, required this.globals});

  final bool debug;

  final Map<String, Property> globals;

  ObjContinuation continuation = ObjContinuation();

  ObjTrying? get trying => continuation.trying;

  set trying(ObjTrying? value) => continuation.trying = value;

  Completer get completer => continuation.completer;

  Stack get stack => continuation.stack;

  Stack<CallFrame> get frames => continuation.frames;

  ObjUpvalue? get openUpvalues => continuation.openUpvalues;

  set openUpvalues(ObjUpvalue? value) => continuation.openUpvalues = value;

  dynamic pop() {
    return stack.pop();
  }

  void push(dynamic value) {
    stack.push(value);
  }

  dynamic peek([int distance = 0]) {
    return stack[stack.size - distance - 1];
  }

  int readCode(CallFrame frame) {
    return frame.chunk.codeAt(frame.ip++);
  }

  Object? readConstant(CallFrame frame) {
    return frame.chunk.constantAt(readCode(frame));
  }

  String readString(CallFrame frame) {
    return readConstant(frame) as String;
  }

  void call(ObjClosure closure, int argCount) {
    if (closure.function.isAsync) {
      resume(ObjContinuation(caller: continuation, argCount: argCount));
    }

    if (frames.size >= MAX_FRAME) {
      throw EvalRuntimeError('Stack overflow.');
    }

    frames.push(CallFrame(slot: stack.size - argCount - 1, closure: closure));
  }

  void callValue(Object callee, int argCount) {
    switch (callee) {
      case ObjClosure():
        call(callee, argCount);
      case ObjBoundMethod():
        stack[stack.size - argCount - 1] = callee.receiver;
        call(callee.method, argCount);
      case ObjClass():
        assert(argCount == 0);
        stack[stack.size - argCount - 1] = ObjInstance(clazz: callee, context: (debug: debug, globals: globals));
        // 初始化帧共用 receiver 槽位，后入先出，按子类到父类初始化字段
        for (final initializer in callee.initializers) {
          call(initializer, 0);
        }
      default:
        throw EvalRuntimeError('Can only call functions and classes.');
    }
  }

  R withOrThrow<R>(String type, R Function<T>() function) {
    final name = '$type.with';
    final getter = globals[name]?.getter;
    if (getter == null) throw EvalRuntimeError("Undefined getter for '$name'.");
    return getter.call(function);
  }

  bool matchInstance(ObjInstance instance, bool Function(ObjClass) match) {
    if (!instance.clazz.isTypeCheckSupported) {
      throw EvalRuntimeError("Unsupported type check for class '${instance.clazz.name}'.");
    }
    for (ObjClass? clazz = instance.clazz; clazz != null; clazz = clazz.superclass) {
      if (match(clazz)) return true;
    }
    return false;
  }

  bool Function(Object?) nativeTypeMatcher(String name) {
    return withOrThrow(name, <T>() => (Object? value) {
      if (value is T) return true;
      if (value is ObjClosure || value is ObjBoundMethod) {
        return <Function>[] is List<T>;
      }
      if (value is ObjInstance) {
        return matchInstance(value, (actual) => actual.isDartSubtype?.call<T>() ?? false);
      }
      return false;
    });
  }

  bool Function(Object?) typeMatcher(ObjTypeCheck type) {
    final isNullable = type.name.endsWith('?');
    final name = isNullable ? type.name.substring(0, type.name.length - 1) : type.name;
    final alias = type.aliases.firstWhereOrNull((alias) => globals['$alias.with']?.getter != null);
    final bool Function(Object?) match;
    if (type.isScriptType) {
      final clazz = globals['$name.class']?.getter?.call();
      if (clazz is! ObjClass) {
        throw EvalRuntimeError("Undefined getter for '$name.class'.");
      }
      if (!clazz.isTypeCheckSupported) {
        throw EvalRuntimeError("Unsupported type check for class '${clazz.name}'.");
      }
      match = (value) => value is ObjInstance && matchInstance(value, (actual) => identical(actual, clazz));
    } else if (alias != null) {
      match = nativeTypeMatcher(alias);
    } else {
      switch (name) {
        case 'dynamic':
          match = (_) => true;
        case 'Object':
          match = (value) => value != null;
        case 'Null':
          match = (value) => value == null;
        case 'Never':
          match = (_) => false;
        case 'Function':
          match = (value) {
            if (value is ObjInstance) {
              return matchInstance(value, (actual) => actual.isDartSubtype?.call<Function>() ?? false);
            }
            return value is Function || value is ObjClosure || value is ObjBoundMethod;
          };
        default:
          match = nativeTypeMatcher(name);
      }
    }
    return (value) => (isNullable && value == null) || match(value);
  }

  Function delegateClosure(ObjClosure closure) {
    final function = closure.function;
    final parameters = closure.parameters;
    final count = parameters.where((e) => e.isPositional).length;
    if (count != parameters.length) {
      throw EvalRuntimeError("Unsupported delegate '$closure' with named parameters.");
    }
    if (count > 2) {
      throw EvalRuntimeError("Unsupported delegate '$closure' with $count parameters greater than 2.");
    }
    return withOrThrow(function.returnType, <T>() {
      const $ = ObjParameter;
      return ([$0 = $, $1 = $]) {
        final previous = continuation;
        resume(ObjContinuation());
        try {
          push(closure);
          if (count > 0) push($0 != $ ? $0 : parameters[0].getDefaultValue(function.name));
          if (count > 1) push($1 != $ ? $1 : parameters[1].getDefaultValue(function.name));
          call(closure, count);
          return execute() as T;
        } finally {
          resume(previous);
        }
      };
    });
  }

  dynamic delegateArgument(dynamic argument) {
    if (argument is! Obj) return argument;
    return switch (argument) {
      ObjClosure() => delegateClosure(argument),
      _ => throw EvalRuntimeError("Unsupported delegate '$argument' of type '${argument.runtimeType}'."),
    };
  }

  ObjUpvalue captureUpvalue(int local) {
    ObjUpvalue? prevUpvalue;
    ObjUpvalue? upvalue = openUpvalues;
    while (upvalue != null && upvalue.location > local) {
      prevUpvalue = upvalue;
      upvalue = upvalue.next;
    }

    if (upvalue != null && upvalue.location == local) {
      return upvalue;
    }

    // 捕获当前堆栈
    final stack = this.stack;
    // 创建新的上值
    final createdUpvalue = ObjUpvalue(local, next: upvalue, get: () => stack[local], set: ($) => stack[local] = $);

    if (prevUpvalue == null) {
      openUpvalues = createdUpvalue;
    } else {
      prevUpvalue.next = createdUpvalue;
    }

    return createdUpvalue;
  }

  void closeUpvalues(int last) {
    while (openUpvalues != null && openUpvalues!.location >= last) {
      final upvalue = openUpvalues!;
      dynamic value = upvalue.get();
      upvalue.get = () => value;
      upvalue.set = ($) => value = $;
      upvalue.location = -1;
      openUpvalues = upvalue.next;
    }
  }

  Function? getInstanceGetter(Object? instance, String name) {
    assert(instance is! Obj || instance is ObjInstance);
    return switch (instance) {
      ObjInstance() => instance.props[name]?.getter,
      _ => globals['.$name']?.getter,
    };
  }

  Function? getInstanceSetter(Object? instance, String name) {
    assert(instance is! Obj || instance is ObjInstance);
    return switch (instance) {
      ObjInstance() => instance.props[name]?.setter,
      _ => globals['.$name']?.setter,
    };
  }

  void trimStack(int slot) {
    closeUpvalues(slot);
    stack.removeRange(slot, stack.size);
  }

  void restoreTrying(ObjTrying handler) {
    frames.removeRange(frames.indexOf(handler.frame) + 1, frames.size);
    trimStack(handler.slot);
  }

  bool unwind(ObjExit exit) {
    while (trying != null) {
      final handler = trying!;
      final finalization = handler.finalization;
      // 登记处理器时发生的错误向外传播，尚未进入 try 的运行范围
      if (finalization == null) {
        trying = handler.enclosing;
        continue;
      }
      if (exit is ObjReturn && handler.frame != exit.frame) break;
      if (exit is ObjJump) {
        if (handler.frame != exit.frame) break;
        final start = handler.isFinalizing ? finalization.start : handler.start;
        // try 或 finally 内部的循环跳转保留当前处理器与待处理退出
        if (start <= exit.target && exit.target < finalization.end) break;
      }
      if (exit is ObjThrow && !handler.isFinalizing) {
        final thrown = exit;
        final ip = handler.frame.ip - 1;
        final isInTryBody = handler.start <= ip && ip < handler.end;
        ObjCatching? catching;
        try {
          catching = isInTryBody ? handler.catchings.firstWhereOrNull((catching) => catching.match(thrown.error)) : null;
        } catch (e, s) {
          // 匹配失败作为新异常经过当前 finally，再向外层传播
          exit = ObjThrow(e, s);
        }
        if (catching != null) {
          restoreTrying(handler);
          handler.frame.ip = catching.start;
          push(handler.error = thrown.error);
          push(handler.stackTrace = thrown.stackTrace);
          return true;
        }
      }
      if (handler.isFinalizing) {
        // finally 发起的新退出替代旧退出，不再次进入同一个 finally
        trying = handler.enclosing;
        continue;
      }
      restoreTrying(handler);
      handler.isFinalizing = true;
      handler.pendingExit = exit;
      handler.frame.ip = finalization.start;
      return true;
    }
    return false;
  }

  void resume(ObjContinuation continuation) {
    this.continuation = continuation;
  }

  void suspend(ObjContinuation continuation, dynamic value) async {
    continuation.caller = null;
    Object? error;
    StackTrace? stackTrace;
    try {
      value = await value;
    } catch (e, s) {
      error = e;
      stackTrace = s;
    }
    final previous = this.continuation;
    resume(continuation);
    try {
      if (error == null) push(value);
      execute(error: error, stackTrace: stackTrace);
    } finally {
      resume(previous);
    }
  }

  dynamic execute({Object? error, StackTrace? stackTrace}) {
    CallFrame frame = frames.last;
    ObjExit? exit;
    while (true) {
      if (debug && exit == null && error == null) {
        disassembleStack(continuation);
        disassembleInstruction(frame.chunk, frame.ip);
      }

      final isAsync = frames.first.closure.function.isAsync;
      try {
        if (error != null) Error.throwWithStackTrace(error, stackTrace!);
        if (exit case ObjExit pending) {
          exit = null;
          if (unwind(pending)) {
            frame = trying!.frame;
            continue;
          }
          switch (pending) {
            case ObjJump():
              trimStack(pending.slot);
              frame = pending.frame..ip = pending.target;
              continue;
            case ObjThrow():
              Error.throwWithStackTrace(pending.error, pending.stackTrace);
            case ObjReturn():
              frame = pending.frame;
              frames.pop();
              final result = pending.value;
              trimStack(frame.slot);

              // 如果还有 frame 未被执行则说明当前函数不是异步函数
              if (frames.isNotEmpty) {
                if (frame.hasReturn) push(result);
                frame = frames.last;
                continue;
              }

              // frames 都执行结束后通过 completer 将结果进行异步回调
              assert(frame.hasReturn);
              completer.complete(result);
              final caller = continuation.caller;

              // caller 为空说明没有调用者或者调用者会等待在 complete 回调之后继续执行
              if (caller == null) return result;

              // caller 不为空则说明在没有执行 await 语句的情况下结束了当前代码块的调用
              final future = completer.future;
              resume(caller);

              // caller 的 frames 为空说明调用者的所有代码块已经运行完成
              if (frames.isEmpty) return future;
              frame = frames.last;
              push(future);
              continue;
          }
        }
        final instruction = readCode(frame);
        switch (instruction) {
          case OP_RETURN:
            exit = ObjReturn(frame, pop());
          case OP_CONSTANT:
            final constant = readConstant(frame);
            push(constant);
          case OP_POP:
            pop();
          case OP_NULL:
            push(null);
          case OP_TRUE:
            push(true);
          case OP_FALSE:
            push(false);
          case OP_GET_GLOBAL:
            final name = readString(frame);
            final getter = globals[name]?.getter;
            if (getter == null) {
              throw EvalRuntimeError("Undefined getter for '$name'.");
            }
            push(getter());
          case OP_SET_GLOBAL:
            final name = readString(frame);
            final setter = globals[name]?.setter;
            if (setter == null) {
              throw EvalRuntimeError("Undefined setter for '$name'.");
            }
            setter(peek());
          case OP_DEFINE_GLOBAL:
            final name = readString(frame);
            final property = EvalProperty.variable(pop());
            assert(globals[name] == null, name);
            globals[name] = property;
          case OP_GET_LOCAL:
            final slot = readCode(frame);
            push(stack[frame.slot + slot]);
          case OP_SET_LOCAL:
            final slot = readCode(frame);
            stack[frame.slot + slot] = peek();
          case OP_JUMP:
            final offset = readCode(frame);
            frame.ip += offset;
          case OP_JUMP_IF_NULL:
            final offset = readCode(frame);
            if (peek() == null) frame.ip += offset;
          case OP_JUMP_IF_FALSE:
            final offset = readCode(frame);
            if (!peek()) frame.ip += offset;
          case OP_CALL:
            final arguments = pop() as ObjArguments;
            final callee = peek();
            if (callee is Function) {
              push(Function.apply(pop(), arguments.positional, arguments.named));
            } else {
              callValue(callee, arguments.forEach(callee, push));
            }
            frame = frames.last;
          case OP_CLOSURE:
            final function = readConstant(frame) as ObjFunction;
            final closure = ObjClosure(function);
            push(closure);
            for (var i = 0; i < closure.function.upvalueCount; i++) {
              final isLocal = readCode(frame);
              final index = readCode(frame);
              if (isLocal == 1) {
                closure.upvalues.add(captureUpvalue(frame.slot + index));
              } else {
                closure.upvalues.add(frame.closure.upvalues[index]);
              }
            }
          case OP_GET_UPVALUE:
            final slot = readCode(frame);
            final upvalue = frame.closure.upvalues[slot];
            push(upvalue.get());
          case OP_SET_UPVALUE:
            final slot = readCode(frame);
            final upvalue = frame.closure.upvalues[slot];
            upvalue.set(peek());
          case OP_CLOSE_UPVALUE:
            closeUpvalues(stack.size - 1);
            pop();
          case OP_CLOSE_UPVALUES:
            closeUpvalues(frame.slot + readCode(frame));
          case OP_CLASS:
            final name = readString(frame);
            push(ObjClass(name, isTypeCheckSupported: readCode(frame) == 1));
          case OP_GET_PROPERTY:
            final instance = pop();
            final name = readString(frame);
            final getter = getInstanceGetter(instance, name);
            if (getter == null) {
              throw EvalRuntimeError("Undefined getter for '$name'.");
            }
            push(getter(instance));
          case OP_SET_PROPERTY:
            final value = pop();
            final instance = pop();
            final name = readString(frame);
            final setter = getInstanceSetter(instance, name);
            if (setter == null) {
              throw EvalRuntimeError("Undefined setter for '$name'.");
            }
            push(value);
            setter(instance, value);
          case OP_INHERIT:
            final subclass = pop() as ObjClass;
            final superclass = peek();
            if (superclass is! ObjClass) {
              throw EvalRuntimeError('Superclass must be a class.');
            }
            subclass.superclass = superclass;
            subclass.isTypeCheckSupported = subclass.isTypeCheckSupported && superclass.isTypeCheckSupported;
            subclass.props.addAll(superclass.props);
            subclass.initializers.addAll(superclass.initializers);
          case OP_GET_SUPER:
            final name = readString(frame);
            final superclass = pop() as ObjClass;
            final instance = pop() as ObjInstance;
            final getter = superclass.props[name]?.getter;
            if (getter == null) {
              throw EvalRuntimeError("Undefined getter '$name' in superclass '${superclass.name}'.");
            }
            push(getter(instance));
          case OP_SET_SUPER:
            final name = readString(frame);
            final value = pop();
            final superclass = pop() as ObjClass;
            final instance = pop() as ObjInstance;
            final setter = superclass.props[name]?.setter;
            if (setter == null) {
              throw EvalRuntimeError("Undefined setter '$name' in superclass '${superclass.name}'.");
            }
            push(value);
            setter(instance, value);
          case OP_PEEK:
            final distance = readCode(frame);
            push(peek(distance));
          case OP_ROTATE:
            final distance = readCode(frame);
            final last = stack.size - 1;
            final first = last - distance;
            final value = stack[last];
            for (var i = last; i > first; i--) {
              stack[i] = stack[i - 1];
            }
            stack[first] = value;
          case OP_DEFINE_GLOBAL_GETTER:
            final name = readString(frame);
            final closure = pop() as ObjClosure;
            globals[name] = EvalProperty.getter(() {
              push(closure);
              call(closure, 0);
              frame = frames.last;
              return pop();
            }, globals[name]);
          case OP_DEFINE_GLOBAL_SETTER:
            final name = readString(frame);
            final closure = pop() as ObjClosure;
            globals[name] = EvalProperty.setter((value) {
              push(closure);
              push(value);
              call(closure, 1);
              frame = frames.last..hasReturn = false;
            }, globals[name]);
          case OP_CLASS_FIELD:
            final name = readString(frame);
            final clazz = peek() as ObjClass;
            final fieldName = '${clazz.name}.$name';
            final property = EvalProperty.field(fieldName);
            // 限定名初始化声明类自己的字段，公开名保持虚拟属性访问
            clazz.props[fieldName] = property;
            clazz.props[name] = property;
          case OP_CLASS_INITIALIZER:
            final initializer = pop() as ObjClosure;
            (peek() as ObjClass).initializers.add(initializer);
          case OP_CLASS_GETTER:
            final name = readString(frame);
            final closure = pop() as ObjClosure;
            final props = (peek() as ObjClass).props;
            props[name] = EvalProperty.getter((instance) {
              push(instance);
              call(closure, 0);
              frame = frames.last;
              return pop();
            }, props[name]);
          case OP_CLASS_SETTER:
            final name = readString(frame);
            final closure = pop() as ObjClosure;
            final props = (peek() as ObjClass).props;
            props[name] = EvalProperty.setter((instance, value) {
              push(instance);
              push(value);
              call(closure, 1);
              frame = frames.last..hasReturn = false;
            }, props[name]);
          case OP_CLASS_METHOD:
            final name = readString(frame);
            final method = pop();
            final clazz = peek() as ObjClass;
            clazz.props[name] = EvalProperty.method(method);
          case OP_CONCAT_STRING:
            final length = readCode(frame);
            final result = stack.sublist(stack.size - length).join();
            stack.removeRange(stack.size - length, stack.size);
            push(result);
          case OP_PARAMETER_POSITIONAL:
            final name = readString(frame);
            push(ObjParameter(name, isPositional: true));
          case OP_PARAMETER_NAMED:
            final name = readString(frame);
            push(ObjParameter(name, isPositional: false));
          case OP_PARAMETER_DEFAULT:
            final defaultValue = pop();
            final parameter = peek() as ObjParameter;
            parameter.defaultValue = defaultValue;
          case OP_PARAMETER_LIST:
            final paramCount = readCode(frame);
            final closure = peek(paramCount) as ObjClosure;
            final parameters = stack.sublist(stack.size - paramCount);
            closure.parameters.addAll(parameters.cast<ObjParameter>());
            stack.removeRange(stack.size - paramCount, stack.size);
          case OP_ARGUMENT_LIST:
            final callee = peek();
            final delegate = callee is Function ? delegateArgument : ($) => $;
            push(ObjArguments(delegate));
          case OP_ARGUMENT_POSITIONAL:
            final value = pop();
            final arguments = peek() as ObjArguments;
            arguments.positional.add(arguments.delegate(value));
          case OP_ARGUMENT_NAMED:
            final value = pop();
            final name = pop() as String;
            final arguments = peek() as ObjArguments;
            arguments.named[Symbol(name)] = arguments.delegate(value);
          case OP_ASYNC:
            final closure = peek() as ObjClosure;
            closure.function.isAsync = true;
          case OP_AWAIT:
            final caller = continuation.caller;
            suspend(continuation, pop());
            if (caller == null) return;
            final future = completer.future;
            resume(caller);
            if (frames.isEmpty) return future;
            frame = frames.last;
            push(future);
          case OP_IS:
            final type = pop() as ObjTypeCheck;
            final value = pop() as Object?;
            push(typeMatcher(type)(value));
          case OP_AS:
            final type = pop() as ObjTypeCheck;
            final value = peek();
            if (!typeMatcher(type)(value)) {
              final actual = value is ObjInstance ? value.clazz.name : value.runtimeType.toString();
              throw EvalTypeError("Type '$actual' is not a subtype of type '$type' in type cast.");
            }
          case OP_OPERATOR_1:
            final operator = readString(frame);
            final getter = globals[operator]?.getter;
            if (getter == null) {
              throw EvalRuntimeError("Undefined unary operator getter for '$operator'.");
            }
            final operand = pop();
            push(getter(operand));
          case OP_OPERATOR_2:
            final operator = readString(frame);
            final getter = globals[operator]?.getter;
            if (getter == null) {
              throw EvalRuntimeError("Undefined binary operator getter for '$operator'.");
            }
            final rightOperand = pop();
            final leftOperand = pop();
            push(getter(leftOperand, rightOperand));
          case OP_OPERATOR_3:
            final operator = readString(frame);
            final getter = globals[operator]?.getter;
            if (getter == null) {
              throw EvalRuntimeError("Undefined ternary operator getter for '$operator'.");
            }
            final p3 = pop();
            final p2 = pop();
            final p1 = pop();
            push(getter(p1, p2, p3));
          case OP_SET:
            final type = pop() as String;
            withOrThrow(type, <E>() => push(<E>{}));
          case OP_MAP:
            final valueType = pop() as String;
            final keyType = pop() as String;
            withOrThrow(keyType, <K>() {
              withOrThrow(valueType, <V>() => push(<K, V>{}));
            });
          case OP_LIST:
            final type = pop() as String;
            withOrThrow(type, <E>() => push(<E>[]));
          case OP_COLLECTION_ADD:
            final distance = readCode(frame);
            final value = pop();
            peek(distance).add(value);
          case OP_COLLECTION_ADD_ENTRY:
            final value = pop();
            final key = pop();
            (peek() as Map)[key] = value;
          case OP_COLLECTION_CHECK_SPREAD:
            final isMap = readCode(frame) == 1;
            final source = pop();
            // 脚本实例沿用属性/方法协议，原生对象先检查展开源的集合类型
            if (source is ObjInstance) {
              push(source);
            } else if (isMap) {
              push(source as Map);
            } else {
              push(source as Iterable);
            }
          case OP_COLLECTION_ENTRY_CALLBACK:
            // 集合位于 forEach 方法和参数列表下方，回调逐项写入并检查键值类型
            final collection = peek(2) as Map;
            push((dynamic key, dynamic value) {
              collection[key] = value;
            });
          case OP_COLLECTION_BEGIN:
            final slot = frame.slot + readCode(frame);
            final collection = peek();
            // 集合可能已占据正在初始化变量的槽位，保留全部已有局部槽
            final temporaries = stack.sublist(slot);
            stack.removeRange(slot, stack.size);
            push(temporaries);
            push(collection);
          case OP_COLLECTION_END:
            // 原集合引用仍在保留的局部槽或暂存操作数中
            pop();
            final temporaries = pop() as List;
            temporaries.forEach(push);
          case OP_THROW:
            throw pop();
          case OP_RETHROW:
            ObjTrying handler = trying!;
            for (var depth = readCode(frame); depth > 0; depth--) {
              handler = handler.enclosing!;
            }
            Error.throwWithStackTrace(handler.error, handler.stackTrace);
          case OP_TRY_JUMP:
            final offset = readCode(frame);
            final start = frame.ip;
            final slot = stack.size;
            trying = ObjTrying(enclosing: trying, frame: frame, slot: slot, start: start, end: frame.ip += offset);
          case OP_CATCH_JUMP:
            final type = pop() as ObjTypeCheck;
            final offset = readCode(frame);
            final match = typeMatcher(type);
            final catching = ObjCatching(start: frame.ip, end: frame.ip += offset, match: match);
            trying!.catchings.add(catching);
          case OP_FINALLY_JUMP:
            final offset = readCode(frame);
            final finalization = ObjFinally(start: frame.ip, end: frame.ip + offset + 2);
            trying!.finalization = finalization;
            frame.ip += offset;
          case OP_TRY_END:
            exit = ObjJump(frame, target: trying!.finalization!.end, slot: trying!.slot);
          case OP_FINALLY_END:
            exit = trying!.pendingExit!;
            trying = trying!.enclosing;
          case OP_UNWIND_JUMP:
            final slot = frame.slot + readCode(frame);
            final offset = readCode(frame);
            exit = ObjJump(frame, target: frame.ip + offset, slot: slot);
          default:
            throw EvalRuntimeError('Unknown instruction: $instruction.');
        }
      } catch (e, s) {
        error = null;
        exit = null;
        if (unwind(ObjThrow(e, s))) {
          frame = trying!.frame;
          continue;
        }
        closeUpvalues(0);
        stack.clear();
        frames.clear();
        trying = null;
        if (!isAsync) rethrow;
        completer.completeError(e, s);
        final caller = continuation.caller;
        if (caller == null) return;
        final future = completer.future;
        resume(caller);
        if (frames.isEmpty) return future;
        frame = frames.last;
        push(future);
      }
    }
  }

  @override
  dynamic apply(ObjBoundMethod bound, List<dynamic>? positionalArguments) {
    [bound.receiver, ...?positionalArguments].forEach(push);
    callValue(bound, positionalArguments?.length ?? 0);
    return execute();
  }

  @override
  dynamic interpret(ObjFunction function) {
    final closure = ObjClosure(function);
    push(closure);
    call(closure, 0);
    return execute();
  }
}
