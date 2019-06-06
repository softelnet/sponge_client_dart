// Copyright 2018 The Sponge authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

/// A data type kind.
enum DataTypeKind {
  ANY,
  BINARY,
  BOOLEAN,
  DATE_TIME,
  DYNAMIC,
  INTEGER,
  LIST,
  MAP,
  NUMBER,
  OBJECT,
  RECORD,
  STREAM,
  STRING,
  TYPE,
  VOID,
}

DataType _typeFromJson(Map<String, dynamic> json) {
  DataTypeKind kind = DataType.fromJsonDataTypeKind(json['kind']);
  switch (kind) {
    case DataTypeKind.ANY:
      return AnyType.fromJson(json);
    case DataTypeKind.BINARY:
      return BinaryType.fromJson(json);
    case DataTypeKind.BOOLEAN:
      return BooleanType.fromJson(json);
    case DataTypeKind.DATE_TIME:
      return DateTimeType.fromJson(json);
    case DataTypeKind.DYNAMIC:
      return DynamicType.fromJson(json);
    case DataTypeKind.INTEGER:
      return IntegerType.fromJson(json);
    case DataTypeKind.LIST:
      return ListType.fromJson(json);
    case DataTypeKind.MAP:
      return MapType.fromJson(json);
    case DataTypeKind.NUMBER:
      return NumberType.fromJson(json);
    case DataTypeKind.OBJECT:
      return ObjectType.fromJson(json);
    case DataTypeKind.RECORD:
      return RecordType.fromJson(json);
    case DataTypeKind.STREAM:
      return StreamType.fromJson(json);
    case DataTypeKind.STRING:
      return StringType.fromJson(json);
    case DataTypeKind.TYPE:
      return TypeType.fromJson(json);
    case DataTypeKind.VOID:
      return VoidType.fromJson(json);
  }

  throw Exception('Unsupported type kind $kind');
}

/// A data type. Used for example in action arguments metadata.
class DataType<T> {
  DataType(
    this.kind, {
    this.registeredType,
    this.name,
    this.label,
    this.description,
    this.annotated = false,
    this.format,
    this.defaultValue,
    this.nullable = false,
    Map<String, Object> features,
    this.optional = false,
    this.provided,
  }) : this.features = features ?? Map();

  /// The feature name for the format.
  static const String FEATURE_FORMAT = 'format';

  /// The data type kind.
  final DataTypeKind kind;

  /// The optional corresponding registered data type name.
  String registeredType;

  /// The data type location name.
  String name;

  /// The data type location label.
  String label;

  /// The data type location description.
  String description;

  /// Tells if a value of this type is annotated, i.e. wrapped by an instance of `AnnotatedValue`. Defaults to `false`.
  bool annotated;

  /// The format (optional).
  String format;

  /// The default value (optional).
  T defaultValue;

  /// Tells if a value of this type may be `null`. The default is that a value must not be `null`,
  /// i.e. it is not nullable.
  bool nullable;

  /// The data type features as a map of names to values.
  final Map<String, Object> features;

  /// The flag specifying if this type is optional. Defaults to `false`.
  bool optional;

  /// The provided value specification. Defaults to `null`.
  ProvidedMeta provided;

  /// The string value of the data type kind, e.g. `'LIST'`.
  String get kindValue => _getDataTypeKindValue(kind);

  factory DataType.fromJson(Map<String, dynamic> json) =>
      json != null ? _typeFromJson(json) : null;

  @protected
  static DataType fromJsonBase(DataType type, Map<String, dynamic> json) {
    type.registeredType = json['registeredType'];
    type.name = json['name'];
    type.label = json['label'];
    type.description = json['description'];
    type.annotated = json['annotated'] ?? type.annotated;
    type.format = json['format'];
    type.defaultValue = json['defaultValue'];
    type.nullable = json['nullable'] ?? type.nullable;
    (json['features'] as Map)
        ?.forEach((name, value) => type.features[name] = value);
    type.optional = json['optional'] ?? type.optional;
    type.provided = ProvidedMeta.fromJson(json['provided']);
    return type;
  }

  static DataTypeKind fromJsonDataTypeKind(String jsonDataTypeKind) {
    DataTypeKind kind = DataTypeKind.values.firstWhere(
        (k) => _getDataTypeKindValue(k) == jsonDataTypeKind,
        orElse: () => null);
    return Validate.notNull(kind, 'Unsupported type kind $jsonDataTypeKind');
  }

  static String _getDataTypeKindValue(DataTypeKind kind) =>
      kind.toString().split('.')[1];

  Map<String, dynamic> toJson() => {
        'kind': _getDataTypeKindValue(kind),
        'name': name,
        'label': label,
        'description': description,
        'annotated': annotated,
        'format': format,
        'defaultValue': defaultValue,
        'nullable': nullable,
        'features': features,
        'optional': optional,
        'provided': provided?.toJson(),
      };
}

/// A qualified data type.
class QualifiedDataType<T> {
  QualifiedDataType(this.path, this.type, {this.isRoot = true});

  /// The qualified name path. Can be `null` for the root type or a path that has at least one element unnamed.
  final String path;

  /// The type.
  final DataType<T> type;

  /// The flag that informs if this qualified type is a root.
  bool isRoot;

  QualifiedDataType<C> createChild<C>(DataType<C> childType) {
    String parentPath = path != null
        ? path + SpongeClientConstants.ATTRIBUTE_PATH_SEPARATOR
        : (isRoot ? '' : null);

    return QualifiedDataType(
        parentPath != null && childType.name != null
            ? parentPath + childType.name
            : null,
        childType,
        isRoot: false);
  }
}

abstract class CollectionType<T> extends DataType<T> {
  CollectionType(DataTypeKind kind) : super(kind);
}

/// An any type. It may be used in situations when type is not important.
class AnyType extends DataType<dynamic> {
  AnyType() : super(DataTypeKind.ANY);

  factory AnyType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(AnyType(), json);
}

/// A binary (byte array) type. Provides an optional property `mimeType`.
class BinaryType extends DataType<Uint8List> {
  BinaryType(this.mimeType) : super(DataTypeKind.BINARY);

  /// The feature name for the mimeType.
  static const String FEATURE_MIME_TYPE = 'mimeType';

  /// The binary data mime type.
  final String mimeType;

  factory BinaryType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(BinaryType(json['mimeType']), json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'mimeType': mimeType,
    });
}

/// A boolean type.
class BooleanType extends DataType<bool> {
  BooleanType() : super(DataTypeKind.BOOLEAN);

  factory BooleanType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(BooleanType(), json);
}

/// A date/time kind.
enum DateTimeKind {
  /// Represented by DateTime.
  DATE_TIME,

  /// Represented by TZDateTime or DateTime.
  DATE_TIME_ZONE,

  /// Represented by DateTime. Requires a format in the corresponding data type.
  DATE,

  /// Represented by DateTime. Requires a format in the corresponding data type.
  TIME,

  /// Represented by DateTime. A format in the corresponding data type is ignored.
  INSTANT
}

/// A date/time type.
class DateTimeType extends DataType<Uint8List> {
  DateTimeType(this.dateTimeKind) : super(DataTypeKind.DATE_TIME);

  /// The feature name for the dateTimeKind.
  static const String FEATURE_DATE_TIME_KIND = 'dateTimeKind';

  /// The date/time kind.
  final DateTimeKind dateTimeKind;

  factory DateTimeType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(
          DateTimeType(_fromJsonDateTimeKind(json['dateTimeKind'])), json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'dateTimeKind': _getDateTimeKindValue(dateTimeKind),
    });

  static DateTimeKind _fromJsonDateTimeKind(String jsonDateTimeKind) {
    DateTimeKind dateTimeKind = DateTimeKind.values.firstWhere(
        (k) => _getDateTimeKindValue(k) == jsonDateTimeKind,
        orElse: () => null);
    return Validate.notNull(
        dateTimeKind, 'Unsupported date/time kind $jsonDateTimeKind');
  }

  static String _getDateTimeKindValue(DateTimeKind dateTimeKind) =>
      dateTimeKind.toString().split('.')[1];
}

/// An dynamic type representing dynamically typed values. A value of this type has to be an instance of `DynamicValue`.
class DynamicType extends DataType<DynamicValue> {
  DynamicType() : super(DataTypeKind.DYNAMIC);

  factory DynamicType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(DynamicType(), json);
}

/// An integer type (commonly used integer type or long).
class IntegerType extends DataType<int> {
  IntegerType({
    this.minValue,
    this.maxValue,
    this.exclusiveMin = false,
    this.exclusiveMax = false,
  }) : super(DataTypeKind.INTEGER);

  /// The feature name for the exclusiveMax.
  static const String FEATURE_MIN_VALUE = 'minValue';

  /// The feature name for the maxValue.
  static const String FEATURE_MAX_VALUE = 'maxValue';

  /// The feature name for the exclusiveMin.
  static const String FEATURE_EXCLUSIVE_MIN = 'exclusiveMin';

  /// The feature name for the exclusiveMax.
  static const String FEATURE_EXCLUSIVE_MAX = 'exclusiveMax';

  /// The minimum value (optional).
  final int minValue;

  /// The maximum value (optional).
  final int maxValue;

  /// Tells if the minimum value should be exclusive. Defaults to `false`.
  final bool exclusiveMin;

  /// Tells if the maximum value should be exclusive. Defaults to `false`.
  final bool exclusiveMax;

  factory IntegerType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(
          IntegerType(
            minValue: json['minValue'],
            maxValue: json['maxValue'],
            exclusiveMin: json['exclusiveMin'],
            exclusiveMax: json['exclusiveMax'],
          ),
          json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'minValue': minValue,
      'maxValue': maxValue,
      'exclusiveMin': exclusiveMin,
      'exclusiveMax': exclusiveMax,
    });
}

/// A list type. This type requires an `elementType` parameter, which is is a type of list elements.
class ListType extends CollectionType<List> {
  ListType(
    this.elementType, {
    bool unique,
  })  : this.unique = unique ?? false,
        super(DataTypeKind.LIST);

  /// The list element type.
  final DataType elementType;

  final bool unique;

  factory ListType.fromJson(Map<String, dynamic> json) => DataType.fromJsonBase(
      ListType(
        DataType.fromJson(json['elementType']),
        unique: json['unique'],
      ),
      json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'elementType': elementType.toJson(),
      'unique': unique,
    });
}

/// A map type. This type requires two parameters: a type of keys and a type of values in the map.
class MapType extends CollectionType<Map> {
  MapType(this.keyType, this.valueType) : super(DataTypeKind.MAP);

  /// The map key type.
  final DataType keyType;

  /// The map value type.
  final DataType valueType;

  factory MapType.fromJson(Map<String, dynamic> json) => DataType.fromJsonBase(
      MapType(DataType.fromJson(json['keyType']),
          DataType.fromJson(json['valueType'])),
      json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'keyType': keyType.toJson(),
      'valueType': valueType.toJson(),
    });
}

/// A number type, that include both integer and floating-point numbers.
class NumberType extends DataType<num> {
  NumberType({
    this.minValue,
    this.maxValue,
    this.exclusiveMin = false,
    this.exclusiveMax = false,
  }) : super(DataTypeKind.NUMBER);

  /// The feature name for the exclusiveMax.
  static const String FEATURE_MIN_VALUE = 'minValue';

  /// The feature name for the maxValue.
  static const String FEATURE_MAX_VALUE = 'maxValue';

  /// The feature name for the exclusiveMin.
  static const String FEATURE_EXCLUSIVE_MIN = 'exclusiveMin';

  /// The feature name for the exclusiveMax.
  static const String FEATURE_EXCLUSIVE_MAX = 'exclusiveMax';

  /// The minimum value (optional).
  final double minValue;

  /// The maximum value (optional).
  final double maxValue;

  /// Tells if the minimum value should be exclusive. Defaults to `false`.
  final bool exclusiveMin;

  /// Tells if the maximum value should be exclusive. Defaults to `false`.
  final bool exclusiveMax;

  factory NumberType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(
          NumberType(
            minValue: json['minValue'],
            maxValue: json['maxValue'],
            exclusiveMin: json['exclusiveMin'],
            exclusiveMax: json['exclusiveMax'],
          ),
          json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'minValue': minValue,
      'maxValue': maxValue,
      'exclusiveMin': exclusiveMin,
      'exclusiveMax': exclusiveMax,
    });
}

/// An object. This type requires a class name (typically a Java class name) as a constructor parameter.
class ObjectType extends DataType<dynamic> {
  ObjectType(this.className) : super(DataTypeKind.OBJECT);

  /// The feature name for the className.
  static const String FEATURE_CLASS_NAME = 'className';

  /// The class name.
  final String className;

  factory ObjectType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(ObjectType(json['className']), json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'className': className,
    });
}

/// A record type. This type requires a list of record field types. A value of this type has to be an instance of Map<String, dynamic> with
/// elements corresponding to the field names and values.
class RecordType extends DataType<Map<String, dynamic>> {
  RecordType(
    this.fields, {
    this.baseType,
    this.inheritationApplied = false,
  }) : super(DataTypeKind.RECORD) {
    _fieldsMap = Map.fromIterable(this.fields,
        key: (field) => field.name, value: (field) => field);
  }

  /// The field types.
  final List<DataType> fields;

  /// The base record type.
  final RecordType baseType;

  /// The flag that tells if inheritance has been applied to this type.
  final bool inheritationApplied;

  Map<String, DataType> _fieldsMap;

  factory RecordType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(
          RecordType(
            (json['fields'] as List)
                ?.map((arg) => DataType.fromJson(arg))
                ?.toList(),
            baseType: DataType.fromJson(json['baseType']),
            inheritationApplied: json['inheritationApplied'],
          ),
          json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'fields': fields?.map((field) => field.toJson())?.toList(),
    });

  DataType getFieldType(String fieldName) =>
      Validate.notNull(_fieldsMap[fieldName], 'Field $fieldName not found');
}

/// A stream type.
class StreamType extends DataType<dynamic> {
  StreamType() : super(DataTypeKind.STREAM);

  factory StreamType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(StreamType(), json);

  Map<String, dynamic> toJson() => super.toJson();
}

/// A string type.
class StringType extends DataType<String> {
  StringType({
    this.minLength,
    this.maxLength,
  }) : super(DataTypeKind.STRING);

  /// The feature name for the minLength.
  static const String FEATURE_MIN_LENGTH = 'minLength';

  /// The feature name for the maxLength.
  static const String FEATURE_MAX_LENGTH = 'maxLength';

  /// The minimum length (optional).
  final int minLength;

  /// The maximum length (optional).
  final int maxLength;

  factory StringType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(
          StringType(
            minLength: json['minLength'],
            maxLength: json['maxLength'],
          ),
          json);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'minLength': minLength,
      'maxLength': maxLength,
    });
}

/// A type representing a data type. A value of this type has to be an instance of `DataType`.
class TypeType extends DataType<DataType> {
  TypeType() : super(DataTypeKind.TYPE);

  factory TypeType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(TypeType(), json);
}

/// A void type that may be used to specify that an action returns no meaningful result.
class VoidType extends DataType<void> {
  VoidType() : super(DataTypeKind.VOID);

  factory VoidType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(VoidType(), json);
}
