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
import 'package:sponge_client_dart/src/util/validate.dart';

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
          {bool returnAnnotatedTarget = false}) =>
      _getSubValueByPathElements(value, getPathElements(path),
          returnAnnotatedTarget: returnAnnotatedTarget);

  static dynamic _getSubValueByPathElements(
      dynamic value, List<String> pathElements,
      {bool returnAnnotatedTarget = false}) {
    pathElements.forEach((element) {
      value = value is AnnotatedValue ? (value as AnnotatedValue).value : value;
      if (value == null) {
        return null;
      }

      // Verify Record/Map type.
      Validate.isTrue(value is Map, 'The value path doesn\'t contain a record');
      value = (value as Map)[element];
    });

    if (!returnAnnotatedTarget) {
      value = value is AnnotatedValue ? (value as AnnotatedValue).value : value;
    }

    return value;
  }

  /// Supports sub-arguments and bypasses annotated values. The `value` has to be a complex type.
  static void setSubValue(dynamic value, String path, dynamic subValue) {
    var elements = getPathElements(path);

    Validate.isTrue(elements.isNotEmpty,
        'The path \'$path\' is empty or points to the same value');
    if (elements.length > 1) {
      value = _getSubValueByPathElements(
          value, elements.sublist(0, elements.length - 1),
          returnAnnotatedTarget: false);
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

    // TODO Traversing all data type tree is not necessary.
    traverseValue(QualifiedDataType(null, type), value, (_qType, _value) {
      if (!_qType.type.nullable && _value == null) {
        result = false;
      }
    });

    return result;
  }

  static bool hasSubType(DataType type, DataTypeKind subTypeKind) {
    bool result = false;

    // Traverses record and collection sub-types.
    traverseDataType(QualifiedDataType(null, type), (QualifiedDataType qType) {
      if (qType.type.kind == subTypeKind) {
        result = true;
      }
    }, namedOnly: false, traverseCollections: true);

    return result;
  }

  /// Traverses the data type but only through record types.
  static void traverseDataType(
    QualifiedDataType qType,
    void onType(QualifiedDataType _), {
    bool namedOnly = true,
    bool traverseCollections = false,
  }) {
    if (namedOnly && qType.type.name == null) {
      return;
    }

    onType(qType);

    List<QualifiedDataType> subTypes = [];

    switch (qType.type.kind) {
      case DataTypeKind.RECORD:
        (qType.type as RecordType)
            .fields
            ?.forEach((field) => subTypes.add(qType.createChild(field)));
        break;
      case DataTypeKind.LIST:
        if (traverseCollections) {
          subTypes.add(
              QualifiedDataType(null, (qType.type as ListType).elementType));
        }
        break;
      case DataTypeKind.MAP:
        if (traverseCollections) {
          subTypes
            ..add(QualifiedDataType(null, (qType.type as MapType).keyType))
            ..add(QualifiedDataType(null, (qType.type as MapType).valueType));
        }
        break;
      default:
        break;
    }

    subTypes.forEach((subType) => traverseDataType(subType, onType,
        namedOnly: namedOnly, traverseCollections: traverseCollections));
  }

  static dynamic traverseValue<T>(QualifiedDataType qType, dynamic value,
      dynamic onValue(QualifiedDataType _qType, dynamic _value)) {
    // OnValue may change the value.
    value = onValue(qType, value);

    if (value == null) {
      return value;
    }

    // Bypass an annotated value.
    AnnotatedValue annotatedValue;
    if (value is AnnotatedValue) {
      annotatedValue = value;
      value = value.value;
    }

    if (value != null) {
      // Traverses only through record types.
      switch (qType.type.kind) {
        case DataTypeKind.RECORD:
          var valueMap = value as Map<String, dynamic>;
          valueMap.forEach((String fieldName, dynamic fieldValue) {
            valueMap[fieldName] = traverseValue(
                qType.createChild(
                    (qType.type as RecordType).getFieldType(fieldName)),
                fieldValue,
                onValue);
          });
          break;
        default:
          break;
      }
    }

    // Reverse bypassing of an annotated value.
    if (annotatedValue != null) {
      annotatedValue.value = value;
      value = annotatedValue;
    }

    return value;
  }

  static P getFeatureOrProperty<P>(
      DataType type, dynamic value, String propertyName, P orElse()) {
    P property;
    if (value is AnnotatedValue) {
      property = value.features[propertyName];
    }

    return property ?? type.features[propertyName] ?? orElse();
  }
}
