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

enum SubActionType { create, read, update, delete, context }

class SubActionSpec {
  SubActionSpec._(
    this.actionName,
    this.type, {
    this.argSubstitutions,
    this.expression,
  });

  final String actionName;
  final SubActionType type;
  final List<SubActionArgSpec> argSubstitutions;
  final String expression;

  void setup(ActionMeta subActionMeta, DataType sourceType) {
    Validate.notNull(subActionMeta, 'Sub-action $actionName not found');

    if (argSubstitutions != null) {
      Validate.isTrue(argSubstitutions.length <= subActionMeta.args.length,
          'Too many arguments');

      // Fills missing target arguments but only leading.
      int i = 0;
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
        var targetType = subActionMeta.getArg(substitution.target);
        // TODO Consider more strict type validation.
        Validate.isTrue(
            targetType.kind ==
                DataTypeUtils.getSubType(sourceType, substitution.source).kind,
            'The target argument type ${targetType.kind} of ${substitution.target} is incompatible with'
            ' the source type ${sourceType.kind} of ${substitution.source}');
      });
    }
  }

  factory SubActionSpec.parse(String expression, SubActionType type) {
    var regExp = RegExp(r'^\s*((?:\w|\.)+)\s*(\(.*\))*\s*$');
    Validate.isTrue(regExp.hasMatch(expression),
        'Invalid action specification: $expression');
    var match = regExp.firstMatch(expression);
    Validate.isTrue(
        match.groupCount > 0, 'Invalid action specification: $expression');
    var actionName = match.group(1);

    List<SubActionArgSpec> argSubstitutions;
    String argsSpecsString = match.group(2)?.trim();
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
        var sourceArg = second != null ? second : first;

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
