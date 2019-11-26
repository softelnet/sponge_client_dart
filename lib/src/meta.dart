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
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

/// A value set metadata.
class ValueSetMeta {
  ValueSetMeta({this.limited = true});

  /// The flag specifying if the value set is limited only to the provided values. Defaults to `true`.
  final bool limited;

  factory ValueSetMeta.fromJson(Map<String, dynamic> json) =>
      json != null ? ValueSetMeta(limited: json['limited']) : null;

  Map<String, dynamic> toJson() => {
        'limited': limited,
      };
}

/// A provided mode.
enum ProvidedMode {
  EXPLICIT,
  OPTIONAL,
  IMPLICIT,
}

/// A provided object metadata.
class ProvidedMeta {
  ProvidedMeta({
    this.value = false,
    this.valueSet,
    this.dependencies,
    this.readOnly = false,
    this.overwrite = false,
    this.elementValueSet = false,
    this.submittable = false,
    this.lazyUpdate = false,
    this.current = false,
    this.mode = ProvidedMode.EXPLICIT,
  });

  /// The flag specifying if the value is provided. Defaults to `false`.
  bool value;

  /// The metadata specifying if the value set is provided. Defaults to `null`.
  ValueSetMeta valueSet;

  /// The list of names that this provided object depends on.
  final List<String> dependencies;

  /// The flag specifying if this provided object is read only. Defaults to `false`.
  final bool readOnly;

  /// The flag specifying if the provided value of this object should overwrite the value set in a client code. Defaults to `false`.
  final bool overwrite;

  /// The flag specifying if the list element value set is provided. Applicable only for list types. Defaults to `false`.
  final bool elementValueSet;

  /// The flag specifying if the value can be submitted by a client.
  final bool submittable;

  /// The flag specifying if the provided value should be updated lazily in a client code when a dependency changes (experimental).
  final bool lazyUpdate;

  /// The flag specifying if the current value in a client code should be passed to a server.
  final bool current;

  /// The provided read mode: `explicit` (a value has to specified to be provided in `provideArgs`), `optional` (a value
  /// may or may not be specified to be provided in `provideArgs`) or `implicit` (a value shouldn't be specified to be provided
  /// in `provideArgs`). Defaults to `explicit`. For example a value can be provided optionally or implicitly when an other
  /// value is submitted.
  final ProvidedMode mode;

  bool get hasValueSet => valueSet != null;

  factory ProvidedMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ProvidedMeta(
            value: json['value'],
            valueSet: ValueSetMeta.fromJson(json['valueSet']),
            dependencies:
                (json['dependencies'] as List)?.cast<String>()?.toList(),
            readOnly: json['readOnly'] ?? false,
            overwrite: json['overwrite'] ?? false,
            elementValueSet: json['elementValueSet'] ?? false,
            submittable: json['submittable'] ?? false,
            lazyUpdate: json['lazyUpdate'] ?? false,
            current: json['current'] ?? false,
            mode: fromJsonProvidedMode(json['mode']),
          )
        : null;
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'valueSet': valueSet?.toJson(),
        'dependencies': dependencies,
        'readOnly': readOnly,
        'overwrite': overwrite,
        'elementValueSet': elementValueSet,
        'submittable': submittable,
        'lazyUpdate': lazyUpdate,
        'current': current,
        'mode': _getProvidedModeValue(mode),
      };

  static ProvidedMode fromJsonProvidedMode(String jsonProvidedMode) {
    ProvidedMode mode = ProvidedMode.values.firstWhere(
        (k) => _getProvidedModeValue(k) == jsonProvidedMode,
        orElse: () => null);
    return Validate.notNull(
        mode, 'Unsupported provided mode $jsonProvidedMode');
  }

  static String _getProvidedModeValue(ProvidedMode mode) =>
      mode.toString().split('.')[1];
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
    Map<String, Object> features,
  }) : this.features = features ?? Map();

  /// The category name.
  String name;

  /// The category label.
  String label;

  /// The category description.
  String description;

  /// The category features.
  final Map<String, Object> features;

  factory CategoryMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? CategoryMeta(
            json['name'],
            label: json['label'],
            description: json['description'],
            features: json['features'] ?? {},
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
    this.args,
    this.result,
    this.callable = true,
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

  /// The action argument types (optional).
  final List<DataType> args;

  /// The action result type (optional).
  DataType result;

  /// The callable flag.
  final bool callable;

  /// The action qualified version.
  ProcessorQualifiedVersion qualifiedVersion;

  /// Could be `null` if the action has no argument metadata.
  RecordType get argsAsRecordType =>
      args != null ? (RecordType(args)..name = this.name) : null;

  factory ActionMeta.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ActionMeta(
            name: json['name'],
            label: json['label'],
            description: json['description'],
            knowledgeBase: KnowledgeBaseMeta.fromJson(json['knowledgeBase']),
            category: CategoryMeta.fromJson(json['category']),
            features: json['features'] ?? {},
            args: (json['args'] as List)
                ?.map((arg) => DataType.fromJson(arg))
                ?.toList(),
            result: DataType.fromJson(json['result']),
            callable: json['callable'],
            qualifiedVersion:
                ProcessorQualifiedVersion.fromJson(json['qualifiedVersion']),
          )
        : null;
  }

  /// Supports sub-arguments.
  DataType getArg(String path) =>
      DataTypeUtils.getSubType(argsAsRecordType, path);

  int getArgIndex(String argName) {
    var index = args.indexWhere((arg) => arg.name == argName);
    Validate.isTrue(index > -1, 'Argument $argName not found');
    return index;
  }
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
