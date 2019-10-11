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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:quiver/cache.dart';
import 'package:sponge_client_dart/src/context.dart';
import 'package:sponge_client_dart/src/rest_client_configuration.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/exception.dart';
import 'package:sponge_client_dart/src/listener.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/request.dart';
import 'package:sponge_client_dart/src/response.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_converter.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/util/validate.dart';
import 'package:sponge_client_dart/src/utils.dart';
import 'package:synchronized/synchronized.dart';

/// A Sponge REST API client.
///
/// SpongeRestClient performs best when you create a single instance and reuse it for all of your REST API calls.
/// It keeps action metadata cache.
class SpongeRestClient {
  SpongeRestClient(
    this._configuration, {
    TypeConverter typeConverter,
  }) : _typeConverter = typeConverter ?? DefaultTypeConverter() {
    _actionMetaCache = _createActionMetaCache();
    _eventTypeCache = _createEventTypeCache();
  }

  static final Logger _logger = Logger('SpongeRestClient');
  final SpongeRestClientConfiguration _configuration;

  /// The REST API client configuration.
  SpongeRestClientConfiguration get configuration => _configuration;

  String get _url => _configuration.url;

  int _currentRequestId = 0;
  int get currentRequestId => _currentRequestId;

  String _currentAuthToken;
  String get currentAuthToken => _currentAuthToken;

  MapCache<String, ActionMeta> _actionMetaCache;
  MapCache<String, RecordType> _eventTypeCache;
  Map<String, dynamic> _featuresCache;
  final TypeConverter _typeConverter;

  /// The type converter.
  TypeConverter get typeConverter => _typeConverter;

  final Lock _lock = Lock(reentrant: true);

  final List<OnRequestSerializedListener> _onRequestSerializedListeners = [];

  final List<OnResponseDeserializedListener> _onResponseDeserializedListeners =
      [];

  void addOnRequestSerializedListener(OnRequestSerializedListener listener) =>
      _onRequestSerializedListeners.add(listener);

  bool removeOnRequestSerializedListener(
          OnRequestSerializedListener listener) =>
      _onRequestSerializedListeners.remove(listener);

  void addOnResponseDeserializedListener(
          OnResponseDeserializedListener listener) =>
      _onResponseDeserializedListeners.add(listener);

  bool removeOnResponseDeserializedListener(
          OnResponseDeserializedListener listener) =>
      _onResponseDeserializedListeners.remove(listener);

  String _getUrl(String operation) =>
      _url + (_url.endsWith('/') ? '' : '/') + operation;

  T setupRequest<T extends SpongeRequest>(T request) {
    // Set empty header if none.
    request.header ??= RequestHeader();

    var header = request.header;

    if (_configuration.useRequestId) {
      int newRequestId = ++_currentRequestId;
      header.id = '$newRequestId';
    }

    // Must be isolate-safe.
    String authToken = _currentAuthToken;
    if (authToken != null) {
      header.authToken ??= authToken;
    } else {
      if (_configuration.username != null && header.username == null) {
        header.username = _configuration.username;
      }
      if (_configuration.password != null && header.password == null) {
        header.password = _configuration.password;
      }
    }

    return request;
  }

  R _setupResponse<R extends SpongeResponse>(String operation, R response) {
    // Set empty header if none.
    response.header ??= ResponseHeader();
    handleResponseHeader(operation, response.header.errorCode,
        response.header.errorMessage, response.header.detailedErrorMessage);

    return response;
  }

  void handleResponseHeader(String operation, String errorCode,
      String errorMessage, String detailedErrorMessage) {
    if (errorCode != null) {
      _logger.fine(() =>
          'Error response for $operation ($errorCode): $errorMessage\n${detailedErrorMessage ?? ""}');

      if (_configuration.throwExceptionOnErrorResponse) {
        switch (errorCode) {
          case SpongeClientConstants.ERROR_CODE_INVALID_AUTH_TOKEN:
            throw InvalidAuthTokenException(
                errorCode, errorMessage, detailedErrorMessage);
          case SpongeClientConstants.ERROR_CODE_INVALID_KB_VERSION:
            throw InvalidKnowledgeBaseVersionException(
                errorCode, errorMessage, detailedErrorMessage);
          case SpongeClientConstants.ERROR_CODE_INVALID_USERNAME_PASSWORD:
            throw InvalidUsernamePasswordException(
                errorCode, errorMessage, detailedErrorMessage);
          default:
            throw SpongeClientException(
                errorCode, errorMessage, detailedErrorMessage);
        }
      }
    }
  }

  bool _isRequestAnonymous(String requestUsername, String requestPassword) =>
      _configuration.username == null &&
      requestUsername == null &&
      _configuration.password == null &&
      requestPassword == null;

  Future<T> executeWithAuthentication<T>({
    @required String requestUsername,
    @required String requestPassword,
    @required String requestAuthToken,
    @required Future<T> onExecute(),
    @required void onClearAuthToken(),
  }) async {
    try {
      if (_configuration.autoUseAuthToken &&
          _currentAuthToken == null &&
          requestAuthToken == null &&
          !_isRequestAnonymous(requestUsername, requestPassword)) {
        await login();
      }

      return await onExecute();
    } on InvalidAuthTokenException {
      // Relogin if set up and necessary.
      if (_currentAuthToken != null && _configuration.relogin) {
        await login();

        // Clear the request auth token.
        onClearAuthToken();

        return await onExecute();
      } else {
        rethrow;
      }
    }
  }

  /// Sends the request to the server and returns the response.
  Future<R> execute<T extends SpongeRequest, R extends SpongeResponse>(
      String operation, T request, ResponseFromJsonCallback<R> fromJson,
      [SpongeRequestContext context]) async {
    context ??= SpongeRequestContext();

    // Set empty header if none.
    request.header ??= RequestHeader();

    return await executeWithAuthentication(
        requestUsername: request.header.username,
        requestPassword: request.header.password,
        requestAuthToken: request.header.authToken,
        onExecute: () async =>
            await _executeDelegate(operation, request, fromJson, context),
        onClearAuthToken: () {
          request.header.authToken = null;
        });
  }

  Future<SpongeResponse> _executeDelegate(
      String operation,
      SpongeRequest request,
      ResponseFromJsonCallback fromJson,
      SpongeRequestContext context) async {
    context ??= SpongeRequestContext();

    return _setupResponse(operation,
        await _doExecute(operation, setupRequest(request), fromJson, context));
  }

  void _fireOnRequestSerializedListener(
      SpongeRequest request, SpongeRequestContext context, String requestBody) {
    if (context.onRequestSerializedListener != null) {
      context.onRequestSerializedListener(request, requestBody);
    }
    _onRequestSerializedListeners
        .where((listener) => listener != null)
        .forEach((listener) => listener(request, requestBody));
  }

  void _fireOnResponseDeserializedListener(
      SpongeRequest request,
      SpongeRequestContext context,
      SpongeResponse response,
      String responseBody) {
    if (context.onResponseDeserializedListener != null) {
      context.onResponseDeserializedListener(request, response, responseBody);
    }
    _onResponseDeserializedListeners
        .where((listener) => listener != null)
        .forEach((listener) => listener(request, response, responseBody));
  }

  Future<SpongeResponse> _doExecute(String operation, SpongeRequest request,
      ResponseFromJsonCallback fromJson, SpongeRequestContext context) async {
    String requestBody = json.encode(request.toJson());

    _logger.finer(() =>
        'REST API $operation request: ${SpongeUtils.obfuscatePassword(requestBody)}');

    _fireOnRequestSerializedListener(request, context, requestBody);

    Response httpResponse = await post(_getUrl(operation),
        headers: {'Content-type': SpongeClientConstants.CONTENT_TYPE_JSON},
        body: requestBody);

    _logger.finer(() =>
        'REST API $operation response: ${SpongeUtils.obfuscatePassword(httpResponse.body)})');

    if (!SpongeUtils.isHttpSuccess(httpResponse.statusCode)) {
      _logger.fine(() =>
          'HTTP error (status code ${httpResponse.statusCode}): ${httpResponse.body}');
      throw Exception('HTTP error (status code ${httpResponse.statusCode})');
    }

    String responseBody = httpResponse.body;
    SpongeResponse response;
    try {
      response = fromJson(json.decode(responseBody));
    } finally {
      _fireOnResponseDeserializedListener(
          request, context, response, responseBody);
    }
    return response;
  }

  /// Sends the `version` request to the server and returns the response.
  Future<GetVersionResponse> getVersionByRequest(GetVersionRequest request,
          {SpongeRequestContext context}) async =>
      await execute(SpongeClientConstants.OPERATION_VERSION, request,
          (json) => GetVersionResponse.fromJson(json), context);

  /// Sends the `version` request to the server and returns the version.
  Future<String> getVersion() async =>
      (await getVersionByRequest(GetVersionRequest())).version;

  /// Sends the `features` request to the server and returns the response.
  Future<GetFeaturesResponse> getFeaturesByRequest(GetFeaturesRequest request,
          {SpongeRequestContext context}) async =>
      await execute(SpongeClientConstants.OPERATION_FEATURES, request,
          (json) => GetFeaturesResponse.fromJson(json), context);

  /// Returns the Sponge API features by sending the `features` request to the server and returning the features or using the cache.
  Future<Map<String, dynamic>> getFeatures() async {
    _featuresCache ??=
        (await getFeaturesByRequest(GetFeaturesRequest())).features;

    return _featuresCache;
  }

  /// Sends the `login` request to the server and returns the response. Sets the auth token
  /// in the client for further requests.
  Future<LoginResponse> loginByRequest(LoginRequest request,
      {SpongeRequestContext context}) async {
    return await _lock.synchronized(() async {
      _currentAuthToken = null;
      LoginResponse response = await _executeDelegate(
          SpongeClientConstants.OPERATION_LOGIN,
          request,
          (json) => LoginResponse.fromJson(json),
          context);
      _currentAuthToken = response.authToken;

      return response;
    });
  }

  /// Sends the `login` request to the server and returns the auth token. See [loginByRequest].
  Future<String> login() async => (await loginByRequest(
          LoginRequest(_configuration.username, _configuration.password)))
      .authToken;

  /// Sends the `logout` request to the server and returns the response.
  /// Clears the auth token in the client.
  Future<LogoutResponse> logoutByRequest(LogoutRequest request,
      {SpongeRequestContext context}) async {
    return await _lock.synchronized(() async {
      LogoutResponse response = await execute(
          SpongeClientConstants.OPERATION_LOGOUT,
          request,
          (json) => LogoutResponse.fromJson(json),
          context);
      _currentAuthToken = null;

      return response;
    });
  }

  /// Sends the `logout` request to the server. See [logoutByRequest].
  Future<void> logout() async {
    await logoutByRequest(LogoutRequest());
  }

  /// Sends the `knowledgeBases` request to the server and returns the response.
  Future<GetKnowledgeBasesResponse> getKnowledgeBasesByRequest(
          GetKnowledgeBasesRequest request,
          {SpongeRequestContext context}) async =>
      await execute(SpongeClientConstants.OPERATION_KNOWLEDGE_BASES, request,
          (json) => GetKnowledgeBasesResponse.fromJson(json), context);

  /// Sends the `knowledgeBases` request to the server and returns the list of available
  /// knowledge bases metadata.
  Future<List<KnowledgeBaseMeta>> getKnowledgeBases() async =>
      (await getKnowledgeBasesByRequest(GetKnowledgeBasesRequest()))
          .knowledgeBases;

  /// Sends the `actions` request to the server and returns the response. This method may populate
  /// the action metadata cache.
  Future<GetActionsResponse> getActionsByRequest(GetActionsRequest request,
          {SpongeRequestContext context}) async =>
      await _doGetActionsByRequest(request, true, context);

  /// Sends the `actions` request to the server and returns the list of available actions metadata.
  Future<List<ActionMeta>> getActions(
          {String name, bool metadataRequired}) async =>
      (await getActionsByRequest(GetActionsRequest(
              name: name, metadataRequired: metadataRequired)))
          .actions;

  Future<GetActionsResponse> _doGetActionsByRequest(GetActionsRequest request,
      bool populateCache, SpongeRequestContext context) async {
    GetActionsResponse response = await execute(
        SpongeClientConstants.OPERATION_ACTIONS,
        request,
        (json) => GetActionsResponse.fromJson(json),
        context);

    if (response.actions != null) {
      // Unmarshal defaultValues in action meta.
      for (var actionMeta in response.actions) {
        await _unmarshalActionMeta(actionMeta);
      }

      // Populate the meta cache.
      if (populateCache &&
          configuration.useActionMetaCache &&
          _actionMetaCache != null) {
        await for (var actionMeta in Stream.fromIterable(response.actions)) {
          await _actionMetaCache.set(actionMeta.name, actionMeta);
        }
      }
    }

    if (response.types != null) {
      for (var type in response.types.values) {
        await _unmarshalDataType(type);
      }
    }

    return response;
  }

  Future<void> _unmarshalDataType(DataType type) async {
    type.defaultValue = await _typeConverter.unmarshal(type, type.defaultValue);
  }

  Future<void> _unmarshalActionMeta(ActionMeta actionMeta) async {
    if (actionMeta?.args == null) {
      return;
    }

    for (var argType in actionMeta.args) {
      await _unmarshalDataType(argType);
    }

    if (actionMeta.result != null) {
      await _unmarshalDataType(actionMeta.result);
    }
  }

  Future<void> unmarshalProvidedActionArgValues(
      ActionMeta actionMeta, Map<String, ProvidedValue> argValues) async {
    if (argValues == null || actionMeta.args == null) {
      return;
    }

    for (var entry in argValues.entries) {
      ProvidedValue argValue = entry.value;
      var argType = actionMeta.getArg(entry.key);

      argValue.value = await _typeConverter.unmarshal(argType, argValue.value);

      if (argValue.annotatedValueSet != null) {
        for (var annotatedValue in argValue.annotatedValueSet) {
          if (annotatedValue != null) {
            annotatedValue.value =
                await _typeConverter.unmarshal(argType, annotatedValue.value);
          }
        }
      }

      if (argValue.annotatedElementValueSet != null &&
          SpongeUtils.supportsElementValueSet(argType)) {
        for (var annotatedValue in argValue.annotatedElementValueSet) {
          if (annotatedValue != null) {
            annotatedValue.value = await _typeConverter.unmarshal(
                (argType as ListType).elementType, annotatedValue.value);
          }
        }
      }
    }
  }

  Future<ActionMeta> _fetchActionMeta(
      String actionName, SpongeRequestContext context) async {
    var request = GetActionsRequest(metadataRequired: true, name: actionName);
    var response = await _doGetActionsByRequest(request, false, context);

    return response.actions?.singleWhere((_) => true, orElse: () => null);
  }

  /// Returns the metadata for the specified action or `null` if there is no such action
  /// or that action has no metadata.
  ///
  /// This method may fetch the metadata from the server or use the action metadata cache if configured.
  /// If you want to prevent fetching metadata from the server, set [allowFetchMetadata] to `false`.
  /// The default value is `true`.
  Future<ActionMeta> getActionMeta(String actionName,
      {bool allowFetchMetadata = true, SpongeRequestContext context}) async {
    allowFetchMetadata = allowFetchMetadata ?? true;
    if (_configuration.useActionMetaCache && _actionMetaCache != null) {
      ActionMeta actionMeta = await _actionMetaCache.get(actionName);
      // Populate the cache if not found.
      return actionMeta ??
          (allowFetchMetadata
              ? await _actionMetaCache.get(actionName,
                  ifAbsent: (name) async =>
                      await _fetchActionMeta(name, context))
              : null);
    } else {
      return allowFetchMetadata
          ? await _fetchActionMeta(actionName, context)
          : null;
    }
  }

  /// Sends the `call` request to the server and returns the response.
  ///
  /// Marshals the arguments and unmarshals the result using a best effort strategy, i.e. when a metadata
  /// is defined.
  ///
  /// If the action metadata [actionMeta] is not `null`, it will be used for marshalling and unmarshalling.
  /// If the [actionMeta] is `null`, this method may fetch the action metadata from the server if the action
  /// metadata cache is turned off or is not populated.
  ///
  /// If [allowFetchMetadata] is `true` (the default value), the action metadata (if `null`) may be fetched
  /// from the server by sending an additional request. If [allowFetchMetadata] is `false` and the action
  /// metadata is `null` or is not in the cache, the marshalling of arguments and unmarshalling of the result
  /// will be suppressed.
  Future<ActionCallResponse> callByRequest(ActionCallRequest request,
          {ActionMeta actionMeta,
          bool allowFetchMetadata = true,
          SpongeRequestContext context}) async =>
      await _doCallByRequest(
          actionMeta ??
              await getActionMeta(request.name,
                  allowFetchMetadata: allowFetchMetadata),
          request,
          context);

  /// Sends the `call` request to the server and returns the response. See [callByRequest].
  Future<dynamic> call(String actionName,
          [List args,
          ActionMeta actionMeta,
          bool allowFetchMetadata = true]) async =>
      (await callByRequest(ActionCallRequest(actionName, args: args),
              actionMeta: actionMeta, allowFetchMetadata: allowFetchMetadata))
          .result;

  void _setupActionExecutionRequest(
      ActionMeta actionMeta, ActionExecutionRequest request) {
    // Conditionally set the verification of the processor qualified version on the server side.
    if (_configuration.verifyProcessorVersion &&
        actionMeta != null &&
        request.qualifiedVersion == null) {
      request.qualifiedVersion = actionMeta.qualifiedVersion;
    }

    Validate.isTrue(
        actionMeta == null || actionMeta.name == request.name,
        'Action name ${actionMeta?.name} in the metadata doesn\'t match '
        'the action name ${request?.name} in the request');
  }

  Future<ActionCallResponse> _doCallByRequest(ActionMeta actionMeta,
      ActionCallRequest request, SpongeRequestContext context) async {
    _setupActionExecutionRequest(actionMeta, request);

    validateCallArgs(actionMeta, request.args);

    request.args = await _marshalActionCallArgs(actionMeta, request.args);

    ActionCallResponse response = await execute(
        SpongeClientConstants.OPERATION_CALL,
        request,
        (json) => ActionCallResponse.fromJson(json),
        context);

    await _unmarshalActionCallResult(actionMeta, response);

    return response;
  }

  /// Validates the action call arguments. This method is invoked internally by the `call` methods.
  /// Throws exception on validation failure.
  void validateCallArgs(ActionMeta actionMeta, List args) {
    if (actionMeta?.args == null) {
      return;
    }

    int expectedAllArgCount = actionMeta.args.length;
    int expectedNonOptionalArgCount =
        actionMeta.args.where((argType) => !argType.optional).length;
    int actualArgCount = args?.length ?? 0;

    if (expectedNonOptionalArgCount == expectedAllArgCount) {
      Validate.isTrue(expectedAllArgCount == actualArgCount,
          'Incorrect number of arguments. Expected $expectedAllArgCount but got $actualArgCount');
    } else {
      Validate.isTrue(
          expectedNonOptionalArgCount <= actualArgCount &&
              actualArgCount <= expectedAllArgCount,
          'Incorrect number of arguments. Expected between $expectedNonOptionalArgCount and $expectedAllArgCount'
          ' but got $actualArgCount');
    }

    // Validate non-nullable arguments.
    for (int i = 0; i < actionMeta.args.length; i++) {
      var argType = actionMeta.args[i];
      Validate.isTrue(argType.optional || argType.nullable || args[i] != null,
          'The ${argType.label ?? argType.name} action argument is not set');
    }
  }

  // Marshals the action call arguments.
  Future<List> _marshalActionCallArgs(ActionMeta actionMeta, List args) async {
    if (args == null || actionMeta?.args == null) {
      return args;
    }

    List result = [];
    for (int i = 0; i < args.length; i++) {
      result.add(await _typeConverter.marshal(actionMeta.args[i], args[i]));
    }

    return result;
  }

  Future<Map<String, Object>> _marshalAuxiliaryActionArgsCurrent(
      ActionMeta actionMeta, Map<String, Object> current) async {
    if (current == null || actionMeta?.args == null) {
      return current;
    }

    Map<String, Object> marshalled = {};
    for (var entry in current.entries) {
      var name = entry.key;
      marshalled[name] =
          await _typeConverter.marshal(actionMeta.getArg(name), entry.value);
    }

    return marshalled;
  }

  /// Unmarshals the action call result.
  Future<void> _unmarshalActionCallResult(
      ActionMeta actionMeta, ActionCallResponse response) async {
    if (actionMeta?.result == null || response.result == null) {
      return;
    }

    response.result =
        await _typeConverter.unmarshal(actionMeta.result, response.result);
  }

  /// Sends the `provideActionArgs` request to the server. Fetches the provided action arguments from the server.
  Future<ProvideActionArgsResponse> provideActionArgsByRequest(
      ProvideActionArgsRequest request,
      {SpongeRequestContext context}) async {
    ActionMeta actionMeta = await getActionMeta(request.name);
    _setupActionExecutionRequest(actionMeta, request);

    request.current =
        await _marshalAuxiliaryActionArgsCurrent(actionMeta, request.current);

    ProvideActionArgsResponse response = await execute(
        SpongeClientConstants.OPERATION_PROVIDE_ACTION_ARGS,
        request,
        (json) => ProvideActionArgsResponse.fromJson(json),
        context);

    if (actionMeta != null) {
      await unmarshalProvidedActionArgValues(actionMeta, response.provided);
    }

    return response;
  }

  /// Fetches the provided action arguments from the server.
  Future<Map<String, ProvidedValue>> provideActionArgs(
    String actionName, {
    List<String> argNames,
    Map<String, Object> current,
  }) async =>
      (await provideActionArgsByRequest(
              ProvideActionArgsRequest(actionName, argNames, current: current)))
          .provided;

  /// Sends the `submitActionArgs` request to the server to submit action arguments.
  Future<SubmitActionArgsResponse> submitActionArgsByRequest(
      SubmitActionArgsRequest request,
      {SpongeRequestContext context}) async {
    ActionMeta actionMeta = await getActionMeta(request.name);
    _setupActionExecutionRequest(actionMeta, request);

    request.current =
        await _marshalAuxiliaryActionArgsCurrent(actionMeta, request.current);

    return await execute(SpongeClientConstants.OPERATION_SUBMIT_ACTION_ARGS,
        request, (json) => SubmitActionArgsResponse.fromJson(json), context);
  }

  /// Submits action arguments.
  Future<void> submitActionArgs(
    String actionName, {
    List<String> argNames,
    Map<String, Object> current,
  }) async =>
      (await submitActionArgsByRequest(
          SubmitActionArgsRequest(actionName, argNames, current: current)));

  /// Sends the `eventTypes` request to the server.
  Future<GetEventTypesResponse> _doGetEventTypesByRequest(
      GetEventTypesRequest request,
      bool populateCache,
      SpongeRequestContext context) async {
    GetEventTypesResponse response = await execute(
        SpongeClientConstants.OPERATION_EVENT_TYPES,
        request,
        (json) => GetEventTypesResponse.fromJson(json),
        context);

    if (response?.eventTypes != null) {
      for (var eventType in response.eventTypes.values) {
        await _unmarshalDataType(eventType);
      }

      // Populate the event type cache.
      if (populateCache &&
          configuration.useEventTypeCache &&
          _eventTypeCache != null) {
        for (var entry in response.eventTypes.entries) {
          await _eventTypeCache.set(entry.key, entry.value);
        }
      }
    }

    return response;
  }

  /// Sends the `eventTypes` request to the server.
  Future<GetEventTypesResponse> getEventTypesByRequest(
          GetEventTypesRequest request,
          {SpongeRequestContext context}) async =>
      await _doGetEventTypesByRequest(request, true, context);

  /// Sends the `eventTypes` request to the server.
  Future<Map<String, RecordType>> getEventTypes({String name}) async =>
      (await getEventTypesByRequest(GetEventTypesRequest(name))).eventTypes;

  /// Returns the event type for the specified event type name or `null` if there is no such event type.
  ///
  /// This method may fetch the event type from the server or use the event type cache if configured.
  /// If you want to prevent fetching the event type from the server, set [allowFetchEventType] to `false`.
  /// The default value is `true`.
  Future<RecordType> getEventType(String eventTypeName,
      {bool allowFetchEventType = true, SpongeRequestContext context}) async {
    allowFetchEventType = allowFetchEventType ?? true;
    if (_configuration.useEventTypeCache && _eventTypeCache != null) {
      RecordType eventType = await _eventTypeCache.get(eventTypeName);
      // Populate the cache if not found.
      return eventType ??
          (allowFetchEventType
              ? await _eventTypeCache.get(eventTypeName,
                  ifAbsent: (name) async =>
                      await _fetchEventType(name, context))
              : null);
    } else {
      return allowFetchEventType
          ? await _fetchEventType(eventTypeName, context)
          : null;
    }
  }

  Future<RecordType> _fetchEventType(
          String eventTypeName, SpongeRequestContext context) async =>
      (await _doGetEventTypesByRequest(
              GetEventTypesRequest(eventTypeName), false, context))
          .eventTypes[eventTypeName];

  /// Sends the `send` request to the server and returns the response.
  Future<SendEventResponse> sendByRequest(SendEventRequest request,
          {SpongeRequestContext context}) async =>
      await execute(SpongeClientConstants.OPERATION_SEND, request,
          (json) => SendEventResponse.fromJson(json), context);

  /// Sends the event named [eventName] with optional [attributes], [label] and [description] to the server.
  Future<String> send(
    String eventName, {
    Map<String, Object> attributes,
    String label,
    String description,
  }) async =>
      (await sendByRequest(SendEventRequest(eventName,
              attributes: attributes, label: label, description: description)))
          .eventId;

  /// Sends the `reload` request to the server and returns the response.
  Future<ReloadResponse> reloadByRequest(ReloadRequest request,
          {SpongeRequestContext context}) async =>
      await execute(SpongeClientConstants.OPERATION_RELOAD, request,
          (json) => ReloadResponse.fromJson(json), context);

  /// Sends the `reload` request to the server.
  Future<void> reload() async {
    await reloadByRequest(ReloadRequest());
  }

  MapCache<String, ActionMeta> _createActionMetaCache() => _createCache(
      _configuration.useActionMetaCache, _configuration.actionMetaCacheMaxSize);

  MapCache<String, RecordType> _createEventTypeCache() => _createCache(
      _configuration.useEventTypeCache, _configuration.eventTypeCacheMaxSize);

  MapCache<K, V> _createCache<K, V>(bool useCache, int maxSize) {
    if (!useCache) {
      return null;
    } else {
      int cacheMaxSize = maxSize ?? -1;
      return cacheMaxSize > -1
          ? MapCache.lru(maximumSize: cacheMaxSize)
          : MapCache();
    }
  }

  /// Clears the action metadata cache.
  Future<void> clearActionMetaCache() async =>
      await _lock.synchronized(() async {
        // Must recreate the cache because of the internal cache implementation.
        _actionMetaCache = _createActionMetaCache();
      });

  /// Clears the event type cache.
  Future<void> clearEventTypeCache() async =>
      await _lock.synchronized(() async {
        // Must recreate the cache because of the internal cache implementation.
        _eventTypeCache = _createEventTypeCache();
      });

  /// Clears caches.
  Future<void> clearCache() async => await _lock.synchronized(() async {
        await clearActionMetaCache();
        await clearEventTypeCache();
        await clearFeaturesCache();
      });

  Future<void> clearFeaturesCache() async => _featuresCache = null;

  /// Clears the session, i.e. the auth token.
  Future<void> clearSession() async {
    await _lock.synchronized(() async {
      _currentAuthToken = null;
    });
  }
}

typedef R ResponseFromJsonCallback<R extends SpongeResponse>(
    Map<String, dynamic> json);
