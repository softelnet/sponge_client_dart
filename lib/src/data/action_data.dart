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

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/data/pageable_list.dart';
import 'package:sponge_client_dart/src/features/features.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

class ActionCallResultInfo {
  ActionCallResultInfo({this.result, this.exception});

  final dynamic result;
  final dynamic exception;

  bool get isSuccess => exception == null;
}

@experimental
class ActionData {
  ActionData(this.actionMeta) {
    _init();
  }

  final ActionMeta actionMeta;
  List<Object> args;
  ActionCallResultInfo resultInfo;
  bool calling = false;
  Map<String, ProvidedValue> _providedValues = {};
  Map<String, PageableList> _pageableLists = {};
  Map<String, Map<String, dynamic>> _additionalArgData = {};

  Map<String, Map<String, dynamic>> get additionalArgData => _additionalArgData;
  set additionalArgData(Map<String, Map<String, dynamic>> value) =>
      _additionalArgData = Map.of(value);

  bool get hasResponse => resultInfo != null;
  bool get isSuccess => resultInfo != null && resultInfo.exception == null;
  bool get isError => resultInfo != null && resultInfo.exception != null;

  bool get isVisible => actionMeta.features[Features.VISIBLE] ?? true;
  bool get needsRunConfirmation =>
      actionMeta.features[Features.ACTION_CONFIRMATION] ?? false;

  Map<String, ProvidedValue> get providedValues => _providedValues;
  set providedValues(Map<String, ProvidedValue> value) {
    _providedValues = Map.of(value);
  }

  Map<String, PageableList> get pageableLists => _pageableLists;
  set pageableLists(Map<String, PageableList> value) {
    _pageableLists = Map.of(value);
  }

  bool get hasVisibleArgs =>
      actionMeta.args.isNotEmpty &&
      actionMeta.args.any((type) => type.features[Features.VISIBLE] ?? true);

  void _init() {
    args = createInitialArgs(actionMeta);
    actionMeta.args
        .where((type) => isArgPageableListByType(type))
        .forEach((type) => _pageableLists[type.name] = PageableList());
  }

  void clear({bool clearReadOnly = true}) {
    actionMeta.args?.asMap()?.forEach((i, argType) {
      if (clearReadOnly || !(argType.provided?.readOnly ?? false)) {
        args[i] = argType?.defaultValue;
      }
    });
    resultInfo = null;
    calling = false;
    _providedValues.clear();
    _pageableLists.clear();
    _additionalArgData.clear();
  }

  RecordType get argsAsRecordType {
    var recordType = actionMeta.argsAsRecordType;

    // Copy context actions from the action to the record type.
    var actionContextActions = actionMeta.features[Features.CONTEXT_ACTIONS];
    if (actionContextActions != null) {
      recordType.features[Features.CONTEXT_ACTIONS] = actionContextActions;
    }
    return recordType;
  }

  Map<String, dynamic> get argsAsRecord => _ActionArgsMap(this);

  /// Supports sub-arguments. Bypasses annotated values. Doesn't support collections inside the path with the exception of the last path element.
  dynamic getArgValueByName(
    String argName, {
    bool unwrapAnnotatedTarget = false,
    bool unwrapDynamicTarget = true,
  }) =>
      DataTypeUtils.getSubValue(
        argsAsRecord,
        argName,
        unwrapAnnotatedTarget: unwrapAnnotatedTarget,
        unwrapDynamicTarget: unwrapDynamicTarget,
      );

  /// Supports sub-arguments and bypasses annotated values.
  void setArgValueByName(
    String argName,
    dynamic value, {
    bool ignoreNullParent = false,
  }) {
    if (argName != null) {
      DataTypeUtils.setSubValue(argsAsRecord, argName, value,
          ignoreNullParent: ignoreNullParent);
    } else {
      // Support for setting all arguments.
      Validate.isTrue(
          value is Map, 'The value of root path is not a record/map');
      args = List.of((value as Map).values);
    }
  }

  ActionData clone({ActionData prototype}) =>
      (prototype ?? ActionData(actionMeta))
        ..args = DataTypeUtils.cloneValue(args)
        .._providedValues = _providedValues
        .._pageableLists = _pageableLists
        ..calling = calling
        ..resultInfo = resultInfo != null
            ? ActionCallResultInfo(
                result: resultInfo.result, exception: resultInfo.exception)
            : null
        .._additionalArgData = _additionalArgData;

  void rebind(
    ActionData source, {
    List<Object> overrideArgs,
    ActionCallResultInfo overrideResultInfo,
    bool overrideCalling,
    Map<String, ProvidedValue> overrideProvidedValues,
    Map<String, PageableList> overridePageableLists,
    Map<String, Map<String, dynamic>> overrideAdditionalArgData,
  }) {
    args = overrideArgs ?? source.args;
    resultInfo = overrideResultInfo ?? source.resultInfo;
    calling = overrideCalling ?? source.calling;
    _providedValues = overrideProvidedValues ?? source._providedValues;
    _pageableLists = overridePageableLists ?? source._pageableLists;
    _additionalArgData = overrideAdditionalArgData ?? source._additionalArgData;
  }

  static List<Object> createInitialArgs(ActionMeta action) => List.generate(
      action.args?.length ?? 0, (i) => action.args[i]?.defaultValue);

  /// Supports sub-arguments.
  Map<String, Object> getArgMap(Iterable<String> argNames,
          {Map<String, Object> predefined}) =>
      {
        for (var name in argNames)
          name: (predefined?.containsKey(name) ?? false)
              ? predefined[name]
              : getArgValueByName(name)
      };

  Map<String, DataType> getDynamicTypeNestedTypes(Iterable<String> argNames) {
    var selectedArgNames = argNames.where((name) =>
        DataTypeUtils.isTypePathNestedInDynamic(argsAsRecordType, name));
    return {
      for (var qType in DataTypeUtils.getQualifiedTypes(argsAsRecordType,
              value: argsAsRecord)
          .where((qType) => selectedArgNames.contains(qType.path)))
        qType.path: qType.type
    };
  }

  PageableList getPageableList(String argName) => _pageableLists[argName];

  DataType getArgType(String argName) =>
      actionMeta.getArg(argName, argsAsRecord: argsAsRecord);

  void traverseArguments(void Function(QualifiedDataType _) onType,
      {bool namedOnly = true}) {
    DataTypeUtils.traverseDataType(
      QualifiedDataType(argsAsRecordType),
      onType,
      namedOnly: namedOnly,
      value: argsAsRecord,
      traverseRoot: false,
    );
  }

  bool isArgPageableList(String argName) =>
      isArgPageableListByType(getArgType(argName));

  bool isArgPageableListByType(DataType type) =>
      type is ListType &&
      type.name != null &&
      type.annotated &&
      (type.features[Features.PROVIDE_VALUE_PAGEABLE] ?? false);

  List<String> getProvidedOptionalPageableListArgNames() => actionMeta.args
      .where((type) =>
          isArgPageableListByType(type) &&
          type.provided != null &&
          type.provided.mode == ProvidedMode.OPTIONAL)
      .map((type) => type.name)
      .toList();

  bool get hasCacheableArgs =>
      actionMeta.features[Features.CACHEABLE_ARGS] ?? true;

  bool get hasCacheableContextArgs =>
      hasCacheableArgs &&
      (actionMeta.features[Features.CACHEABLE_CONTEXT_ARGS] ?? false);

  void setAdditionalArgData(String argPath, String type, dynamic value) {
    _additionalArgData.putIfAbsent(argPath, () => <String, dynamic>{})[type] =
        value;
  }

  dynamic getAdditionalArgData(String argPath, String type) {
    var argData = _additionalArgData[argPath];

    return (argData?.containsKey(type) ?? false) ? argData[type] : null;
  }
}

class _ActionArgsMap extends MapBase<String, dynamic> {
  _ActionArgsMap(this.actionData)
      : _argIndexMap = {
          for (var i in List<int>.generate(
              actionData.actionMeta.args.length, (int i) => i))
            actionData.actionMeta.args[i].name: i
        };

  final ActionData actionData;
  final Map<String, int> _argIndexMap;

  int _getArgIndex(String key) =>
      Validate.notNull(_argIndexMap[key], 'Argument $key not found');

  @override
  dynamic operator [](Object key) => actionData.args[_getArgIndex(key)];

  @override
  void operator []=(key, value) => actionData.args[_getArgIndex(key)] = value;

  @override
  void clear() {
    throw Exception('Clear is not allowed');
  }

  @override
  Iterable<String> get keys =>
      actionData.actionMeta.args.map((argType) => argType.name).toList();

  @override
  dynamic remove(Object key) {
    throw Exception('Remove is not allowed');
  }
}
