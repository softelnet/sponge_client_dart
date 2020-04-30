// Copyright 2020 The Sponge authors.
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

import 'package:meta/meta.dart';

/// A sub-action argument substitution.
class SubActionArg {
  SubActionArg({
    @required this.target,
    @required this.source,
    Map<String, Object> features,
  }) : features = features ?? {};

  /// The target attribute name (i.e. the argument name of the sub-action).
  String target;

  /// The source attribute (i.e. the argument name of the parent action).
  String source;

  /// The argument substitution features.
  Map<String, Object> features;

  factory SubActionArg.fromJson(Map<String, dynamic> json) => json != null
      ? SubActionArg(
          target: json['target'],
          source: json['source'],
          features: Map.of(json['features'] as Map ?? {}),
        )
      : null;

  Map<String, dynamic> toJson() => {
        'target': target,
        'source': source,
        'features': features,
      };

  SubActionArg clone() => SubActionArg(
        target: target,
        source: source,
        features: features != null ? Map.of(features) : null,
      );
}

/// A sub-action result substitution.
class SubActionResult {
  SubActionResult({
    @required this.target,
    Map<String, Object> features,
  }) : features = features ?? {};

  /// The target attribute for the result (i.e. the argument name of the parent action).
  String target;

  /// The result substitution features.
  Map<String, Object> features;

  factory SubActionResult.fromJson(Map<String, dynamic> json) => json != null
      ? SubActionResult(
          target: json['target'],
          features: Map.of(json['features'] as Map ?? {}),
        )
      : null;

  Map<String, dynamic> toJson() => {
        'target': target,
        'features': features,
      };

  SubActionResult clone() => SubActionResult(
        target: target,
        features: features != null ? Map.of(features) : null,
      );
}

/// A sub-action specification.
class SubAction {
  SubAction({
    @required this.name,
    this.label,
    this.description,
    List<SubActionArg> args,
    this.result,
    Map<String, Object> features,
  })  : args = args ?? [],
        features = features ?? {};

  /// The sub-action name.
  String name;

  /// The sub-action label.
  String label;

  /// The sub-action description.
  String description;

  /// The sub-action argument substitutions.
  List<SubActionArg> args;

  /// The sub-action result substitution.
  SubActionResult result;

  /// The sub-action features.
  Map<String, Object> features;

  factory SubAction.fromJson(Map<String, dynamic> json) => json != null
      ? SubAction(
          name: json['name'],
          label: json['label'],
          description: json['description'],
          args: (json['args'] as List)
              ?.map((arg) => SubActionArg.fromJson(arg))
              ?.toList(),
          result: SubActionResult.fromJson(json['result']),
          features: Map.of(json['features'] as Map ?? {}),
        )
      : null;

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'description': description,
        'args': args?.map((arg) => arg.toJson())?.toList(),
        'result': result?.toJson(),
        'features': features,
      };

  SubAction clone() => SubAction(
        name: name,
        label: label,
        description: description,
        args: args?.map((arg) => arg.clone())?.toList(),
        result: result?.clone(),
        features: features != null ? Map.of(features) : null,
      );
}
