// Copyright 2019 The Sponge authors.
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

import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/utils.dart';

class DataTypeUtils {
  static const THIS = 'this';

  static List<String> getPathElements(String path) {
    if (path == null || path == THIS) {
      return [];
    }

    return path.split(SpongeClientConstants.ATTRIBUTE_PATH_SEPARATOR);
  }

  // Bypasses annotated values. Doesn't support collections inside the path with the exception of the last path element.
  static dynamic getSubValue(dynamic value, String path,
          {bool returnAnnotated = false}) =>
      _getSubValueByPathElements(value, getPathElements(path),
          returnAnnotated: returnAnnotated);

  static dynamic _getSubValueByPathElements(
      dynamic value, List<String> pathElements,
      {bool returnAnnotated = false}) {
    pathElements.forEach((element) {
      value = value is AnnotatedValue ? (value as AnnotatedValue).value : value;
      if (value == null) {
        return null;
      }

      // Verify Record/Map type.
      Validate.isTrue(value is Map, 'The value path doesn\'t contain a record');
      value = (value as Map)[element];
    });

    if (!returnAnnotated) {
      value = value is AnnotatedValue ? (value as AnnotatedValue).value : value;
    }

    return value;
  }

  /// Supports sub-arguments and bypasses annotated values. The `value` has to a complex type.
  static void setSubValue(dynamic value, String path, dynamic subValue) {
    var elements = getPathElements(path);

    Validate.isTrue(
        elements.isNotEmpty, 'The $path is empty or points to the same value');
    if (elements.length > 1) {
      value = _getSubValueByPathElements(
          value, elements.sublist(0, elements.length - 1),
          returnAnnotated: false);
    }

    Validate.notNull(value, 'The parent value of $path is null');

    // Verify Record/Map type.
    Validate.isTrue(value is Map, 'The value of $path is not a record');

    (value as Map)[elements.last] = subValue;
  }

  static DataType getSubType(DataType type, String path) {
    var elements = getPathElements(path);
    var subType = type;
    elements.forEach((element) {
      Validate.notNull(subType, 'Argument $path not found');

      // Verify Record/Map type.
      Validate.isTrue(subType is RecordType,
          'The element ${subType.name ?? subType.kind} is not a record');

      subType = (subType as RecordType).getFieldType(element);
    });

    return subType;
  }

  static bool hasAllNotNullValuesSet(DataType type, dynamic value) {
    bool result = true;
    traverseValue(QualifiedDataType(null, type), value, (_qType, _value) {
      if (!_qType.type.nullable && _value == null) {
        result = false;
      }
    });

    return result;
  }

  /// Traverses the data type but only through record types.
  static void traverseDataType(
      QualifiedDataType qType, void onType(QualifiedDataType _),
      [bool namedOnly = true]) {
    if (namedOnly && qType.type.name == null) {
      return;
    }

    onType(qType);

    // Traverses only through record types.
    switch (qType.type.kind) {
      case DataTypeKind.RECORD:
        (qType.type as RecordType).fields?.forEach((field) =>
            traverseDataType(qType.createChild(field), onType, namedOnly));
        break;
      default:
        break;
    }
  }

  static void traverseValue(QualifiedDataType qType, dynamic value,
      void onValue(QualifiedDataType _qType, dynamic _value)) {
    onValue(qType, value);

    if (value == null) {
      return;
    }

    // Bypass an annotated value.
    if (value is AnnotatedValue) {
      value = value.value;
    }

    // Traverses only through record types.
    switch (qType.type.kind) {
      case DataTypeKind.RECORD:
        (value as Map<String, dynamic>).forEach(
            (String fieldName, dynamic fieldValue) => traverseValue(
                qType.createChild(
                    (qType.type as RecordType).getFieldType(fieldName)),
                fieldValue,
                onValue));
        break;
      default:
        break;
    }
  }
}
