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
    DataType sourceParentType,
  }) {
    Validate.notNull(subActionMeta, 'Sub-action ${subAction.name} not found');

    if (hasArgSubstitutions) {
      subAction.args.forEach((substitution) {
        Validate.isTrue(
            subActionMeta.args.any((subActionArgMeta) =>
                subActionArgMeta.name == substitution.target),
            'Unknown target attribute: ${substitution.target}');
      });

      // TODO Support context actions in dynamic types. Consider more strict type validation.

      // Type validation.
      subAction.args.forEach((substitution) {
        var targetType = subActionMeta.getArg(substitution.target);

        switch (substitution.source) {
          case DataTypeConstants.PATH_INDEX:
            Validate.isTrue(targetType.kind == DataTypeKind.INTEGER,
                'The target type for ${DataTypeConstants.PATH_INDEX} should be an INTEGER');
            break;
          case DataTypeConstants.PATH_PARENT:
            Validate.notNull(
                sourceParentType, 'The source parent type is unknown');
            Validate.isTrue(targetType.kind == sourceParentType.kind,
                'The target type for ${DataTypeConstants.PATH_PARENT} should be ${sourceParentType.kind} not ${targetType.kind}');
            break;
          default:
            Validate.isTrue(
                targetType.kind ==
                    DataTypeUtils.getSubType(
                            sourceType, substitution.source, null)
                        .kind,
                'The target argument type ${targetType.kind} of ${substitution.target} in ${subActionMeta.name} is incompatible with'
                ' the source type ${sourceType.kind} of ${substitution.source}');
            break;
        }
      });
    }

    if (subAction.result?.target != null) {
      switch (subAction.result.target) {
        case DataTypeConstants.PATH_INDEX:
          throw Exception(
              'The result target ${DataTypeConstants.PATH_INDEX} is not supported');
          break;
        case DataTypeConstants.PATH_PARENT:
          Validate.notNull(
              sourceParentType, 'The source parent type is unknown');
          Validate.isTrue(
              subActionMeta.result.kind == sourceParentType.kind,
              'The sub-action ${subAction.name} result type ${subActionMeta.result.kind} is incompatible with'
              ' the result substitution type ${sourceParentType.kind} of ${subAction.result.target}');
          break;
        default:
          var targetType =
              subAction.result.target != DataTypeConstants.PATH_THIS
                  ? DataTypeUtils.getSubType(
                      sourceType, subAction.result.target, null)
                  : sourceType;

          Validate.isTrue(
              subActionMeta.result.kind == targetType.kind,
              'The sub-action ${subAction.name} result type ${subActionMeta.result.kind} is incompatible with'
              ' the result substitution type ${targetType.kind} of ${subAction.result.target}');
          break;
      }
    }
  }
}

class SubActionArgSpec {
  SubActionArgSpec(this.target, this.source);

  String target;
  String source;
}
