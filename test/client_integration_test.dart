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
import 'package:intl/intl.dart';
import 'package:sponge_client_dart/sponge_client_dart.dart';
import 'package:timezone/standalone.dart';

import 'package:http/http.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/context.dart';
import 'package:sponge_client_dart/src/exception.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/request.dart';
import 'package:sponge_client_dart/src/response.dart';
import 'package:sponge_client_dart/src/rest_client.dart';
import 'package:sponge_client_dart/src/rest_client_configuration.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/utils.dart';
import 'package:test/test.dart';
import 'package:timezone/timezone.dart';

import 'complex_object.dart';
import 'logger_configuration.dart';
import 'test_constants.dart';
import 'test_utils.dart';

/// This integration test requires the sponge-examples-project-remote-api-client-test-service/RemoteApiClientTestServiceMain
/// service running on the localhost.
///
/// Note: No other tests should be running using this service at the same time.
void main() {
  configLogger();

  Future<SpongeRestClient> getClient() async =>
      SpongeRestClient(SpongeRestClientConfiguration('http://localhost:8888'));

  Future<SpongeRestClient> getGuestRestClient() async => await getClient()
    ..configuration.username = 'joe'
    ..configuration.password = 'password';

  // Tests mirroring BaseRestApiTestTemplate.java.
  group('REST API Client base opertions', () {
    test('testVersion', () async {
      var client = await getClient();
      expect(SpongeUtils.isServerVersionCompatible(await client.getVersion()),
          isTrue);
    });
    test('testResponseTimes', () async {
      var client = await getClient();
      var response = await client.getVersionByRequest(GetVersionRequest());
      expect(response.header.requestTime, isNotNull);
      expect(response.header.responseTime, isNotNull);
      expect(response.header.responseTime.isBefore(response.header.requestTime),
          isFalse);
    });
    test('testVersionWithId', () async {
      var client = await getClient();
      client.configuration.useRequestId = true;

      var request = GetVersionRequest();
      var response = await client.getVersionByRequest(request);
      expect(response.header.errorCode, isNull);
      expect(response.header.errorMessage, isNull);
      expect(response.header.detailedErrorMessage, isNull);
      expect(
          SpongeUtils.isServerVersionCompatible(response.body.version), isTrue);
      expect(response.header.id, equals('1'));
      expect(response.header.id, equals(request.header.id));
    });
    test('testFeatures', () async {
      var client = await getClient();
      var features = await client.getFeatures();
      expect(features.length, equals(5));
      expect(features[SpongeClientConstants.REMOTE_API_FEATURE_VERSION],
          equals(await client.getVersion()));

      expect(features[SpongeClientConstants.REMOTE_API_FEATURE_NAME],
          equals('Sponge Test REST API'));
      expect(features[SpongeClientConstants.REMOTE_API_FEATURE_DESCRIPTION],
          equals('Sponge Test REST API description'));
      expect(features[SpongeClientConstants.REMOTE_API_FEATURE_LICENSE],
          equals('Apache 2.0'));

      expect(features[SpongeClientConstants.REMOTE_API_FEATURE_GRPC_ENABLED],
          isTrue);
    });
  });
  group('REST API Client actions', () {
    test('testActions', () async {
      var client = await getClient();
      var actions = await client.getActions();
      expect(actions.length, equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
    });
    test('testActionsArgRequiredTrue', () async {
      var client = await getClient();
      var actions = await client.getActions(metadataRequired: true);
      expect(actions.length,
          equals(TestConstants.ANONYMOUS_ACTIONS_WITH_METADATA_COUNT));
    });
    test('testActionsArgRequiredFalse', () async {
      var client = await getClient();
      var actions = await client.getActions(metadataRequired: false);
      expect(actions.length, equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
    });
    test('testActionsNameRegExp', () async {
      var client = await getClient();
      var name = '.*Case';
      var actions = await client.getActions(name: name);
      expect(actions.length, equals(2));
    });
    test('testActionsNameExact', () async {
      var client = await getClient();
      var name = 'UpperCase';
      var actions = await client.getActions(name: name);
      expect(actions.length, equals(1));
      expect(actions[0].name, equals(name));
    });
  });
  group('REST API Client getActionMeta', () {
    test('testGetActionMeta', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('UpperCase');
      expect(actionMeta.name, equals('UpperCase'));
      expect(actionMeta.category.name, equals('category1'));
      expect(actionMeta.category.label, equals('Category 1'));
      expect(actionMeta.category.description, equals('Category 1 description'));
      expect(actionMeta.args.length, equals(1));
      expect(actionMeta.args[0] is StringType, isTrue);
      expect(actionMeta.result is StringType, isTrue);
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
      actionMeta.qualifiedVersion = ProcessorQualifiedVersion(1, 1);

      try {
        await client.call('UpperCase', [arg1]);
        fail('$InvalidKnowledgeBaseVersionException expected');
      } catch (e) {
        expect(e is InvalidKnowledgeBaseVersionException, isTrue);
        expect(
            (e as InvalidKnowledgeBaseVersionException).errorMessage,
            equals(
                'The expected action qualified version (1.1) differs from the actual (2.2)'));
        expect(e.errorCode,
            equals(SpongeClientConstants.ERROR_CODE_INVALID_KB_VERSION));
      }
    });
    test('testCallBinaryArgAndResult', () async {
      var client = await getClient();
      var image = Uint8List.fromList(
          await File('test/resources/image.png').readAsBytes());
      Uint8List resultImage = await client.call('EchoImage', [image]);
      expect(image, equals(resultImage));
    });
    test('testCallLanguageError', () async {
      var client = await getClient();
      try {
        await client.call('LangErrorAction');
        fail('$SpongeClientException expected');
      } on SpongeClientException catch (e) {
        expect(e.errorCode, equals(SpongeClientConstants.ERROR_CODE_GENERIC));
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
        await client.call('KnowledgeBaseErrorAction');
        fail('$SpongeClientException expected');
      } on SpongeClientException catch (e) {
        expect(e.errorCode, equals(SpongeClientConstants.ERROR_CODE_GENERIC));
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
    test('testCallContentCharset', () async {
      var client = await getClient();
      var arg1 = 'íñäöüèąśęćżźółń';
      var result = await client.call('UpperCase', [arg1]);
      expect(result is String, isTrue);
      expect(result, equals(arg1.toUpperCase()));
    });
    test('testCallAnnotatedType', () async {
      var client = await getClient();
      var annotatedArg =
          AnnotatedValue(true, features: {'argFeature1': 'argFeature1Value1'});
      AnnotatedValue result =
          await client.call('AnnotatedTypeAction', [annotatedArg]);
      expect(result.value, equals('RESULT'));
      expect(result.features.length, equals(2));
      expect(result.features['feature1'], equals('value1'));
      expect(result.features['argFeature1'], equals('argFeature1Value1'));

      expect(result.valueLabel, equals('Result value'));
      expect(result.valueDescription, equals('Result value description'));
      expect(result.typeLabel, equals('Result type'));
      expect(result.typeDescription, equals('Result type description'));
    });
    test('testCallDynamicType', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('DynamicResultAction');
      var resultType = actionMeta.result;
      expect(resultType.kind, equals(DataTypeKind.DYNAMIC));

      DynamicValue resultForString =
          await client.call(actionMeta.name, ['string']);
      expect(resultForString.value, equals('text'));
      expect(resultForString.type.kind, equals(DataTypeKind.STRING));

      DynamicValue resultForBoolean =
          await client.call(actionMeta.name, ['boolean']);
      expect(resultForBoolean.value, equals(true));
      expect(resultForBoolean.type.kind, equals(DataTypeKind.BOOLEAN));
    });
    test('testCallTypeType', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('TypeResultAction');
      var resultType = actionMeta.result;
      expect(resultType.kind, equals(DataTypeKind.TYPE));

      expect(await client.call(actionMeta.name, ['string', null]) is StringType,
          isTrue);
      expect(
          await client.call(actionMeta.name, ['boolean', null]) is BooleanType,
          isTrue);

      var stringType = StringType()
        ..name = 'string'
        ..defaultValue = 'DEF';

      StringType resultStringType =
          await client.call(actionMeta.name, ['arg', stringType]);
      expect(resultStringType.name, equals(stringType.name));
      expect(resultStringType.defaultValue, equals(stringType.defaultValue));

      var recordType = RecordType([
        StringType()
          ..name = 'field1'
          ..defaultValue = 'DEF1',
        IntegerType()
          ..name = 'field2'
          ..annotated = true
          ..defaultValue = AnnotatedValue(0)
      ])
        ..name = 'record';

      RecordType resultRecordType =
          await client.call(actionMeta.name, ['arg', recordType]);
      expect(resultRecordType.name, equals(recordType.name));
      expect(resultRecordType.fields.length, equals(2));

      var resultField1Type = resultRecordType.getFieldType('field1');
      expect(resultField1Type.name, equals('field1'));
      expect(resultField1Type.defaultValue, equals('DEF1'));

      var resultField2Type = resultRecordType.getFieldType('field2');
      expect(resultField2Type.name, equals('field2'));
      expect(
          (resultField2Type.defaultValue as AnnotatedValue).value, equals(0));
    });
    test('testCallDateTimeType', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('DateTimeAction');

      var firstType = actionMeta.args[0] as DateTimeType;
      expect(firstType.dateTimeKind, equals(DateTimeKind.DATE_TIME));
      expect((actionMeta.args[1] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.DATE_TIME_ZONE));
      expect((actionMeta.args[2] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.DATE));
      expect((actionMeta.args[3] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.TIME));
      expect((actionMeta.args[4] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.INSTANT));

      expect(firstType.minValue, equals(DateTime(2020, 1, 1, 0, 0)));
      expect(firstType.maxValue, equals(DateTime(2030, 1, 1, 0, 0)));

      var dateTime = DateTime.now();
      await initializeTimeZone();
      var dateTimeZone = TZDateTime.now(getLocation('America/Detroit'));
      var date = DateTime.parse('2019-02-06');
      var time = DateFormat(actionMeta.args[3].format).parse('15:15:00');
      var instant = DateTime.now().toUtc();

      List<dynamic> dates = await client
          .call(actionMeta.name, [dateTime, dateTimeZone, date, time, instant]);
      expect(dates[0].value is DateTime, isTrue);
      expect(dates[0].value, equals(dateTime));

      expect(dates[1].value is DateTime, isTrue);
      expect(dates[1].value, equals(dateTimeZone));

      expect(dates[2].value is DateTime, isTrue);
      expect(dates[2].value, equals(date));

      expect(dates[3].value is DateTime, isTrue);
      expect(dates[3].value, equals(time));

      expect(dates[4].value is DateTime, isTrue);
      expect(dates[4].value, equals(instant));
    });

    test('testCallRecordType', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('RecordAsResultAction');
      TestUtils.assertBookRecordType(actionMeta.result as RecordType);

      Map<String, Object> book1 = await client.call(actionMeta.name, [1]);
      expect(book1.length, equals(4));
      expect(book1['id'], equals(1));
      expect(book1['author'], equals('James Joyce'));
      expect(book1['title'], equals('Ulysses'));
      expect(book1.containsKey('comment'), isTrue);
      expect(book1['comment'], isNull);

      actionMeta = await client.getActionMeta('RecordAsArgAction');
      TestUtils.assertBookRecordType(actionMeta.args[0] as RecordType);

      var book2 = {
        'id': 5,
        'author': 'Arthur Conan Doyle',
        'title': 'Adventures of Sherlock Holmes',
        'comment': null,
      };

      Map<String, Object> book3 =
          await client.call('RecordAsArgAction', [book2]);
      expect(book3.length, equals(4));
      book2.forEach((key, value) => expect(book3[key], equals(value)));
      expect(book3['comment'], isNull);
    });

    test('testCallObjectTypeWithCompanionType', () async {
      void assertObjectTypeWithRecord(ObjectType type) {
        expect(type.className,
            equals('org.openksavi.sponge.examples.CustomObject'));
        var argRecordType = type.companionType as RecordType;
        expect(argRecordType.fields.length, equals(2));

        expect(argRecordType.fields[0] is IntegerType, isTrue);
        expect(argRecordType.fields[0].name, equals('id'));
        expect(argRecordType.fields[0].label, equals('ID'));

        expect(argRecordType.fields[1] is StringType, isTrue);
        expect(argRecordType.fields[1].name, equals('name'));
        expect(argRecordType.fields[1].label, equals('Name'));
      }

      var client = await getClient();
      var actionMeta =
          await client.getActionMeta('ObjectTypeWithCompanionTypeAction');

      expect(actionMeta.args.length, equals(1));
      assertObjectTypeWithRecord(actionMeta.args[0] as ObjectType);
      assertObjectTypeWithRecord(actionMeta.result as ObjectType);

      var arg = {'id': 1, 'name': 'Name 1"'};

      Map<String, dynamic> mapResult =
          await client.call(actionMeta.name, [arg]);
      expect(mapResult['id'], equals(arg['id']));
      expect(mapResult['name'], equals((arg['name'] as String).toUpperCase()));
    });

    test('testRegisteredTypeArgAction', () async {
      var client = await getClient();
      var request = GetActionsRequest(GetActionsRequestBody(
        name: 'RegisteredTypeArgAction',
        registeredTypes: true,
      ));

      var types = (await client.getActionsByRequest(request)).body.types;
      expect(types.length, equals(1));
      TestUtils.assertPersonRecordType(types['Person'] as RecordType);

      String surname = await client.call('RegisteredTypeArgAction', [
        {'firstName': 'James', 'surname': 'Joyce'}
      ]);
      expect(surname, equals('Joyce'));
    });
    test('testInheritedRegisteredTypeArgAction', () async {
      var client = await getClient();
      var request = GetActionsRequest(GetActionsRequestBody(
        name: 'InheritedRegisteredTypeArgAction',
        registeredTypes: true,
      ));

      var types = (await client.getActionsByRequest(request)).body.types;
      expect(types.length, equals(2));

      TestUtils.assertPersonRecordType(types['Person'] as RecordType);
      TestUtils.assertCitizenRecordType(types['Citizen'] as RecordType);

      String sentence = await client.call('InheritedRegisteredTypeArgAction', [
        {'firstName': 'John', 'surname': 'Brown', 'country': 'UK'}
      ]);
      expect(sentence, equals('John comes from UK'));
    });

    test('testNestedRecordAsArgAction', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('NestedRecordAsArgAction');
      expect(actionMeta.args.length, equals(1));
      var argType = actionMeta.args[0] as RecordType;
      expect(argType.kind, equals(DataTypeKind.RECORD));
      expect(argType.name, equals('book'));
      expect(argType.label, equals('Book'));
      expect(argType.fields.length, equals(3));

      expect(argType.fields[0].kind, equals(DataTypeKind.INTEGER));
      expect(argType.fields[0].name, equals('id'));
      expect(argType.fields[0].label, equals('Identifier'));

      var authorType = argType.fields[1] as RecordType;
      expect(authorType.name, equals('author'));
      expect(authorType.label, equals('Author'));
      expect(authorType.fields.length, equals(3));

      expect(authorType.fields[0].kind, equals(DataTypeKind.INTEGER));
      expect(authorType.fields[0].name, equals('id'));
      expect(authorType.fields[0].label, equals('Identifier'));

      expect(authorType.fields[1].kind, equals(DataTypeKind.STRING));
      expect(authorType.fields[1].name, equals('firstName'));
      expect(authorType.fields[1].label, equals('First name'));

      expect(authorType.fields[2].kind, equals(DataTypeKind.STRING));
      expect(authorType.fields[2].name, equals('surname'));
      expect(authorType.fields[2].label, equals('Surname'));

      expect(argType.fields[2].kind, equals(DataTypeKind.STRING));
      expect(argType.fields[2].name, equals('title'));
      expect(argType.fields[2].label, equals('Title'));

      String bookSummary = await client.call(actionMeta.name, [
        {
          'author': {'firstName': 'James', 'surname': 'Joyce'},
          'title': 'Ulysses'
        }
      ]);

      expect(bookSummary, equals('James Joyce - Ulysses'));
    });
    test('testProvideActionArgs', () async {
      var client = await getClient();
      var actionName = 'SetActuator';

      var argTypes = (await client.getActionMeta(actionName)).args;

      expect(argTypes[0].provided.value, isTrue);
      expect(argTypes[0].provided.hasValueSet, isTrue);
      expect(argTypes[0].provided.valueSet.limited, isTrue);
      expect(argTypes[0].provided.dependencies?.length, equals(0));
      expect(argTypes[0].readOnly, isFalse);
      expect(argTypes[1].provided.value, isTrue);
      expect(argTypes[1].provided.hasValueSet, isFalse);
      expect(argTypes[1].provided.dependencies?.length, equals(0));
      expect(argTypes[1].readOnly, isFalse);
      expect(argTypes[2].provided.value, isTrue);
      expect(argTypes[2].provided.hasValueSet, isFalse);
      expect(argTypes[2].provided.dependencies?.length, equals(0));
      expect(argTypes[2].readOnly, isTrue);
      expect(argTypes[3].provided, isNull);

      // Reset the test state.
      await client.call(actionName, ['A', false, null, 1]);

      var providedArgs = await client.provideActionArgs(actionName,
          provide: ['actuator1', 'actuator2', 'actuator3']);
      expect(providedArgs.length, equals(3));
      expect(providedArgs['actuator1'], isNotNull);
      expect(providedArgs['actuator1'].value, equals('A'));
      expect(providedArgs['actuator1'].valueSet, equals(['A', 'B', 'C']));
      expect(providedArgs['actuator1'].valuePresent, isTrue);
      expect(providedArgs['actuator2'], isNotNull);
      expect(providedArgs['actuator2'].value, equals(false));
      expect(providedArgs['actuator2'].valueSet, isNull);
      expect(providedArgs['actuator2'].valuePresent, isTrue);
      expect(providedArgs['actuator3'], isNotNull);
      // The value of actuator3 should not be asserted because it is read only in this test.
      /// Other tests may change its value.
      expect(providedArgs['actuator3'].valueSet, isNull);
      expect(providedArgs['actuator3'].valuePresent, isTrue);
      expect(providedArgs['actuator4'], isNull);

      await client.call(actionName, ['B', true, null, 10]);

      providedArgs = await client.provideActionArgs(actionName,
          provide: ['actuator1', 'actuator2', 'actuator3']);
      expect(providedArgs.length, equals(3));
      expect(providedArgs['actuator1'], isNotNull);
      expect(providedArgs['actuator1'].value, equals('B'));
      expect(providedArgs['actuator1'].valueSet, equals(['A', 'B', 'C']));
      expect(providedArgs['actuator1'].valuePresent, isTrue);
      expect(providedArgs['actuator2'], isNotNull);
      expect(providedArgs['actuator2'].value, equals(true));
      expect(providedArgs['actuator2'].valueSet, isNull);
      expect(providedArgs['actuator2'].valuePresent, isTrue);
      expect(providedArgs['actuator3'], isNotNull);
      // The value of actuator3 should not be asserted because it is read only in this test.
      /// Other tests may change its value.
      expect(providedArgs['actuator3'].valueSet, isNull);
      expect(providedArgs['actuator3'].valuePresent, isTrue);
      expect(providedArgs['actuator4'], isNull);
    });
    test('testProvideActionArgsNotLimitedValueSet', () async {
      var client = await getClient();
      var actionName = 'SetActuatorNotLimitedValueSet';

      var argTypes = (await client.getActionMeta(actionName)).args;

      expect(argTypes[0].provided, isNotNull);
      expect(argTypes[0].provided.value, isNotNull);
      expect(argTypes[0].provided.hasValueSet, isTrue);
      expect(argTypes[0].provided.valueSet.limited, isFalse);
    });
    test('testProvideActionArgsDepends', () async {
      var client = await getClient();
      var actionName = 'SetActuatorDepends';

      // Reset the test state.
      await client.call(actionName, ['A', false, 1, 1, 'X']);

      var argTypes = (await client.getActionMeta(actionName)).args;

      expect(argTypes[0].provided.value, isTrue);
      expect(argTypes[0].provided.valueSet.limited, isTrue);
      expect(argTypes[0].provided.dependencies?.length, equals(0));
      expect(argTypes[1].provided.value, isTrue);
      expect(argTypes[1].provided.hasValueSet, isFalse);
      expect(argTypes[1].provided.dependencies?.length, equals(0));
      expect(argTypes[2].provided.value, isTrue);
      expect(argTypes[2].provided.hasValueSet, isFalse);
      expect(argTypes[2].provided.dependencies?.length, equals(0));
      expect(argTypes[3].provided, isNull);
      expect(argTypes[4].provided.value, isTrue);
      expect(argTypes[4].provided.valueSet.limited, isTrue);
      expect(argTypes[4].provided.dependencies?.length, equals(1));
      expect(argTypes[4].provided.dependencies, equals(['actuator1']));

      var providedArgs =
          await client.provideActionArgs(actionName, provide: ['actuator1']);
      expect(providedArgs.length, equals(1));
      expect(providedArgs['actuator1'], isNotNull);
      var actuator1value = providedArgs['actuator1'].value;
      expect(actuator1value, equals('A'));
      expect(providedArgs['actuator1'].valueSet, equals(['A', 'B', 'C']));
      var actuator1AnnotatedValueSet =
          providedArgs['actuator1'].annotatedValueSet;
      expect(actuator1AnnotatedValueSet.length, equals(3));
      expect(actuator1AnnotatedValueSet[0].value, equals('A'));
      expect(actuator1AnnotatedValueSet[0].valueLabel, equals('Value A'));
      expect(actuator1AnnotatedValueSet[1].value, equals('B'));
      expect(actuator1AnnotatedValueSet[1].valueLabel, equals('Value B'));
      expect(actuator1AnnotatedValueSet[2].value, equals('C'));
      expect(actuator1AnnotatedValueSet[2].valueLabel, equals('Value C'));

      expect(providedArgs['actuator1'].valuePresent, isTrue);

      providedArgs = await client.provideActionArgs(actionName,
          provide: ['actuator2', 'actuator3', 'actuator5'],
          current: {'actuator1': actuator1value});

      expect(providedArgs.length, equals(3));
      expect(providedArgs['actuator2'], isNotNull);
      expect(providedArgs['actuator2'].value, equals(false));
      expect(providedArgs['actuator2'].valueSet, isNull);
      expect(providedArgs['actuator2'].valuePresent, isTrue);
      expect(providedArgs['actuator3'], isNotNull);
      expect(providedArgs['actuator3'].value, equals(1));
      expect(providedArgs['actuator3'].valueSet, isNull);
      expect(providedArgs['actuator3'].valuePresent, isTrue);
      expect(providedArgs['actuator4'], isNull);
      expect(providedArgs['actuator5'], isNotNull);
      expect(providedArgs['actuator5'].value, equals('X'));
      expect(providedArgs['actuator5'].valueSet, equals(['X', 'Y', 'Z', 'A']));
      expect(providedArgs['actuator5'].valuePresent, isTrue);

      await client.call(actionName, ['B', true, 5, 10, 'Y']);

      providedArgs =
          await client.provideActionArgs(actionName, provide: ['actuator1']);
      expect(providedArgs.length, equals(1));
      expect(providedArgs['actuator1'], isNotNull);
      actuator1value = providedArgs['actuator1'].value;
      expect(actuator1value, equals('B'));
      expect(providedArgs['actuator1'].valueSet, equals(['A', 'B', 'C']));
      expect(providedArgs['actuator1'].valuePresent, isTrue);

      providedArgs = await client.provideActionArgs(actionName,
          provide: ['actuator2', 'actuator3', 'actuator5'],
          current: {'actuator1': actuator1value});
      expect(providedArgs.length, equals(3));
      expect(providedArgs['actuator2'], isNotNull);
      expect(providedArgs['actuator2'].value, equals(true));
      expect(providedArgs['actuator2'].valueSet, isNull);
      expect(providedArgs['actuator2'].valuePresent, isTrue);
      expect(providedArgs['actuator3'], isNotNull);
      expect(providedArgs['actuator3'].value, equals(5));
      expect(providedArgs['actuator3'].valueSet, isNull);
      expect(providedArgs['actuator3'].valuePresent, isTrue);
      expect(providedArgs['actuator4'], isNull);
      expect(providedArgs['actuator5'], isNotNull);
      expect(providedArgs['actuator5'].value, equals('Y'));
      expect(providedArgs['actuator5'].valueSet, equals(['X', 'Y', 'Z', 'B']));
      expect(providedArgs['actuator5'].valuePresent, isTrue);
    });
    test('testProvideActionArgByAction', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('ProvideByAction');
      var values = (await client
              .provideActionArgs(actionMeta.name, provide: ['value']))['value']
          .valueSet;
      expect(
          await client.call(actionMeta.name, [values.last]), equals('value3'));
    });
    test('testProvideActionArgsElementValueSet', () async {
      var client = await getClient();
      var actionName = 'FruitsElementValueSetAction';

      var fruitsType =
          (await client.getActionMeta(actionName)).args[0] as ListType;
      expect(fruitsType.unique, isTrue);
      expect(fruitsType.provided, isNotNull);
      expect(fruitsType.provided.value, isFalse);
      expect(fruitsType.provided.hasValueSet, isFalse);
      expect(fruitsType.provided.elementValueSet, isTrue);

      var provided =
          await client.provideActionArgs(actionName, provide: ['fruits']);
      var elementValueSet = provided['fruits'].annotatedElementValueSet;
      expect(elementValueSet.length, equals(3));
      expect(elementValueSet[0].value, equals('apple'));
      expect(elementValueSet[0].valueLabel, equals('Apple'));
      expect(elementValueSet[1].value, equals('banana'));
      expect(elementValueSet[1].valueLabel, equals('Banana'));
      expect(elementValueSet[2].value, equals('lemon'));
      expect(elementValueSet[2].valueLabel, equals('Lemon'));

      expect(
          await client.call(actionName, [
            ['apple', 'lemon']
          ]),
          equals(2));
    });

    test('testProvideActionArgsSubmit', () async {
      var client = await getClient();
      var actionName = 'SetActuatorSubmit';

      // Reset the test state.
      await client.call(actionName, ['A', false]);

      var argTypes = (await client.getActionMeta(actionName)).args;
      expect(argTypes[0].provided.value, isTrue);
      expect(argTypes[0].provided.hasValueSet, isTrue);
      expect(argTypes[0].provided.valueSet.limited, isTrue);
      expect(argTypes[0].provided.dependencies?.length, equals(0));
      expect(argTypes[0].readOnly, isFalse);
      expect(argTypes[0].provided.submittable, isNotNull);
      expect(
          argTypes[0].provided.submittable.influences, equals(['actuator2']));
      expect(argTypes[1].provided.value, isTrue);
      expect(argTypes[1].provided.hasValueSet, isFalse);
      expect(argTypes[1].provided.dependencies?.length, equals(0));
      expect(argTypes[1].readOnly, isFalse);
      expect(argTypes[1].provided.submittable, isNull);

      Map<String, ProvidedValue> providedArgs;

      providedArgs = await client
          .provideActionArgs(actionName, provide: ['actuator1', 'actuator2']);
      expect(providedArgs.length, equals(2));
      expect(providedArgs['actuator1'], isNotNull);
      expect(providedArgs['actuator1'].value, equals('A'));
      expect(providedArgs['actuator1'].valueSet, equals(['A', 'B', 'C']));
      expect(providedArgs['actuator1'].valuePresent, isTrue);
      expect(providedArgs['actuator2'], isNotNull);
      expect(providedArgs['actuator2'].value, equals(false));
      expect(providedArgs['actuator2'].valueSet, isNull);
      expect(providedArgs['actuator2'].valuePresent, isTrue);

      await client.provideActionArgs(actionName,
          submit: ['actuator1'], current: {'actuator1': 'B'});
      expect(
          (await client.provideActionArgs(actionName,
                  provide: ['actuator1']))['actuator1']
              .value,
          equals('B'));

      await client.call(actionName, ['C', true]);
      expect(
          (await client.provideActionArgs(actionName,
                  provide: ['actuator1']))['actuator1']
              .value,
          equals('C'));

      // Reset the test state.
      await client.call(actionName, ['A', false]);
    });

    test('testProvideActionArgsPagingMeta', () async {
      var client = await getClient();
      var actionName = 'ViewFruitsPaging';
      var argTypes = (await client.getActionMeta(actionName)).args;

      expect(argTypes[0].provided, isNotNull);
      expect(argTypes[0].provided.value, isTrue);
      expect(argTypes[0].provided.valueSet, isNull);
      expect(argTypes[0].features[Features.PROVIDE_VALUE_PAGEABLE], isTrue);
    });
    test('testProvideActionArgsPagingValue', () async {
      var client = await getClient();
      var actionName = 'ViewFruitsPaging';
      var valueLimit = 5;

      var providedFruits =
          (await client.provideActionArgs(actionName, provide: [
        'fruits'
      ], argFeatures: {
        'fruits': {
          Features.PROVIDE_VALUE_OFFSET: 0,
          Features.PROVIDE_VALUE_LIMIT: valueLimit
        }
      }))['fruits'];

      AnnotatedValue fruits = providedFruits.value;
      expect(fruits.value.length, equals(valueLimit));
      expect(fruits.value,
          equals(['apple', 'orange', 'lemon', 'banana', 'cherry']));
      expect(fruits.features[Features.PROVIDE_VALUE_OFFSET], equals(0));
      expect(fruits.features[Features.PROVIDE_VALUE_LIMIT], equals(valueLimit));
      expect(fruits.features[Features.PROVIDE_VALUE_COUNT], equals(11));

      providedFruits = (await client.provideActionArgs(actionName, provide: [
        'fruits'
      ], argFeatures: {
        'fruits': {
          Features.PROVIDE_VALUE_OFFSET: valueLimit,
          Features.PROVIDE_VALUE_LIMIT: valueLimit
        }
      }))['fruits'];

      fruits = providedFruits.value;
      expect(fruits.value.length, equals(valueLimit));
      expect(fruits.value,
          equals(['grapes', 'peach', 'mango', 'grapefruit', 'kiwi']));
      expect(
          fruits.features[Features.PROVIDE_VALUE_OFFSET], equals(valueLimit));
      expect(fruits.features[Features.PROVIDE_VALUE_LIMIT], equals(valueLimit));
      expect(fruits.features[Features.PROVIDE_VALUE_COUNT], equals(11));

      providedFruits = (await client.provideActionArgs(actionName, provide: [
        'fruits'
      ], argFeatures: {
        'fruits': {
          Features.PROVIDE_VALUE_OFFSET: 2 * valueLimit,
          Features.PROVIDE_VALUE_LIMIT: valueLimit
        }
      }))['fruits'];

      fruits = providedFruits.value;
      expect(fruits.value.length, equals(1));
      expect(fruits.value, equals(['plum']));
      expect(fruits.features[Features.PROVIDE_VALUE_OFFSET],
          equals(2 * valueLimit));
      expect(fruits.features[Features.PROVIDE_VALUE_LIMIT], equals(valueLimit));
      expect(fruits.features[Features.PROVIDE_VALUE_COUNT], equals(11));

      // Without paging.
      expect(
          () async =>
              await client.provideActionArgs(actionName, provide: ['fruits']),
          throwsA(predicate((e) =>
              e is SpongeClientException &&
              e.message ==
                  'There is no feature offset for argument fruits in example.ViewFruitsPaging')));
    });

    test('testActionsAnnotatedWithDefaultValue', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('AnnotatedWithDefaultValue');

      expect(actionMeta.args[0].annotated, isTrue);
      expect((actionMeta.args[0].defaultValue as AnnotatedValue).value,
          equals('Value'));

      var newValue = 'NEW VALUE';

      expect(await client.call(actionMeta.name, [AnnotatedValue(newValue)]),
          equals(newValue));
    });
    test('testActionsProvidedWithCurrentAndLazyUpdate', () async {
      var client = await getClient();
      var actionMeta =
          await client.getActionMeta('ProvidedWithCurrentAndLazyUpdate');

      expect(actionMeta.args[0].annotated, isTrue);
      expect(actionMeta.args[0].provided.current, isTrue);
      expect(actionMeta.args[0].provided.lazyUpdate, isTrue);
      expect(actionMeta.args[0].provided.mode, equals(ProvidedMode.EXPLICIT));

      var currentValue = 'NEW VALUE';

      var provided = (await client.provideActionArgs(actionMeta.name,
          provide: ['arg'],
          current: {'arg': AnnotatedValue(currentValue)}))['arg'];

      expect((provided.value as AnnotatedValue).value, equals(currentValue));
    });
    test('testActionsProvidedWithOptional', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('ProvidedWithOptional');

      expect(actionMeta.args[0].provided.current, isFalse);
      expect(actionMeta.args[0].provided.lazyUpdate, isFalse);
      expect(actionMeta.args[0].provided.mode, equals(ProvidedMode.OPTIONAL));

      var provided = (await client.provideActionArgs(actionMeta.name))['arg'];

      expect(provided.value, equals('VALUE'));
    });

    test('testIsActionActive', () async {
      var client = await getClient();
      var actionMeta = await client.getActionMeta('IsActionActiveAction');
      expect(actionMeta.activatable, isTrue);

      var active = await client.isActionActive(
          [IsActionActiveEntry(name: actionMeta.name, contextValue: 'ACTIVE')]);
      expect(active.length, equals(1));
      expect(active[0], isTrue);

      active = await client.isActionActive(
          [IsActionActiveEntry(name: actionMeta.name, contextValue: null)]);
      expect(active.length, equals(1));
      expect(active[0], isFalse);
    });

    test('testSubActions', () async {
      var client = await getClient();
      List<SubAction> subActions =
          (await client.getActionMeta('SubActionsAction'))
              .features[Features.CONTEXT_ACTIONS];
      expect(subActions.length, equals(4));

      expect(subActions[0].name, equals('SubAction1'));
      expect(subActions[0].label, equals('Sub-action 1/1'));
      expect(subActions[0].args.length, equals(1));
      expect(subActions[0].args[0].target, equals('target1'));
      expect(subActions[0].args[0].source, equals('arg1'));
      expect(subActions[0].result.target, equals('arg1'));
    });

    test('testTraverseActionArguments', () async {
      var client = await getClient();
      var meta = await client.getActionMeta('NestedRecordAsArgAction');

      var bookType = meta.args[0] as RecordType;
      var authorType = bookType.fields[1] as RecordType;
      expect(identical(meta.getArg('book'), bookType), isTrue);
      expect(identical(meta.getArg('book.id'), bookType.fields[0]), isTrue);
      expect(identical(meta.getArg('book.author'), authorType), isTrue);
      expect(identical(meta.getArg('book.author.id'), authorType.fields[0]),
          isTrue);
      expect(
          identical(meta.getArg('book.author.firstName'), authorType.fields[1]),
          isTrue);
      expect(
          identical(meta.getArg('book.author.surname'), authorType.fields[2]),
          isTrue);
      expect(identical(meta.getArg('book.title'), bookType.fields[2]), isTrue);

      var namedQTypes = <QualifiedDataType>[];
      SpongeUtils.traverseActionArguments(
          meta, (qType) => namedQTypes.add(qType),
          namedOnly: true);

      expect(namedQTypes[0].path, equals('book'));
      expect(identical(namedQTypes[0].type, meta.getArg('book')), isTrue);
      expect(namedQTypes[1].path, equals('book.id'));
      expect(identical(namedQTypes[1].type, meta.getArg('book.id')), isTrue);
      expect(namedQTypes[2].path, equals('book.author'));
      expect(
          identical(namedQTypes[2].type, meta.getArg('book.author')), isTrue);
      expect(namedQTypes[3].path, equals('book.author.id'));
      expect(identical(namedQTypes[3].type, meta.getArg('book.author.id')),
          isTrue);
      expect(namedQTypes[4].path, equals('book.author.firstName'));
      expect(
          identical(namedQTypes[4].type, meta.getArg('book.author.firstName')),
          isTrue);
      expect(namedQTypes[5].path, equals('book.author.surname'));
      expect(identical(namedQTypes[5].type, meta.getArg('book.author.surname')),
          isTrue);
      expect(namedQTypes[6].path, equals('book.title'));
      expect(identical(namedQTypes[6].type, meta.getArg('book.title')), isTrue);
    });
  });
  group('REST API Client send', () {
    test('testSend', () async {
      var client = await getGuestRestClient();
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

  group('REST API Client eventTypes', () {
    test('testGetEventTypes', () async {
      var client = await getClient();
      var eventTypes = await client.getEventTypes();

      expect(eventTypes.length, equals(1));
      TestUtils.assertNotificationRecordType(eventTypes['notification']);
    });
  });

  group('REST API Client getEventType', () {
    test('testGetEventType', () async {
      var client = await getClient();
      TestUtils.assertNotificationRecordType(
          await client.getEventType('notification'));
    });
  });

  // Tests mirroring ActionMetaCacheTest.java.
  group('REST API Client action meta cache', () {
    test('testActionCacheOn', () async {
      var client = await getClient();
      var actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNull);

      var actionMeta = await client.getActionMeta(actionName);
      expect(actionMeta, isNotNull);
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNotNull);

      expect(identical(actionMeta, await client.getActionMeta(actionName)),
          isTrue);

      await client.clearCache();
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNull);
      expect(identical(actionMeta, await client.getActionMeta(actionName)),
          isFalse);
      expect(await client.getActionMeta(actionName), isNotNull);
    });
    test('testActionCacheOff', () async {
      var client = (await getClient())
        ..configuration.useActionMetaCache = false;

      var actionName = 'UpperCase';
      var actionMeta = await client.getActionMeta(actionName);
      expect(actionMeta, isNotNull);
      expect(await client.getActionMeta(actionName), isNotNull);
      expect(identical(actionMeta, await client.getActionMeta(actionName)),
          isFalse);
      await client.clearCache();
      expect(await client.getActionMeta(actionName), isNotNull);
    });
    test('testActionCacheOnGetActions', () async {
      var client = await getClient();
      var actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNull);

      await client.getActions();
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNotNull);

      expect(await client.getActionMeta(actionName), isNotNull);

      await client.clearCache();
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNull);

      await client.getActions();
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNotNull);
    });
    test('testFetchActionMeta', () async {
      var client = await getClient();
      var actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNull);
      expect(await client.getActionMeta(actionName), isNotNull);
    });
  });

  // Tests mirroring EventTypeCacheTest.java.
  group('REST API Client event type cache', () {
    test('testEventTypeCacheOn', () async {
      var client = await getClient();
      var eventTypeName = 'notification';
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNull);

      var eventType = await client.getEventType(eventTypeName);
      expect(eventType, isNotNull);
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNotNull);

      expect(identical(eventType, await client.getEventType(eventTypeName)),
          isTrue);

      await client.clearCache();
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNull);
      expect(identical(eventType, await client.getEventType(eventTypeName)),
          isFalse);
      expect(await client.getEventType(eventTypeName), isNotNull);
    });
    test('testEventTypeCacheOff', () async {
      var client = (await getClient())..configuration.useEventTypeCache = false;

      var eventTypeName = 'notification';
      var eventType = await client.getEventType(eventTypeName);
      expect(eventType, isNotNull);
      expect(await client.getEventType(eventTypeName), isNotNull);
      expect(identical(eventType, await client.getEventType(eventTypeName)),
          isFalse);
      await client.clearCache();
      expect(await client.getEventType(eventTypeName), isNotNull);
    });
    test('testEventTypeCacheOnGetEventTypes', () async {
      var client = await getClient();
      var eventTypeName = 'notification';
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNull);

      await client.getEventTypes();
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNotNull);

      expect(await client.getEventType(eventTypeName), isNotNull);

      await client.clearCache();
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNull);

      await client.getEventTypes();
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNotNull);
    });
    test('testFetchEventType', () async {
      var client = await getClient();
      var eventTypeName = 'notification';
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNull);
      expect(await client.getEventType(eventTypeName), isNotNull);
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
        expect(e.errorCode,
            equals(SpongeClientConstants.ERROR_CODE_INVALID_AUTH_TOKEN));
      }
    });
  });

  // Tests mirroring ComplexObjectRestApiTest.java.
  group('REST API Client complex object', () {
    test('testRestCallComplexObject', () async {
      var client = await getClient()
        ..typeConverter.register(TestUtils.createObjectTypeUnitConverter());
      var compoundObject = TestUtils.createTestCompoundComplexObject();

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
        ..typeConverter.register(TestUtils.createObjectTypeUnitConverter());
      var compoundObject = TestUtils.createTestCompoundComplexObject();

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
        ..typeConverter.register(TestUtils.createObjectTypeUnitConverter());
      var compoundObject = TestUtils.createTestCompoundComplexObject();

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
        ..typeConverter.register(TestUtils.createObjectTypeUnitConverter(true));

      var compoundObject = TestUtils.createTestCompoundComplexObject();
      var map = <String, CompoundComplexObject>{'first': compoundObject};

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
      expect((await client.getKnowledgeBases()).length, equals(4));
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
    test('testAutoUseAuthTokenTrue', () async {
      var client = await getClient();
      client.configuration
        ..username = 'john'
        ..password = 'password'
        ..autoUseAuthToken = true;

      expect(client.currentAuthToken, isNull);
      await client.getActions();
      expect(client.currentAuthToken, isNotNull);
    });
    test('testAutoUseAuthTokenFalse', () async {
      var client = await getClient();
      client.configuration
        ..username = 'john'
        ..password = 'password'
        ..autoUseAuthToken = false;

      expect(client.currentAuthToken, isNull);
      await client.getActions();
      expect(client.currentAuthToken, isNull);
    });
  });

  // Tests mirroring HttpErrorTest.java.
  group('REST API Client HTTP error', () {
    test('testHttpErrorInJsonParser', () async {
      var client = await getClient();
      var requestBody = '{"error_property":""}';
      var httpResponse = await post('${client.configuration.url}/actions',
          headers: {'Content-type': SpongeClientConstants.CONTENT_TYPE_JSON},
          body: requestBody);

      expect(httpResponse.statusCode, equals(500));
      // Use a fake response.
      var apiResponse =
          GetVersionResponse.fromJson(json.decode(httpResponse.body));
      expect(apiResponse.header.errorCode,
          equals(SpongeClientConstants.ERROR_CODE_GENERIC));
      expect(
          apiResponse.header.errorMessage
              .contains('Unrecognized field "error_property"'),
          isTrue);
    });
  });

  // Tests mirroring ClientListenerTest.java.
  group('REST API Client listener', () {
    String normalizeJson(String json) => json.replaceAll(RegExp(r'\s'), '');

    test('testGlobalListeners', () async {
      var client = await getClient();

      var requestStringList = <String>[];
      var responseStringList = <String>[];

      client
        ..addOnRequestSerializedListener(
            (request, requestString) => requestStringList.add(requestString))
        ..addOnResponseDeserializedListener(
            (request, response, responseString) =>
                responseStringList.add(responseString));

      await client.getVersion();
      var version = await client.getVersion();
      await client.getVersion();

      expect(SpongeUtils.isServerVersionCompatible(version), isTrue);
      expect(requestStringList.length, equals(3));
      expect(responseStringList.length, equals(3));
      expect(
          normalizeJson(requestStringList[0]),
          equals(
              '{"header":{"id":null,"username":null,"password":null,"authToken":null,"features":null}}'));
      expect(
          normalizeJson(responseStringList[0]),
          matches(
              '{"header":{"id":null,"errorCode":null,"errorMessage":null,"detailedErrorMessage":null,"requestTime":".*","responseTime":".*","features":null},"body":{"version":"$version"}}'));
    });
    test('testOneRequestListeners', () async {
      var client = await getClient();

      String actualRequestString;
      String actualResponseString;

      await client.getVersion();

      var context = SpongeRequestContext()
        ..onRequestSerializedListener =
            ((request, requestString) => actualRequestString = requestString)
        ..onResponseDeserializedListener =
            ((request, response, responseString) =>
                actualResponseString = responseString);
      var version = (await client.getVersionByRequest(GetVersionRequest(),
              context: context))
          .body
          .version;

      expect(SpongeUtils.isServerVersionCompatible(version), isTrue);

      await client.getVersion();

      expect(
          normalizeJson(actualRequestString),
          equals(
              '{"header":{"id":null,"username":null,"password":null,"authToken":null,"features":null}}'));
      expect(
          normalizeJson(actualResponseString),
          matches(
              '{"header":{"id":null,"errorCode":null,"errorMessage":null,"detailedErrorMessage":null,"requestTime":".*","responseTime":".*","features":null},"body":{"version":"$version"}}'));
    });
  });
}
