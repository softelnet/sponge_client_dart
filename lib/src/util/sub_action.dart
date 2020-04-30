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

  void setup(ActionMeta subActionMeta, DataType sourceType) {
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
        Validate.isTrue(
            targetType.kind ==
                DataTypeUtils.getSubType(sourceType, substitution.source, null)
                    .kind,
            'The target argument type ${targetType.kind} of ${substitution.target} in ${subActionMeta.name} is incompatible with'
            ' the source type ${sourceType.kind} of ${substitution.source}');
      });
    }

    if (subAction.result?.target != null) {
      var parentType = subAction.result.target != DataTypeConstants.PATH_THIS
          ? DataTypeUtils.getSubType(sourceType, subAction.result.target, null)
          : sourceType;
      Validate.isTrue(
          subActionMeta.result.kind == parentType.kind,
          'The sub-action ${subAction.name} result type ${subActionMeta.result.kind} is incompatible with'
          ' the result substitution type ${parentType.kind} of ${subAction.result.target}');
    }
  }
}

class SubActionArgSpec {
  SubActionArgSpec(this.target, this.source);

  String target;
  String source;
}
