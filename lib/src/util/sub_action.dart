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

import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

enum SubActionType { create, read, update, delete, activate, context }

class SubActionSpec {
  SubActionSpec._(
    this.actionName,
    this.type, {
    this.argSubstitutions,
    this.resultSubstitution,
    this.expression,
  });

  final String actionName;
  final SubActionType type;
  final List<SubActionArgSpec> argSubstitutions;
  final String resultSubstitution;
  final String expression;

  bool get hasArgSubstitutions =>
      argSubstitutions == null || argSubstitutions.isNotEmpty;

  // The value 1 means that there will be a default substitution.
  int get argSubstitutionCount => argSubstitutions?.length ?? 1;

  void setup(ActionMeta subActionMeta, DataType sourceType) {
    Validate.notNull(subActionMeta, 'Sub-action $actionName not found');

    if (argSubstitutions != null) {
      Validate.isTrue(argSubstitutions.length <= subActionMeta.args.length,
          'Too many arguments');

      // Fills missing target arguments but only leading.
      var i = 0;
      for (var substitution in argSubstitutions) {
        if (substitution.target != null) {
          break;
        }
        substitution.target = subActionMeta.args[i++].name;
      }

      Validate.isTrue(
          argSubstitutions.every((substitution) => substitution.target != null),
          'Target attribute missing');
      Validate.isTrue(
          argSubstitutions.every((substitution) => subActionMeta.args.any(
              (subActionArgMeta) =>
                  subActionArgMeta.name == substitution.target)),
          'Unknown target attribute');

      // Type validation.
      argSubstitutions.asMap().forEach((i, substitution) {
        // TODO Support context actions in dynamic types.
        var targetType = subActionMeta.getArg(substitution.target);
        // TODO Consider more strict type validation.
        // TODO Support context actions in dynamic types.
        Validate.isTrue(
            targetType.kind ==
                DataTypeUtils.getSubType(sourceType, substitution.source, null)
                    .kind,
            'The target argument type ${targetType.kind} of ${substitution.target} in ${subActionMeta.name} is incompatible with'
            ' the source type ${sourceType.kind} of ${substitution.source}');
      });
    }

    if (resultSubstitution != null) {
      // TODO Support context actions in dynamic types.
      var parentType = resultSubstitution != DataTypeUtils.THIS
          ? DataTypeUtils.getSubType(sourceType, resultSubstitution, null)
          : sourceType;
      Validate.isTrue(
          subActionMeta.result.kind == parentType.kind,
          'The sub-action $actionName result type ${subActionMeta.result.kind} is incompatible with'
          ' the result substitution type ${parentType.kind} of $resultSubstitution');
    }
  }

  factory SubActionSpec.parse(String expression, SubActionType type) {
    var regExp = RegExp(r'^\s*(?:(\w+)\s*=\s*)?(.+)$');
    var match = regExp.firstMatch(expression);
    Validate.isTrue(match != null && match.groupCount > 0,
        'Invalid action specification: $expression');
    var resultSubstitution = match.groupCount > 1 ? match.group(1) : null;
    var actionFragment = match.groupCount > 1 ? match.group(2) : match.group(1);

    var spec = _parseActionFragment(actionFragment, type);

    return SubActionSpec._(spec.actionName, type,
        argSubstitutions: spec.argSubstitutions,
        resultSubstitution: resultSubstitution,
        expression: expression);
  }

  static SubActionSpec _parseActionFragment(
      String expression, SubActionType type) {
    var regExp = RegExp(r'^\s*((?:\w|\.)+)\s*(\(.*\))*\s*$');
    var match = regExp.firstMatch(expression);
    Validate.isTrue(match != null && match.groupCount > 0,
        'Invalid action specification: $expression');
    var actionName = match.group(1);

    List<SubActionArgSpec> argSubstitutions;
    var argsSpecsString = match.group(2)?.trim();
    if (argsSpecsString == null) {
      argSubstitutions = null;
    } else if (argsSpecsString.isEmpty) {
      argSubstitutions = [];
    } else {
      argSubstitutions = [];
      argsSpecsString =
          argsSpecsString.substring(1, argsSpecsString.length - 1);

      argsSpecsString
          .split(',')
          .map((argSpec) => argSpec.trim())
          .where((argSpec) => argSpec.isNotEmpty)
          .forEach((argSpec) {
        var argSplit = argSpec.split('=');
        Validate.isTrue(argSplit.isNotEmpty && argSplit.length <= 2,
            'Invalid argument in the action specification: $expression');
        var first = argSplit[0].trim();
        var second = argSplit.length > 1 ? argSplit[1].trim() : null;

        var targetArg = second != null ? first : null;
        var sourceArg = second ?? first;

        Validate.isTrue(
            (targetArg == null ||
                    targetArg.isNotEmpty && !targetArg.contains('.')) &&
                sourceArg.isNotEmpty,
            'Invalid argument in the action specification: $expression');

        argSubstitutions.add(SubActionArgSpec(targetArg, sourceArg));
      });
    }

    return SubActionSpec._(actionName, type,
        argSubstitutions: argSubstitutions, expression: expression);
  }
}

class SubActionArgSpec {
  SubActionArgSpec(this.target, this.source);

  String target;
  String source;
}
