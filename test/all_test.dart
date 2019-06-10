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

import 'package:test/test.dart';

import 'client_integration_test.dart' as client_integration_test;
import 'data_type_utils_test.dart' as data_type_utils_test;
import 'sub_action_specification_test.dart' as sub_action_specification_test;
import 'utils_test.dart' as utils_test;

void main() async {
  group('All', () {
    group('Integration', client_integration_test.main);
    group('Sub-actions', sub_action_specification_test.main);
    group('Data type utils', data_type_utils_test.main);
    group('Utils', utils_test.main);
  });
}
