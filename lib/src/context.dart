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

import 'package:sponge_client_dart/src/listener.dart';

class SpongeRequestContext {
  SpongeRequestContext({
    bool expectsResponseStream,
    this.onRequestSerializedListener,
    this.onResponseDeserializedListener,
  }) : expectsResponseStream = expectsResponseStream ?? false;

  factory SpongeRequestContext.overwrite(
    SpongeRequestContext context, {
    bool expectsResponseStream,
    OnRequestSerializedListener onRequestSerializedListener,
    OnResponseDeserializedListener onResponseDeserializedListener,
  }) {
    return SpongeRequestContext(
      expectsResponseStream:
          expectsResponseStream ?? context?.expectsResponseStream,
      onRequestSerializedListener:
          onRequestSerializedListener ?? context?.onRequestSerializedListener,
      onResponseDeserializedListener: onResponseDeserializedListener ??
          context?.onResponseDeserializedListener,
    );
  }

  final bool expectsResponseStream;
  final OnRequestSerializedListener onRequestSerializedListener;
  final OnResponseDeserializedListener onResponseDeserializedListener;
}
