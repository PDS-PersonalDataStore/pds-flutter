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
