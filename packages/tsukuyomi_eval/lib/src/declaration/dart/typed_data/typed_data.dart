library declaration.dart.typed_data;

import 'dart:typed_data';

import 'package:tsukuyomi_eval/src/property.dart';

DartClass get _$ByteBuffer => DartClass<ByteBuffer>(($) => '''
abstract final class ByteBuffer {
  // ${$.debug('lengthInBytes', ($, $$) => $.lengthInBytes)}
  int get lengthInBytes;

  // ${$.debug('asUint8List', ($, $$) => $.asUint8List)}
  Uint8List asUint8List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asInt8List', ($, $$) => $.asInt8List)}
  Int8List asInt8List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asUint8ClampedList', ($, $$) => $.asUint8ClampedList)}
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]);

  // ${$.debug('asUint16List', ($, $$) => $.asUint16List)}
  Uint16List asUint16List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asInt16List', ($, $$) => $.asInt16List)}
  Int16List asInt16List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asUint32List', ($, $$) => $.asUint32List)}
  Uint32List asUint32List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asInt32List', ($, $$) => $.asInt32List)}
  Int32List asInt32List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asUint64List', ($, $$) => $.asUint64List)}
  Uint64List asUint64List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asInt64List', ($, $$) => $.asInt64List)}
  Int64List asInt64List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asInt32x4List', ($, $$) => $.asInt32x4List)}
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asFloat32List', ($, $$) => $.asFloat32List)}
  Float32List asFloat32List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asFloat64List', ($, $$) => $.asFloat64List)}
  Float64List asFloat64List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asFloat32x4List', ($, $$) => $.asFloat32x4List)}
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asFloat64x2List', ($, $$) => $.asFloat64x2List)}
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]);

  // ${$.debug('asByteData', ($, $$) => $.asByteData)}
  ByteData asByteData([int offsetInBytes = 0, int? length]);
}
''');

DartClass get _$TypedData => DartClass<TypedData>(($) => '''
abstract final class TypedData {
  // ${$.debug('elementSizeInBytes', ($, $$) => $.elementSizeInBytes)}
  int get elementSizeInBytes;

  // ${$.debug('offsetInBytes', ($, $$) => $.offsetInBytes)}
  int get offsetInBytes;

  // ${$.debug('lengthInBytes', ($, $$) => $.lengthInBytes)}
  int get lengthInBytes;

  // ${$.debug('buffer', ($, $$) => $.buffer)}
  ByteBuffer get buffer;
}
''');

DartClass get _$$TypedIntList => DartClass<Int8List>(($) => '''
abstract final class _TypedIntList extends TypedData {
  // ${$.debug('+', ($, $$) => $ + $$)}
  List<int> operator +(List<int> other);
}
''');

DartClass get _$$TypedFloatList => DartClass<Float32List>(($) => '''
abstract final class _TypedFloatList extends TypedData {
  // ${$.debug('+', ($, $$) => $ + $$)}
  List<double> operator +(List<double> other);
}
''');

DartClass get _$Endian => DartClass<Endian>(($) => '''
final class Endian {
  const Endian._(bool littleEndian);

  // ${$.empty('Endian.big', () => Endian.big)}
  static const Endian big = Endian._(false);

  // ${$.empty('Endian.little', () => Endian.little)}
  static const Endian little = Endian._(true);

  // ${$.empty('Endian.host', () => Endian.host)}
  external static final Endian host;
}
''');

DartClass get _$ByteData => DartClass<ByteData>(($) => '''
abstract final class ByteData implements TypedData {
  // ${$.empty('ByteData.new', () => ByteData.new)}
  external factory ByteData(int length);

  // ${$.empty('ByteData.view', () => ByteData.view)}
  external factory ByteData.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('ByteData.sublistView', () => ByteData.sublistView)}
  external factory ByteData.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('getInt8', ($, $$) => $.getInt8)}
  int getInt8(int byteOffset);

  // ${$.debug('setInt8', ($, $$) => $.setInt8)}
  void setInt8(int byteOffset, int value);

  // ${$.debug('getUint8', ($, $$) => $.getUint8)}
  int getUint8(int byteOffset);

  // ${$.debug('setUint8', ($, $$) => $.setUint8)}
  void setUint8(int byteOffset, int value);

  // ${$.debug('getInt16', ($, $$) => $.getInt16)}
  int getInt16(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setInt16', ($, $$) => $.setInt16)}
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]);

  // ${$.debug('getUint16', ($, $$) => $.getUint16)}
  int getUint16(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setUint16', ($, $$) => $.setUint16)}
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]);

  // ${$.debug('getInt32', ($, $$) => $.getInt32)}
  int getInt32(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setInt32', ($, $$) => $.setInt32)}
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]);

  // ${$.debug('getUint32', ($, $$) => $.getUint32)}
  int getUint32(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setUint32', ($, $$) => $.setUint32)}
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]);

  // ${$.debug('getInt64', ($, $$) => $.getInt64)}
  int getInt64(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setInt64', ($, $$) => $.setInt64)}
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]);

  // ${$.debug('getUint64', ($, $$) => $.getUint64)}
  int getUint64(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setUint64', ($, $$) => $.setUint64)}
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]);

  // ${$.debug('getFloat32', ($, $$) => $.getFloat32)}
  double getFloat32(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setFloat32', ($, $$) => $.setFloat32)}
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]);

  // ${$.debug('getFloat64', ($, $$) => $.getFloat64)}
  double getFloat64(int byteOffset, [Endian endian = Endian.big]);

  // ${$.debug('setFloat64', ($, $$) => $.setFloat64)}
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]);
}
''');

DartClass get _$Int8List => DartClass<Int8List>(($) => '''
abstract final class Int8List implements List<int>, _TypedIntList {
  // ${$.empty('Int8List.new', () => Int8List.new)}
  external factory Int8List(int length);

  // ${$.empty('Int8List.fromList', () => Int8List.fromList)}
  external factory Int8List.fromList(List<int> elements);

  // ${$.empty('Int8List.view', () => Int8List.view)}
  external factory Int8List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Int8List.sublistView', () => Int8List.sublistView)}
  external factory Int8List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Int8List sublist(int start, [int? end]);

  // ${$.empty('Int8List.bytesPerElement', () => Int8List.bytesPerElement)}
  static const int bytesPerElement = 1;
}
''');

DartClass get _$Uint8List => DartClass<Uint8List>(($) => '''
abstract final class Uint8List implements List<int>, _TypedIntList {
  // ${$.empty('Uint8List.new', () => Uint8List.new)}
  external factory Uint8List(int length);

  // ${$.empty('Uint8List.fromList', () => Uint8List.fromList)}
  external factory Uint8List.fromList(List<int> elements);

  // ${$.empty('Uint8List.view', () => Uint8List.view)}
  external factory Uint8List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Uint8List.sublistView', () => Uint8List.sublistView)}
  external factory Uint8List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('+', ($, $$) => $ + $$)}
  List<int> operator +(List<int> other);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Uint8List sublist(int start, [int? end]);

  // ${$.empty('Uint8List.bytesPerElement', () => Uint8List.bytesPerElement)}
  static const int bytesPerElement = 1;
}
''');

DartClass get _$Uint8ClampedList => DartClass<Uint8ClampedList>(($) => '''
abstract final class Uint8ClampedList implements List<int>, _TypedIntList {
  // ${$.empty('Uint8ClampedList.new', () => Uint8ClampedList.new)}
  external factory Uint8ClampedList(int length);

  // ${$.empty('Uint8ClampedList.fromList', () => Uint8ClampedList.fromList)}
  external factory Uint8ClampedList.fromList(List<int> elements);

  // ${$.empty('Uint8ClampedList.view', () => Uint8ClampedList.view)}
  external factory Uint8ClampedList.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Uint8ClampedList.sublistView', () => Uint8ClampedList.sublistView)}
  external factory Uint8ClampedList.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Uint8ClampedList sublist(int start, [int? end]);

  // ${$.empty('Uint8ClampedList.bytesPerElement', () => Uint8ClampedList.bytesPerElement)}
  static const int bytesPerElement = 1;
}
''');

DartClass get _$Int16List => DartClass<Int16List>(($) => '''
abstract final class Int16List implements List<int>, _TypedIntList {
  // ${$.empty('Int16List.new', () => Int16List.new)}
  external factory Int16List(int length);

  // ${$.empty('Int16List.fromList', () => Int16List.fromList)}
  external factory Int16List.fromList(List<int> elements);

  // ${$.empty('Int16List.view', () => Int16List.view)}
  external factory Int16List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Int16List.sublistView', () => Int16List.sublistView)}
  external factory Int16List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Int16List sublist(int start, [int? end]);

  // ${$.empty('Int16List.bytesPerElement', () => Int16List.bytesPerElement)}
  static const int bytesPerElement = 2;
}
''');

DartClass get _$Uint16List => DartClass<Uint16List>(($) => '''
abstract final class Uint16List implements List<int>, _TypedIntList {
  // ${$.empty('Uint16List.new', () => Uint16List.new)}
  external factory Uint16List(int length);

  // ${$.empty('Uint16List.fromList', () => Uint16List.fromList)}
  external factory Uint16List.fromList(List<int> elements);

  // ${$.empty('Uint16List.view', () => Uint16List.view)}
  external factory Uint16List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Uint16List.sublistView', () => Uint16List.sublistView)}
  external factory Uint16List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Uint16List sublist(int start, [int? end]);

  // ${$.empty('Uint16List.bytesPerElement', () => Uint16List.bytesPerElement)}
  static const int bytesPerElement = 2;
}
''');

DartClass get _$Int32List => DartClass<Int32List>(($) => '''
abstract final class Int32List implements List<int>, _TypedIntList {
  // ${$.empty('Int32List.new', () => Int32List.new)}
  external factory Int32List(int length);

  // ${$.empty('Int32List.fromList', () => Int32List.fromList)}
  external factory Int32List.fromList(List<int> elements);

  // ${$.empty('Int32List.view', () => Int32List.view)}
  external factory Int32List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Int32List.sublistView', () => Int32List.sublistView)}
  external factory Int32List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Int32List sublist(int start, [int? end]);

  // ${$.empty('Int32List.bytesPerElement', () => Int32List.bytesPerElement)}
  static const int bytesPerElement = 4;
}
''');

DartClass get _$Uint32List => DartClass<Uint32List>(($) => '''
abstract final class Uint32List implements List<int>, _TypedIntList {
  // ${$.empty('Uint32List.new', () => Uint32List.new)}
  external factory Uint32List(int length);

  // ${$.empty('Uint32List.fromList', () => Uint32List.fromList)}
  external factory Uint32List.fromList(List<int> elements);

  // ${$.empty('Uint32List.view', () => Uint32List.view)}
  external factory Uint32List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Uint32List.sublistView', () => Uint32List.sublistView)}
  external factory Uint32List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Uint32List sublist(int start, [int? end]);

  // ${$.empty('Uint32List.bytesPerElement', () => Uint32List.bytesPerElement)}
  static const int bytesPerElement = 4;
}
''');

DartClass get _$Int64List => DartClass<Int64List>(($) => '''
abstract final class Int64List implements List<int>, _TypedIntList {
  // ${$.empty('Int64List.new', () => Int64List.new)}
  external factory Int64List(int length);

  // ${$.empty('Int64List.fromList', () => Int64List.fromList)}
  external factory Int64List.fromList(List<int> elements);

  // ${$.empty('Int64List.view', () => Int64List.view)}
  external factory Int64List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Int64List.sublistView', () => Int64List.sublistView)}
  external factory Int64List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Int64List sublist(int start, [int? end]);

  // ${$.empty('Int64List.bytesPerElement', () => Int64List.bytesPerElement)}
  static const int bytesPerElement = 8;
}
''');

DartClass get _$Uint64List => DartClass<Uint64List>(($) => '''
abstract final class Uint64List implements List<int>, _TypedIntList {
  // ${$.empty('Uint64List.new', () => Uint64List.new)}
  external factory Uint64List(int length);

  // ${$.empty('Uint64List.fromList', () => Uint64List.fromList)}
  external factory Uint64List.fromList(List<int> elements);

  // ${$.empty('Uint64List.view', () => Uint64List.view)}
  external factory Uint64List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Uint64List.sublistView', () => Uint64List.sublistView)}
  external factory Uint64List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Uint64List sublist(int start, [int? end]);

  // ${$.empty('Uint64List.bytesPerElement', () => Uint64List.bytesPerElement)}
  static const int bytesPerElement = 8;
}
''');

DartClass get _$Float32List => DartClass<Float32List>(($) => '''
abstract final class Float32List implements List<double>, _TypedFloatList {
  // ${$.empty('Float32List.new', () => Float32List.new)}
  external factory Float32List(int length);

  // ${$.empty('Float32List.fromList', () => Float32List.fromList)}
  external factory Float32List.fromList(List<double> elements);

  // ${$.empty('Float32List.view', () => Float32List.view)}
  external factory Float32List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Float32List.sublistView', () => Float32List.sublistView)}
  external factory Float32List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Float32List sublist(int start, [int? end]);

  // ${$.empty('Float32List.bytesPerElement', () => Float32List.bytesPerElement)}
  static const int bytesPerElement = 4;
}
''');

DartClass get _$Float64List => DartClass<Float64List>(($) => '''
abstract final class Float64List implements List<double>, _TypedFloatList {
  // ${$.empty('Float64List.new', () => Float64List.new)}
  external factory Float64List(int length);

  // ${$.empty('Float64List.fromList', () => Float64List.fromList)}
  external factory Float64List.fromList(List<double> elements);

  // ${$.empty('Float64List.view', () => Float64List.view)}
  external factory Float64List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Float64List.sublistView', () => Float64List.sublistView)}
  external factory Float64List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Float64List sublist(int start, [int? end]);

  // ${$.empty('Float64List.bytesPerElement', () => Float64List.bytesPerElement)}
  static const int bytesPerElement = 8;
}
''');

DartClass get _$Float32x4List => DartClass<Float32x4List>(($) => '''
abstract final class Float32x4List implements List<Float32x4>, TypedData {
  // ${$.empty('Float32x4List.new', () => Float32x4List.new)}
  external factory Float32x4List(int length);

  // ${$.empty('Float32x4List.fromList', () => Float32x4List.fromList)}
  external factory Float32x4List.fromList(List<Float32x4> elements);

  // ${$.empty('Float32x4List.view', () => Float32x4List.view)}
  external factory Float32x4List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Float32x4List.sublistView', () => Float32x4List.sublistView)}
  external factory Float32x4List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('+', ($, $$) => $ + $$)}
  List<Float32x4> operator +(List<Float32x4> other);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Float32x4List sublist(int start, [int? end]);

  // ${$.empty('Float32x4List.bytesPerElement', () => Float32x4List.bytesPerElement)}
  static const int bytesPerElement = 16;
}
''');

DartClass get _$Int32x4List => DartClass<Int32x4List>(($) => '''
abstract final class Int32x4List implements List<Int32x4>, TypedData {
  // ${$.empty('Int32x4List.new', () => Int32x4List.new)}
  external factory Int32x4List(int length);

  // ${$.empty('Int32x4List.fromList', () => Int32x4List.fromList)}
  external factory Int32x4List.fromList(List<Int32x4> elements);

  // ${$.empty('Int32x4List.view', () => Int32x4List.view)}
  external factory Int32x4List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Int32x4List.sublistView', () => Int32x4List.sublistView)}
  external factory Int32x4List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('+', ($, $$) => $ + $$)}
  List<Int32x4> operator +(List<Int32x4> other);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Int32x4List sublist(int start, [int? end]);

  // ${$.empty('Int32x4List.bytesPerElement', () => Int32x4List.bytesPerElement)}
  static const int bytesPerElement = 16;
}
''');

DartClass get _$Float64x2List => DartClass<Float64x2List>(($) => '''
abstract final class Float64x2List implements List<Float64x2>, TypedData {
  // ${$.empty('Float64x2List.new', () => Float64x2List.new)}
  external factory Float64x2List(int length);

  // ${$.empty('Float64x2List.fromList', () => Float64x2List.fromList)}
  external factory Float64x2List.fromList(List<Float64x2> elements);

  // ${$.debug('+', ($, $$) => $ + $$)}
  List<Float64x2> operator +(List<Float64x2> other);

  // ${$.empty('Float64x2List.view', () => Float64x2List.view)}
  external factory Float64x2List.view(ByteBuffer buffer, [int offsetInBytes = 0, int? length]);

  // ${$.empty('Float64x2List.sublistView', () => Float64x2List.sublistView)}
  external factory Float64x2List.sublistView(TypedData data, [int start = 0, int? end]);

  // ${$.debug('sublist', ($, $$) => $.sublist)}
  Float64x2List sublist(int start, [int? end]);

  // ${$.empty('Float64x2List.bytesPerElement', () => Float64x2List.bytesPerElement)}
  static const int bytesPerElement = 16;
}
''');

DartLibrary get dartTypedDataLibrary {
  return DartLibrary('dart:typed_data', path: 'typed_data/typed_data.dart', source: 'library dart.typed_data;', declarations: [
    _$ByteBuffer,
    _$TypedData,
    _$$TypedIntList,
    _$$TypedFloatList,
    _$Endian,
    _$ByteData,
    _$Int8List,
    _$Uint8List,
    _$Uint8ClampedList,
    _$Int16List,
    _$Uint16List,
    _$Int32List,
    _$Uint32List,
    _$Int64List,
    _$Uint64List,
    _$Float32List,
    _$Float64List,
    _$Float32x4List,
    _$Int32x4List,
    _$Float64x2List,
  ]);
}
