## 1.6.0 (not released yet)

* A new REST API operation `actionArgs` that fetches the provided action arguments from the server. There is a possibility to provide action argument values and possible value sets in the action configuration. It makes easier creating a generic UI for an action call that reads and presents the actual state of the entities that are to be changed by the action and its arguments.
* API change: Removed `ActionType` because there is a more versatile feature of providing action argument values and value sets.
* Added a context and listeners to the REST API client.
* Added a new data type `AnnotatedType`.

## 1.5.1 (2018-11-14)

* Removed `dart:io` dependency.
* Allowed non strict types in type converters.

## 1.5.0 (2018-11-14)

* The initial release, compatible with Sponge 1.5.x.