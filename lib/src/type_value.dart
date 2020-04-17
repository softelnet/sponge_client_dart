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

import 'package:equatable/equatable.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';

abstract class DecoratedValue {
  /// The value.
  dynamic value;
}

class AnnotatedValue with EquatableMixin implements DecoratedValue {
  AnnotatedValue(
    this.value, {
    this.valueLabel,
    this.valueDescription,
    Map<String, Object> features,
    this.typeLabel,
    this.typeDescription,
  }) : features = features ?? {};

  static const Set<String> FIELDS = {
    'value',
    'valueLabel',
    'valueDescription',
    'features',
    'typeLabel',
    'typeDescription'
  };

  /// The value.
  @override
  dynamic value;

  /// The optional value label.
  String valueLabel;

  /// The optional value description.
  String valueDescription;

  /// The annotated type features as a map of names to values.
  Map<String, Object> features;

  /// The optional type label.
  String typeLabel;

  /// The optional type description.
  String typeDescription;

  factory AnnotatedValue.of(AnnotatedValue other) => AnnotatedValue(
        DataTypeUtils.cloneValue(other.value),
        valueLabel: other.valueLabel,
        valueDescription: other.valueDescription,
        features: Map.from(other.features),
        typeLabel: other.typeLabel,
        typeDescription: other.typeDescription,
      );

  factory AnnotatedValue.fromJson(Map<String, dynamic> json) => AnnotatedValue(
        json['value'],
        valueLabel: json['valueLabel'],
        valueDescription: json['valueDescription'],
        features: json['features'] ?? {},
        typeLabel: json['typeLabel'],
        typeDescription: json['typeDescription'],
      );

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'valueLabel': valueLabel,
      'valueDescription': valueDescription,
      'features': features,
      'typeLabel': typeLabel,
      'typeDescription': typeDescription,
    };
  }

  void updateIfAbsent(AnnotatedValue source) {
    valueLabel ??= source.valueLabel;
    valueDescription ??= source.valueDescription;
    typeLabel ??= source.typeLabel;
    typeDescription ??= source.typeDescription;
    if (features.isEmpty) {
      features.addAll(source.features);
    }
  }

  @override
  List<Object> get props => [
        value,
        valueLabel,
        valueDescription,
        features,
        typeLabel,
        typeDescription
      ];

  @override
  String toString() => '$value';
}

/// A dynamic value that specifies its type.
class DynamicValue with EquatableMixin implements DecoratedValue {
  DynamicValue(this.value, this.type);

  /// The value.
  @override
  dynamic value;

  /// The value type.
  DataType type;

  factory DynamicValue.of(DynamicValue other) =>
      DynamicValue(DataTypeUtils.cloneValue(other.value), other.type);

  factory DynamicValue.fromJson(Map<String, dynamic> json) =>
      DynamicValue(json['value'], DataType.fromJson(json['type']));

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'type': type.toJson(),
    };
  }

  @override
  List<Object> get props => [value, type];
}

/// A provided object value and a possible value set.
class ProvidedValue<T> {
  ProvidedValue({
    this.value,
    this.valuePresent,
    this.annotatedValueSet,
    this.annotatedElementValueSet,
  });

  /// The value.
  T value;

  /// If the value is present this flag is `true`.
  bool valuePresent;

  /// The possible value set with optional annotations. For example it may be a list of string values to choose from.
  /// If there is no value set, this property should is `null`.
  List<AnnotatedValue> annotatedValueSet;

  /// The utility getter for the possible value set without labels.
  List<T> get valueSet => annotatedValueSet
      ?.map((annotatedValue) => annotatedValue.value)
      ?.toList();

  /// The possible element value set (with optional annotations) for a list type. For example it may be a list of string
  /// values to multiple choice. Applicable only for list types. If there is no element value set,
  /// this property is `null`.
  List<AnnotatedValue> annotatedElementValueSet;

  /// The utility getter for the possible element value set without labels.
  List get elementValueSet => annotatedElementValueSet
      ?.map((annotatedValue) => annotatedValue.value)
      ?.toList();

  factory ProvidedValue.fromJson(Map<String, dynamic> json) => ProvidedValue(
        value: json['value'],
        valuePresent: json['valuePresent'],
        annotatedValueSet: (json['annotatedValueSet'] as List)
            ?.map((arg) => AnnotatedValue.fromJson(arg))
            ?.toList(),
        annotatedElementValueSet: (json['annotatedElementValueSet'] as List)
            ?.map((arg) => AnnotatedValue.fromJson(arg))
            ?.toList(),
      );
}
