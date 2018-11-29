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

import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Utils', () {
    test('obfuscatePassword', () {
      expect(
          SpongeUtils.obfuscatePassword(
              '{"username":"test","password":"secret"}'),
          equals('{"username":"test","password":"***"}'));
      expect(SpongeUtils.obfuscatePassword('{"username":null,"password":null}'),
          equals('{"username":null,"password":null}'));
      expect(
          SpongeUtils.obfuscatePassword(
              '{"username":null,"password":null,"object":{"name":"value"}}'),
          equals(
              '{"username":null,"password":null,"object":{"name":"value"}}'));
      expect(
          SpongeUtils.obfuscatePassword(
              '{"id":null,"username":"test","password":"password","authToken":null,"name":"TestAction","args":["TEST",null],"version":null}'),
          equals(
              '{"id":null,"username":"test","password":"***","authToken":null,"name":"TestAction","args":["TEST",null],"version":null}'));
    });
    test('isHttpSuccess', () {
      expect(SpongeUtils.isHttpSuccess(200), isTrue);
      expect(SpongeUtils.isHttpSuccess(404), isFalse);
    });
    test('isServerVersionCompatible', () {
      expect(
          SpongeUtils.isServerVersionCompatible(
              '${SpongeClientConstants.SUPPORTED_SPONGE_VERSION_MAJOR_MINOR}.5'),
          isTrue);
      expect(SpongeUtils.isServerVersionCompatible('0.4.3'), isFalse);
    });
  });
}
