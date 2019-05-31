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

class ComplexObject {
  ComplexObject({this.id, this.name, this.bigDecimal, this.date});
  int id;
  String name;
  double bigDecimal;
  DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bigDecimal': bigDecimal,
        'date': date?.toIso8601String(),
      };
  factory ComplexObject.fromJson(Map<String, dynamic> json) => json != null
      ? ComplexObject(
          id: json['id'],
          name: json['name'],
          bigDecimal: json['bigDecimal'],
          date: json['date'] != null ? DateTime.parse(json['date']) : null,
        )
      : null;
}

class CompoundComplexObject {
  CompoundComplexObject({this.id, this.name, this.complexObject});
  int id;
  String name;
  ComplexObject complexObject;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'complexObject': complexObject?.toJson(),
      };

  factory CompoundComplexObject.fromJson(Map<String, dynamic> json) =>
      json != null
          ? CompoundComplexObject(
              id: json['id'],
              name: json['name'],
              complexObject: ComplexObject.fromJson(json['complexObject']),
            )
          : null;
}
