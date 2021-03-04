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

import 'package:sponge_client_dart/src/features/model/features_model.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

enum SubActionType { create, read, update, delete, activate, context }

class SubActionSpec {
  SubActionSpec(this.subAction, this.type);

  final SubAction subAction;
  final SubActionType type;

  String get actionName => subAction.name;

  bool get hasArgSubstitutions => subAction.args.isNotEmpty;

  bool get hasResultSubstitution => subAction.result?.target != null;

  void setup(
    ActionMeta subActionMeta,
    DataType sourceType, {
    RefTypeBundle sourceTypeBundle,
  }) {
    Validate.notNull(subActionMeta, 'Sub-action ${subAction.name} not found');

    if (hasArgSubstitutions) {
      subAction.args.forEach((substitution) {
        Validate.isTrue(
            substitution.target == DataTypeUtils.ROOT_PATH_PREFIX ||
                subActionMeta.args.any((subActionArgMeta) =>
                    subActionArgMeta.name == substitution.target),
            'Unknown target attribute: ${substitution.target}');
      });

      // TODO Support context actions in dynamic types. Consider more strict type validation.

      // Type validation.
      subAction.args.forEach((substitution) {
        var targetType = subActionMeta.getArg(substitution.target);

        if (substitution.source == DataTypeConstants.PATH_INDEX) {
          Validate.isTrue(targetType.kind == DataTypeKind.INTEGER,
              'The target type for ${DataTypeConstants.PATH_INDEX} should be an INTEGER');
        } else if (substitution.source == DataTypeConstants.PATH_PARENT) {
          Validate.notNull(
              sourceTypeBundle.parentType, 'The source parent type is unknown');
          Validate.isTrue(
              DataTypeUtils.areTypesCompatible(
                  targetType, sourceTypeBundle.parentType),
              'The target type for ${DataTypeConstants.PATH_PARENT} is incompatible');
        } else if (DataTypeUtils.isPathRelativeToRoot(substitution.source)) {
          var sourceSubType = DataTypeUtils.getSubType(
              sourceTypeBundle.rootType,
              DataTypeUtils.getRootRelativePath(substitution.source),
              null);
          Validate.isTrue(
            DataTypeUtils.areTypesCompatible(
              targetType,
              sourceSubType,
            ),
            'The target type ${targetType.kind} of ${substitution.target} in ${subActionMeta.name} is incompatible with'
            ' the source type ${sourceSubType.kind} of ${substitution.source}',
          );
        } else {
          Validate.isTrue(
            DataTypeUtils.areTypesCompatible(
              targetType,
              DataTypeUtils.getSubType(sourceType, substitution.source, null),
            ),
            'The target type ${targetType.kind} of ${substitution.target} in ${subActionMeta.name} is incompatible with'
            ' the source type ${sourceType.kind} of ${substitution.source}',
          );
        }
      });
    }

    if (subAction.result?.target != null) {
      var target = subAction.result.target;
      if (target == DataTypeConstants.PATH_INDEX) {
        throw Exception(
            'The result target ${DataTypeConstants.PATH_INDEX} is not supported');
      } else if (target == DataTypeConstants.PATH_PARENT) {
        Validate.notNull(
            sourceTypeBundle.parentType, 'The source parent type is unknown');
        Validate.isTrue(
            DataTypeUtils.areTypesCompatible(
                subActionMeta.result, sourceTypeBundle.parentType),
            'The sub-action ${subAction.name} result type ${subActionMeta.result.kind} is incompatible with'
            ' the result substitution type ${sourceTypeBundle.parentType.kind} of ${subAction.result.target}');
      } else if (DataTypeUtils.isPathRelativeToRoot(target)) {
        var targetType = DataTypeUtils.getSubType(sourceTypeBundle.rootType,
            DataTypeUtils.getRootRelativePath(target), null);
        Validate.isTrue(
            DataTypeUtils.areTypesCompatible(subActionMeta.result, targetType),
            'The sub-action ${subAction.name} result type ${subActionMeta.result.kind} is incompatible with'
            ' the result substitution type ${targetType.kind} of ${subAction.result.target}');
      } else {
        var targetType = subAction.result.target != DataTypeConstants.PATH_THIS
            ? DataTypeUtils.getSubType(
                sourceType, subAction.result.target, null)
            : sourceType;

        Validate.isTrue(
            DataTypeUtils.areTypesCompatible(subActionMeta.result, targetType),
            'The sub-action ${subAction.name} result type ${subActionMeta.result.kind} is incompatible with'
            ' the result substitution type ${targetType.kind} of ${subAction.result.target}');
      }
    }
  }
}

class SubActionArgSpec {
  SubActionArgSpec(this.target, this.source);

  String target;
  String source;
}
