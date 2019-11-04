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

import 'package:sponge_client_dart/src/util/validate.dart';

class Features {
  static const INTENT = 'intent';

  static const VISIBLE = 'visible';

  static const ICON = 'icon';

  static const WIDGET = 'widget';

  static const RESPONSIVE = 'responsive';

  static const ACTION_CONFIRMATION = 'confirmation';

  static const TYPE_CHARACTERISTIC = 'characteristic';
  static const TYPE_CHARACTERISTIC_DRAWING = 'drawing';
  static const TYPE_CHARACTERISTIC_COLOR = 'color';

  static const TYPE_FILENAME = 'filename';

  static const ACTION_INTENT_VALUE_LOGIN = 'login';
  static const ACTION_INTENT_VALUE_LOGOUT = 'logout';
  static const ACTION_INTENT_VALUE_SIGN_UP = 'signUp';
  static const TYPE_INTENT_VALUE_USERNAME = 'username';
  static const TYPE_INTENT_VALUE_PASSWORD = 'password';

  static const ACTION_INTENT_VALUE_SUBSCRIPTION = 'subscription';
  static const TYPE_INTENT_VALUE_EVENT_NAMES = 'eventNames';
  static const TYPE_INTENT_VALUE_SUBSCRIBE = 'subscribe';

  static const ACTION_REFRESH_EVENTS = 'refreshEvents';

  static const EVENT_HANDLER_ACTION = 'handlerAction';
  static const ACTION_INTENT_DEFAULT_EVENT_HANDLER = 'defaultEventHandler';

  static const STRING_MULTILINE = 'multiline';
  static const STRING_MAX_LINES = 'maxLines';
  static const STRING_OBSCURE = 'obscure';

  // Action features for the Action call widget.
  static const ACTION_CALL_CALL_LABEL = 'callLabel';
  static const ACTION_CALL_REFRESH_LABEL = 'refreshLabel';
  static const ACTION_CALL_CLEAR_LABEL = 'clearLabel';
  static const ACTION_CALL_CANCEL_LABEL = 'cancelLabel';

  static const CONTEXT_ACTIONS = 'contextActions';

  // Type features for ListType in action forms.
  static const ACTION_ARG_LIST_CREATE_ACTION = 'createAction';
  static const ACTION_ARG_LIST_READ_ACTION = 'readAction';
  static const ACTION_ARG_LIST_UPDATE_ACTION = 'updateAction';
  static const ACTION_ARG_LIST_DELETE_ACTION = 'deleteAction';
  static const ACTION_ARG_LIST_ACTIVATE_ACTION = 'activateAction';

  static const BINARY_WIDTH = 'width';
  static const BINARY_HEIGHT = 'height';
  static const BINARY_STROKE_WIDTH = 'strokeWidth';
  static const BINARY_COLOR = 'color';
  static const BINARY_BACKGROUND = 'background';

  static const WIDGET_SLIDER = 'slider';
  static const WIDGET_SWITCH = 'switch';

  static const SCROLL = 'scroll';

  static const PROVIDE_VALUE_PAGINABLE = 'valuePaginable';
  static const PROVIDE_VALUE_OFFSET = 'valueOffset';
  static const PROVIDE_VALUE_LIMIT = 'valueLimit';
  static const PROVIDE_VALUE_SET_PAGINABLE = 'valueSetPaginable';
  static const PROVIDE_VALUE_SET_OFFSET = 'valueSetOffset';
  static const PROVIDE_VALUE_SET_LIMIT = 'valueSetLimit';
  static const PROVIDE_ELEMENT_VALUE_SET_PAGINABLE = 'elementValueSetPaginable';
  static const PROVIDE_ELEMENT_VALUE_SET_OFFSET = 'elementValueSetOffset';
  static const PROVIDE_ELEMENT_VALUE_SET_LIMIT = 'elementValueSetLimit';

  static String getCharacteristic(Map<String, Object> features) {
    var characteristic = features[TYPE_CHARACTERISTIC];

    if (characteristic != null) {
      Validate.isTrue(characteristic is String,
          'The characteristic feature should be a string');
    }

    return characteristic;
  }

  static T getOptional<T>(
          Map<String, Object> features, String name, T orElse()) =>
      features.containsKey(name) ? features[name] : orElse();

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
}

class Formats {
  static const STRING_FORMAT_PHONE = 'phone';
  static const STRING_FORMAT_EMAIL = 'email';
  static const STRING_FORMAT_URL = 'url';

  static const STRING_FORMAT_CONSOLE = 'console';
  static const STRING_FORMAT_MARKDOWN = 'markdown';
}