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

/// A Sponge Remote API configuration.
class SpongeClientConfiguration {
  SpongeClientConfiguration(
    this.url, {
    this.username,
    this.password,
    this.autoUseAuthToken = false,
    this.relogin = true,
    this.verifyProcessorVersion = true,
    this.useActionMetaCache = true,
    this.actionMetaCacheMaxSize = -1,
    this.useEventTypeCache = true,
    this.eventTypeCacheMaxSize = -1,
    this.throwExceptionOnErrorResponse = true,
    this.allowFetchActionMetadataInActionCall = true,
    this.features,
    this.httpHeaders,
  });

  /// The service URL (reqired).
  String url;

  /// The optional service username.
  String username;

  /// The optional service username.
  String password;

  /// The flag telling if the client should automatically use auth token authentication (i.e. the login
  /// operation won't be required to use the auth token authentication). Defaults to `false`.
  bool autoUseAuthToken;

  /// The flag telling if the client should automatically relogin when an auth token expires.
  bool relogin;

  /// The flag telling if the client should request verification of a processor
  /// version on the server.
  bool verifyProcessorVersion;

  /// The flag telling if the client should use the action meta cache.
  bool useActionMetaCache;

  /// The maximum size of the action meta cache. The default value (-1) implies that
  /// there is no maximum size.
  int actionMetaCacheMaxSize;

  /// The flag telling if the client should use the event type cache.
  bool useEventTypeCache;

  /// The maximum size of the event type cache. The default value (-1) implies that
  /// there is no maximum size.
  int eventTypeCacheMaxSize;

  /// The flag that instructs the client to throw an exception when a response is an error response.
  /// Defaults to `true`.
  /// Setting this value to `false` makes sense only when using the client API methods `*ByRequest()`.
  bool throwExceptionOnErrorResponse;

  /// The request header features.
  Map<String, Object> features;

  bool allowFetchActionMetadataInActionCall;

  /// The HTTP request headers.
  Map<String, Object> httpHeaders;

  /// Returns true if the connection URL is HTTPS.
  bool get secure => url != null && url.toLowerCase().startsWith('https');
}
