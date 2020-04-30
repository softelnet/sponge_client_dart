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

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:sponge_client_dart/src/exception.dart';
import 'package:sponge_client_dart/src/features/features.dart';
import 'package:sponge_client_dart/src/features/model/features_model.dart';
import 'package:sponge_client_dart/src/features/model/geo_model.dart';
import 'package:sponge_client_dart/src/features/model/ui_model.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

class FeaturesUtils {
  static Future<Map<String, Object>> marshal(
      FeatureConverter converter, Map<String, Object> features) async {
    if (converter == null) {
      return features;
    }

    var result = <String, Object>{};

    if (features != null) {
      for (var featureName in features.keys) {
        result[featureName] =
            await converter.marshal(featureName, features[featureName]);
      }
    }
    return result;
  }

  static Future<Map<String, Object>> unmarshal(
      FeatureConverter converter, Map<String, Object> features) async {
    if (converter == null) {
      return features;
    }

    var result = <String, Object>{};

    if (features != null) {
      for (var featureName in features.keys) {
        result[featureName] =
            await converter.unmarshal(featureName, features[featureName]);
      }
    }
    return result;
  }
}

/// A feature converter.
abstract class FeatureConverter {
  static final Logger _logger = Logger('FeatureConverter');
  final Map<String, UnitFeatureConverter> _registry = {};

  /// Marshals the [value] as [feature].
  Future<dynamic> marshal(String name, dynamic value) async {
    if (name == null || value == null) {
      return value;
    }

    var unitConverter = _registry[name];
    return unitConverter != null
        ? await unitConverter.marshal(this, value)
        : value;
  }

  /// Unmarshals the [value] as [feature].
  Future<dynamic> unmarshal(String name, dynamic value) async {
    if (name == null || value == null) {
      return value;
    }

    var unitConverter = _registry[name];
    return unitConverter != null
        ? await unitConverter.unmarshal(this, value)
        : value;
  }

  /// Registers the unit feature converter.
  void register(UnitFeatureConverter unitConverter) {
    _logger.finest(
        'Registering ${unitConverter.names} feature(s) converter: $unitConverter');
    unitConverter.names.forEach((name) => _registry[name] = unitConverter);
  }

  /// Registers the unit feature converters.
  void registerAll(List<UnitFeatureConverter> unitConverters) =>
      unitConverters.forEach(register);

  /// Unregisters a unit feature converter for the feature [name]. Returns the previously registered unit type converter.
  UnitFeatureConverter unregister(String name) => _registry.remove(name);
}

/// A default feature converter.
class DefaultFeatureConverter extends FeatureConverter {
  DefaultFeatureConverter() {
    // Register default unit converters.
    registerAll([
      SubActionFeatureUnitConverter(),
      SubActionFeaturesUnitConverter(),
      IconFeatureUnitConverter(),
      GeoMapFeatureUnitConverter(),
      GeoPositionFeatureUnitConverter(),
    ]);
  }
}

/// An unit feature converter. All implementations should be stateless because one instance is shared
/// by different invocations of [marshal] and [unmarshal] methods.
abstract class UnitFeatureConverter {
  UnitFeatureConverter(this.names);

  /// The feature names.
  final List<String> names;

  /// Marshals the [value].
  ///
  /// The [value] will never be null here.
  Future<dynamic> marshal(FeatureConverter converter, dynamic value) async =>
      value;

  /// Unmarshals the [value].
  ///
  /// The [value] will never be null here.
  Future<dynamic> unmarshal(FeatureConverter converter, dynamic value) async =>
      value;
}

class SubActionFeatureUnitConverter extends UnitFeatureConverter {
  SubActionFeatureUnitConverter()
      : super([
          Features.SUB_ACTION_ACTIVATE_ACTION,
          Features.SUB_ACTION_CREATE_ACTION,
          Features.SUB_ACTION_DELETE_ACTION,
          Features.SUB_ACTION_READ_ACTION,
          Features.SUB_ACTION_UPDATE_ACTION
        ]);

  @override
  Future<dynamic> marshal(FeatureConverter converter, dynamic value) async {
    var subAction = (value as SubAction).clone();

    subAction.features =
        await FeaturesUtils.marshal(converter, subAction.features);
    for (var arg in subAction.args ?? []) {
      arg.features = await FeaturesUtils.marshal(converter, arg.features);
    }

    if (subAction.result != null) {
      subAction.result.features =
          await FeaturesUtils.marshal(converter, subAction.result.features);
    }

    return subAction;
  }

  @override
  Future<dynamic> unmarshal(FeatureConverter converter, dynamic value) async {
    var subAction = SubAction.fromJson(value);

    subAction.features =
        await FeaturesUtils.unmarshal(converter, subAction.features);
    for (var arg in subAction.args ?? []) {
      arg.features = await FeaturesUtils.unmarshal(converter, arg.features);
    }

    if (subAction.result != null) {
      subAction.result.features =
          await FeaturesUtils.unmarshal(converter, subAction.result.features);
    }

    return subAction;
  }
}

class SubActionFeaturesUnitConverter extends UnitFeatureConverter {
  SubActionFeaturesUnitConverter() : super([Features.CONTEXT_ACTIONS]);

  final _elementConverter = SubActionFeatureUnitConverter();

  @override
  Future<dynamic> marshal(FeatureConverter converter, dynamic value) async {
    Validate.isTrue(value is List<SubAction>,
        'The ${Features.CONTEXT_ACTIONS} feature has to be a list of sub-actions');

    var subActions = [];
    for (var subAction in (value as List<SubAction>)) {
      subActions.add(await _elementConverter.marshal(converter, subAction));
    }

    return subActions;
  }

  @override
  Future<dynamic> unmarshal(FeatureConverter converter, dynamic value) async {
    Validate.isTrue(value is List,
        'The ${Features.CONTEXT_ACTIONS} feature has to be a list of sub-actions');

    var subActions = <SubAction>[];
    for (var subAction in (value as List)) {
      subActions.add(await _elementConverter.unmarshal(converter, subAction));
    }

    return subActions;
  }
}

class IconFeatureUnitConverter extends UnitFeatureConverter {
  IconFeatureUnitConverter() : super([Features.ICON]);

  @override
  Future<dynamic> marshal(FeatureConverter converter, dynamic value) async {
    if (value is IconInfo) {
      return value.toJson();
    } else if (value is String) {
      return value;
    } else {
      throw SpongeException('Unsupported icon type: ${value.runtimeType}');
    }
  }

  @override
  Future<dynamic> unmarshal(FeatureConverter converter, dynamic value) async {
    if (value is Map) {
      return IconInfo.fromJson(value);
    } else if (value is String) {
      return IconInfo(name: value);
    } else {
      throw SpongeException('Unsupported icon type: ${value.runtimeType}');
    }
  }
}

class GeoMapFeatureUnitConverter extends UnitFeatureConverter {
  GeoMapFeatureUnitConverter() : super([Features.GEO_MAP]);

  @override
  Future<dynamic> marshal(FeatureConverter converter, dynamic value) async {
    throw SpongeException('Marshalling of a geo map is not supported');
  }

  @override
  Future<dynamic> unmarshal(FeatureConverter converter, dynamic value) async {
    var geoMap = GeoMap.fromJson(value);

    geoMap.features = await FeaturesUtils.unmarshal(converter, geoMap.features);

    for (var layer in geoMap.layers ?? []) {
      layer.features = await FeaturesUtils.unmarshal(converter, layer.features);
    }

    return geoMap;
  }
}

class GeoPositionFeatureUnitConverter extends UnitFeatureConverter {
  GeoPositionFeatureUnitConverter() : super([Features.GEO_POSITION]);

  @override
  Future<dynamic> marshal(FeatureConverter converter, dynamic value) async =>
      (value as GeoPosition)?.toJson();

  @override
  Future<dynamic> unmarshal(FeatureConverter converter, dynamic value) async =>
      GeoPosition.fromJson(value);
}
