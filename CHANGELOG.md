## 0.9.0-dev.2

* Fix AGP library bundling by extracting `classes.jar` from `client-sdk-release.aar` into `client-sdk.jar`.

## 0.9.0-dev.1

* Consume official `client-sdk-release.aar` v0.9.0-dev.1 from `PDS-PersonalDataStore/pds-android`.
* Remove internal duplicates of `PdsAndroidClient`, `PdsCryptoManager`, and AIDL definitions.
* Add session authentication and lifecycle methods (`authenticate`, `getSessionId`, `closeSession`).
* Add entity operations (`putEntity`, `getEntity`, `updateEntity`, `deleteEntity`).
* Update high-level `put`, `get`, and `delete` in `PdsClient` to use entity operations.
* Reset release versioning starting from `0.9.0-dev.1`.

## 1.11.0

* Synchronize capabilities with `pds-android` v1.11.0.
* Add native tracing log level controls (`setLogLevel`, `getLogLevel`).
* Add persistent client identity key derivation and storage via `PdsCryptoManager`.
* Add client identity management methods (`getClientId`, `isAuthorized`, `clearClientIdentity`).
* Make `publicKey` optional in `registerClient`, defaulting to the SDK identity key.
* Add Pigeon-generated typed host API with automated drift verification in CI.
* Add comprehensive architecture, error handling, and API reference documentation.

## 1.9.0

* Add zero-knowledge client-side encrypted blobs (`putEncryptedBlob`, `getEncryptedBlob`).
* Add entity relations support (`createRelation`, `createMultimemberRelation`).
* Add client authorization popup dialog (`requestAuthorization`).
* Add client management methods (`listClients`, `revokeClient`, `removeClient`).

## 0.0.1

* Initial release.
