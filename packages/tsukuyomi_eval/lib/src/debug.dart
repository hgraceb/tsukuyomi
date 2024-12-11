import 'dart:io';

import 'chunk.dart';
import 'error.dart';
import 'object.dart';
import 'ops.dart';

const _padding = 23;

int? _line;

WeakReference<ObjContinuation>? _continuation;

int _simpleInstruction(String name, int offset) {
  stdout.write('$name\n');
  return offset + 1;
}

int _constantInstruction(String name, Chunk chunk, int offset) {
  final constant = chunk.codeAt(offset + 1);
  stdout.write('${name.padRight(_padding)} $constant ');
  stdout.write('\'${chunk.constantAt(constant)}\'\n');
  return offset + 2;
}

int _byteInstruction(String name, Chunk chunk, int offset) {
  final slot = chunk.codeAt(offset + 1);
  stdout.write('${name.padRight(_padding)} $slot\n');
  return offset + 2;
}

int _jumpInstruction(String name, Chunk chunk, int offset) {
  final jump = chunk.codeAt(offset + 1);
  stdout.write('${name.padRight(_padding)} $offset -> ');
  stdout.write('${offset + 2 + jump}\n');
  return offset + 2;
}

int _closureInstruction(String name, Chunk chunk, int offset) {
  offset++;
  final constant = chunk.codeAt(offset++);
  stdout.write('${name.padRight(_padding)} $constant ');
  stdout.write('${chunk.constantAt(constant)}\n');

  final function = chunk.constantAt(constant) as ObjFunction;
  for (int i = 0; i < function.upvalueCount; i++) {
    final isLast = i == function.upvalueCount - 1;
    final isLocal = chunk.codeAt(offset++) == 1;
    final index = chunk.codeAt(offset++);
    stdout.write('${(offset - 2).toString().padLeft(4, '0')} ');
    stdout.write('${(isLast ? '\\' : '+').padRight(_padding, '-')} ');
    stdout.write('${isLocal ? 'local' : 'upvalue'} $index\n');
  }

  return offset;
}

int disassembleInstruction(Chunk chunk, int offset) {
  final line = chunk.lineAt(offset);
  if (_line == line) {
    stdout.write('    | ');
  } else {
    _line = line;
    stdout.write('${(_line != null ? _line.toString() : 'X' * 4).padLeft(4, '0')}: ');
  }
  stdout.write('${offset.toString().padLeft(4, '0')} ');

  final instruction = chunk.codeAt(offset);
  return switch (instruction) {
    OP_RETURN => _simpleInstruction('OP_RETURN', offset),
    OP_CONSTANT => _constantInstruction('OP_CONSTANT', chunk, offset),
    OP_POP => _simpleInstruction('OP_POP', offset),
    OP_NULL => _simpleInstruction('OP_NULL', offset),
    OP_TRUE => _simpleInstruction('OP_TRUE', offset),
    OP_FALSE => _simpleInstruction('OP_FALSE', offset),
    OP_GET_GLOBAL => _constantInstruction('OP_GET_GLOBAL', chunk, offset),
    OP_SET_GLOBAL => _constantInstruction('OP_SET_GLOBAL', chunk, offset),
    OP_DEFINE_GLOBAL => _constantInstruction('OP_DEFINE_GLOBAL', chunk, offset),
    OP_GET_LOCAL => _byteInstruction('OP_GET_LOCAL', chunk, offset),
    OP_SET_LOCAL => _byteInstruction('OP_SET_LOCAL', chunk, offset),
    OP_JUMP => _jumpInstruction('OP_JUMP', chunk, offset),
    OP_JUMP_IF_NULL => _jumpInstruction('OP_JUMP_IF_NULL', chunk, offset),
    OP_JUMP_IF_FALSE => _jumpInstruction('OP_JUMP_IF_FALSE', chunk, offset),
    OP_CALL => _simpleInstruction('OP_CALL', offset),
    OP_CLOSURE => _closureInstruction('OP_CLOSURE', chunk, offset),
    OP_GET_UPVALUE => _byteInstruction('OP_GET_UPVALUE', chunk, offset),
    OP_SET_UPVALUE => _byteInstruction('OP_SET_UPVALUE', chunk, offset),
    OP_CLOSE_UPVALUE => _simpleInstruction('OP_CLOSE_UPVALUE', offset),
    OP_CLASS => _constantInstruction('OP_CLASS', chunk, offset),
    OP_GET_PROPERTY => _constantInstruction('OP_GET_PROPERTY', chunk, offset),
    OP_SET_PROPERTY => _constantInstruction('OP_SET_PROPERTY', chunk, offset),
    OP_INHERIT => _simpleInstruction('OP_INHERIT', offset),
    OP_GET_SUPER => _constantInstruction('OP_GET_SUPER', chunk, offset),
    OP_PEEK => _byteInstruction('OP_PEEK', chunk, offset),
    OP_DEFINE_GLOBAL_GETTER => _constantInstruction('OP_DEFINE_GLOBAL_GETTER', chunk, offset),
    OP_DEFINE_GLOBAL_SETTER => _constantInstruction('OP_DEFINE_GLOBAL_SETTER', chunk, offset),
    OP_CLASS_FIELD => _constantInstruction('OP_CLASS_FIELD', chunk, offset),
    OP_CLASS_GETTER => _constantInstruction('OP_CLASS_GETTER', chunk, offset),
    OP_CLASS_SETTER => _constantInstruction('OP_CLASS_SETTER', chunk, offset),
    OP_CLASS_METHOD => _constantInstruction('OP_CLASS_METHOD', chunk, offset),
    OP_CONCAT_STRING => _byteInstruction('OP_CONCAT_STRING', chunk, offset),
    OP_PARAMETER_POSITIONAL => _constantInstruction('OP_PARAMETER_POSITIONAL', chunk, offset),
    OP_PARAMETER_NAMED => _constantInstruction('OP_PARAMETER_NAMED', chunk, offset),
    OP_PARAMETER_DEFAULT => _simpleInstruction('OP_PARAMETER_DEFAULT', offset),
    OP_PARAMETER_LIST => _byteInstruction('OP_PARAMETER_LIST', chunk, offset),
    OP_ARGUMENT_LIST => _simpleInstruction('OP_ARGUMENT_LIST', offset),
    OP_ARGUMENT_POSITIONAL => _simpleInstruction('OP_ARGUMENT_POSITIONAL', offset),
    OP_ARGUMENT_NAMED => _simpleInstruction('OP_ARGUMENT_NAMED', offset),
    OP_ASYNC => _simpleInstruction('OP_ASYNC', offset),
    OP_AWAIT => _simpleInstruction('OP_AWAIT', offset),
    OP_IS => _simpleInstruction('OP_IS', offset),
    OP_OPERATOR_1 => _constantInstruction('OP_OPERATOR_1', chunk, offset),
    OP_OPERATOR_2 => _constantInstruction('OP_OPERATOR_2', chunk, offset),
    OP_OPERATOR_3 => _constantInstruction('OP_OPERATOR_3', chunk, offset),
    OP_SET => _byteInstruction('OP_SET', chunk, offset),
    OP_MAP => _byteInstruction('OP_MAP', chunk, offset),
    OP_LIST => _byteInstruction('OP_LIST', chunk, offset),
    OP_THROW => _simpleInstruction('OP_THROW', offset),
    OP_RETHROW => _simpleInstruction('OP_RETHROW', offset),
    OP_TRY_JUMP => _jumpInstruction('OP_TRY_JUMP', chunk, offset),
    OP_CATCH_JUMP => _jumpInstruction('OP_CATCH_JUMP', chunk, offset),
    OP_FINALLY_JUMP => _jumpInstruction('OP_FINALLY_JUMP', chunk, offset),
    _ => throw EvalRuntimeError('Unknown instruction: $instruction.'),
  };
}

void disassembleChunk(Chunk chunk) {
  stdout.write('\n======= Chunk (${chunk.name}) =======\n');

  for (int offset = 0; offset < chunk.size;) {
    offset = disassembleInstruction(chunk, offset);
  }
}

void disassembleStack(ObjContinuation continuation) {
  final stack = continuation.stack;
  if (_continuation?.target != continuation) {
    _line = null;
    _continuation = WeakReference(continuation);
    stdout.write('\n======= Continuation (${continuation.hashCode}) =======\n');
  }
  stdout.write('    |      ${stack.isEmpty ? '[]' : ''}');
  for (final element in stack) {
    final quote = element is String ? "'" : '';
    String message = '$element';
    message = switch (element) {
      Function() when message.contains("'") => '<fn ${message.split("'")[1]}>',
      _ => message,
    };
    // 限制最大字符长度
    if (message.length >= 52) {
      message = '${message.substring(0, 24)}...${message.substring(message.length - 24, message.length)}';
    }
    // 替换所有换行字符
    stdout.write('[ $quote' '${message.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}' '$quote ]');
  }
  stdout.write('\n');
}
