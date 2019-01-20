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

/// A labeled value.
class LabeledValue<T> {
  LabeledValue(this.value, this.label);

  /// The value.
  T value;

  /// The optional value label.
  String label;

  factory LabeledValue.fromJson(Map<String, dynamic> json) =>
      LabeledValue(json['value'], json['label']);
}

/// An argument value and a possible value set.
class ArgValue<T> {
  ArgValue({
    this.value,
    this.valuePresent,
    this.labeledValueSet,
  });

  /// The value.
  T value;

  /// If the value is present this flag is `true`.
  bool valuePresent;

  /// The possible value set with optional labels. For example it may be a list of string values to choose from.
  /// If there is no value set for this argument, this property should is `null`.
  List<LabeledValue<T>> labeledValueSet;

  /// The utility getter for the possible value set without labels. 
  List<T> get valueSet => labeledValueSet?.map((labeledValue) => labeledValue.value)?.toList();

  factory ArgValue.fromJson(Map<String, dynamic> json) => ArgValue(
        value: json['value'],
        valuePresent: json['valuePresent'],
        labeledValueSet: (json['labeledValueSet'] as List)
            ?.map((arg) => LabeledValue.fromJson(arg))
            ?.toList(),
      );
}

class AnnotatedValue {
  AnnotatedValue(
    this.value,
    Map<String, Object> features,
  ) : this.features = features ?? {};

  /// The value.
  dynamic value;

  /// The annotated type features as a map of names to values.
  final Map<String, Object> features;

  factory AnnotatedValue.fromJson(Map<String, dynamic> json) => AnnotatedValue(
        json['value'],
        json['features'],
      );

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'features': features,
    };
  }
}
