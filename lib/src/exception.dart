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

/// A Sponge client exception.
class SpongeClientException implements Exception {
  const SpongeClientException([this.errorCode, this.errorMessage, this.detailedErrorMessage]);

  final String errorCode;
  final String errorMessage;
  final String detailedErrorMessage;

  @override
  String toString() => errorMessage ?? 'Sponge error, code: $errorCode';
}

/// A Sponge client exception for incorrect knowledge base version.
class IncorrectKnowledgeBaseVersionException extends SpongeClientException {
  const IncorrectKnowledgeBaseVersionException([String errorCode, String errorMessage, String detailedErrorMessage])
      : super(errorCode, errorMessage, detailedErrorMessage);
}

/// A Sponge client exception for invalid auth token.
class InvalidAuthTokenException extends SpongeClientException {
  const InvalidAuthTokenException([String errorCode, String errorMessage, String detailedErrorMessage])
      : super(errorCode, errorMessage, detailedErrorMessage);
}