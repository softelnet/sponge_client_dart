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

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_converter.dart';

/// A Sponge Remote API event.
class RemoteEvent {
  RemoteEvent({
    @required this.id,
    @required this.name,
    @required this.time,
    @required this.priority,
    this.label,
    this.description,
    Map<String, dynamic> attributes,
  }) : this.attributes = attributes ?? {};

  String id;
  String name;
  DateTime time;
  int priority;
  String label;
  String description;
  Map<String, dynamic> attributes;

  Future<Map<String, dynamic>> convertToJson(
      RecordType eventType, TypeConverter converter) async {
    return {
      'id': id,
      'name': name,
      'time': DateTimeTypeUnitConverter.marshalInstant(time),
      'priority': priority,
      'label': label,
      'description': description,
      'attributes': attributes != null
          ? await converter.marshal(eventType, attributes)
          : {},
    };
  }
}
