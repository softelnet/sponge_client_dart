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

/// A response error.
class ResponseError {
  ResponseError(
    this.code,
    this.message, {
    this.data,
  });

  /// The error code.
  final int code;

  /// The error message.
  final String message;

  /// The error data.
  final ErrorData data;

  factory ResponseError.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ResponseError(
            json['code'],
            json['message'],
            data: ErrorData.fromJson(json['data']),
          )
        : null;
  }
}

/// An error data.
class ErrorData {
  ErrorData({
    this.detailedErrorMessage,
  });

  /// The detailed error message.
  final String detailedErrorMessage;

  factory ErrorData.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ErrorData(
            detailedErrorMessage: json['detailedErrorMessage'],
          )
        : null;
  }
}

/// A response header.
class ResponseHeader {
  ResponseHeader({
    this.requestTime,
    this.responseTime,
    this.features,
  });

  /// The optional request time.
  DateTime requestTime;

  /// The optional response time.
  DateTime responseTime;

  /// The response features (optional).
  Map<String, Object> features;

  factory ResponseHeader.fromJson(Map<String, dynamic> json) {
    return json != null
        ? ResponseHeader(
            requestTime: json['requestTime'] != null
                ? DateTime.parse(json['requestTime'])
                : null,
            responseTime: json['responseTime'] != null
                ? DateTime.parse(json['responseTime'])
                : null,
            features: json['features'],
          )
        : null;
  }
}

/// A response result.
class ResponseResult<T> {
  ResponseResult({this.header, this.value});

  /// The response header.
  ResponseHeader header;

  /// The response value.
  T value;

  factory ResponseResult.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic json) onValue,
  }) {
    if (json == null) {
      return null;
    }

    var jsonValue = json['value'];

    return ResponseResult(
      header: ResponseHeader.fromJson(json['header']),
      value:
          jsonValue != null && onValue != null ? onValue(jsonValue) : jsonValue,
    );
  }
}

/// A base response.
abstract class SpongeResponse<T> {
  SpongeResponse({
    this.jsonrpc,
    this.result,
    this.error,
    this.id,
  });

  /// The JSON-RPC version.
  String jsonrpc;

  /// The result.
  ResponseResult<T> result;

  /// The error.
  ResponseError error;

  /// The JSON-RPC id.
  dynamic id;

  @protected
  void setupFromJson(Map<String, dynamic> json) {
    if (json != null) {
      jsonrpc = json['jsonrpc'];
      result = ResponseResult.fromJson(json['result'], onValue: onResultValue);
      error = ResponseError.fromJson(json['error']);
      id = json['id'];
    }
  }

  @protected
  T onResultValue(dynamic json) => json;
}

/// An action call response.
class ActionCallResponse extends SpongeResponse<dynamic> {
  ActionCallResponse._();

  factory ActionCallResponse.fromJson(Map<String, dynamic> json) =>
      ActionCallResponse._()..setupFromJson(json);
}

class GetActionsValue {
  GetActionsValue({
    @required this.actions,
    this.types,
  });

  /// The available actions.
  List<ActionMeta> actions;

  /// The registered types used in the actions.
  Map<String, DataType> types;

  factory GetActionsValue.fromJson(Map<String, dynamic> json) => json != null
      ? GetActionsValue(
          actions: (json['actions'] as List)
                  ?.map((action) => ActionMeta.fromJson(action))
                  ?.toList() ??
              [],
          types: (json['types'] as Map)?.map(
              (name, typeJson) => MapEntry(name, DataType.fromJson(typeJson))),
        )
      : null;
}

/// A get actions response.
class GetActionsResponse extends SpongeResponse<GetActionsValue> {
  GetActionsResponse._();

  factory GetActionsResponse.fromJson(Map<String, dynamic> json) =>
      GetActionsResponse._()..setupFromJson(json);

  @override
  @protected
  GetActionsValue onResultValue(dynamic json) => GetActionsValue.fromJson(json);
}

/// A get event types response.
class GetEventTypesResponse extends SpongeResponse<Map<String, RecordType>> {
  GetEventTypesResponse._();

  factory GetEventTypesResponse.fromJson(Map<String, dynamic> json) =>
      GetEventTypesResponse._()..setupFromJson(json);

  @override
  @protected
  Map<String, RecordType> onResultValue(dynamic json) =>
      (json as Map)?.map((name, typeJson) =>
          MapEntry(name, DataType.fromJson(typeJson) as RecordType));
}

/// A get features response.
class GetFeaturesResponse extends SpongeResponse<Map<String, dynamic>> {
  GetFeaturesResponse._();

  factory GetFeaturesResponse.fromJson(Map<String, dynamic> json) =>
      GetFeaturesResponse._()..setupFromJson(json);
}

/// A get knowledge bases response.
class GetKnowledgeBasesResponse
    extends SpongeResponse<List<KnowledgeBaseMeta>> {
  GetKnowledgeBasesResponse._();

  factory GetKnowledgeBasesResponse.fromJson(Map<String, dynamic> json) =>
      GetKnowledgeBasesResponse._()..setupFromJson(json);

  @override
  @protected
  List<KnowledgeBaseMeta> onResultValue(dynamic json) => (json as List)
      ?.map((knowledgeBase) => KnowledgeBaseMeta.fromJson(knowledgeBase))
      ?.toList();
}

/// A get version response.
class GetVersionResponse extends SpongeResponse<String> {
  GetVersionResponse._();

  factory GetVersionResponse.fromJson(Map<String, dynamic> json) =>
      GetVersionResponse._()..setupFromJson(json);
}

/// An action active response.
class IsActionActiveResponse extends SpongeResponse<List<bool>> {
  IsActionActiveResponse._();

  factory IsActionActiveResponse.fromJson(Map<String, dynamic> json) =>
      IsActionActiveResponse._()..setupFromJson(json);

  @override
  @protected
  List<bool> onResultValue(dynamic json) => (json as List)?.cast<bool>();
}

/// A login response value.
class LoginValue {
  LoginValue({
    @required this.authToken,
  });

  /// The authentication token.
  String authToken;

  factory LoginValue.fromJson(Map<String, dynamic> json) =>
      json != null ? LoginValue(authToken: json['authToken']) : null;
}

/// A login response.
class LoginResponse extends SpongeResponse<LoginValue> {
  LoginResponse._();

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      LoginResponse._()..setupFromJson(json);

  @override
  @protected
  LoginValue onResultValue(dynamic json) => LoginValue.fromJson(json);
}

/// A logout response.
class LogoutResponse extends SpongeResponse<bool> {
  LogoutResponse._();

  factory LogoutResponse.fromJson(Map<String, dynamic> json) =>
      LogoutResponse._()..setupFromJson(json);
}

/// A provide action arguments response.
class ProvideActionArgsResponse
    extends SpongeResponse<Map<String, ProvidedValue>> {
  ProvideActionArgsResponse._();

  factory ProvideActionArgsResponse.fromJson(Map<String, dynamic> json) =>
      ProvideActionArgsResponse._()..setupFromJson(json);

  @override
  @protected
  Map<String, ProvidedValue> onResultValue(dynamic json) =>
      (json as Map)?.map((argName, argValueJson) =>
          MapEntry(argName, ProvidedValue.fromJson(argValueJson)));
}

/// A reload response.
class ReloadResponse extends SpongeResponse<bool> {
  ReloadResponse._();

  factory ReloadResponse.fromJson(Map<String, dynamic> json) =>
      ReloadResponse._()..setupFromJson(json);
}

/// A send event response body.
class SendEventResponse extends SpongeResponse<String> {
  SendEventResponse._();

  factory SendEventResponse.fromJson(Map<String, dynamic> json) =>
      SendEventResponse._()..setupFromJson(json);
}

class ErrorResponse extends SpongeResponse<dynamic> {
  ErrorResponse._();

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      ErrorResponse._()..setupFromJson(json);
}
