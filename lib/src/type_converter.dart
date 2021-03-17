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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:quiver/check.dart';
import 'package:sponge_client_dart/src/features/feature_converter.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:sponge_client_dart/src/util/validate.dart';
import 'package:sponge_client_dart/src/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';

import 'package:logging/logging.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_value.dart';

/// A type converter.
abstract class TypeConverter {
  static final Logger _logger = Logger('TypeConverter');
  final Map<DataTypeKind, UnitTypeConverter> _registry = {};

  FeatureConverter featureConverter;

  /// Marshals the [value] as [type].
  Future<dynamic> marshal<T, D extends DataType>(D type, T value) async {
    if (value == null) {
      return null;
    }

    checkNotNull(type, message: 'The type must not be null');

    if (type.annotated && value is AnnotatedValue) {
      return AnnotatedValue(
        value.value != null
            ? await getInternalUnitConverterByType(type)
                .marshal(this, type, value.value)
            : null,
        valueLabel: value.valueLabel,
        valueDescription: value.valueDescription,
        features: await FeaturesUtils.marshal(featureConverter, value.features),
        typeLabel: value.typeLabel,
        typeDescription: value.typeDescription,
      );
    }

    return await getInternalUnitConverterByType(type)
        .marshal(this, type, value);
  }

  /// Unmarshals the [value] as [type].
  Future<dynamic> unmarshal<D extends DataType>(D type, dynamic value) async {
    if (value == null) {
      return null;
    }

    checkNotNull(type, message: 'The type must not be null');

    // Handle a wrapped annotated value.
    if (type.annotated && SpongeClientUtils.isAnnotatedValueMap(value)) {
      var annotatedValue = AnnotatedValue.fromJson(value);
      if (annotatedValue.value != null) {
        annotatedValue.value = await getInternalUnitConverterByType(type)
            .unmarshal(this, type, annotatedValue.value);
      }

      annotatedValue.features = await FeaturesUtils.unmarshal(
          featureConverter, annotatedValue.features);

      return annotatedValue;
    }

    return await getInternalUnitConverterByType(type)
        .unmarshal(this, type, value);
  }

  /// Registers the unit type converter.
  void register(UnitTypeConverter unitConverter) {
    _logger.finest(
        'Registering ${unitConverter.typeKind} type converter: $unitConverter');
    _registry[unitConverter.typeKind] = unitConverter;
  }

  /// Registers the unit type converters.
  void registerAll(List<UnitTypeConverter> unitConverters) =>
      unitConverters.forEach(register);

  /// Unregisters a unit type converter for the [typeKind]. Returns the previously registered unit type converter.
  UnitTypeConverter unregister(DataTypeKind typeKind) =>
      _registry.remove(typeKind);

  UnitTypeConverter<T, D> getInternalUnitConverterByType<T, D extends DataType>(
          D type) =>
      getInternalUnitConverter(type.kind);

  UnitTypeConverter<T, D> getInternalUnitConverter<T, D extends DataType>(
          DataTypeKind typeKind) =>
      Validate.notNull(_registry[typeKind], 'Unsupported type $typeKind');
}

/// A default type converter.
class DefaultTypeConverter extends TypeConverter {
  DefaultTypeConverter() {
    // Register default unit converters.
    registerAll([
      AnyTypeUnitConverter(),
      BinaryTypeUnitConverter(),
      BooleanTypeUnitConverter(),
      DateTimeTypeUnitConverter(),
      DynamicTypeUnitConverter(),
      IntegerTypeUnitConverter(),
      ListTypeUnitConverter(),
      MapTypeUnitConverter(),
      NumberTypeUnitConverter(),
      ObjectTypeUnitConverter(),
      RecordTypeUnitConverter(),
      OutputStreamTypeUnitConverter(),
      InputStreamTypeUnitConverter(),
      StringTypeUnitConverter(),
      TypeTypeUnitConverter(),
      VoidTypeUnitConverter(),
    ]);
  }
}

/// An unit type converter. All implementations should be stateless because one instance is shared
/// by different invocations of [marshal] and [unmarshal] methods.
abstract class UnitTypeConverter<T, D extends DataType> {
  UnitTypeConverter(this.typeKind);

  /// The data type kind.
  final DataTypeKind typeKind;

  /// Marshals the [value] as [type].
  ///
  /// The [value] will never be null here.
  Future<dynamic> marshal(TypeConverter converter, D type, T value) async =>
      value;

  /// Unmarshals the [value] as [type].
  ///
  /// The [value] will never be null here.
  Future<dynamic> unmarshal(
          TypeConverter converter, D type, dynamic value) async =>
      value;
}

class AnyTypeUnitConverter extends UnitTypeConverter<dynamic, AnyType> {
  AnyTypeUnitConverter() : super(DataTypeKind.ANY);
}

class BinaryTypeUnitConverter extends UnitTypeConverter<Uint8List, BinaryType> {
  BinaryTypeUnitConverter() : super(DataTypeKind.BINARY);

  @override
  Future<dynamic> marshal(
          TypeConverter converter, BinaryType type, Uint8List value) async =>
      base64.encode(value);

  @override
  Future<Uint8List> unmarshal(
          TypeConverter converter, BinaryType type, dynamic value) async =>
      base64.decode(value);
}

class BooleanTypeUnitConverter extends UnitTypeConverter<bool, BooleanType> {
  BooleanTypeUnitConverter() : super(DataTypeKind.BOOLEAN);
}

class DateTimeTypeUnitConverter
    extends UnitTypeConverter<dynamic, DateTimeType> {
  DateTimeTypeUnitConverter() : super(DataTypeKind.DATE_TIME);

  @override
  Future<dynamic> marshal(
      TypeConverter converter, DateTimeType type, dynamic value) async {
    if (type.format != null) {
      return DateFormat(type.format).format(value as DateTime);
    }
    switch (type.dateTimeKind) {
      case DateTimeKind.DATE_TIME:
        return (value as DateTime).toIso8601String();
      case DateTimeKind.DATE_TIME_ZONE:
        return SpongeClientUtils.formatIsoDateTimeZone(value as TZDateTime);
      case DateTimeKind.DATE:
      case DateTimeKind.TIME:
        throw Exception(
            'The Dart implementation of ${type.dateTimeKind} requires format');
      case DateTimeKind.INSTANT:
        return marshalInstant(value);
    }

    throw Exception('Unsupported DateTime kind ${type.dateTimeKind}');
  }

  @override
  Future<dynamic> unmarshal(
      TypeConverter converter, DateTimeType type, dynamic value) async {
    var stringValue = value as String;
    switch (type.dateTimeKind) {
      case DateTimeKind.DATE_TIME:
        return type.format != null
            ? DateFormat(type.format).parse(stringValue)
            : DateTime.parse(stringValue);
      case DateTimeKind.DATE_TIME_ZONE:
        Validate.isTrue(type.format == null,
            'Format is not supported for the Dart implementation of ${type.dateTimeKind}');
        return SpongeClientUtils.parseIsoDateTimeZone(stringValue);
      case DateTimeKind.DATE:
      case DateTimeKind.TIME:
        Validate.isTrue(type.format != null,
            'The Dart implementation of ${type.dateTimeKind} requires format');
        return DateFormat(type.format).parse(stringValue);
      case DateTimeKind.INSTANT:
        // Formatter not used.
        return DateTime.parse(stringValue);
    }

    var result = DynamicValue.fromJson(value);
    result.value = await converter.unmarshal(result.type, result.value);
    return result;
  }

  static String marshalInstant(dynamic value) {
    // Formatter not used.
    return value != null ? (value as DateTime).toUtc().toIso8601String() : null;
  }
}

class DynamicTypeUnitConverter
    extends UnitTypeConverter<DynamicValue, DynamicType> {
  DynamicTypeUnitConverter() : super(DataTypeKind.DYNAMIC);

  @override
  Future<dynamic> marshal(TypeConverter converter, DynamicType type,
          DynamicValue value) async =>
      // Marshal the data type in the DynamicValue as well.
      DynamicValue(await converter.marshal(value.type, value.value),
              await converter.marshal(TypeType(), value.type))
          .toJson();

  @override
  Future<DynamicValue> unmarshal(
      TypeConverter converter, DynamicType type, dynamic value) async {
    var result = DynamicValue.fromJson(value);

    result.value = await converter.unmarshal(result.type, result.value);

    // Unmarshal the data type in the DynamicValue as well.
    result.type = await converter.unmarshal(TypeType(), result.type);

    return result;
  }
}

class IntegerTypeUnitConverter extends UnitTypeConverter<int, IntegerType> {
  IntegerTypeUnitConverter() : super(DataTypeKind.INTEGER);
}

class ListTypeUnitConverter extends UnitTypeConverter<List, ListType> {
  ListTypeUnitConverter() : super(DataTypeKind.LIST);

  @override
  Future<dynamic> marshal(
      TypeConverter converter, ListType type, List value) async {
    var result = [];
    for (var element in value) {
      result.add(await converter.marshal(type.elementType, element));
    }
    return result;
  }

  @override
  Future<List> unmarshal(
      TypeConverter converter, ListType type, dynamic value) async {
    var result = [];
    for (var element in (value as List)) {
      result.add(await converter.unmarshal(type.elementType, element));
    }
    return result;
  }
}

class MapTypeUnitConverter extends UnitTypeConverter<Map, MapType> {
  MapTypeUnitConverter() : super(DataTypeKind.MAP);

  @override
  Future<dynamic> marshal(
      TypeConverter converter, MapType type, Map value) async {
    var result = {};
    for (var entry in value.entries) {
      result[await converter.marshal(type.keyType, entry.key)] =
          await converter.marshal(type.valueType, entry.value);
    }
    return result;
  }

  @override
  Future<Map> unmarshal(
      TypeConverter converter, MapType type, dynamic value) async {
    var result = {};
    for (var entry in (value as Map).entries) {
      result[await converter.unmarshal(type.keyType, entry.key)] =
          await converter.unmarshal(type.valueType, entry.value);
    }
    return result;
  }
}

class NumberTypeUnitConverter extends UnitTypeConverter<num, NumberType> {
  NumberTypeUnitConverter() : super(DataTypeKind.NUMBER);
}

typedef ObjectTypeUnitConverterMapper = Future<dynamic> Function(
    TypeConverter converter, dynamic value);

/// Doesn't support reflection.
class ObjectTypeUnitConverter extends UnitTypeConverter<dynamic, ObjectType> {
  ObjectTypeUnitConverter([this.useTransparentIfNotFound = false])
      : super(DataTypeKind.OBJECT);

  bool useTransparentIfNotFound;

  final Map<String, ObjectTypeUnitConverterMapper> marshalers = {};
  final Map<String, ObjectTypeUnitConverterMapper> unmarshalers = {};

  @override
  Future<dynamic> marshal(
      TypeConverter converter, ObjectType type, dynamic value) async {
    // Use marshaler if registered.
    if (marshalers.containsKey(type.className)) {
      return await marshalers[type.className](converter, value);
    }

    // Reflection is not supported here.

    if (type.companionType != null) {
      return await converter.marshal(type.companionType, value);
    }

    if (!useTransparentIfNotFound) {
      throw Exception('Unsupported object type class name ${type.className}');
    }

    return value;
  }

  @override
  Future<dynamic> unmarshal(
      TypeConverter converter, ObjectType type, dynamic value) async {
    // Use unmarshaler if registered.
    if (unmarshalers.containsKey(type.className)) {
      return await unmarshalers[type.className](converter, value);
    }

    // Reflection is not supported here.

    if (type.companionType != null) {
      return await converter.unmarshal(type.companionType, value);
    }

    if (!useTransparentIfNotFound) {
      throw Exception('Unsupported object type class name ${type.className}');
    }

    return value;
  }

  void addMarshaler(String className, ObjectTypeUnitConverterMapper mapper) =>
      marshalers[className] = mapper;

  void addUnmarshaler(String className, ObjectTypeUnitConverterMapper mapper) =>
      unmarshalers[className] = mapper;
}

class RecordTypeUnitConverter
    extends UnitTypeConverter<Map<String, dynamic>, RecordType> {
  RecordTypeUnitConverter() : super(DataTypeKind.RECORD);

  @override
  Future<dynamic> marshal(TypeConverter converter, RecordType type,
      Map<String, dynamic> value) async {
    var fieldMap = _createFieldMap(type);

    var result = <String, dynamic>{};
    for (var entry in value.entries) {
      result[entry.key] = await converter.marshal(
          _getFieldType(fieldMap, type, entry.key), entry.value);
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> unmarshal(
      TypeConverter converter, RecordType type, dynamic value) async {
    var fieldMap = _createFieldMap(type);
    var result = <String, dynamic>{};
    for (var entry in (value as Map).entries) {
      result[entry.key] = await converter.unmarshal(
          _getFieldType(fieldMap, type, entry.key), entry.value);
    }
    return result;
  }

  DataType _getFieldType(
      Map<String, DataType> fieldMap, RecordType type, String fieldName) {
    Validate.isTrue(fieldMap.containsKey(fieldName),
        'Field $fieldName is not defined in the record type ${type.name ?? ""}');
    return fieldMap[fieldName];
  }

  Map<String, DataType> _createFieldMap(RecordType type) =>
      {for (var field in type.fields) field.name: field};
}

class OutputStreamTypeUnitConverter extends UnitTypeConverter<String, OutputStreamType> {
  OutputStreamTypeUnitConverter() : super(DataTypeKind.OUTPUT_STREAM);
}

class InputStreamTypeUnitConverter extends UnitTypeConverter<String, InputStreamType> {
  InputStreamTypeUnitConverter() : super(DataTypeKind.INPUT_STREAM);
}

class StringTypeUnitConverter extends UnitTypeConverter<String, StringType> {
  StringTypeUnitConverter() : super(DataTypeKind.STRING);
}

class TypeTypeUnitConverter extends UnitTypeConverter<DataType, TypeType> {
  TypeTypeUnitConverter() : super(DataTypeKind.TYPE);

  /// Note that the `value` is modified in this method.
  @override
  Future<dynamic> marshal(
      TypeConverter converter, TypeType type, DataType value) async {
    // It's very important to clone the instance because the copy will be modified.
    var result = value.clone();

    // Recursively marshal default values and features.
    for (var t in DataTypeUtils.getTypes(result)) {
      t.defaultValue = await converter.marshal(t, t.defaultValue);

      t.features =
          await FeaturesUtils.marshal(converter.featureConverter, t.features);

      await _marshalSpecificTypeProperties(converter, t);
    }

    return result;
  }

  @override
  Future<DataType> unmarshal(
      TypeConverter converter, TypeType type, dynamic value) async {
    var result = value is DataType ? value : DataType.fromJson(value);

    // Recursively unmarshal default values and features.
    for (var t in DataTypeUtils.getTypes(result)) {
      t.defaultValue = await converter.unmarshal(t, t.defaultValue);

      t.features =
          await FeaturesUtils.unmarshal(converter.featureConverter, t.features);

      await _unmarshalSpecificTypeProperties(converter, result);
    }

    return result;
  }

  Future<void> _marshalSpecificTypeProperties(
      TypeConverter converter, DataType value) async {
    if (value is DateTimeType) {
      value.minValue = await converter.marshal(value, value.minValue);
      value.maxValue = await converter.marshal(value, value.maxValue);
    }
  }

  Future<void> _unmarshalSpecificTypeProperties(
      TypeConverter converter, DataType result) async {
    if (result is DateTimeType) {
      result.minValue = await converter.unmarshal(result, result.minValue);
      result.maxValue = await converter.unmarshal(result, result.maxValue);
    }
  }
}

class VoidTypeUnitConverter extends UnitTypeConverter<void, VoidType> {
  VoidTypeUnitConverter() : super(DataTypeKind.VOID);
}
