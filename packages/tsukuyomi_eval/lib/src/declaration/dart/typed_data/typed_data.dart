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
  ]);
}
