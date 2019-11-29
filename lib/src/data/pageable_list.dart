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
import 'package:sponge_client_dart/src/features.dart';
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

  @override
  int get length => _internal.length;

  int get limit => _limit;

  int get count => _count;

  set length(int value) => throw UnsupportedError(
      'Setting length of a pageable list is not supported');

  @override
  operator [](int index) {
    return _internal[index];
  }

  @override
  void operator []=(int index, E value) {
    _internal[index] = value;
  }

  bool get initialized => _lastOffset != null;

  void addPage(AnnotatedValue page) {
    int lastOffset = page.features[Features.PROVIDE_VALUE_OFFSET];
    int limit = page.features[Features.PROVIDE_VALUE_LIMIT];
    int count = page.features[Features.PROVIDE_VALUE_COUNT];

    if (lastOffset < length) {
      Validate.isTrue(lastOffset == null || lastOffset == 0,
          'A new page has a non zero offset');
      _internal.clear();
      _lastOffset = 0;
    } else {
      _lastOffset = lastOffset;
    }

    _internal.addAll(List.from(page.value));

    _limit = limit;
    _count = count;
  }

  bool get hasMorePages => _count != null ? (length < _count) : true;
}
