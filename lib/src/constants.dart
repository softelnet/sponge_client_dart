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
  static const String SUPPORTED_SPONGE_VERSION_MAJOR_MINOR = '1.15';

  static const int API_VERSION = 1;
  static const String CONTENT_TYPE_JSON = 'application/json;charset=utf-8';
  static const int DEFAULT_PORT = 1836;

  static const String OPERATION_VERSION = 'version';
  static const String OPERATION_FEATURES = 'features';
  static const String OPERATION_LOGIN = 'login';
  static const String OPERATION_LOGOUT = 'logout';
  static const String OPERATION_KNOWLEDGE_BASES = 'knowledgeBases';
  static const String OPERATION_ACTIONS = 'actions';
  static const String OPERATION_CALL = 'call';
  static const String OPERATION_SEND = 'send';
  static const String OPERATION_IS_ACTION_ACTIVE = 'isActionActive';
  static const String OPERATION_PROVIDE_ACTION_ARGS = 'provideActionArgs';
  static const String OPERATION_EVENT_TYPES = 'eventTypes';

  static const String OPERATION_RELOAD = 'reload';

  static const String ERROR_CODE_GENERIC = 'GENERIC';
  static const String ERROR_CODE_INVALID_AUTH_TOKEN = 'INVALID_AUTH_TOKEN';
  static const String ERROR_CODE_INVALID_KB_VERSION = 'INVALID_KB_VERSION';
  static const String ERROR_CODE_INVALID_USERNAME_PASSWORD =
      'INVALID_USERNAME_PASSWORD';
  static const String ERROR_CODE_INACTIVE_ACTION = 'INACTIVE_ACTION';

  static const String ATTRIBUTE_PATH_SEPARATOR = '.';

  static const String REMOTE_API_FEATURE_VERSION = 'version';
  static const String REMOTE_API_FEATURE_GRPC_ENABLED = 'grpcEnabled';

  static const String REMOTE_EVENT_OBJECT_TYPE_CLASS_NAME =
      'org.openksavi.sponge.restapi.model.RemoteEvent';

  static const int HTTP_CODE_ERROR = 500;

  static const String SERVICE_DISCOVERY_TYPE = '_sponge._tcp';

  static const String SERVICE_DISCOVERY_PROPERTY_UUID = 'uuid';
  static const String SERVICE_DISCOVERY_PROPERTY_NAME = 'name';
  static const String SERVICE_DISCOVERY_PROPERTY_URL = 'url';
}
