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
import 'package:quiver/check.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/type.dart';

/// A value set metadata.
class ValueSetMeta {
  ValueSetMeta({this.limited = true});

  /// The flag specifying if the value set is limited only to the provided values. Defaults to `true`.
  bool limited = true;

  factory ValueSetMeta.fromJson(Map<String, dynamic> json) =>
      json != null ? ValueSetMeta(limited: json['limited']) : null;
}

/// A provided argument metadata.
class ArgProvidedMeta {
  ArgProvidedMeta({
    this.value,
    this.valueSet,
    this.dependencies,
    this.readOnly = false,
    this.overwrite = false,
  });

  /// The flag specifying if this argument value is provided.
  bool value;

  /// The metadata specifying if this argument value set is provided. Defaults to `null`.
  ValueSetMeta valueSet;

  /// The list of attribute names that this provided attribute depends on.
  final List<String> dependencies;

  /// The flag specifying if this provided argument is read only.
  final bool readOnly;

  /// The flag specifying if the provided value of this argument should overwrite the value set in a client code.
  final bool overwrite;

  bool get hasValueSet => valueSet != null;

  factory ArgProvidedMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ArgProvidedMeta(
            value: json['value'],
            valueSet: ValueSetMeta.fromJson(json['valueSet']),
            dependencies:
                (json['dependencies'] as List)?.cast<String>()?.toList(),
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
    this.label,
    this.description,
    this.optional = false,
    this.provided,
    Map<String, Object> features,
    List<ArgMeta> subArgs,
  })  : this.features = features ?? {},
        this.subArgs = subArgs ?? [];

  /// The argument name.
  final String name;

  /// The argument data type.
  DataType type;

  /// The argument label.
  final String label;

  /// The argument description.
  final String description;

  /// The flag specifying if this argument is optional.
  final bool optional;

  /// The provided argument specification. Defaults to `null`.
  final ArgProvidedMeta provided;

  /// The argument features.
  final Map<String, Object> features;

  /// The sub-arguments metadata. Defaults to an empty list.
  final List<ArgMeta> subArgs;

  factory ArgMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ArgMeta(
            name: json['name'],
            type: DataType.fromJson(json['type']),
            label: json['label'],
            description: json['description'],
            optional: json['optional'] ?? false,
            provided: ArgProvidedMeta.fromJson(json['provided']),
            features: json['features'] ?? {},
            subArgs: (json['subArgs'] as List)
                    ?.map((arg) => ArgMeta.fromJson(arg))
                    ?.toList() ??
                [],
          )
        : null;
  }
}

/// An action result metadata.
class ResultMeta {
  ResultMeta({
    @required this.type,
    this.label,
    this.description,
  });

  /// The result data type.
  DataType type;

  /// The result label.
  final String label;

  /// The result description.
  final String description;

  factory ResultMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ResultMeta(
            type: DataType.fromJson(json['type']),
            label: json['label'],
            description: json['description'],
          )
        : null;
  }
}

/// A processor qualified version.
class ProcessorQualifiedVersion {
  ProcessorQualifiedVersion(this.knowledgeBaseVersion, this.processorVersion);

  /// The optional knowledge base version.
  int knowledgeBaseVersion;

  /// The optional processor version.
  int processorVersion;

  factory ProcessorQualifiedVersion.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ProcessorQualifiedVersion(
            json['knowledgeBaseVersion'], json['processorVersion'])
        : null;
  }

  Map<String, dynamic> toJson() => {
        'knowledgeBaseVersion': knowledgeBaseVersion,
        'processorVersion': processorVersion,
      };

  @override
  String toString() =>
      (knowledgeBaseVersion != null ? '$knowledgeBaseVersion.' : '') +
      '$processorVersion';
}

/// A category metadata.
class CategoryMeta {
  CategoryMeta(
    this.name, {
    this.label,
    this.description,
  });

  /// The category name.
  String name;

  /// The category label.
  String label;

  /// The category description.
  String description;

  factory CategoryMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? CategoryMeta(
            json['name'],
            label: json['label'],
            description: json['description'],
          )
        : null;
  }
}

/// An action metadata.
class ActionMeta {
  ActionMeta({
    @required this.name,
    this.label,
    this.description,
    @required this.knowledgeBase,
    this.category,
    Map<String, Object> features,
    this.argsMeta,
    this.resultMeta,
    this.qualifiedVersion,
  }) : this.features = features ?? Map();

  /// The action name.
  final String name;

  /// The action label (optional).
  final String label;

  /// The action description (optional).
  final String description;

  /// The action knowledge base metadata.
  final KnowledgeBaseMeta knowledgeBase;

  /// The action category metadata.
  final CategoryMeta category;

  /// The action features.
  final Map<String, Object> features;

  /// The action arguments metadata (optional).
  final List<ArgMeta> argsMeta;

  /// The action result metadata (optional).
  final ResultMeta resultMeta;

  /// The action qualified version.
  ProcessorQualifiedVersion qualifiedVersion;

  factory ActionMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ActionMeta(
            name: json['name'],
            label: json['label'],
            description: json['description'],
            knowledgeBase: KnowledgeBaseMeta.fromJson(json['knowledgeBase']),
            category: CategoryMeta.fromJson(json['category']),
            features: json['features'] ?? {},
            argsMeta: (json['argsMeta'] as List)
                ?.map((arg) => ArgMeta.fromJson(arg))
                ?.toList(),
            resultMeta: ResultMeta.fromJson(json['resultMeta']),
            qualifiedVersion:
                ProcessorQualifiedVersion.fromJson(json['qualifiedVersion']),
          )
        : null;
  }

  String getArgName(int index) => getArgMetaByIndex(index).name;

  int getArgIndex(String argName) =>
      argsMeta.indexWhere((argMeta) => argMeta.name == argName);

  bool isSubArgName(String argName) => argName.contains(SpongeClientConstants.ACTION_SUB_ARG_SEPARATOR);

  /// Supports sub-arguments.
  ArgMeta getArgMeta(String argName) {
    var elements = argName.split(SpongeClientConstants.ACTION_SUB_ARG_SEPARATOR);
    var argMeta = argsMeta[getArgIndex(elements[0])];
    elements.skip(1).forEach((element) {
      // Verify Record/Map type.
      checkArgument(
          argMeta.type is RecordType ||
              argMeta.type is AnnotatedType &&
                  (argMeta.type as AnnotatedType).valueType is RecordType,
          message: 'The argument $argName doesn\'t containt a record');
      argMeta = argMeta.subArgs.firstWhere(
          (subArgMeta) => subArgMeta.name == element,
          orElse: () => null);
      checkNotNull(argMeta, message: 'Metadata for argument $argName not found');
          throw Exception('Metadata for argument $argName not found');
    });

    return argMeta;
  }

  ArgMeta getArgMetaByIndex(int index) => argsMeta[index];
}

/// A knowledge base metadata.
class KnowledgeBaseMeta {
  KnowledgeBaseMeta({
    @required this.name,
    this.label,
    this.description,
    this.version,
  });

  /// The knowledge base name.
  final String name;

  /// The knowledge base label (optional).
  final String label;

  /// The knowledge base description (optional).
  final String description;

  /// The knowledge base version (optional).
  int version;

  factory KnowledgeBaseMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? KnowledgeBaseMeta(
            name: json['name'],
            label: json['label'],
            description: json['description'],
            version: json['version'],
          )
        : null;
  }
}
