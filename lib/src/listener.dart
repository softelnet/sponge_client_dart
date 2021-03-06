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

import 'package:sponge_client_dart/src/request.dart';
import 'package:sponge_client_dart/src/response.dart';

/// A callback that will be invoked when the request is serialized. Remember to obfuscate
/// the password if the [requestString] is to be shown.
typedef OnRequestSerializedListener = void Function(
    SpongeRequest request, String requestString);

/// A callback that will be invoked when the response is deserialized.
typedef OnResponseDeserializedListener = void Function(
    SpongeRequest request, SpongeResponse response, String responseString);
