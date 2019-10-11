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

import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_value.dart';

/// A response header.
class ResponseHeader {
  ResponseHeader({
    this.id,
    this.errorCode,
    this.errorMessage,
    this.detailedErrorMessage,
  });

  /// The corresponding request id (optional).
  String id;

  /// The error code (optional).
  String errorCode;

  /// The error message (optional).
  String errorMessage;

  /// The detailed error message (optional).
  String detailedErrorMessage;

  factory ResponseHeader.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ResponseHeader(
            id: json['id'],
            errorCode: json['errorCode'],
            errorMessage: json['errorMessage'],
            detailedErrorMessage: json['detailedErrorMessage'],
          )
        : null;
  }
}

/// A base response.
class SpongeResponse {
  SpongeResponse({
    this.header,
  }) {
    this.header ??= ResponseHeader();
  }

  /// The request header (optional).
  ResponseHeader header;

  factory SpongeResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(SpongeResponse(), json);

  static dynamic setupFromJson(
          SpongeResponse response, Map<String, dynamic> json) =>
      response
        ..header = ResponseHeader.fromJson(json['header']) ?? ResponseHeader();
}

/// An action call response.
class ActionCallResponse extends SpongeResponse {
  ActionCallResponse(this.result);

  /// The action result.
  dynamic result;

  factory ActionCallResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(ActionCallResponse(json['result']), json);
}

/// A get actions response.
class GetActionsResponse extends SpongeResponse {
  GetActionsResponse(
    this.actions, {
    this.types,
  });

  /// The available actions.
  List<ActionMeta> actions;

  /// The registered types used in the actions.
  Map<String, DataType> types;

  factory GetActionsResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetActionsResponse(
            (json['actions'] as List)
                    ?.map((action) => ActionMeta.fromJson(action))
                    ?.toList() ??
                [],
            types: (json['types'] as Map)?.map((name, typeJson) =>
                MapEntry(name, DataType.fromJson(typeJson))),
          ),
          json);
}

/// A get knowledge bases response.
class GetKnowledgeBasesResponse extends SpongeResponse {
  GetKnowledgeBasesResponse(this.knowledgeBases);

  /// The available knowledge bases.
  List<KnowledgeBaseMeta> knowledgeBases;

  factory GetKnowledgeBasesResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetKnowledgeBasesResponse((json['knowledgeBases'] as List)
              ?.map(
                  (knowledgeBase) => KnowledgeBaseMeta.fromJson(knowledgeBase))
              ?.toList()),
          json);
}

/// A get version response.
class GetVersionResponse extends SpongeResponse {
  GetVersionResponse(this.version);

  /// The Sponge version.
  String version;

  factory GetVersionResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(GetVersionResponse(json['version']), json);
}

/// A get features response.
class GetFeaturesResponse extends SpongeResponse {
  GetFeaturesResponse(Map<String, dynamic> features)
      : this.features = features ?? {};

  /// The Sponge version.
  Map<String, dynamic> features;

  factory GetFeaturesResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(GetFeaturesResponse(json['features']), json);
}

/// A login response.
class LoginResponse extends SpongeResponse {
  LoginResponse(this.authToken);

  /// The authentication token.
  String authToken;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(LoginResponse(json['authToken']), json);
}

/// A logout response.
class LogoutResponse extends SpongeResponse {
  LogoutResponse();

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(LogoutResponse(), json);
}

/// A reload response.
class ReloadResponse extends SpongeResponse {
  ReloadResponse();

  factory ReloadResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(ReloadResponse(), json);
}

/// A send event response.
class SendEventResponse extends SpongeResponse {
  SendEventResponse(this.eventId);

  /// The event id.
  String eventId;

  factory SendEventResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(SendEventResponse(json['eventId']), json);
}

/// A provide action arguments response.
class ProvideActionArgsResponse extends SpongeResponse {
  ProvideActionArgsResponse(this.provided);

  /// The provided action arguments.
  Map<String, ProvidedValue> provided;

  factory ProvideActionArgsResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          ProvideActionArgsResponse((json['provided'] as Map)?.map(
              (argName, argValueJson) =>
                  MapEntry(argName, ProvidedValue.fromJson(argValueJson)))),
          json);
}

/// A submit action arguments response.
class SubmitActionArgsResponse extends SpongeResponse {
  SubmitActionArgsResponse();

  factory SubmitActionArgsResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(SubmitActionArgsResponse(), json);
}

/// A get event types response.
class GetEventTypesResponse extends SpongeResponse {
  GetEventTypesResponse(this.eventTypes);

  /// The available event types.
  Map<String, RecordType> eventTypes;

  factory GetEventTypesResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetEventTypesResponse((json['eventTypes'] as Map)?.map(
              (name, typeJson) =>
                  MapEntry(name, DataType.fromJson(typeJson) as RecordType))),
          json);
}
