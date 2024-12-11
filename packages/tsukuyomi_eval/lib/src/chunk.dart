abstract class Chunk {
  factory Chunk(String name) => _ChunkImpl(name);

  String get name;

  int get size;

  void addCode(int code, int? line);

  void updateCode(int index, int code);

  int addConstant(Object? constant);

  int codeAt(int index);

  int? lineAt(int index);

  Object? constantAt(int index);
}

class _ChunkImpl implements Chunk {
  _ChunkImpl(this._name);

  final String _name;
  final List<int> _codes = [];
  final List<int?> _lines = [];
  final List<Object?> _constants = [];

  @override
  String get name => _name;

  @override
  int get size => _codes.length;

  @override
  void addCode(int code, int? line) {
    _codes.add(code);
    _lines.add(line);
  }

  @override
  void updateCode(int index, int code) {
    assert(index < size);
    _codes[index] = code;
  }

  @override
  int addConstant(Object? constant) {
    _constants.add(constant);
    return _constants.length - 1;
  }

  @override
  int codeAt(int index) {
    assert(index < size);
    return _codes[index];
  }

  @override
  int? lineAt(int index) {
    assert(index < size);
    return _lines[index];
  }

  @override
  Object? constantAt(int index) {
    assert(index < size);
    return _constants[index];
  }
}
