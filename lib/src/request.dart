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

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

/// A request header.
class RequestHeader {
  RequestHeader({
    this.username,
    this.password,
    this.authToken,
    this.features,
  });

  /// The username (optional).
  String username;

  /// The user password (optional).
  String password;

  /// The authentication token (optional).
  String authToken;

  /// The request features (optional).
  Map<String, Object> features;

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};

    if (username != null) {
      json['username'] = username;
    }

    if (password != null) {
      json['password'] = password;
    }

    if (authToken != null) {
      json['authToken'] = authToken;
    }

    if (features != null) {
      json['features'] = features;
    }

    return json;
  }
}

/// A request params.
abstract class RequestParams {
  RequestHeader get header;
  set header(RequestHeader value);

  Map<String, dynamic> toJson();
}

/// A base request.
abstract class SpongeRequest<T> {
  SpongeRequest(
    this.method, {
    this.params,
    this.id,
  });

  /// The JSON-RPC version.
  final String jsonrpc = '2.0';

  /// The JSON-RPC method.
  String method;

  /// The JSON-RPC parameters.
  T params;

  /// The JSON-RPC request id.
  dynamic id;

  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': jsonrpc,
      'method': method,
      'params': params,
      'id': id,
    };
  }

  // TODO Remove because should be unnecessary in the client
  T createParams();

  RequestHeader get header;
  set header(RequestHeader value);
}

/// A base request.
abstract class TypedParamsRequest<T extends RequestParams>
    extends SpongeRequest<T> {
  TypedParamsRequest(
    String method, {
    T params,
    dynamic id,
  }) : super(method, params: params, id: id);

  @override
  RequestHeader get header => params?.header;

  @override
  set header(RequestHeader value) {
    params ??= createParams();
    params.header = value;
  }
}

class BaseRequestParams implements RequestParams {
  @override
  RequestHeader header;

  @override
  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};

    var headerJson = header?.toJson();
    if (headerJson?.isNotEmpty ?? false) {
      json['header'] = headerJson;
    }

    return json;
  }
}

/// An action execution related info.
abstract class ActionExecutionInfo {
  String get name;
  ProcessorQualifiedVersion qualifiedVersion;
}

/// An action call request body.
class ActionCallParams extends BaseRequestParams
    implements ActionExecutionInfo {
  ActionCallParams({
    @required this.name,
    dynamic args,
    this.qualifiedVersion,
  }) {
    this.args = args;
  }

  /// The action name.
  @override
  final String name;

  /// The action arguments (optional).
  dynamic _args;

  dynamic get args => _args;

  set args(dynamic value) {
    Validate.isTrue(args == null || args is List || args is Map,
        'Action args should be an instance of a List or a Map');
    _args = value;
  }

  /// The action expected qualified version (optional).
  @override
  ProcessorQualifiedVersion qualifiedVersion;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
      'args': args,
      'qualifiedVersion': qualifiedVersion,
    });
}

/// An action call request.
class ActionCallRequest extends TypedParamsRequest<ActionCallParams> {
  ActionCallRequest([ActionCallParams params])
      : super(SpongeClientConstants.METHOD_CALL, params: params);

  @override
  ActionCallParams createParams() => ActionCallParams(name: null);
}

/// A get actions request params.
class GetActionsParams extends BaseRequestParams {
  GetActionsParams({
    this.name,
    this.metadataRequired,
    this.registeredTypes,
  });

  /// The action name or the regular expression
  /// compatible with https://docs.oracle.com/javase/8/docs/api/java/util/regex/Pattern.html (optional).
  String name;

  /// The metadata required flag (optional).
  bool metadataRequired;

  /// The flag for requesting registered types in the result (defaults to `false`).
  bool registeredTypes;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
      'metadataRequired': metadataRequired,
      'registeredTypes': registeredTypes,
    });
}

/// A get actions request.
class GetActionsRequest extends TypedParamsRequest<GetActionsParams> {
  GetActionsRequest(GetActionsParams params)
      : super(SpongeClientConstants.METHOD_ACTIONS, params: params);

  @override
  GetActionsParams createParams() => GetActionsParams();
}

/// A get event types request params.
class GetEventTypesParams extends BaseRequestParams {
  GetEventTypesParams({
    @required this.name,
  });

  /// The event name or the regular expression.
  final String name;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
    });
}

/// A get event types request.
class GetEventTypesRequest extends TypedParamsRequest<GetEventTypesParams> {
  GetEventTypesRequest([GetEventTypesParams params])
      : super(SpongeClientConstants.METHOD_EVENT_TYPES, params: params);

  @override
  GetEventTypesParams createParams() => GetEventTypesParams(name: null);
}

/// A get features request
class GetFeaturesRequest extends TypedParamsRequest<BaseRequestParams> {
  GetFeaturesRequest([BaseRequestParams params])
      : super(SpongeClientConstants.METHOD_FEATURES, params: params);

  @override
  BaseRequestParams createParams() => BaseRequestParams();
}

/// A get knowledge bases request.
class GetKnowledgeBasesRequest extends TypedParamsRequest<BaseRequestParams> {
  GetKnowledgeBasesRequest([BaseRequestParams params])
      : super(SpongeClientConstants.METHOD_KNOWLEDGE_BASES, params: params);

  @override
  BaseRequestParams createParams() => BaseRequestParams();
}

/// A get version request
class GetVersionRequest extends TypedParamsRequest<BaseRequestParams> {
  GetVersionRequest([BaseRequestParams params])
      : super(SpongeClientConstants.METHOD_VERSION, params: params);

  @override
  BaseRequestParams createParams() => BaseRequestParams();
}

/// An action active request entry.
class IsActionActiveEntry implements ActionExecutionInfo {
  IsActionActiveEntry({
    @required this.name,
    this.contextValue,
    this.contextType,
    this.args,
    this.features,
    this.qualifiedVersion,
  });

  /// The action name.
  @override
  String name;

  /// The context value.
  dynamic contextValue;

  /// The context type.
  DataType contextType;

  /// The action arguments in the context.
  List args;

  /// The features.
  Map<String, Object> features;

  /// The action qualified version.
  @override
  ProcessorQualifiedVersion qualifiedVersion;

  Map<String, dynamic> toJson() => {
        'name': name,
        'contextValue': contextValue,
        'contextType': contextType,
        'args': args,
        'features': features,
        'qualifiedVersion': qualifiedVersion,
      };

  IsActionActiveEntry clone() => IsActionActiveEntry(
        name: name,
        contextValue: contextValue,
        contextType: contextType,
        args: args?.toList(),
        features: features != null ? Map.of(features) : null,
        qualifiedVersion: qualifiedVersion,
      );
}

/// An action active request params.
class IsActionActiveParams extends BaseRequestParams {
  IsActionActiveParams({@required this.entries});

  final List<IsActionActiveEntry> entries;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'entries': entries?.map((entry) => entry?.toJson())?.toList(),
    });
}

/// An action active request.
class IsActionActiveRequest extends TypedParamsRequest<IsActionActiveParams> {
  IsActionActiveRequest(IsActionActiveParams params)
      : super(SpongeClientConstants.METHOD_IS_ACTION_ACTIVE, params: params);

  @override
  IsActionActiveParams createParams() => IsActionActiveParams(entries: null);
}

/// A login request.
class LoginRequest extends TypedParamsRequest<BaseRequestParams> {
  LoginRequest({
    @required String username,
    @required String password,
  }) : super(SpongeClientConstants.METHOD_LOGIN, params: BaseRequestParams()) {
    header = RequestHeader(username: username, password: password);
  }

  @override
  BaseRequestParams createParams() => BaseRequestParams();
}

/// A logout request.
class LogoutRequest extends TypedParamsRequest<BaseRequestParams> {
  LogoutRequest([BaseRequestParams params])
      : super(SpongeClientConstants.METHOD_LOGOUT, params: params);

  @override
  BaseRequestParams createParams() => BaseRequestParams();
}

/// A provide action arguments request params.
class ProvideActionArgsParams extends BaseRequestParams
    implements ActionExecutionInfo {
  ProvideActionArgsParams({
    @required this.name,
    this.provide,
    this.submit,
    this.current,
    this.dynamicTypes,
    this.qualifiedVersion,
    this.argFeatures,
    this.initial,
  });

  /// The action name.
  @override
  final String name;

  /// The names of action arguments to provide.
  final List<String> provide;

  /// The names of action arguments to submit.
  final List<String> submit;

  /// The current values of action arguments in a client code.
  Map<String, Object> current;

  /// The types of dynamic values used in `current` and `provide`.
  Map<String, DataType> dynamicTypes;

  /// The action expected qualified version (optional).
  @override
  ProcessorQualifiedVersion qualifiedVersion;

  /// The features for arguments (optional).
  Map<String, Map<String, Object>> argFeatures;

  /// The flag indicating if this is the initial provide action arguments request.
  bool initial;

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson()
      ..addAll({
        'name': name,
        'provide': provide,
      });

    if (submit != null) {
      json['submit'] = submit;
    }

    if (current != null) {
      json['current'] = current;
    }

    if (dynamicTypes != null) {
      json['dynamicTypes'] = {
        for (var entry in dynamicTypes.entries) entry.key: entry.value.toJson()
      };
    }

    if (argFeatures != null) {
      json['argFeatures'] = argFeatures;
    }

    if (qualifiedVersion != null) {
      json['qualifiedVersion'] = qualifiedVersion;
    }

    if (initial != null) {
      json['initial'] = initial;
    }

    return json;
  }
}

/// A provide action arguments request.
class ProvideActionArgsRequest
    extends TypedParamsRequest<ProvideActionArgsParams> {
  ProvideActionArgsRequest(ProvideActionArgsParams params)
      : super(SpongeClientConstants.METHOD_PROVIDE_ACTION_ARGS, params: params);

  @override
  ProvideActionArgsParams createParams() => ProvideActionArgsParams(name: null);
}

/// A reload request.
class ReloadRequest extends TypedParamsRequest<BaseRequestParams> {
  ReloadRequest([BaseRequestParams params])
      : super(SpongeClientConstants.METHOD_RELOAD, params: params);

  @override
  BaseRequestParams createParams() => BaseRequestParams();
}

/// A send event request params.
class SendEventParams extends BaseRequestParams {
  SendEventParams({
    @required this.name,
    this.attributes,
    this.label,
    this.description,
    this.features,
  });

  /// The event name.
  final String name;

  /// The event attributes (optional).
  Map<String, Object> attributes;

  /// The event label.
  String label;

  /// The event description.
  String description;

  /// The event features (optional).
  Map<String, Object> features;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
      'attributes': attributes,
      'label': label,
      'description': description,
      'features': features,
    });
}

/// A send event request.
class SendEventRequest extends TypedParamsRequest<SendEventParams> {
  SendEventRequest(SendEventParams params)
      : super(SpongeClientConstants.METHOD_SEND, params: params);

  @override
  SendEventParams createParams() => SendEventParams(name: null);
}

class GenericRequest extends SpongeRequest<Map<String, Object>> {
  GenericRequest(
    String method, {
    Map<String, Object> params,
    dynamic id,
  }) : super(method, params: params, id: id);

  @override
  Map<String, Object> createParams() => {};

  @override
  RequestHeader get header =>
      params != null ? params[SpongeClientConstants.PARAM_HEADER] : null;

  @override
  set header(RequestHeader value) {
    params ??= {};
    params[SpongeClientConstants.PARAM_HEADER] = value;
  }
}
