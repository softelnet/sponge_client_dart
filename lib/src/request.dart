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

/// A base request.
class SpongeRequest {
  SpongeRequest({
    this.id,
    this.username,
    this.password,
    this.authToken,
  });

  /// The request id (optional).
  String id;

  /// The user name (optional).
  String username;

  /// The user password (optional).
  String password;

  /// The authentication token (optional).
  String authToken;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'authToken': authToken,
    };
  }
}

/// An action execution related request.
abstract class ActionExecutionRequest {
  String get name;
  ProcessorQualifiedVersion qualifiedVersion;
}

/// An action call request.
class ActionCallRequest extends SpongeRequest
    implements ActionExecutionRequest {
  ActionCallRequest(
    this.name, {
    this.args,
    this.qualifiedVersion,
  });

  /// The action name.
  final String name;

  /// The action arguments (optional).
  List args;

  /// The action expected qualified version (optional).
  ProcessorQualifiedVersion qualifiedVersion;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
      'args': args,
      'qualifiedVersion': qualifiedVersion,
    });
}

/// A get actions request.
class GetActionsRequest extends SpongeRequest {
  GetActionsRequest({
    this.name,
    this.metadataRequired,
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

/// A get knowledge bases request.
class GetKnowledgeBasesRequest extends SpongeRequest {}

/// A get version request
class GetVersionRequest extends SpongeRequest {}

/// A login request.
class LoginRequest extends SpongeRequest {
  LoginRequest(
    String username,
    String password,
  ) : super(username: username, password: password);
}

/// A logout request.
class LogoutRequest extends SpongeRequest {}

/// A reload request.
class ReloadRequest extends SpongeRequest {}

/// A send event request.
class SendEventRequest extends SpongeRequest {
  SendEventRequest(
    this.name, {
    this.attributes,
  });

  /// The event name.
  final String name;

  /// The event attributes (optional).
  final Map<String, Object> attributes;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
      'attributes': attributes,
    });
}

/// A provide action arguments request.
class ProvideActionArgsRequest extends SpongeRequest
    implements ActionExecutionRequest {
  ProvideActionArgsRequest(
    this.name,
    this.argNames,
    this.current, {
    this.qualifiedVersion,
  });

  /// The action name.
  final String name;

  /// The names of action arguments to provide.
  final List<String> argNames;

  /// The current values of action arguments in a client code.
  Map<String, Object> current;

  /// The action expected qualified version (optional).
  ProcessorQualifiedVersion qualifiedVersion;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'name': name,
      'argNames': argNames,
      'current': current,
      'qualifiedVersion': qualifiedVersion,
    });
}
