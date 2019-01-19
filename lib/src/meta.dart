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

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/type.dart';

/// A provided argument specification.
class ArgProvided {
  ArgProvided({
    this.value,
    this.valueSet,
    this.depends,
    this.readOnly = false,
    this.overwrite = false,
  });

  /// The flag specifying if this argument value is provided.
  bool value;

  /// The flag specifying if this argument value set is provided.
  bool valueSet;

  /// The list of attribute names that this provided attribute depends on.
  final List<String> depends;

  /// The flag specifying if this provided argument is read only.
  final bool readOnly;

  /// The flag specifying if the provided value of this argument should overwrite the value set in a client code.
  final bool overwrite;

  factory ArgProvided.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ArgProvided(
            value: json['value'],
            valueSet: json['valueSet'],
            depends: (json['depends'] as List)?.cast<String>()?.toList(),
            readOnly: json['readOnly'] ?? false,
            overwrite: json['overwrite'] ?? false,
          )
        : null;
  }
}

/// An action argument metadata.
class ArgMeta {
  ArgMeta({
    @required this.name,
    @required this.type,
    this.displayName,
    this.description,
    this.optional = false,
    this.provided,
  });

  /// The argument name.
  final String name;

  /// The argument data type.
  final DataType type;

  /// The argument display name.
  final String displayName;

  /// The argument description.
  final String description;

  /// The flag specifying if this argument is optional.
  final bool optional;

  /// The provided argument specification. Defaults to `null`.
  final ArgProvided provided;

  /// The argument label (the display name or the name).
  String get label => displayName ?? name;

  factory ArgMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ArgMeta(
            name: json['name'],
            type: DataType.fromJson(json['type']),
            displayName: json['displayName'],
            description: json['description'],
            optional: json['optional'] ?? false,
            provided: ArgProvided.fromJson(json['provided']),
          )
        : null;
  }
}

/// An action result metadata.
class ActionResultMeta {
  ActionResultMeta({
    @required this.type,
    this.displayName,
    this.description,
  });

  /// The result data type.
  final DataType type;

  /// The result display name.
  final String displayName;

  /// The result description.
  final String description;

  factory ActionResultMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ActionResultMeta(
            type: DataType.fromJson(json['type']),
            displayName: json['displayName'],
            description: json['description'],
          )
        : null;
  }
}

/// An action metadata.
class ActionMeta {
  ActionMeta({
    @required this.name,
    this.displayName,
    this.description,
    @required this.knowledgeBase,
    Map<String, Object> features,
    this.argsMeta,
    this.resultMeta,
  }) : this.features = features ?? Map();

  /// The action name.
  final String name;

  /// The action display name (optional).
  final String displayName;

  /// The action description (optional).
  final String description;

  /// The action knowledge base metadata.
  final KnowledgeBaseMeta knowledgeBase;

  /// The action features.
  final Map<String, Object> features;

  /// The action arguments metadata (optional).
  final List<ArgMeta> argsMeta;

  /// The action result metadata (optional).
  final ActionResultMeta resultMeta;

  /// The action label.
  String get label => displayName ?? name;

  factory ActionMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ActionMeta(
            name: json['name'],
            displayName: json['displayName'],
            description: json['description'],
            knowledgeBase: KnowledgeBaseMeta.fromJson(json['knowledgeBase']),
            features: json['features'] ?? Map(),
            argsMeta: (json['argsMeta'] as List)
                ?.map((arg) => ArgMeta.fromJson(arg))
                ?.toList(),
            resultMeta: ActionResultMeta.fromJson(json['resultMeta']),
          )
        : null;
  }

  ArgMeta getArgMeta(String argName) {
    ArgMeta argMeta = argsMeta.firstWhere((argMeta) => argMeta.name == argName,
        orElse: () => null);
    if (argMeta == null) {
      throw Exception('Metadata for argument $argName not found');
    }

    return argMeta;
  }
}

/// A knowledge base metadata.
class KnowledgeBaseMeta {
  KnowledgeBaseMeta({
    @required this.name,
    this.displayName,
    this.description,
    this.version,
  });

  /// The knowledge base name.
  final String name;

  /// The knowledge base display name (optional).
  final String displayName;

  /// The knowledge base description (optional).
  final String description;

  /// The knowledge base version (optional).
  int version;

  /// The knowledge base label (the display name or the name).
  String get label => displayName ?? name;

  factory KnowledgeBaseMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? KnowledgeBaseMeta(
            name: json['name'],
            displayName: json['displayName'],
            description: json['description'],
            version: json['version'],
          )
        : null;
  }
}

/// An argument value and a possible value set.
class ArgValue<T> {
  ArgValue(
      {this.value,
      this.valuePresent,
      this.valueSet,
      this.valueSetDisplayNames});

  /// The value.
  T value;

  /// If the value is present this flag is `true`.
  bool valuePresent;

  /// The possible value set. For example it may be a list of string values to choose from.
  /// If the value set is present is is not `null`.
  List<T> valueSet;

  /// The value set display names.
  List<String> valueSetDisplayNames;

  factory ArgValue.fromJson(Map<String, dynamic> json) => ArgValue(
        value: json['value'],
        valuePresent: json['valuePresent'],
        valueSet: json['valueSet'],
        valueSetDisplayNames: (json['valueSetDisplayNames'] as List)?.cast(),
      );
}
