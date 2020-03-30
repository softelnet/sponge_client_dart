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

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/type_converter.dart';

/// A Sponge Remote API event.
class RemoteEvent {
  RemoteEvent({
    this.id,
    @required this.name,
    this.time,
    this.priority,
    this.label,
    this.description,
    Map<String, dynamic> attributes,
    Map<String, Object> features,
  })  : attributes = attributes ?? {},
        features = features ?? {};

  String id;
  String name;
  DateTime time;
  int priority;
  String label;
  String description;
  Map<String, dynamic> attributes;
  Map<String, Object> features;

  factory RemoteEvent.fromJson(Map<String, dynamic> json) {
    return json != null
        ? RemoteEvent(
            id: json['id'],
            name: json['name'],
            time: json['time'] != null ? DateTime.parse(json['time']) : null,
            priority: json['priority'],
            label: json['label'],
            description: json['description'],
            attributes: json['attributes'],
            features: json['features'],
          )
        : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': DateTimeTypeUnitConverter.marshalInstant(time),
        'priority': priority,
        'label': label,
        'description': description,
        'attributes': attributes,
        'features': features,
      };

  RemoteEvent clone() => RemoteEvent(
        id: id,
        name: name,
        time: time,
        priority: priority,
        label: label,
        description: description,
        attributes: attributes != null ? Map.of(attributes) : null,
        features: features != null ? Map.of(features) : null,
      );
}
