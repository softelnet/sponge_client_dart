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

import 'package:meta/meta.dart';

class GeoPosition {
  GeoPosition({
    @required this.latitude,
    @required this.longitude,
  });

  double latitude;
  double longitude;

  factory GeoPosition.fromJson(Map<String, dynamic> json) => json != null
      ? GeoPosition(
          latitude: (json['latitude'] as num)?.toDouble(),
          longitude: (json['longitude'] as num)?.toDouble(),
        )
      : null;

  // TODO toJson
}

class GeoLayer {
  GeoLayer({
    @required this.urlTemplate,
    Map<String, String> options,
    Map<String, Object> features,
  })  : options = options ?? {},
        features = features ?? {};

  String urlTemplate;
  Map<String, String> options;

  /// The geo layer features as a map of names to values.
  final Map<String, Object> features;

  factory GeoLayer.fromJson(Map<String, dynamic> json) => json != null
      ? GeoLayer(
          urlTemplate: json['urlTemplate'],
          options: (json['options'] as Map)
              ?.map((name, valueJson) => MapEntry(name, valueJson?.toString())),
          features: Map.of(json['features'] as Map ?? {}),
        )
      : null;
  // TODO toJson
}

class GeoMap {
  GeoMap({
    @required this.center,
    @required this.zoom,
    @required this.minZoom,
    @required this.maxZoom,
    @required this.crs,
    List<GeoLayer> layers,
    Map<String, Object> features,
  })  : layers = layers ?? [],
        features = features ?? {};

  GeoPosition center;
  double zoom;
  double minZoom;
  double maxZoom;

  /// Coordinate Reference System. Currently ignored.
  String crs;

  List<GeoLayer> layers;

  /// The geo map features as a map of names to values.
  final Map<String, Object> features;

  factory GeoMap.fromJson(Map<String, dynamic> json) => json != null
      ? GeoMap(
          center: GeoPosition.fromJson(json['center']),
          zoom: (json['zoom'] as num)?.toDouble(),
          minZoom: (json['minZoom'] as num)?.toDouble(),
          maxZoom: (json['maxZoom'] as num)?.toDouble(),
          crs: json['crs'],
          layers: (json['layers'] as List)
              ?.map((layer) => GeoLayer.fromJson(layer))
              ?.toList(),
          features: Map.of(json['features'] as Map ?? {}),
        )
      : null;
  // TODO toJson
}
