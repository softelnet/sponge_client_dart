// Copyright 2019 The Sponge authors.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:sponge_client_dart/src/features/model/features_model.dart';
import 'package:sponge_client_dart/src/features/model/geo_model.dart';
import 'package:sponge_client_dart/src/features/model/ui_model.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

class Features {
  static const INTENT = 'intent';

  static const VISIBLE = 'visible';
  static const ENABLED = 'enabled';
  static const REFRESHABLE = 'refreshable';

  static const ICON = 'icon';

  static const COLOR = 'color';
  static const OPACITY = 'opacity';

  static const WIDGET = 'widget';
  static const GROUP = 'group';

  static const KEY = 'key';

  static const RESPONSIVE = 'responsive';

  static const ACTION_CONFIRMATION = 'confirmation';

  static const TYPE_CHARACTERISTIC = 'characteristic';
  static const TYPE_CHARACTERISTIC_DRAWING = 'drawing';
  static const TYPE_CHARACTERISTIC_COLOR = 'color';
  static const TYPE_CHARACTERISTIC_NETWORK_IMAGE = 'networkImage';

  static const TYPE_FILENAME = 'filename';

  static const ACTION_INTENT_VALUE_LOGIN = 'login';
  static const ACTION_INTENT_VALUE_LOGOUT = 'logout';
  static const ACTION_INTENT_VALUE_SIGN_UP = 'signUp';
  static const TYPE_INTENT_VALUE_USERNAME = 'username';
  static const TYPE_INTENT_VALUE_PASSWORD = 'password';
  static const TYPE_INTENT_VALUE_SAVE_PASSWORD = 'savePassword';

  static const ACTION_INTENT_VALUE_SUBSCRIPTION = 'subscription';
  static const TYPE_INTENT_VALUE_EVENT_NAMES = 'eventNames';
  static const TYPE_INTENT_VALUE_SUBSCRIBE = 'subscribe';

  static const ACTION_INTENT_VALUE_RELOAD = 'reload';
  static const ACTION_INTENT_VALUE_RESET = 'reset';

  static const ACTION_REFRESH_EVENTS = 'refreshEvents';

  static const EVENT_HANDLER_ACTION = 'handlerAction';
  static const ACTION_INTENT_DEFAULT_EVENT_HANDLER = 'defaultEventHandler';

  static const STRING_MULTILINE = 'multiline';
  static const STRING_MAX_LINES = 'maxLines';
  static const STRING_OBSCURE = 'obscure';

  // Action features for the Action call widget.
  static const ACTION_CALL_SHOW_CALL = 'showCall';
  static const ACTION_CALL_SHOW_REFRESH = 'showRefresh';
  static const ACTION_CALL_SHOW_CLEAR = 'showClear';
  static const ACTION_CALL_SHOW_CANCEL = 'showCancel';

  static const ACTION_CALL_CALL_LABEL = 'callLabel';
  static const ACTION_CALL_REFRESH_LABEL = 'refreshLabel';
  static const ACTION_CALL_CLEAR_LABEL = 'clearLabel';
  static const ACTION_CALL_CANCEL_LABEL = 'cancelLabel';

  static const CONTEXT_ACTIONS = 'contextActions';

  static const CACHEABLE_ARGS = 'cacheableArgs';
  static const CACHEABLE_CONTEXT_ARGS = 'cacheableContextArgs';

  // Type features for ListType in action forms.
  static const SUB_ACTION_CREATE_ACTION = 'createAction';
  static const SUB_ACTION_READ_ACTION = 'readAction';
  static const SUB_ACTION_UPDATE_ACTION = 'updateAction';
  static const SUB_ACTION_DELETE_ACTION = 'deleteAction';
  static const SUB_ACTION_ACTIVATE_ACTION = 'activateAction';

  static const TYPE_LIST_ACTIVATE_ACTION_VALUE_SUBMIT = '@submit';

  static const BINARY_WIDTH = 'width';
  static const BINARY_HEIGHT = 'height';
  static const BINARY_STROKE_WIDTH = 'strokeWidth';
  static const BINARY_COLOR = 'color';
  static const BINARY_BACKGROUND = 'background';

  static const WIDGET_SLIDER = 'slider';
  static const WIDGET_SWITCH = 'switch';

  static const SCROLL = 'scroll';

  static const PROVIDE_VALUE_PAGEABLE = 'pageable';
  static const PROVIDE_VALUE_OFFSET = 'offset';
  static const PROVIDE_VALUE_LIMIT = 'limit';
  static const PROVIDE_VALUE_COUNT = 'count';
  static const PROVIDE_VALUE_INDICATED_INDEX = 'indicatedIndex';

  static const SUBMITTABLE_BLOCKING = 'submittableBlocking';

  static const GEO_MAP = 'geoMap';
  static const GEO_POSITION = 'geoPosition';
  static const GEO_ATTRIBUTION = 'attribution';
  static const GEO_TMS = 'tms';
  static const GEO_LAYER_NAME = 'geoLayerName';

  static const REQUEST_CHANNEL = 'channel';
  static const REQUEST_LANGUAGE = 'language';

  static const SUB_ACTION_FEATURES = [
    CONTEXT_ACTIONS,
    SUB_ACTION_CREATE_ACTION,
    SUB_ACTION_READ_ACTION,
    SUB_ACTION_UPDATE_ACTION,
    SUB_ACTION_DELETE_ACTION,
    SUB_ACTION_ACTIVATE_ACTION
  ];

  static String getCharacteristic(Map<String, Object> features) {
    var characteristic = features[TYPE_CHARACTERISTIC];

    if (characteristic != null) {
      Validate.isTrue(characteristic is String,
          'The characteristic feature should be a string');
    }

    return characteristic;
  }

  static T getOptional<T>(
          Map<String, Object> features, String name, T Function() orElse) =>
      features.containsKey(name) ? features[name] : orElse();

  static bool getBool(
    Map<String, Object> features,
    String name, {
    bool Function() orElse,
  }) {
    if (!features.containsKey(name)) {
      return orElse();
    }

    var value = features[name];

    Validate.isTrue(value is bool, 'Feature $name should be a boolean');

    return value;
  }

  static double getDouble(
    Map<String, Object> features,
    String name, {
    double Function() orElse,
  }) {
    if (!features.containsKey(name)) {
      return orElse();
    }

    return (features[name] as num)?.toDouble();
  }

  static dynamic findFeature(
          List<Map<String, Object>> featuresList, String name) =>
      featuresList
          .map((features) => features[name])
          .firstWhere((feature) => feature != null, orElse: () => null);

  static List<String> getStringList(Map<String, Object> features, String name) {
    var feature = features[name];
    if (feature is Iterable) {
      return List<String>.from(feature.map((f) => f as String).toList());
    } else if (feature is String) {
      // Allow converting a single string feature to a list.
      return [feature];
    }

    return [];
  }

  static SubAction getSubAction(
          Map<String, Object> features, String subActionFeature) =>
      features != null ? features[subActionFeature] as SubAction : null;

  static List<SubAction> getSubActions(
          Map<String, Object> features, String subActionsFeature) =>
      features != null
          ? (features[subActionsFeature] as List<SubAction> ?? [])
          : [];

  static IconInfo getIcon(Map<String, Object> features) =>
      features != null ? features[ICON] as IconInfo : null;

  static GeoMap getGeoMap(Map<String, Object> features) =>
      features != null ? features[GEO_MAP] as GeoMap : null;

  static GeoPosition getGeoPosition(Map<String, Object> features) =>
      features != null ? features[GEO_POSITION] as GeoPosition : null;
}

class Formats {
  static const STRING_FORMAT_PHONE = 'phone';
  static const STRING_FORMAT_EMAIL = 'email';
  static const STRING_FORMAT_URL = 'url';

  static const STRING_FORMAT_CONSOLE = 'console';
  static const STRING_FORMAT_MARKDOWN = 'markdown';
}
