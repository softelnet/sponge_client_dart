## 1.15.0 (2020-03-30)
* API change: Changed `submittable` type from `bool` to `SubmittableMeta` in the `ProvidedMeta`.
* Added an `activatable` flag to an action.
* Added `features` to the request header.
* Added support for typed features and feature converters.
* Added support for event features.
* Added support for geographical map features.
* The default REST API path is now empty. The previous value was `sponge.json/v1`.
* Dependencies upgrade.

## 1.14.0+1 (2019-12-21)
* Added indicatedIndex to PageableList.
* Code cleanup.
* Dependencies upgrade.
  
## 1.14.0 (2019-12-20)
* API change: A payload in a request and a response has been moved to `body`.
* API change: Renamed `label` to `valueLabel` and `description` to `valueDescription` in `AnnotatedValue`.
* API change: Removed `SpongeRestClient.submitActionArgs`. Use `provideActionArgs` directly.
* Added `AnnotatedValue.typeLabel` and `AnnotatedValue.typeDescription`.
* Added `ProvidedMeta.mode` - a provided read mode: `explicit` (default), `optional` or `implicit`.
* Added support for context action result substitution.
* Added high level classes (e.g. `ActionData`, `PageableList`) in the `data` package. Currently marked as experimental.
* Added support for a companion type in an object type.
* Added support for the `isActionActive` REST operation.
* Removed support for features in an action arguments provision result itself (`ProvidedValue`). Such features can be provided in an `AnnotatedValue`.
* Removed experimental support for pageable value set and element value set.

## 1.13.0 (2019-10-30)

* Added support for submitting action arguments to the server.
* Added support for features in action arguments provision.
* Added the `Features` class that lists all predefined features.
* API change: Renamed error codes.
* Dependencies upgrade.
  
## 1.12.0 (2019-09-30)

* Improved `RemoteEvent` marshaling.
* DynamicValue unwrapping in `DataTypeUtils`.
* Added a return value in the `DataTypeUtils.traverseValue` method.
* Dependencies upgrade.
  
## 1.11.0 (2019-07-11)

* API change: Base request and response properties have been moved to headers.
* Added label and description to REST API send event.
* Added a new property `unique` to the ListType.
* Added support for the `features` REST operation.
* Added support for element value set for provided list types.
* Dependencies upgrade.

## 1.10.0 (2019-05-10)

* Added `DataType.registeredType`.
* Added support for `RecordType` inheritance.
* Added support for automatic use of auth tokens.
* Added support for custom REST API operations.

## 1.9.0 (2019-04-15)

* Added a new type `StreamType`.
* Added a new REST API error code `ERROR_CODE_INCORRECT_USERNAME_PASSWORD ("SPONGE004")`.
* Dependencies upgrade.

## 1.8.0 (2019-03-04)

* API change: Action arguments and result metadata are now specified as data types. `ArgMeta` and `ResultMeta` classes have been removed.
* API change: Renamed `ArgProvidedMeta` to `ProvidedMeta`, `ArgProvidedValue` to `ProvidedValue` and `ProvidedMeta.depends` to `ProvidedMeta.dependencies`.
* API change: Removed `AnnotatedType`. Use `DataType.withAnnotated()` instead.
* Added support for categories. Processors may be assigned to registered categories.
* Added new types: `DynamicType`, `TypeType`, `DateTimeType`.
* Added `CategoryMeta.features`.
* Fixed the bug that caused an error when sending an empty body in the REST API request.

## 1.7.0 (2019-02-01)

* API change: Renamed `displayName` to `label`.
* API change: Renamed `ActionArgMeta` to `ArgMeta`, `ActionResultMeta` to `ResultMeta`, `ArgProvided` to `ArgProvidedMeta`, `ArgValue` to `ArgProvidedValue`.
* API change: A provided argument specification in now placed in the `ArgProvidedMeta` class, not directly in the `ArgMeta` as before.
* API change: Removed `LabeledValue` and `ArgProvidedValue.valueSetDisplayNames` because of a new support for an annotated value set.
  
## 1.6.0 (2019-01-11)

* A new REST API operation `actionArgs` that fetches the provided action arguments from the server. There is a possibility to provide action argument values and possible value sets in the action configuration. It makes easier creating a generic UI for an action call that reads and presents the actual state of the entities that are to be changed by the action and its arguments.
* API change: Removed `ActionType` because there is a more versatile feature of providing action argument values and value sets.
* Added a context and listeners to the REST API client.
* Added a new data type `AnnotatedType`.

## 1.5.1 (2018-11-14)

* Removed `dart:io` dependency.
* Allowed non strict types in type converters.

## 1.5.0 (2018-11-14)

* The initial release, compatible with Sponge 1.5.x.