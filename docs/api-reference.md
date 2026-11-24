# API Reference

Detailed reference for `PdsClient` methods in `pds_flutter`.

## Initialization & Lifecycle

### `connect(): Future<bool>`
Binds the client application to the background `PDS Core` Binder service. Returns `true` on successful binding.

### `disconnect(): Future<bool>`
Unbinds from the PDS Core service and unregisters active subscription listeners.

### `isConnected(): Future<bool>`
Checks whether the client is currently bound to the PDS Core service.

### `isReady(): Future<bool>`
Checks if the PDS Core storage engine is initialized and ready to accept requests.

### `isPdsInstalled(): Future<bool>`
Checks whether the `top.tau2c.pds.core` package is installed on the Android device.

### `installPdsApk(String apkUriString): Future<bool>`
Launches Android package installer for the specified APK file URI.

---

## Authorization & Client Management

### `requestAuthorization({required String clientName, Uint8List? publicKey, List<String>? permissions}): Future<PdsAuthResult>`
Launches the system authorization popup dialog. The user chooses whether to grant permissions. Returns `PdsAuthResult` with `isAuthorized`, `clientId`, and `grantedPermissions`.

### `listClients(): Future<String>`
Returns a JSON array of all registered client applications in PDS Core.

### `revokeClient(String clientId): Future<bool>`
Revokes permissions granted to a specific client application.

### `removeClient(String clientId): Future<bool>`
Completely deletes a client registration record from PDS Core.

---

## Entity Operations

### `put(String entityType, Map<String, dynamic> data): Future<String>`
Inserts or updates an entity record. Returns the generated record ID or JSON response.

### `get(String entityType, String id): Future<String?>`
Retrieves a record by its entity type and ID. Returns `null` if not found.

### `query(String entityType, [Map<String, dynamic>? filter]): Future<String>`
Queries records matching an optional filter map. Returns a JSON string containing matched records.

### `delete(String entityType, String id): Future<bool>`
Deletes a record by its entity type and ID. Returns `true` if deleted successfully.

---

## Content-Addressed Storage (CAS)

### `putBlob(Uint8List data): Future<String>`
Stores binary data directly into content-addressed storage.

### `getBlob(String hash): Future<Uint8List?>`
Retrieves binary data matching the SHA content hash.

### `putBlobWithSession({required String sessionId, required Uint8List data, String? mediaType}): Future<String>`
Stores a binary blob associated with an active sync session.

### `getBlobWithSession({required String sessionId, required String blobId}): Future<Uint8List>`
Retrieves a binary blob using an active session ID and blob identifier.

---

## Zero-Knowledge Encryption (E2EE)

### `putEncryptedBlob({required String sessionId, required Uint8List plaintext, required String keyAlias, String? mediaType}): Future<String>`
Encrypts data client-side with AES-256-GCM using hardware-backed Android KeyStore before sending to PDS Core.

### `getEncryptedBlob({required String sessionId, required String blobId, required String keyAlias}): Future<Uint8List>`
Retrieves encrypted ciphertext from PDS Core and decrypts it on the client device using the specified KeyStore alias.

---

## Relations (PDS Engine 1.5)

### `createRelation({required String sessionId, required String relationType, required String sourceEntityId, required String targetEntityId}): Future<String>`
Creates a binary relationship between a source entity and target entity.

### `createMultimemberRelation({required String sessionId, required String relationType, required String membersJson}): Future<String>`
Creates a multimember relationship with customized roles across multiple entities.

---

## Real-Time Changes & Synchronization

### `watchChanges({String entityType = '*'}): Stream<String>`
Subscribes to live database change notifications via Android Binder callback.

### `getPendingChanges(String sessionId, {int? limit}): Future<String>`
Retrieves unacknowledged changes for offline or reconnecting clients.

### `acknowledgeChanges(String sessionId, String changeId): Future<String>`
Advances the client's durable sync cursor past the specified change ID.

### `getClientCursor(String sessionId): Future<String>`
Reads the current position of the client's durable sync cursor.
