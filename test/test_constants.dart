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

class TestConstants {
  static const int ADMIN_ALL_ACTION_COUNT = 13;
  static const int ANONYMOUS_ALL_ACTION_COUNT = ADMIN_ALL_ACTION_COUNT - 2;
  static const int ACTIONS_WITH_NO_METADATA_COUNT = 1;
  static const int ACTIONS_WITH_METADATA_COUNT = ANONYMOUS_ALL_ACTION_COUNT - ACTIONS_WITH_NO_METADATA_COUNT;
}
