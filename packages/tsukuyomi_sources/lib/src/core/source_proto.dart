import 'dart:core';

import 'package:fixnum/fixnum.dart' show Int64;
import 'package:meta/meta.dart';
import 'package:protobuf/protobuf.dart';

typedef SourceProtoFields = Map<String, SourceProtoField>;

class SourceProtoField {
  SourceProtoField.optionalBool(this.tagNumber) : type = PbFieldType.OB;

  SourceProtoField.optionalBytes(this.tagNumber) : type = PbFieldType.OY;

  SourceProtoField.optionalString(this.tagNumber) : type = PbFieldType.OS;

  SourceProtoField.optionalFloat(this.tagNumber) : type = PbFieldType.OF;

  SourceProtoField.optionalDouble(this.tagNumber) : type = PbFieldType.OD;

  // SourceProtoField.optionalEnum(this.tagNumber) : type = PbFieldType.OE;

  // SourceProtoField.optionalGroup(this.tagNumber) : type = PbFieldType.OG;

  SourceProtoField.optionalInt32(this.tagNumber) : type = PbFieldType.O3;

  SourceProtoField.optionalInt64(this.tagNumber) : type = PbFieldType.O6;

  SourceProtoField.optionalSInt32(this.tagNumber) : type = PbFieldType.OS3;

  SourceProtoField.optionalSInt64(this.tagNumber) : type = PbFieldType.OS6;

  SourceProtoField.optionalUint32(this.tagNumber) : type = PbFieldType.OU3;

  SourceProtoField.optionalUint64(this.tagNumber) : type = PbFieldType.OU6;

  SourceProtoField.optionalFixed32(this.tagNumber) : type = PbFieldType.OF3;

  SourceProtoField.optionalFixed64(this.tagNumber) : type = PbFieldType.OF6;

  SourceProtoField.optionalSFixed32(this.tagNumber) : type = PbFieldType.OSF3;

  SourceProtoField.optionalSFixed64(this.tagNumber) : type = PbFieldType.OSF6;

  SourceProtoField.optionalMessage(this.tagNumber, this._fields) : type = PbFieldType.OM;

  SourceProtoField.repeatedBool(this.tagNumber) : type = PbFieldType.PB;

  SourceProtoField.repeatedBytes(this.tagNumber) : type = PbFieldType.PY;

  SourceProtoField.repeatedString(this.tagNumber) : type = PbFieldType.PS;

  SourceProtoField.repeatedFloat(this.tagNumber) : type = PbFieldType.PF;

  SourceProtoField.repeatedDouble(this.tagNumber) : type = PbFieldType.PD;

  // SourceProtoField.repeatedEnum(this.tagNumber) : type = PbFieldType.PE;

  // SourceProtoField.repeatedGroup(this.tagNumber) : type = PbFieldType.PG;

  SourceProtoField.repeatedInt32(this.tagNumber) : type = PbFieldType.P3;

  SourceProtoField.repeatedInt64(this.tagNumber) : type = PbFieldType.P6;

  SourceProtoField.repeatedSInt32(this.tagNumber) : type = PbFieldType.PS3;

  SourceProtoField.repeatedSInt64(this.tagNumber) : type = PbFieldType.PS6;

  SourceProtoField.repeatedUint32(this.tagNumber) : type = PbFieldType.PU3;

  SourceProtoField.repeatedUint64(this.tagNumber) : type = PbFieldType.PU6;

  SourceProtoField.repeatedFixed32(this.tagNumber) : type = PbFieldType.PF3;

  SourceProtoField.repeatedFixed64(this.tagNumber) : type = PbFieldType.PF6;

  SourceProtoField.repeatedSFixed32(this.tagNumber) : type = PbFieldType.PSF3;

  SourceProtoField.repeatedSFixed64(this.tagNumber) : type = PbFieldType.PSF6;

  SourceProtoField.repeatedMessage(this.tagNumber, this._fields) : type = PbFieldType.PM;

  final int tagNumber;

  final int type;

  late final SourceProtoFields _fields;
}

class SourceProtoMessage extends GeneratedMessage {
  SourceProtoMessage(this.fields);

  SourceProtoMessage.fromBuffer(this.fields, List<int> buffer) {
    mergeFromBuffer(buffer);
  }

  final SourceProtoFields fields;

  @override
  GeneratedMessage clone() => SourceProtoMessage(fields)..mergeFromMessage(this);

  @override
  GeneratedMessage createEmptyInstance() => SourceProtoMessage(fields);

  @override
  late final BuilderInfo info_ = () {
    final info = BuilderInfo(null);
    for (final entry in fields.entries) {
      final name = entry.key;
      final field = entry.value;
      switch (field.type) {
        // optional
        case PbFieldType.OB:
        case PbFieldType.OY:
        case PbFieldType.OS:
        case PbFieldType.OF:
        case PbFieldType.OD:
        case PbFieldType.O3:
        case PbFieldType.OS3:
        case PbFieldType.OU3:
        case PbFieldType.OF3:
        case PbFieldType.OSF3:
          info.a(field.tagNumber, name, field.type);
        case PbFieldType.O6:
        case PbFieldType.OS6:
        case PbFieldType.OU6:
        case PbFieldType.OF6:
        case PbFieldType.OSF6:
          info.a(field.tagNumber, name, field.type, defaultOrMaker: Int64.ZERO);
        case PbFieldType.OM:
          info.aOM(field.tagNumber, name, subBuilder: () => SourceProtoMessage(field._fields));

        // repeated
        case PbFieldType.PB:
        case PbFieldType.PY:
        case PbFieldType.PS:
        case PbFieldType.PF:
        case PbFieldType.PD:
        case PbFieldType.P3:
        case PbFieldType.P6:
        case PbFieldType.PS3:
        case PbFieldType.PS6:
        case PbFieldType.PU3:
        case PbFieldType.PU6:
        case PbFieldType.PF3:
        case PbFieldType.PF6:
        case PbFieldType.PSF3:
        case PbFieldType.PSF6:
          info.p(field.tagNumber, name, field.type);
        case PbFieldType.PM:
          info.pc(field.tagNumber, name, field.type, subBuilder: () => SourceProtoMessage(field._fields));

        // unimplemented
        case PbFieldType.OE:
        case PbFieldType.OG:
        case PbFieldType.PE:
        case PbFieldType.PG:
        default:
          throw UnimplementedError('PbFieldType: ${field.type}');
      }
    }
    return info;
  }();

  @override
  @protected
  dynamic getField(int tagNumber) {
    return super.getField(tagNumber);
  }

  @override
  @protected
  dynamic getFieldOrNull(int tagNumber) {
    return super.getFieldOrNull(tagNumber);
  }

  @override
  @protected
  int? getTagNumber(String fieldName) {
    return super.getTagNumber(fieldName);
  }

  dynamic get(String fieldName) {
    return getOrNull(fieldName)!;
  }

  dynamic getOrNull(String fieldName) {
    final tagNumber = getTagNumber(fieldName);
    return tagNumber != null ? getField(tagNumber) : null;
  }
}
