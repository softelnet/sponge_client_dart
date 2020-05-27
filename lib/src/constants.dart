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

/// The Sponge client constants.
abstract class SpongeClientConstants {
  static const String SUPPORTED_SPONGE_VERSION_MAJOR_MINOR = '1.16';

  static const String CONTENT_TYPE_JSON = 'application/json;charset=utf-8';
  static const int DEFAULT_PORT = 1836;

  static const String ENDPOINT_JSONRPC = 'jsonrpc';
  static const String METHOD_VERSION = 'version';
  static const String METHOD_FEATURES = 'features';
  static const String METHOD_LOGIN = 'login';
  static const String METHOD_LOGOUT = 'logout';
  static const String METHOD_KNOWLEDGE_BASES = 'knowledgeBases';
  static const String METHOD_ACTIONS = 'actions';
  static const String METHOD_CALL = 'call';
  static const String METHOD_SEND = 'send';
  static const String METHOD_IS_ACTION_ACTIVE = 'isActionActive';
  static const String METHOD_PROVIDE_ACTION_ARGS = 'provideActionArgs';
  static const String METHOD_EVENT_TYPES = 'eventTypes';
  static const String METHOD_RELOAD = 'reload';

  static const String PARAM_HEADER = 'header';

  static const int ERROR_CODE_GENERIC = 1001;
  static const int ERROR_CODE_INVALID_AUTH_TOKEN = 1002;
  static const int ERROR_CODE_INVALID_KB_VERSION = 1003;
  static const int ERROR_CODE_INVALID_USERNAME_PASSWORD = 1004;
  static const int ERROR_CODE_INACTIVE_ACTION = 1005;

  static const String ATTRIBUTE_PATH_SEPARATOR = '.';

  static const String REMOTE_API_FEATURE_SPONGE_VERSION = 'spongeVersion';
  static const String REMOTE_API_FEATURE_API_VERSION = 'apiVersion';
  static const String REMOTE_API_FEATURE_GRPC_ENABLED = 'grpcEnabled';
  static const String REMOTE_API_FEATURE_NAME = 'name';
  static const String REMOTE_API_FEATURE_DESCRIPTION = 'description';
  static const String REMOTE_API_FEATURE_LICENSE = 'license';

  static const String REMOTE_EVENT_OBJECT_TYPE_CLASS_NAME =
      'org.openksavi.sponge.remoteapi.model.RemoteEvent';

  static const int HTTP_CODE_ERROR = 500;

  static const String SERVICE_DISCOVERY_TYPE = '_sponge._tcp';

  static const String SERVICE_DISCOVERY_PROPERTY_UUID = 'uuid';
  static const String SERVICE_DISCOVERY_PROPERTY_NAME = 'name';
  static const String SERVICE_DISCOVERY_PROPERTY_URL = 'url';
}

/// JSON-RPC 2.0 constants.
abstract class JsonRpcConstants {
  static const int ERROR_CODE_PARSE = -32700;
  static const int ERROR_CODE_INVALID_REQUEST = -32600;
  static const int ERROR_CODE_METHOD_NOT_FOUND = -32601;
  static const int ERROR_CODE_INVALID_PARAMS = -32602;
  static const int ERROR_CODE_INTERNAL = -32603;

  static const String MEMBER_METHOD = 'method';
  static const String MEMBER_ID = 'id';
  static const String MEMBER_JSONRPC = 'jsonrpc';
  static const String MEMBER_PARAMS = 'params';

  static const String VERSION = '2.0';
}
