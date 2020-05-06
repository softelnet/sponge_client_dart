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

import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/constants.dart';
import 'package:sponge_client_dart/src/event.dart';
import 'package:sponge_client_dart/src/features/feature_converter.dart';
import 'package:sponge_client_dart/src/meta.dart';
import 'package:sponge_client_dart/src/type.dart';
import 'package:sponge_client_dart/src/type_converter.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/util/type_utils.dart';
import 'package:sponge_client_dart/src/util/validate.dart';
import 'package:timezone/timezone.dart';

/// A set of utility methods.
class SpongeUtils {
  /// Obfuscates a password in the JSON text of a request or response.
  static String obfuscatePassword(String text) => text?.replaceAllMapped(
      RegExp(r'"(\w*password\w*)":".*?"', caseSensitive: false),
      (Match m) => '"${m[1]}":"***"');

  /// Returns `true` if the HTTP [code] is success.
  static bool isHttpSuccess(int code) => 200 <= code && code <= 299;

  /// Returns `true` if the HTTP response content type is `application/json`.
  static bool isJson(Response httpResponse) {
    if (httpResponse == null) {
      return false;
    }

    var contentType = httpResponse.headers.entries
        .firstWhere((entry) => entry.key?.toLowerCase() == 'content-type',
            orElse: () => null)
        ?.value;

    if (contentType == null) {
      return false;
    }

    return contentType.startsWith('application/json');
  }

  /// Returns `true` if the Sponge server version [serverVersion] is compatible with the client.
  static bool isServerVersionCompatible(String serverVersion) =>
      serverVersion.startsWith(
          '${SpongeClientConstants.SUPPORTED_SPONGE_VERSION_MAJOR_MINOR}.');

  /// Formats a timezoned date/time to a Java compatible format.
  static String formatIsoDateTimeZone(TZDateTime tzDateTime) {
    var result = tzDateTime.toIso8601String();
    return '${result.substring(0, result.length - 2)}:${result.substring(result.length - 2)}[${tzDateTime.location.name}]';
  }

  /// Parses a Java compatible timezoned date/time format as `TZDateTime` or `DateTime` if the location is not present
  /// in the `tzDateTimeString`.
  static DateTime parseIsoDateTimeZone(String tzDateTimeString) {
    var locationIndex = tzDateTimeString.indexOf('[');
    var location = locationIndex > -1
        ? tzDateTimeString.substring(
            locationIndex + 1, tzDateTimeString.indexOf(']'))
        : null;
    return location != null
        ? TZDateTime.parse(
            getLocation(location), tzDateTimeString.substring(0, locationIndex))
        : DateTime.parse(tzDateTimeString);
  }

  static bool supportsElementValueSet(DataType dataType) =>
      dataType is ListType;

  static bool isAnnotatedValueMap(dynamic value) {
    return value is Map &&
        AnnotatedValue.FIELDS.length == value.length &&
        AnnotatedValue.FIELDS.containsAll(value.keys);
  }

  /// Traverses the action argument types.
  static void traverseActionArguments(
      ActionMeta actionMeta, void Function(QualifiedDataType _) onType,
      {bool namedOnly = true}) {
    actionMeta.args?.forEach((argType) => DataTypeUtils.traverseDataType(
        QualifiedDataType(argType, path: argType.name), onType,
        namedOnly: namedOnly));
  }

  static Future<Map<String, dynamic>> marshalRemoteEvent(
    RemoteEvent event,
    TypeConverter converter, {
    @required FutureOr<RecordType> Function(String argName) eventTypeSupplier,
  }) async {
    if (event == null) {
      return null;
    }

    event = event.clone();

    var eventType = Validate.notNull(await eventTypeSupplier?.call(event.name),
        'Event type ${event.name} not found');
    event.attributes = await converter.marshal(eventType, event.attributes);

    event.features =
        await FeaturesUtils.marshal(converter.featureConverter, event.features);

    return event.toJson();
  }

  static Future<RemoteEvent> unmarshalRemoteEvent(
    Map<String, dynamic> jsonEvent,
    TypeConverter converter,
    FutureOr<RecordType> Function(String argName) eventTypeSupplier,
  ) async {
    if (jsonEvent == null) {
      return null;
    }

    var event = RemoteEvent.fromJson(jsonEvent);

    var eventType = await eventTypeSupplier?.call(event.name);
    if (eventType != null) {
      event.attributes = await converter.unmarshal(eventType, event.attributes);
    }

    event.features = await FeaturesUtils.unmarshal(
        converter.featureConverter, event.features);

    return event;
  }
}
