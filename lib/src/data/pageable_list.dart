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

import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:sponge_client_dart/src/features/features.dart';
import 'package:sponge_client_dart/src/type_value.dart';
import 'package:sponge_client_dart/src/util/validate.dart';

@experimental
class PageableList<E> extends ListBase<E> {
  PageableList({AnnotatedValue initialPage}) {
    if (initialPage != null) {
      addPage(initialPage);
    }
  }

  final List<E> _internal = [];
  int _lastOffset;
  int _limit;
  int _count;
  int _indicatedIndex;

  @override
  int get length => _internal.length;

  int get limit => _limit;

  int get count => _count;

  int get indicatedIndex => _indicatedIndex;

  @override
  set length(int value) => throw UnsupportedError(
      'Setting length of a pageable list is not supported');

  @override
  E operator [](int index) {
    return _internal[index];
  }

  @override
  void operator []=(int index, E value) {
    _internal[index] = value;
  }

  bool get initialized => _lastOffset != null;

  void addPage(AnnotatedValue page) {
    Validate.isTrue(page.value is List, 'A page value should be a list');

    int offset = page.features[Features.PROVIDE_VALUE_OFFSET];
    int limit = page.features[Features.PROVIDE_VALUE_LIMIT];
    int count = page.features[Features.PROVIDE_VALUE_COUNT];
    int indicatedIndex = page.features[Features.PROVIDE_VALUE_INDICATED_INDEX];

    Validate.notNull(offset, 'The offset can\'t be null');

    if (offset < length) {
      Validate.isTrue(offset == 0,
          'A new page has a non zero offset that is lower that the list length');
      _internal.clear();
      _lastOffset = 0;
    } else {
      _lastOffset = offset;
    }

    _internal.addAll(page.value);

    _limit = limit;
    _count = count;
    _indicatedIndex = indicatedIndex;
  }

  bool get hasMorePages => _count != null ? (length < _count) : true;
}
