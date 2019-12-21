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

import 'package:sponge_client_dart/sponge_client_dart.dart';

void main() async {
  // Create a new client for an anonymous user.
  var client = SpongeRestClient(
      SpongeRestClientConfiguration('http://localhost:8888/sponge.json/v1'));

  // Get the Sponge server version.
  var version = await client.getVersion();
  print('Sponge version: $version.');

  // Get actions metadata.
  var actionsMeta = await client.getActions();
  print('Available action count: ${actionsMeta.length}.');

  // Call the action with arguments.
  String upperCaseText = await client.call('UpperCase', ['Text to upper case']);
  print('Upper case text: $upperCaseText.');

  // Send a new event to the Sponge engine.
  var eventId = await client.send('alarm',
      attributes: {'source': 'Dart client', 'message': 'Something happened'});
  print('Sent event id: $eventId.');

  // Create a new client for a named user.
  client = SpongeRestClient(
    SpongeRestClientConfiguration('http://localhost:8888/sponge.json/v1')
      ..username = 'john'
      ..password = 'password',
  );
}
