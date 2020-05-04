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
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';

/// A request header.
class RequestHeader {
  RequestHeader({
    this.id,
    this.username,
    this.password,
    this.authToken,
    this.features,
  });

  /// The request id (optional).
  String id;

  /// The username (optional).
  String username;

  /// The user password (optional).
  String password;

  /// The authentication token (optional).
  String authToken;

  /// The request features (optional).
  Map<String, Object> features;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'authToken': authToken,
      'features': features,
    };
  }
}

/// A request body.
abstract class RequestBody {
  Map<String, dynamic> toJson();
}

/// A base request.
abstract class SpongeRequest {
  SpongeRequest({
    this.header,
  }) {
    header ??= RequestHeader();
  }

  /// The request header (optional).
  RequestHeader header;

  Map<String, dynamic> toJson() {
    return {
      'header': header?.toJson(),
    };
  }
}

/// A request with a body.
abstract class BodySpongeRequest<T extends RequestBody> extends SpongeRequest {
  BodySpongeRequest(this.body);

  /// The request body.
  T body;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'body': body?.toJson(),
    });
}

/// An action execution related info.
abstract class ActionExecutionInfo {
  String get name;
  ProcessorQualifiedVersion qualifiedVersion;
}

/// An action call request body.
class ActionCallRequestBody implements RequestBody, ActionExecutionInfo {
  ActionCallRequestBody({
    @required this.name,
    this.args,
    this.qualifiedVersion,
  });

  /// The action name.
  @override
  final String name;

  /// The action arguments (optional).
  List args;

  /// The action expected qualified version (optional).
  @override
  ProcessorQualifiedVersion qualifiedVersion;

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
        'args': args,
        'qualifiedVersion': qualifiedVersion,
      };
}

/// An action call request.
class ActionCallRequest extends BodySpongeRequest<ActionCallRequestBody> {
  ActionCallRequest(ActionCallRequestBody body) : super(body);
}

/// A get actions request body.
class GetActionsRequestBody implements RequestBody {
  GetActionsRequestBody({
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
  Map<String, dynamic> toJson() => {
        'name': name,
        'metadataRequired': metadataRequired,
        'registeredTypes': registeredTypes,
      };
}

/// A get actions request.
class GetActionsRequest extends BodySpongeRequest<GetActionsRequestBody> {
  GetActionsRequest(GetActionsRequestBody body) : super(body);
}

/// A get knowledge bases request.
class GetKnowledgeBasesRequest extends SpongeRequest {}

/// A get version request
class GetVersionRequest extends SpongeRequest {}

/// A get features request
class GetFeaturesRequest extends SpongeRequest {}

/// A login request.
class LoginRequest extends SpongeRequest {
  LoginRequest(
    String username,
    String password,
  ) : super(header: RequestHeader(username: username, password: password));
}

/// A logout request.
class LogoutRequest extends SpongeRequest {}

/// A reload request.
class ReloadRequest extends SpongeRequest {}

/// A send event request body.
class SendEventRequestBody implements RequestBody {
  SendEventRequestBody({
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
  Map<String, dynamic> toJson() => {
        'name': name,
        'attributes': attributes,
        'label': label,
        'description': description,
        'features': features,
      };
}

/// A send event request.
class SendEventRequest extends BodySpongeRequest<SendEventRequestBody> {
  SendEventRequest(SendEventRequestBody body) : super(body);
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

/// An action active request body.
class IsActionActiveRequestBody implements RequestBody {
  IsActionActiveRequestBody({@required this.entries});

  final List<IsActionActiveEntry> entries;

  @override
  Map<String, dynamic> toJson() => {
        'entries': entries?.map((entry) => entry?.toJson())?.toList(),
      };
}

/// An action active request.
class IsActionActiveRequest
    extends BodySpongeRequest<IsActionActiveRequestBody> {
  IsActionActiveRequest(IsActionActiveRequestBody body) : super(body);
}

/// A provide action arguments request body.
class ProvideActionArgsRequestBody implements RequestBody, ActionExecutionInfo {
  ProvideActionArgsRequestBody({
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
  Map<String, dynamic> toJson() => {
        'name': name,
        'provide': provide,
        'submit': submit,
        'current': current,
        'dynamicTypes': dynamicTypes != null
            ? {
                for (var entry in dynamicTypes.entries)
                  entry.key: entry.value.toJson()
              }
            : null,
        'qualifiedVersion': qualifiedVersion,
        'argFeatures': argFeatures,
        'initial': initial,
      };
}

/// A provide action arguments request.
class ProvideActionArgsRequest
    extends BodySpongeRequest<ProvideActionArgsRequestBody> {
  ProvideActionArgsRequest(ProvideActionArgsRequestBody body) : super(body);
}

/// A get event types request body.
class GetEventTypesRequestBody implements RequestBody {
  GetEventTypesRequestBody({
    @required this.name,
  });

  /// The event name or the regular expression.
  final String name;

  @override
  Map<String, dynamic> toJson() => {
        'name': name,
      };
}

/// A get event types request.
class GetEventTypesRequest extends BodySpongeRequest<GetEventTypesRequestBody> {
  GetEventTypesRequest(GetEventTypesRequestBody body) : super(body);
}
