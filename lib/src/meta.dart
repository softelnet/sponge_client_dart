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

/// An action argument metadata.
class ActionArgMeta {
  ActionArgMeta({
    @required this.name,
    @required this.type,
    this.displayName,
    this.description,
    this.optional = false,
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

  /// The argument label (the display name or the name).
  String get label => displayName ?? name;

  factory ActionArgMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ActionArgMeta(
            name: json['name'],
            type: DataType.fromJson(json['type']),
            displayName: json['displayName'],
            description: json['description'],
            optional: json['optional'],
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
  final List<ActionArgMeta> argsMeta;

  /// The action result metadata (optional).
  final ActionResultMeta resultMeta;

  /// The action label.
  String get label => '${knowledgeBase?.label}: ${displayName ?? name}';

  factory ActionMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ActionMeta(
            name: json['name'],
            displayName: json['displayName'],
            description: json['description'],
            knowledgeBase: KnowledgeBaseMeta.fromJson(json['knowledgeBase']),
            features: json['features'] ?? Map(),
            argsMeta: (json['argsMeta'] as List)
                ?.map((arg) => ActionArgMeta.fromJson(arg))
                ?.toList(),
            resultMeta: ActionResultMeta.fromJson(json['resultMeta']),
          )
        : null;
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
