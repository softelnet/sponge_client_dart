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

import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/exception.dart';
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
  static dynamic getSubValue(
    dynamic value,
    String path, {
    bool unwrapAnnotatedTarget = true,
    bool unwrapDynamicTarget = true,
  }) =>
      _getSubValueByPathElements(value, getPathElements(path),
          unwrapAnnotatedTarget: unwrapAnnotatedTarget,
          unwrapDynamicTarget: unwrapDynamicTarget);

  static dynamic _getSubValueByPathElements(
    dynamic value,
    List<String> pathElements, {
    bool unwrapAnnotatedTarget = true,
    bool unwrapDynamicTarget = true,
  }) {
    pathElements.forEach((element) {
      if (value is AnnotatedValue) {
        value = value.value;
      }
      if (value == null) {
        return null;
      }

      if (value is DynamicValue) {
        value = value.value;
      }
      // Verify Record/Map type.
      Validate.isTrue(value is Map,
          'The value path at \`$element\`doesn\'t contain a record/map');
      value = (value as Map)[element];
    });

    if (unwrapAnnotatedTarget) {
      value = value is AnnotatedValue ? (value as AnnotatedValue).value : value;
    }

    if (unwrapDynamicTarget) {
      value = value is DynamicValue ? (value as DynamicValue).value : value;
    }

    return value;
  }

  /// Supports sub-arguments and bypasses annotated values. The `value` has to be a complex type.
  static void setSubValue(dynamic value, String path, dynamic subValue) {
    Validate.isTrue(path != null && path.isNotEmpty, 'The path is empty');

    var elements = getPathElements(path);

    if (elements.length > 1) {
      value = _getSubValueByPathElements(
          value, elements.sublist(0, elements.length - 1),
          unwrapAnnotatedTarget: true, unwrapDynamicTarget: true);
    }

    Validate.notNull(value, 'The parent value of $path is null');

    // Verify Record/Map type.
    Validate.isTrue(value is Map, 'The value of $path is not a record/map');

    if (elements.isNotEmpty) {
      (value as Map)[elements.last] = subValue;
    } else {
      Validate.isTrue(
          subValue is Map, 'The new value of $path is not a record/map');
      (value as Map)
        ..clear()
        ..addAll(subValue);
    }
  }

  static DataType getSubType(DataType type, String path) {
    var elements = getPathElements(path);
    var subType = type;
    elements.forEach((element) {
      Validate.notNull(subType, 'Argument $path not found');

      if (subType is RecordType) {
        subType = (subType as RecordType).getFieldType(element);
      } else if (subType is ListType) {
        subType = (subType as ListType).elementType;
        Validate.isTrue(subType.name == element,
            'The list element type name ${subType.name} is different that $element');
      } else {
        throw SpongeClientException(
            'The element ${subType.name ?? subType.kind} is not a record or a list');
      }
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

  static bool isProvidedRead(DataType type) =>
      type.provided != null &&
      (type.provided.value ||
          type.provided.valueSet != null ||
          type.provided.elementValueSet);

  static bool isProvidedWrite(DataType type) =>
      type.provided != null && type.provided.submittable;

  static bool isValueNotSet(dynamic value) =>
      value == null || value is AnnotatedValue && value.value == null;

  static dynamic cloneValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is AnnotatedValue) {
      return AnnotatedValue.of(value);
    } else if (value is DynamicValue) {
      return DynamicValue.of(value);
    } else if (value is Uint8List) {
      return Uint8List.fromList(value);
    } else if (value is List) {
      var result = value.toList();
      for (int i = 0; i < result.length; i++) {
        result[i] = cloneValue(result[i]);
      }
      return result;
    } else if (value is Map<String, dynamic>) {
      Map<String, dynamic> result = {};
      for (var entry in value.entries) {
        result[entry.key] = cloneValue(entry.value);
      }
      return result;
    } else if (value is Map) {
      var result = Map.of(value);
      for (var key in result.keys) {
        result[key] = cloneValue(result[key]);
      }
      return result;
    }

    return value;
  }

  static bool equalsValue(dynamic a, dynamic b) {
    if (a == null && b == null) {
      return true;
    } else if (a == null || b == null) {
      return false;
    }

    if (a is AnnotatedValue) {
      return b is AnnotatedValue
          ? a == b && equalsValue(a.value, b.value)
          : false;
    } else if (a is DynamicValue) {
      return b is DynamicValue
          ? a == b && equalsValue(a.value, b.value)
          : false;
    } else if (a is List) {
      if (b is List && a.length == b.length) {
        for (int i = 0; i < a.length; i++) {
          if (!equalsValue(a[i], b[i])) {
            return false;
          }
        }

        return true;
      } else {
        return false;
      }
    } else if (a is Map) {
      // For maps, keys are not check for equality in any special way.
      if (b is Map && a.length == b.length) {
        if (!IterableEquality().equals(a.keys, b.keys)) {
          return false;
        }

        for (var key in a.keys) {
          if (!equalsValue(a[key], b[key])) {
            return false;
          }
        }

        return true;
      } else {
        return false;
      }
    }

    return a == b;
  }

  static bool isNull(dynamic value) =>
      value is AnnotatedValue ? value.value == null : value == null;
}
