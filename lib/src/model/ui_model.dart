// Copyright 2020 The Sponge authors.
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

class IconInfo {
  IconInfo({
    this.name,
    this.color,
    this.size,
    this.url,
  });

  String name;

  String color;

  double size;

  String url;

  factory IconInfo.fromJson(Map<String, dynamic> json) => json != null
      ? IconInfo(
          name: json['name'],
          color: json['color'],
          size: (json['size'] as num)?.toDouble(),
          url: json['url'],
        )
      : null;

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'size': size,
        'url': url,
      };
}
