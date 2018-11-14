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
import 'package:quiver/check.dart';

/// A data type kind.
enum DataTypeKind {
  ACTION,
  ANY,
  BINARY,
  BOOLEAN,
  INTEGER,
  LIST,
  MAP,
  NUMBER,
  OBJECT,
  STRING,
  VOID,
}

DataType _typeFromJson(Map<String, dynamic> json) {
    DataTypeKind kind = DataType.fromJsonDataTypeKind(json['kind']);
    switch (kind) {
      case DataTypeKind.ACTION:
        return ActionType.fromJson(json);
      case DataTypeKind.ANY:
        return AnyType.fromJson(json);
      case DataTypeKind.BINARY:
        return BinaryType.fromJson(json);
      case DataTypeKind.BOOLEAN:
        return BooleanType.fromJson(json);
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
      case DataTypeKind.STRING:
        return StringType.fromJson(json);
      case DataTypeKind.VOID:
        return VoidType.fromJson(json);
    }

    throw Exception('Unsupported type kind $kind');
  }

/// A data type. Used for example in action arguments metadata.
class DataType<T> {
  DataType(
    this.kind, {
    this.nullable = false,
    this.format,
    this.defaultValue,
    Map<String, Object> features,
  }) : this.features = features ?? Map();

  /// The data type kind.
  final DataTypeKind kind;

  /// Tells if a value of this type may be `null`. The default is that a value must not be `null`,
  /// i.e. it is not nullable.
  bool nullable;

  /// The format (optional).
  String format;

  /// The default value (optional).
  T defaultValue;

  /// The data type features as a map of names to values.
  final Map<String, Object> features;

  /// The string value of the data type kind, e.g. `'LIST'`.
  String get kindValue => _getDataTypeKindValue(kind);

  factory DataType.fromJson(Map<String, dynamic> json) => _typeFromJson(json);

  @protected
  static DataType fromJsonBase(DataType type, Map<String, dynamic> json) {
    type.nullable = json['nullable'] ?? type.nullable;
    type.format = json['format'];
    type.defaultValue = json['defaultValue'];
    (json['features'] as Map)
        ?.forEach((name, value) => type.features[name] = value);

    return type;
  }

  static DataTypeKind fromJsonDataTypeKind(String jsonDataTypeKind) {
    DataTypeKind kind = DataTypeKind.values.firstWhere(
        (k) => _getDataTypeKindValue(k) == jsonDataTypeKind,
        orElse: () => null);
    return checkNotNull(kind,
        message: 'Unsupported type kind $jsonDataTypeKind');
  }

  static String _getDataTypeKindValue(DataTypeKind kind) =>
      kind.toString().split('.')[1];
}

/// A type that is a result of the given action, e.g. a list of string values. It allows using a result
/// of one action to be a type for another action argument or result.
class ActionType extends DataType<dynamic> {
  ActionType(this.actionName) : super(DataTypeKind.ACTION);

  /// The action name.
  final String actionName;

  factory ActionType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(ActionType(json['actionName']), json);
}

/// Any type. It may be used in situations when type is not important.
class AnyType extends DataType<dynamic> {
  AnyType() : super(DataTypeKind.ANY);

  factory AnyType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(AnyType(), json);
}

/// A binary (byte array) type. Provides an optional property `mimeType`.
class BinaryType extends DataType<Uint8List> {
  BinaryType(this.mimeType) : super(DataTypeKind.BINARY);

  /// The binary data mime type.
  final String mimeType;

  factory BinaryType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(BinaryType(json['mimeType']), json);
}

/// A boolean type.
class BooleanType extends DataType<bool> {
  BooleanType() : super(DataTypeKind.BOOLEAN);

  factory BooleanType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(BooleanType(), json);
}

/// An integer type (commonly used integer type or long).
class IntegerType extends DataType<int> {
  IntegerType({
    this.minValue,
    this.maxValue,
    this.exclusiveMin = false,
    this.exclusiveMax = false,
  }) : super(DataTypeKind.INTEGER);

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
}

/// A list type. This type requires an `elementType` parameter, which is is a type of list elements.
class ListType extends DataType<List> {
  ListType(this.elementType) : super(DataTypeKind.LIST);

  /// The list element type.
  final DataType elementType;

  factory ListType.fromJson(Map<String, dynamic> json) => DataType.fromJsonBase(
      ListType(DataType.fromJson(json['elementType'])), json);
}

/// A map type. This type requires two parameters: a type of keys and a type of values in the map.
class MapType extends DataType<Map> {
  MapType(this.keyType, this.valueType) : super(DataTypeKind.MAP);

  /// The map key type.
  final DataType keyType;

  /// The map value type.
  final DataType valueType;

  factory MapType.fromJson(Map<String, dynamic> json) => DataType.fromJsonBase(
      MapType(DataType.fromJson(json['keyType']),
          DataType.fromJson(json['valueType'])),
      json);
}

/// A number type, that include both integer and floating-point numbers.
class NumberType extends DataType<num> {
  NumberType({
    this.minValue,
    this.maxValue,
    this.exclusiveMin = false,
    this.exclusiveMax = false,
  }) : super(DataTypeKind.NUMBER);

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
}

/// An object. This type requires a class name (typically a Java class name) as a constructor parameter.
class ObjectType extends DataType<dynamic> {
  ObjectType(this.className) : super(DataTypeKind.OBJECT);

  /// The class name.
  final String className;

  factory ObjectType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(ObjectType(json['className']), json);
}

/// A string type.
class StringType extends DataType<String> {
  StringType({
    this.minLength,
    this.maxLength,
  }) : super(DataTypeKind.STRING);

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
}

/// A void type that may be used to specify that an action returns no meaningful result.
class VoidType extends DataType<Null> {
  VoidType() : super(DataTypeKind.VOID);

  factory VoidType.fromJson(Map<String, dynamic> json) =>
      DataType.fromJsonBase(VoidType(), json);
}
