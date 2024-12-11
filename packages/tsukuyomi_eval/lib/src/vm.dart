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

  Function delegateClosure(ObjContinuation continuation, ObjClosure closure) {
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
        resume(ObjContinuation());
        push(closure);
        if (count > 0) push($0 != $ ? $0 : parameters[0].getDefaultValue(function.name));
        if (count > 1) push($1 != $ ? $1 : parameters[1].getDefaultValue(function.name));
        call(closure, count);
        final result = execute();
        resume(continuation);
        return result as T;
      };
    });
  }

  dynamic delegateArgument(dynamic argument) {
    if (argument is! Obj) return argument;
    return switch (argument) {
      ObjClosure() => delegateClosure(continuation, argument),
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
      ObjInstance() => instance.clazz.props[name]?.getter,
      _ => globals['.$name']?.getter,
    };
  }

  Function? getInstanceSetter(Object? instance, String name) {
    assert(instance is! Obj || instance is ObjInstance);
    return switch (instance) {
      ObjInstance() => instance.clazz.props[name]?.setter,
      _ => globals['.$name']?.setter,
    };
  }

  ObjTrying? tryCatch(Object e, StackTrace s) {
    for (ObjTrying? trying = this.trying; trying != null; trying = trying.enclosing) {
      final ip = trying.frame.ip - 1;
      final index = frames.indexOf(trying.frame);
      final catching = trying.catchings.firstWhereOrNull((catching) => catching.match(e));
      if (ip <= trying.start || ip >= trying.end || index == -1 || catching == null) continue;
      closeUpvalues(trying.slot);
      frames.removeRange(index + 1, frames.size);
      stack.removeRange(trying.slot, stack.size);
      trying.frame.ip = catching.start;
      push(trying.error = e);
      push(s);
      return trying;
    }
    return null;
  }

  void resume(ObjContinuation continuation) {
    this.continuation = continuation;
  }

  void suspend(ObjContinuation continuation, dynamic value) async {
    continuation.caller = null;
    try {
      final result = await value;
      resume(continuation);
      push(result);
      execute();
    } catch (e, s) {
      resume(continuation);
      if (tryCatch(e, s) == null) rethrow;
      execute();
    }
  }

  dynamic execute() {
    CallFrame frame = frames.last;
    while (true) {
      if (debug) {
        disassembleStack(continuation);
        disassembleInstruction(frame.chunk, frame.ip);
      }

      final instruction = readCode(frame);
      try {
        switch (instruction) {
          case OP_RETURN:
            frames.pop();
            final result = pop();
            closeUpvalues(frame.slot);
            stack.removeRange(frame.slot, stack.size);

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
            final property = EvalProperty.variable(pop(), isStatic: true);
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
          case OP_CLASS:
            push(ObjClass(readString(frame)));
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
            subclass.props.addAll(superclass.props);
          case OP_GET_SUPER:
            final name = readString(frame);
            final superclass = pop() as ObjClass;
            final instance = pop() as ObjInstance;
            final getter = superclass.props[name]?.getter;
            if (getter == null) {
              throw EvalRuntimeError("Undefined getter '$name' in superclass '${superclass.name}'.");
            }
            push(getter(instance));
          case OP_PEEK:
            final distance = readCode(frame);
            push(peek(distance));
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
            final field = pop();
            final clazz = peek() as ObjClass;
            clazz.props[name] = EvalProperty.variable(field, isStatic: false);
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
            final type = pop() as String;
            final value = pop() as Object?;
            push(withOrThrow(type, <T>() => ($) => $ is T)(value));
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
            final length = readCode(frame);
            final params = stack.sublist(stack.size - length);
            stack.removeRange(stack.size - length, stack.size);
            final type = pop() as String;
            withOrThrow(type, <E>() => push(Set<E>.from(params)));
          case OP_MAP:
            final length = readCode(frame);
            final params = stack.sublist(stack.size - length * 2);
            stack.removeRange(stack.size - length * 2, stack.size);
            final valueType = pop() as String;
            final keyType = pop() as String;
            withOrThrow(keyType, <K>() {
              withOrThrow(valueType, <V>() {
                final keys = List<K>.generate(length, (i) => params[i * 2]);
                final values = List<V>.generate(length, (i) => params[i * 2 + 1]);
                push(Map.fromIterables(keys, values));
              });
            });
          case OP_LIST:
            final length = readCode(frame);
            final list = stack.sublist(stack.size - length);
            stack.removeRange(stack.size - length, stack.size);
            final type = pop() as String;
            withOrThrow(type, <E>() => push(List<E>.from(list)));
          case OP_THROW:
            throw pop();
          case OP_RETHROW:
            throw trying!.error;
          case OP_TRY_JUMP:
            final offset = readCode(frame);
            final start = frame.ip - 1;
            final slot = stack.size;
            final enclosing = trying != null && trying!.start <= start && start <= trying!.end ? trying : null;
            trying = ObjTrying(enclosing: enclosing, frame: frame, slot: slot, start: start, end: frame.ip += offset);
          case OP_CATCH_JUMP:
            final type = pop() as String;
            final offset = readCode(frame);
            final match = withOrThrow(type, <T>() => ($) => $ is T);
            final catching = ObjCatching(start: frame.ip, end: frame.ip += offset, match: match);
            trying!.catchings.add(catching);
          case OP_FINALLY_JUMP:
            final offset = readCode(frame);
            final finalization = ObjFinally(start: frame.ip, end: frame.ip += offset);
            trying!.finalization = finalization;
          default:
            throw EvalRuntimeError('Unknown instruction: $instruction.');
        }
      } catch (e, s) {
        final trying = tryCatch(e, s);
        if (trying == null) rethrow;
        frame = trying.frame;
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
