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

class AnnotatedValue<T> {
  AnnotatedValue(
    this.value, {
    this.label,
    this.description,
    Map<String, Object> features,
  }) : this.features = features ?? {};

  /// The value.
  dynamic value;

  /// The optional value label.
  String label;

  /// The optional value description.
  String description;

  /// The annotated type features as a map of names to values.
  final Map<String, Object> features;

  factory AnnotatedValue.fromJson(Map<String, dynamic> json) => AnnotatedValue(
        json['value'],
        label: json['label'],
        description: json['description'],
        features: json['features'],
      );

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'description': description,
      'features': features,
    };
  }
}

/// A provided argument value and a possible value set.
class ArgProvidedValue<T> {
  ArgProvidedValue({
    this.value,
    this.valuePresent,
    this.annotatedValueSet,
  });

  /// The value.
  T value;

  /// If the value is present this flag is `true`.
  bool valuePresent;

  /// The possible value set with optional annotations. For example it may be a list of string values to choose from.
  /// If there is no value set for this argument, this property should is `null`.
  List<AnnotatedValue<T>> annotatedValueSet;

  /// The utility getter for the possible value set without labels.
  List<T> get valueSet => annotatedValueSet
      ?.map((annotatedValue) => annotatedValue.value)
      ?.toList();

  factory ArgProvidedValue.fromJson(Map<String, dynamic> json) => ArgProvidedValue(
        value: json['value'],
        valuePresent: json['valuePresent'],
        annotatedValueSet: (json['annotatedValueSet'] as List)
            ?.map((arg) => AnnotatedValue.fromJson(arg))
            ?.toList(),
      );
}
