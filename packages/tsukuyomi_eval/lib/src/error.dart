sealed class EvalError extends Error {
  EvalError(this._message);

  final String _message;

  abstract final String _name;

  @override
  String toString() => _message.isEmpty ? _name : '$_name: $_message';
}

class EvalCompileError extends EvalError {
  EvalCompileError(super.message);

  @override
  final String _name = 'EvalCompileError';
}

class EvalRuntimeError extends EvalError {
  EvalRuntimeError(super.message);

  @override
  final String _name = 'EvalRuntimeError';
}

class EvalPermissionError extends EvalError {
  EvalPermissionError(super.message);

  @override
  final String _name = 'EvalPermissionError';
}
