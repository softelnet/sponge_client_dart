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

import 'dart:mirrors';

import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/utils.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';

void main() {
  group('Utils', () {
    test('obfuscatePassword', () {
      expect(
          SpongeClientUtils.obfuscatePassword(
              '{"username":"test","password":"secret"}'),
          equals('{"username":"test","password":"***"}'));
      expect(
          SpongeClientUtils.obfuscatePassword(
              '{"username":null,"password":null}'),
          equals('{"username":null,"password":null}'));
      expect(
          SpongeClientUtils.obfuscatePassword(
              '{"username":null,"password":null,"object":{"name":"value"}}'),
          equals(
              '{"username":null,"password":null,"object":{"name":"value"}}'));
      expect(
          SpongeClientUtils.obfuscatePassword(
              '{"id":null,"username":"test","password":"password","authToken":null,"name":"TestAction","args":["TEST",null],"version":null}'),
          equals(
              '{"id":null,"username":"test","password":"***","authToken":null,"name":"TestAction","args":["TEST",null],"version":null}'));

      expect(
          SpongeClientUtils.obfuscatePassword('{"passwordRetype":"secret!!!"}'),
          equals('{"passwordRetype":"***"}'));
      expect(
          SpongeClientUtils.obfuscatePassword('{"PASSwordRetype":"secret!!!"}'),
          equals('{"PASSwordRetype":"***"}'));
      expect(SpongeClientUtils.obfuscatePassword('{"a":"b"}'),
          equals('{"a":"b"}'));
    });
    test('isHttpSuccess', () {
      expect(SpongeClientUtils.isHttpSuccess(200), isTrue);
      expect(SpongeClientUtils.isHttpSuccess(404), isFalse);
    });
    test('isServerVersionCompatible', () {
      expect(
          SpongeClientUtils.isServerVersionCompatible(
              SpongeClientConstants.PROTOCOL_VERSION),
          isTrue);
      expect(SpongeClientUtils.isServerVersionCompatible('0'), isFalse);
    });
    test('formatIsoDateTimeZone', () async {
      await initializeTimeZone();
      var dateTimeZone = TZDateTime.from(
          DateTime.parse('2019-02-07T15:16:17'), getLocation('Europe/Paris'));
      expect(SpongeClientUtils.formatIsoDateTimeZone(dateTimeZone),
          equals('2019-02-07T15:16:17.000+01:00[Europe/Paris]'));
    });
    test('parseIsoDateTimeZone', () async {
      await initializeTimeZone();
      var dateTimeZone = TZDateTime.from(
          DateTime.parse('2019-02-07T15:16:17'), getLocation('Europe/Paris'));
      expect(
          SpongeClientUtils.parseIsoDateTimeZone(
              '2019-02-07T15:16:17.000+01:00[Europe/Paris]'),
          equals(dateTimeZone));
    });
    test('isAnnotatedValueMap', () {
      var reflectedClass = reflect(AnnotatedValue(null));

      var fieldNames = reflectedClass.type.declarations.values
          .where((declaration) =>
              declaration is VariableMirror && !declaration.isStatic)
          .map((declaration) => MirrorSystem.getName(declaration.simpleName))
          .toSet();

      var exampleMap = {for (var name in fieldNames) name: null};

      expect(SpongeClientUtils.isAnnotatedValueMap(exampleMap), isTrue);
      expect(SpongeClientUtils.isAnnotatedValueMap({'value': null}), isFalse);
    });
    test('shouldContentDispositionHaveFilename', () {
      expect(
        SpongeClientUtils.getFilenameFromContentDisposition(
            'Content-Disposition: attachment; filename="filename.jpg"'),
        equals('filename.jpg'),
      );
    });
    test('shouldContentDispositionHaveFilenameNone', () {
      expect(
        SpongeClientUtils.getFilenameFromContentDisposition(
            'Content-Disposition: attachment;'),
        isNull,
      );
    });
  });
}
