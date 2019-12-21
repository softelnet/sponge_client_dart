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
    this.requestTime,
    this.responseTime,
  });

  /// The corresponding request id (optional).
  String id;

  /// The error code (optional).
  String errorCode;

  /// The error message (optional).
  String errorMessage;

  /// The detailed error message (optional).
  String detailedErrorMessage;

  /// The optional request time.
  DateTime requestTime;

  /// The optional response time.
  DateTime responseTime;

  factory ResponseHeader.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ResponseHeader(
            id: json['id'],
            errorCode: json['errorCode'],
            errorMessage: json['errorMessage'],
            detailedErrorMessage: json['detailedErrorMessage'],
            requestTime: json['requestTime'] != null
                ? DateTime.parse(json['requestTime'])
                : null,
            responseTime: json['responseTime'] != null
                ? DateTime.parse(json['responseTime'])
                : null,
          )
        : null;
  }
}

/// A response body.
abstract class ResponseBody {}

/// A base response.
abstract class SpongeResponse {
  SpongeResponse({
    this.header,
  }) {
    header ??= ResponseHeader();
  }

  /// The request header (optional).
  ResponseHeader header;

  static dynamic setupFromJson(
          SpongeResponse response, Map<String, dynamic> json) =>
      response
        ..header = ResponseHeader.fromJson(json['header']) ?? ResponseHeader();
}

/// A response with a body.
abstract class BodySpongeResponse<T extends ResponseBody>
    extends SpongeResponse {
  BodySpongeResponse(this.body);

  T body;
}

/// An action call response body.
class ActionCallResponseBody implements ResponseBody {
  ActionCallResponseBody({
    @required this.result,
  });

  /// The action result.
  dynamic result;

  factory ActionCallResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null
          ? ActionCallResponseBody(
              result: json['result'],
            )
          : null;
}

/// An action call response.
class ActionCallResponse extends BodySpongeResponse<ActionCallResponseBody> {
  ActionCallResponse(ActionCallResponseBody body) : super(body);

  factory ActionCallResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          ActionCallResponse(ActionCallResponseBody.fromJson(json['body'])),
          json);
}

/// A get actions response body.
class GetActionsResponseBody implements ResponseBody {
  GetActionsResponseBody({
    @required this.actions,
    this.types,
  });

  /// The available actions.
  List<ActionMeta> actions;

  /// The registered types used in the actions.
  Map<String, DataType> types;

  factory GetActionsResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null
          ? GetActionsResponseBody(
              actions: (json['actions'] as List)
                      ?.map((action) => ActionMeta.fromJson(action))
                      ?.toList() ??
                  [],
              types: (json['types'] as Map)?.map((name, typeJson) =>
                  MapEntry(name, DataType.fromJson(typeJson))),
            )
          : null;
}

/// A get actions response.
class GetActionsResponse extends BodySpongeResponse<GetActionsResponseBody> {
  GetActionsResponse(GetActionsResponseBody body) : super(body);

  factory GetActionsResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetActionsResponse(GetActionsResponseBody.fromJson(json['body'])),
          json);
}

/// A get knowledge bases response body.
class GetKnowledgeBasesResponseBody implements ResponseBody {
  GetKnowledgeBasesResponseBody({
    @required this.knowledgeBases,
  });

  /// The available knowledge bases.
  List<KnowledgeBaseMeta> knowledgeBases;

  factory GetKnowledgeBasesResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null
          ? GetKnowledgeBasesResponseBody(
              knowledgeBases: (json['knowledgeBases'] as List)
                  ?.map((knowledgeBase) =>
                      KnowledgeBaseMeta.fromJson(knowledgeBase))
                  ?.toList())
          : null;
}

/// A get knowledge bases response.
class GetKnowledgeBasesResponse
    extends BodySpongeResponse<GetKnowledgeBasesResponseBody> {
  GetKnowledgeBasesResponse(GetKnowledgeBasesResponseBody body) : super(body);

  factory GetKnowledgeBasesResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetKnowledgeBasesResponse(
              GetKnowledgeBasesResponseBody.fromJson(json['body'])),
          json);
}

/// A get version response body.
class GetVersionResponseBody implements ResponseBody {
  GetVersionResponseBody({
    @required this.version,
  });

  /// The Sponge version.
  String version;

  factory GetVersionResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null ? GetVersionResponseBody(version: json['version']) : null;
}

/// A get version response.
class GetVersionResponse extends BodySpongeResponse<GetVersionResponseBody> {
  GetVersionResponse(GetVersionResponseBody body) : super(body);

  factory GetVersionResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetVersionResponse(GetVersionResponseBody.fromJson(json['body'])),
          json);
}

/// A get features response body.
class GetFeaturesResponseBody implements ResponseBody {
  GetFeaturesResponseBody({
    @required Map<String, dynamic> features,
  }) : features = features ?? {};

  /// The Sponge version.
  Map<String, dynamic> features;

  factory GetFeaturesResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null ? GetFeaturesResponseBody(features: json['features']) : null;
}

/// A get features response.
class GetFeaturesResponse extends BodySpongeResponse<GetFeaturesResponseBody> {
  GetFeaturesResponse(GetFeaturesResponseBody body) : super(body);

  factory GetFeaturesResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetFeaturesResponse(GetFeaturesResponseBody.fromJson(json['body'])),
          json);
}

/// A login response body.
class LoginResponseBody implements ResponseBody {
  LoginResponseBody({
    @required this.authToken,
  });

  /// The authentication token.
  String authToken;

  factory LoginResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null ? LoginResponseBody(authToken: json['authToken']) : null;
}

/// A login response.
class LoginResponse extends BodySpongeResponse<LoginResponseBody> {
  LoginResponse(LoginResponseBody body) : super(body);

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          LoginResponse(LoginResponseBody.fromJson(json['body'])), json);
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

/// A send event response body.
class SendEventResponseBody implements ResponseBody {
  SendEventResponseBody({
    @required this.eventId,
  });

  /// The event id.
  String eventId;

  factory SendEventResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null ? SendEventResponseBody(eventId: json['eventId']) : null;
}

/// A send event response.
class SendEventResponse extends BodySpongeResponse<SendEventResponseBody> {
  SendEventResponse(SendEventResponseBody body) : super(body);

  factory SendEventResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          SendEventResponse(SendEventResponseBody.fromJson(json['body'])),
          json);
}

/// An action active response body.
class IsActionActiveResponseBody implements ResponseBody {
  IsActionActiveResponseBody({@required List<bool> active})
      : active = active ?? [];

  ///The actions activity statuses.
  final List<bool> active;

  factory IsActionActiveResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null
          ? IsActionActiveResponseBody(
              active: (json['active'] as List)?.cast<bool>())
          : null;
}

/// An action active response.
class IsActionActiveResponse
    extends BodySpongeResponse<IsActionActiveResponseBody> {
  IsActionActiveResponse(IsActionActiveResponseBody body) : super(body);

  factory IsActionActiveResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          IsActionActiveResponse(
              IsActionActiveResponseBody.fromJson(json['body'])),
          json);
}

/// A provide action arguments response body.
class ProvideActionArgsResponseBody implements ResponseBody {
  ProvideActionArgsResponseBody({
    @required this.provided,
  });

  /// The provided action arguments.
  Map<String, ProvidedValue> provided;

  factory ProvideActionArgsResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null
          ? ProvideActionArgsResponseBody(
              provided: (json['provided'] as Map)?.map(
                  (argName, argValueJson) =>
                      MapEntry(argName, ProvidedValue.fromJson(argValueJson))))
          : null;
}

/// A provide action arguments response.
class ProvideActionArgsResponse
    extends BodySpongeResponse<ProvideActionArgsResponseBody> {
  ProvideActionArgsResponse(ProvideActionArgsResponseBody body) : super(body);

  factory ProvideActionArgsResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          ProvideActionArgsResponse(
              ProvideActionArgsResponseBody.fromJson(json['body'])),
          json);
}

/// A get event types response body.
class GetEventTypesResponseBody implements ResponseBody {
  GetEventTypesResponseBody({
    @required this.eventTypes,
  });

  /// The available event types.
  Map<String, RecordType> eventTypes;

  factory GetEventTypesResponseBody.fromJson(Map<String, dynamic> json) =>
      json != null
          ? GetEventTypesResponseBody(
              eventTypes: (json['eventTypes'] as Map)?.map((name, typeJson) =>
                  MapEntry(name, DataType.fromJson(typeJson) as RecordType)))
          : null;
}

/// A get event types response.
class GetEventTypesResponse
    extends BodySpongeResponse<GetEventTypesResponseBody> {
  GetEventTypesResponse(GetEventTypesResponseBody body) : super(body);

  factory GetEventTypesResponse.fromJson(Map<String, dynamic> json) =>
      SpongeResponse.setupFromJson(
          GetEventTypesResponse(
              GetEventTypesResponseBody.fromJson(json['body'])),
          json);
}
