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

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/exception.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/request.dart';
import 'package:sponge_client_dart/src/response.dart';
import 'package:sponge_client_dart/src/rest_client.dart';
import 'package:sponge_client_dart/src/rest_client_configuration.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/utils.dart';
import 'package:test/test.dart';

import 'complex_object.dart';
import 'logger_configuration.dart';
import 'test_constants.dart';

/// This integration test requires sponge-examples-project-rest-api-client-test-service/RestApiClientTestServiceMain
/// running on the localhost.
void main() {
  configLogger();

  getClient() async => SpongeRestClient(
      SpongeRestClientConfiguration('http://localhost:8888/sponge.json/v1'));

  // Tests mirroring BaseRestApiTestTemplate.java.
  group('REST API Client version', () {
    test('testVersion', () async {
      var client = await getClient();
      expect(SpongeUtils.isServerVersionCompatible(await client.getVersion()),
          isTrue);
    });
    test('testVersionWithId', () async {
      var client = await getClient();
      client.configuration.useRequestId = true;

      var request = GetVersionRequest();
      var response = await client.getVersionByRequest(request);
      expect(response.errorCode, isNull);
      expect(response.errorMessage, isNull);
      expect(response.detailedErrorMessage, isNull);
      expect(SpongeUtils.isServerVersionCompatible(response.version), isTrue);
      expect(response.id, equals('1'));
      expect(response.id, equals(request.id));
    });
  });
  group('REST API Client actions', () {
    test('testActions', () async {
      var client = await getClient();
      List<ActionMeta> actions = await client.getActions();
      expect(actions.length,
          equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
    });
    test('testActionsParamArgMetadataRequiredTrue', () async {
      var client = await getClient();
      List<ActionMeta> actions =
          await client.getActions(metadataRequired: true);
      expect(actions.length,
          equals(TestConstants.ANONYMOUS_ACTIONS_WITH_METADATA_COUNT));
    });
    test('testActionsParamArgMetadataRequiredFalse', () async {
      var client = await getClient();
      List<ActionMeta> actions =
          await client.getActions(metadataRequired: false);
      expect(actions.length,
          equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
    });
    test('testActionsNameRegExp', () async {
      var client = await getClient();
      String name = '.*Case';
      List<ActionMeta> actions = await client.getActions(name: name);
      expect(actions.length, equals(2));
    });
    test('testActionsNameExact', () async {
      var client = await getClient();
      String name = 'UpperCase';
      List<ActionMeta> actions = await client.getActions(name: name);
      expect(actions.length, equals(1));
      expect(actions[0].name, equals(name));
    });
  });
  group('REST API Client getActionMeta', () {
    test('testGetActionMeta', () async {
      var client = await getClient();
      ActionMeta actionMeta = await client.getActionMeta('UpperCase');
      expect(actionMeta.name, equals('UpperCase'));
      expect(actionMeta.argsMeta.length, equals(1));
      expect(actionMeta.argsMeta[0].type is StringType, isTrue);
      expect(actionMeta.resultMeta.type is StringType, isTrue);
    });
  });
  group('REST API Client call', () {
    test('testCall', () async {
      var client = await getClient();
      var arg1 = 'test1';
      var result = await client.call('UpperCase', [arg1]);
      expect(result is String, isTrue);
      expect(result, equals(arg1.toUpperCase()));
    });
    test('testCallWithWrongExpectedKnowledgeBaseVersion', () async {
      var client = await getClient();
      var arg1 = 'test1';
      var actionMeta = await client.getActionMeta('UpperCase');
      actionMeta.knowledgeBase.version = 2;

      try {
        await client.call('UpperCase', [arg1]);
        fail('$IncorrectKnowledgeBaseVersionException expected');
      } catch (e) {
        expect(e is IncorrectKnowledgeBaseVersionException, isTrue);
        expect(
            e.errorCode,
            equals(
                SpongeClientConstants.ERROR_CODE_INCORRECT_KNOWLEDGE_BASE_VERSION));
      }
    });
    test('testCallBinaryArgAndResult', () async {
      var client = await getClient();
      Uint8List image = Uint8List.fromList(await File('test/resources/image.png').readAsBytes());
      Uint8List resultImage = await client.call('EchoImage', [image]);
      expect(image, equals(resultImage));
    });
    test('testCallWithActionTypeArg', () async {
      var client = await getClient();
      ActionMeta actionMeta = await client.getActionMeta('ActionTypeAction');
      List values = await client
          .call((actionMeta.argsMeta[0].type as ActionType).actionName, []);
      expect(await client.call('ActionTypeAction', [values.last]),
          equals('value3'));
    });
    test('testCallLanguageError', () async {
      var client = await getClient();
      try {
        await client.call('LangErrorAction', []);
        fail('$SpongeClientException expected');
      } on SpongeClientException catch (e) {
        expect(e.errorCode, equals(SpongeClientConstants.DEFAULT_ERROR_CODE));
        expect(
            e.errorMessage,
            startsWith(
                'NameError: global name \'throws_error\' is not defined in'));
        expect(
            e.detailedErrorMessage,
            startsWith(
                'org.openksavi.sponge.engine.WrappedException: NameError: global name \'throws_error\' is not defined in'));
      } catch (e) {
        fail('$SpongeClientException expected');
      }
    });
    test('testCallKnowledgeBaseError', () async {
      var client = await getClient();
      try {
        await client.call('KnowledgeBaseErrorAction', []);
        fail('$SpongeClientException expected');
      } on SpongeClientException catch (e) {
        expect(e.errorCode, equals(SpongeClientConstants.DEFAULT_ERROR_CODE));
        expect(e.errorMessage,
            startsWith('Exception: Knowledge base exception in'));
        expect(
            e.detailedErrorMessage,
            startsWith(
                'org.openksavi.sponge.engine.WrappedException: Exception: Knowledge base exception in'));
      } catch (e) {
        fail('$SpongeClientException expected');
      }
    });
  });
  group('REST API Client send', () {
    test('testSend', () async {
      var client = await getClient();
      var result = await client.send('alarm', attributes: {'attr1': 'Test'});
      expect(result, isNotNull);
    });
  });

  group('REST API Client knowledgeBases', () {
    test('testKnowledgeBases', () async {
      var client = await getClient();
      expect((await client.getKnowledgeBases()).length, equals(1));
    });
  });

  // Tests mirroring ActionMetaCacheTest.java.
  group('REST API Client action meta cache', () {
    test('testActionCacheOn', () async {
      var client = await getClient();
      String actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, false), isNull);

      ActionMeta actionMeta = await client.getActionMeta(actionName);
      expect(actionMeta, isNotNull);
      expect(await client.getActionMeta(actionName, false), isNotNull);

      expect(identical(actionMeta, await client.getActionMeta(actionName)),
          isTrue);

      await client.clearCache();
      expect(await client.getActionMeta(actionName, false), isNull);
      expect(identical(actionMeta, await client.getActionMeta(actionName)),
          isFalse);
      expect(await client.getActionMeta(actionName), isNotNull);
    });
    test('testActionCacheOff', () async {
      var client = (await getClient())
        ..configuration.useActionMetaCache = false;

      String actionName = 'UpperCase';
      ActionMeta actionMeta = await client.getActionMeta(actionName);
      expect(actionMeta, isNotNull);
      expect(await client.getActionMeta(actionName), isNotNull);
      expect(identical(actionMeta, await client.getActionMeta(actionName)),
          isFalse);
      await client.clearCache();
      expect(await client.getActionMeta(actionName), isNotNull);
    });
    test('testActionCacheOnGetActions', () async {
      var client = await getClient();
      String actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, false), isNull);

      await client.getActions();
      expect(await client.getActionMeta(actionName, false), isNotNull);

      expect(await client.getActionMeta(actionName), isNotNull);

      await client.clearCache();
      expect(await client.getActionMeta(actionName, false), isNull);

      await client.getActions();
      expect(await client.getActionMeta(actionName, false), isNotNull);
    });
    test('testFetchActionMeta', () async {
      var client = await getClient();
      String actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, false), isNull);
      expect(await client.getActionMeta(actionName), isNotNull);
    });
  });
  // Tests mirroring AuthTokenExpirationTest.java.
  group('REST API Client token expiration', () {
    test('testAuthTokeExpirationRelogin', () async {
      var client = await getClient();
      client.configuration
        ..username = 'john'
        ..password = 'password'
        ..relogin = true;
      expect(await client.login(), isNotNull);
      expect((await client.getActions()).length,
          equals(TestConstants.ADMIN_ACTIONS_COUNT));

      sleep(Duration(seconds: 3));

      expect((await client.getActions()).length,
          equals(TestConstants.ADMIN_ACTIONS_COUNT));
    });
    test('testAuthTokeExpirationNoRelogin', () async {
      var client = await getClient();
      client.configuration
        ..username = 'john'
        ..password = 'password'
        ..relogin = false;
      expect(await client.login(), isNotNull);
      expect((await client.getActions()).length,
          equals(TestConstants.ADMIN_ACTIONS_COUNT));

      sleep(Duration(seconds: 3));

      try {
        expect((await client.getActions()).length,
            equals(TestConstants.ADMIN_ACTIONS_COUNT));
        fail('$InvalidAuthTokenException expected');
      } catch (e) {
        expect(e is InvalidAuthTokenException, isTrue);
        expect(
            e.errorCode, equals(SpongeClientConstants.ERROR_CODE_INVALID_AUTH_TOKEN));
      }
    });
  });

  // Tests mirroring ComplexObjectRestApiTest.java.
  group('REST API Client complex object', () {
    test('testRestCallComplexObject', () async {
      var client = await getClient()
        ..typeConverter.register(createObjectTypeUnitConverter());
      var compoundObject = createTestCompoundComplexObject();

      CompoundComplexObject result =
          await client.call('ComplexObjectAction', [compoundObject]);
      expect(result.id, equals(compoundObject.id + 1));
      expect(result.name, equals(compoundObject.name));
      expect(result.complexObject.id, equals(compoundObject.complexObject.id));
      expect(
          result.complexObject.name, equals(compoundObject.complexObject.name));
      expect(result.complexObject.bigDecimal,
          equals(compoundObject.complexObject.bigDecimal));
      expect(
          result.complexObject.date, equals(compoundObject.complexObject.date));
    });
    test('testRestCallComplexObjectNoMeta', () async {
      var client = await getClient()
        ..typeConverter.register(createObjectTypeUnitConverter());
      var compoundObject = createTestCompoundComplexObject();

      var value = (await client.call(
          'ComplexObjectAction', [compoundObject], null, false));

      expect(value is Map, isTrue);

      var result = CompoundComplexObject.fromJson(value);

      expect(result.id, equals(compoundObject.id + 1));
      expect(result.name, equals(compoundObject.name));
      expect(result.complexObject.id, equals(compoundObject.complexObject.id));
      expect(
          result.complexObject.name, equals(compoundObject.complexObject.name));
      expect(result.complexObject.bigDecimal,
          equals(compoundObject.complexObject.bigDecimal));
      expect(
          result.complexObject.date, equals(compoundObject.complexObject.date));
    });
    test('testRestCallComplexObjectList', () async {
      var client = await getClient()
        ..typeConverter.register(createObjectTypeUnitConverter());
      var compoundObject = createTestCompoundComplexObject();

      List resultList = await client.call('ComplexObjectListAction', [
        [compoundObject]
      ]);
      expect(resultList.length, equals(1));
      CompoundComplexObject result = resultList[0];
      expect(result.id, equals(compoundObject.id + 1));
      expect(result.name, equals(compoundObject.name));
      expect(result.complexObject.id, equals(compoundObject.complexObject.id));
      expect(
          result.complexObject.name, equals(compoundObject.complexObject.name));
      expect(result.complexObject.bigDecimal,
          equals(compoundObject.complexObject.bigDecimal));
      expect(
          result.complexObject.date, equals(compoundObject.complexObject.date));
    });
    test('testRestCallComplexObjectList', () async {
      var client = await getClient()
        ..typeConverter.register(createObjectTypeUnitConverter(true));

      var compoundObject = createTestCompoundComplexObject();
      Map<String, CompoundComplexObject> map = {'first': compoundObject};

      var returnValue = await client.call('ComplexObjectHierarchyAction', [
        'String',
        100,
        ['a', 'b', 'c'],
        [1.25, 5.5],
        ['A', 'B'],
        map
      ]);

      expect(returnValue is List, isTrue);
    });
  });

  // Tests mirroring RestApiSimpleSpringSecurityTest.java.
  group('REST API Client security', () {
    test('testRestActionsUser1', () async {
      var client = await getClient()
        ..configuration.username = 'john'
        ..configuration.password = 'password';
      expect((await client.getActions()).length,
          equals(TestConstants.ADMIN_ACTIONS_COUNT));
    });
    test('testRestActionsUser2', () async {
      var client = await getClient()
        ..configuration.username = 'joe'
        ..configuration.password = 'password';
      expect((await client.getActions()).length,
          equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
    });
    test('testLogin', () async {
      var client = await getClient()
        ..configuration.username = 'john'
        ..configuration.password = 'password';

      expect(await client.login(), isNotNull);
      expect((await client.getActions()).length,
          equals(TestConstants.ADMIN_ACTIONS_COUNT));

      client
        ..configuration.username = null
        ..configuration.password = null;
      await client.logout();

      // Allowed anonymous access.
      expect((await client.getActions()).length,
          equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
    });
    test('testLogout', () async {
      var client = await getClient()
        ..configuration.username = 'john'
        ..configuration.password = 'password';
      await client.logout();
    });
    test('testKnowledgeBasesUser1', () async {
      var client = await getClient()
        ..configuration.username = 'john'
        ..configuration.password = 'password';
      expect((await client.getKnowledgeBases()).length, equals(3));
    });
    test('testKnowledgeBasesUser2', () async {
      var client = await getClient()
        ..configuration.username = 'joe'
        ..configuration.password = 'password';
      expect((await client.getKnowledgeBases()).length, equals(1));
    });
    test('testReloadUser1', () async {
      var client = await getClient()
        ..configuration.username = 'john'
        ..configuration.password = 'password';
      await client.reload();
    });
    test('testReloadUser2', () async {
      var client = await getClient()
        ..configuration.username = 'joe'
        ..configuration.password = 'password';
      expect(() async => await client.reload(),
          throwsA(const TypeMatcher<SpongeClientException>()));
    });
  });

  // Tests mirroring HttpErrorTest.java.
  group('REST API Client HTTP error', () {
    test('testHttpErrorInJsonParser', () async {
      var client = await getClient();
      var requestBody = '{"error_property":""}';
      Response httpResponse = await post('${client.configuration.url}/actions',
          headers: {'Content-type': SpongeClientConstants.APPLICATION_JSON_VALUE},
          body: requestBody);

      expect(httpResponse.statusCode, equals(200));
      var apiResponse =
          SpongeResponse.fromJson(json.decode(httpResponse.body));
      expect(apiResponse.errorCode, equals(SpongeClientConstants.DEFAULT_ERROR_CODE));
      expect(
          apiResponse.errorMessage
              .contains('Unrecognized field "error_property"'),
          isTrue);
    });
  });
}
