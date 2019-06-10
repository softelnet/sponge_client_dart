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
      expect(response.header.errorCode, isNull);
      expect(response.header.errorMessage, isNull);
      expect(response.header.detailedErrorMessage, isNull);
      expect(SpongeUtils.isServerVersionCompatible(response.version), isTrue);
      expect(response.header.id, equals('1'));
      expect(response.header.id, equals(request.header.id));
    });
  });
  group('REST API Client actions', () {
    test('testActions', () async {
      var client = await getClient();
      List<ActionMeta> actions = await client.getActions();
      expect(actions.length, equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
    });
    test('testActionsArgRequiredTrue', () async {
      var client = await getClient();
      List<ActionMeta> actions =
          await client.getActions(metadataRequired: true);
      expect(actions.length,
          equals(TestConstants.ANONYMOUS_ACTIONS_WITH_METADATA_COUNT));
    });
    test('testActionsArgRequiredFalse', () async {
      var client = await getClient();
      List<ActionMeta> actions =
          await client.getActions(metadataRequired: false);
      expect(actions.length, equals(TestConstants.ANONYMOUS_ACTIONS_COUNT));
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
        fail('$IncorrectKnowledgeBaseVersionException expected');
      } catch (e) {
        expect(e is IncorrectKnowledgeBaseVersionException, isTrue);
        expect(
            (e as IncorrectKnowledgeBaseVersionException).errorMessage,
            equals(
                'The expected action qualified version (1.1) differs from the actual (2.2)'));
        expect(
            e.errorCode,
            equals(SpongeClientConstants
                .ERROR_CODE_INCORRECT_KNOWLEDGE_BASE_VERSION));
      }
    });
    test('testCallBinaryArgAndResult', () async {
      var client = await getClient();
      Uint8List image = Uint8List.fromList(
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
        await client.call('KnowledgeBaseErrorAction');
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
    });
    test('testCallDynamicType', () async {
      var client = await getClient();
      ActionMeta actionMeta = await client.getActionMeta('DynamicResultAction');
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
      ActionMeta actionMeta = await client.getActionMeta('TypeResultAction');
      var resultType = actionMeta.result;
      expect(resultType.kind, equals(DataTypeKind.TYPE));

      expect(
          await client.call(actionMeta.name, ['string']) is StringType, isTrue);
      expect(await client.call(actionMeta.name, ['boolean']) is BooleanType,
          isTrue);
    });
    test('testCallDateTimeType', () async {
      var client = await getClient();
      ActionMeta actionMeta = await client.getActionMeta('DateTimeAction');

      expect((actionMeta.args[0] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.DATE_TIME));
      expect((actionMeta.args[1] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.DATE_TIME_ZONE));
      expect((actionMeta.args[2] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.DATE));
      expect((actionMeta.args[3] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.TIME));
      expect((actionMeta.args[4] as DateTimeType).dateTimeKind,
          equals(DateTimeKind.INSTANT));

      DateTime dateTime = DateTime.now();
      await initializeTimeZone();
      TZDateTime dateTimeZone = TZDateTime.now(getLocation('America/Detroit'));
      DateTime date = DateTime.parse('2019-02-06');
      DateTime time = DateFormat(actionMeta.args[3].format).parse('15:15:00');
      DateTime instant = DateTime.now().toUtc();

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
      ActionMeta actionMeta =
          await client.getActionMeta('RecordAsResultAction');
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

    test('testRegisteredTypeArgAction', () async {
      var client = await getClient();
      var request = GetActionsRequest()
        ..name = 'RegisteredTypeArgAction'
        ..registeredTypes = true;

      Map<String, DataType> types =
          (await client.getActionsByRequest(request)).types;
      expect(types.length, equals(1));
      TestUtils.assertPersonRecordType(types['Person'] as RecordType);

      String surname = await client.call('RegisteredTypeArgAction', [
        {'firstName': 'James', 'surname': 'Joyce'}
      ]);
      expect(surname, equals('Joyce'));
    });
    test('testInheritedRegisteredTypeArgAction', () async {
      var client = await getClient();
      var request = GetActionsRequest()
        ..name = 'InheritedRegisteredTypeArgAction'
        ..registeredTypes = true;

      Map<String, DataType> types =
          (await client.getActionsByRequest(request)).types;
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
      ActionMeta actionMeta =
          await client.getActionMeta('NestedRecordAsArgAction');
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

      List<DataType> argTypes = (await client.getActionMeta(actionName)).args;

      expect(argTypes[0].provided.value, isTrue);
      expect(argTypes[0].provided.hasValueSet, isTrue);
      expect(argTypes[0].provided.valueSet.limited, isTrue);
      expect(argTypes[0].provided.dependencies?.length, equals(0));
      expect(argTypes[0].provided.readOnly, isFalse);
      expect(argTypes[1].provided.value, isTrue);
      expect(argTypes[1].provided.hasValueSet, isFalse);
      expect(argTypes[1].provided.dependencies?.length, equals(0));
      expect(argTypes[1].provided.readOnly, isFalse);
      expect(argTypes[2].provided.value, isTrue);
      expect(argTypes[2].provided.hasValueSet, isFalse);
      expect(argTypes[2].provided.dependencies?.length, equals(0));
      expect(argTypes[2].provided.readOnly, isTrue);
      expect(argTypes[3].provided, isNull);

      // Reset the test state.
      await client.call(actionName, ['A', false, null, 1]);

      Map<String, ProvidedValue> providedArgs =
          await client.provideActionArgs(actionName);
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

      providedArgs = await client.provideActionArgs(actionName);
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

      List<DataType> argTypes = (await client.getActionMeta(actionName)).args;

      expect(argTypes[0].provided, isNotNull);
      expect(argTypes[0].provided.value, isNotNull);
      expect(argTypes[0].provided.hasValueSet, isTrue);
      expect(argTypes[0].provided.valueSet.limited, isFalse);
    });
    test('testProvideActionArgsDepends', () async {
      var client = await getClient();
      String actionName = 'SetActuatorDepends';

      // Reset the test state.
      await client.call(actionName, ['A', false, 1, 1, 'X']);

      List<DataType> argTypes = (await client.getActionMeta(actionName)).args;

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

      Map<String, ProvidedValue> providedArgs =
          await client.provideActionArgs(actionName, argNames: ['actuator1']);
      expect(providedArgs.length, equals(1));
      expect(providedArgs['actuator1'], isNotNull);
      var actuator1value = providedArgs['actuator1'].value;
      expect(actuator1value, equals('A'));
      expect(providedArgs['actuator1'].valueSet, equals(['A', 'B', 'C']));
      var actuator1AnnotatedValueSet =
          providedArgs['actuator1'].annotatedValueSet;
      expect(actuator1AnnotatedValueSet.length, equals(3));
      expect(actuator1AnnotatedValueSet[0].value, equals('A'));
      expect(actuator1AnnotatedValueSet[0].label, equals('Value A'));
      expect(actuator1AnnotatedValueSet[1].value, equals('B'));
      expect(actuator1AnnotatedValueSet[1].label, equals('Value B'));
      expect(actuator1AnnotatedValueSet[2].value, equals('C'));
      expect(actuator1AnnotatedValueSet[2].label, equals('Value C'));

      expect(providedArgs['actuator1'].valuePresent, isTrue);

      providedArgs = await client.provideActionArgs(actionName,
          argNames: ['actuator2', 'actuator3', 'actuator5'],
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
          await client.provideActionArgs(actionName, argNames: ['actuator1']);
      expect(providedArgs.length, equals(1));
      expect(providedArgs['actuator1'], isNotNull);
      actuator1value = providedArgs['actuator1'].value;
      expect(actuator1value, equals('B'));
      expect(providedArgs['actuator1'].valueSet, equals(['A', 'B', 'C']));
      expect(providedArgs['actuator1'].valuePresent, isTrue);

      providedArgs = await client.provideActionArgs(actionName,
          argNames: ['actuator2', 'actuator3', 'actuator5'],
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
      ActionMeta actionMeta = await client.getActionMeta('ProvideByAction');
      List values =
          (await client.provideActionArgs(actionMeta.name))['value'].valueSet;
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

      var provided = await client.provideActionArgs(actionName);
      var elementValueSet = provided['fruits'].annotatedElementValueSet;
      expect(elementValueSet.length, equals(3));
      expect(elementValueSet[0].value, equals('apple'));
      expect(elementValueSet[0].label, equals('Apple'));
      expect(elementValueSet[1].value, equals('banana'));
      expect(elementValueSet[1].label, equals('Banana'));
      expect(elementValueSet[2].value, equals('lemon'));
      expect(elementValueSet[2].label, equals('Lemon'));

      expect(
          await client.call(actionName, [
            ['apple', 'lemon']
          ]),
          equals(2));
    });
    test('testTraverseActionArguments', () async {
      var client = await getClient();
      ActionMeta meta = await client.getActionMeta('NestedRecordAsArgAction');

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

      List<QualifiedDataType> namedQTypes = [];
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
      String actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNull);

      ActionMeta actionMeta = await client.getActionMeta(actionName);
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
      String actionName = 'UpperCase';
      expect(await client.getActionMeta(actionName, allowFetchMetadata: false),
          isNull);
      expect(await client.getActionMeta(actionName), isNotNull);
    });
  });

  // Tests mirroring EventTypeCacheTest.java.
  group('REST API Client event type cache', () {
    test('testEventTypeCacheOn', () async {
      var client = await getClient();
      String eventTypeName = 'notification';
      expect(
          await client.getEventType(eventTypeName, allowFetchEventType: false),
          isNull);

      RecordType eventType = await client.getEventType(eventTypeName);
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

      String eventTypeName = 'notification';
      RecordType eventType = await client.getEventType(eventTypeName);
      expect(eventType, isNotNull);
      expect(await client.getEventType(eventTypeName), isNotNull);
      expect(identical(eventType, await client.getEventType(eventTypeName)),
          isFalse);
      await client.clearCache();
      expect(await client.getEventType(eventTypeName), isNotNull);
    });
    test('testEventTypeCacheOnGetEventTypes', () async {
      var client = await getClient();
      String eventTypeName = 'notification';
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
      String eventTypeName = 'notification';
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
      Response httpResponse = await post('${client.configuration.url}/actions',
          headers: {'Content-type': SpongeClientConstants.CONTENT_TYPE_JSON},
          body: requestBody);

      expect(httpResponse.statusCode, equals(200));
      var apiResponse = SpongeResponse.fromJson(json.decode(httpResponse.body));
      expect(apiResponse.header.errorCode,
          equals(SpongeClientConstants.DEFAULT_ERROR_CODE));
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

      List<String> requestStringList = [];
      List<String> responseStringList = [];

      client
        ..addOnRequestSerializedListener(
            (request, requestString) => requestStringList.add(requestString))
        ..addOnResponseDeserializedListener(
            (request, response, responseString) =>
                responseStringList.add(responseString));

      await client.getVersion();
      String version = await client.getVersion();
      await client.getVersion();

      expect(SpongeUtils.isServerVersionCompatible(version), isTrue);
      expect(requestStringList.length, equals(3));
      expect(responseStringList.length, equals(3));
      expect(
          normalizeJson(requestStringList[0]),
          equals(
              '{"header":{"id":null,"username":null,"password":null,"authToken":null}}'));
      expect(
          normalizeJson(responseStringList[0]),
          equals(
              '{"header":{"id":null,"errorCode":null,"errorMessage":null,"detailedErrorMessage":null},"version":"$version"}'));
    });
    test('testOneRequestListeners', () async {
      var client = await getClient();

      String actualRequestString;
      String actualResponseString;

      await client.getVersion();

      SpongeRequestContext context = SpongeRequestContext()
        ..onRequestSerializedListener =
            ((request, requestString) => actualRequestString = requestString)
        ..onResponseDeserializedListener =
            ((request, response, responseString) =>
                actualResponseString = responseString);
      var version = (await client.getVersionByRequest(GetVersionRequest(),
              context: context))
          .version;

      expect(SpongeUtils.isServerVersionCompatible(version), isTrue);

      await client.getVersion();

      expect(
          normalizeJson(actualRequestString),
          equals(
              '{"header":{"id":null,"username":null,"password":null,"authToken":null}}'));
      expect(
          normalizeJson(actualResponseString),
          equals(
              '{"header":{"id":null,"errorCode":null,"errorMessage":null,"detailedErrorMessage":null},"version":"$version"}'));
    });
  });
}
