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

class AnnotatedValue {
  AnnotatedValue(
    this.value, {
    Map<String, Object> features,
  }) : this.features = features ?? {};

  /// The value.
  dynamic value;

  /// The annotated type features as a map of names to values.
  final Map<String, Object> features;

  factory AnnotatedValue.fromJson(Map<String, dynamic> json) => AnnotatedValue(
        json['value'],
        features: json['features'],
      );

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'features': features,
    };
  }
}
