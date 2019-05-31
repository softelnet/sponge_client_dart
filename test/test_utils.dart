// Copyright 2019 The Sponge authors.
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

import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_converter.dart';
import 'package:test/test.dart';

import 'complex_object.dart';

class TestUtils {
  static CompoundComplexObject createTestCompoundComplexObject() {
    var complexObject = ComplexObject(
        id: 1,
        name: 'TestComplexObject1',
        bigDecimal: 1.25,
        date: DateTime.now());
    return CompoundComplexObject(
        id: 1,
        name: 'TestCompoundComplexObject1',
        complexObject: complexObject);
  }

  static ObjectTypeUnitConverter createObjectTypeUnitConverter(
          [bool useTransparentIfNotFound = false]) =>
      ObjectTypeUnitConverter(useTransparentIfNotFound)
        ..addMarshaler(
            'org.openksavi.sponge.restapi.test.base.CompoundComplexObject',
            (_, value) async => (value as CompoundComplexObject)?.toJson())
        ..addUnmarshaler(
            'org.openksavi.sponge.restapi.test.base.CompoundComplexObject',
            (_, value) async => CompoundComplexObject.fromJson(value));

  static void assertBookRecordType(RecordType bookType) {
    expect(bookType, isNotNull);
    expect(bookType.kind, equals(DataTypeKind.RECORD));
    expect(bookType.name, equals('book'));
    expect(bookType.fields.length, equals(4));
    expect(bookType.fields[0].name, equals('id'));
    expect(bookType.fields[0].kind, equals(DataTypeKind.INTEGER));
    expect(bookType.fields[1].name, equals('author'));
    expect(bookType.fields[1].kind, equals(DataTypeKind.STRING));
    expect(bookType.fields[2].name, equals('title'));
    expect(bookType.fields[2].kind, equals(DataTypeKind.STRING));
    expect(bookType.fields[3].name, equals('comment'));
    expect(bookType.fields[3].kind, equals(DataTypeKind.STRING));
  }

  static void assertPersonRecordType(RecordType personType) {
    expect(personType, isNotNull);
    expect(personType.fields.length, equals(2));
    expect(personType.fields[0].name, equals('firstName'));
    expect(personType.fields[0].kind, equals(DataTypeKind.STRING));
    expect(personType.fields[1].name, equals('surname'));
    expect(personType.fields[1].kind, equals(DataTypeKind.STRING));
  }

  static void assertCitizenRecordType(RecordType citizenType) {
    expect(citizenType, isNotNull);
    expect(citizenType.fields.length, equals(3));
    expect(citizenType.fields[0].name, equals('firstName'));
    expect(citizenType.fields[0].kind, equals(DataTypeKind.STRING));
    expect(citizenType.fields[1].name, equals('surname'));
    expect(citizenType.fields[1].kind, equals(DataTypeKind.STRING));
    expect(citizenType.fields[2].name, equals('country'));
    expect(citizenType.fields[2].kind, equals(DataTypeKind.STRING));
  }

  static void assertNotificationRecordType(RecordType notificationType) {
    expect(notificationType, isNotNull);
    expect(notificationType.fields.length, equals(3));
    expect(notificationType.fields[0].kind, equals(DataTypeKind.STRING));
    expect(notificationType.fields[0].name, equals('source'));
    expect(notificationType.fields[0].label, equals('Source'));
    expect(notificationType.fields[1].kind, equals(DataTypeKind.INTEGER));
    expect(notificationType.fields[1].name, equals('severity'));
    expect(notificationType.fields[1].label, equals('Severity'));

    assertPersonRecordType(notificationType.getFieldType('person'));
  }
}
