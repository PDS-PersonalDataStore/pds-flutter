# PDS IPC Protocol Specification (`IpcRequest` / `IpcResponse`)

All IPC messages between client applications and the PDS Core storage engine are encoded in JSON using serde's adjacent tagging representation:
- **Request envelope**: `{"action": "<VariantName>", "payload": { ... }}`
- **Response envelope**: `{"status": "<VariantName>", "payload": { ... }}`

---

## 1. Authentication Handshake & Session Management

Every client application must establish an authenticated session before performing storage operations.

### 1.1 `Hello`
Initiates session negotiation.

**Request:**
```json
{
  "action": "Hello",
  "payload": {
    "client_id": "01HQXYZ123456789ABCDEF0123",
    "api_version": "1.4.0",
    "client_nonce": [0, 1, 2, ..., 31],
    "capabilities": ["entities", "relations", "blobs"],
    "supported_versions": ["1.0.0", "1.1.0", "1.2.0", "1.3.0", "1.4.0"]
  }
}
```

**Response (`Challenge`):**
```json
{
  "status": "Challenge",
  "payload": {
    "server_instance_id": "pds-node-01",
    "client_id": "01HQXYZ123456789ABCDEF0123",
    "client_nonce": [0, 1, 2, ..., 31],
    "server_nonce": [9, 8, 7, ..., 31],
    "api_version": "1.4.0",
    "challenge_expires_at": "2026-11-25T23:45:00Z"
  }
}
```

---

### 1.2 `Authenticate`
Responds to server challenge using Ed25519 signature.

**Signature Payload format:**
`"PDS-CLIENT-AUTH-v1" + server_instance_id + client_id (16 bytes ULID) + client_nonce (32 bytes) + server_nonce (32 bytes) + api_version`

**Request:**
```json
{
  "action": "Authenticate",
  "payload": {
    "client_id": "01HQXYZ123456789ABCDEF0123",
    "signature": [ ... 64 bytes Ed25519 signature ... ]
  }
}
```

**Response (`Authenticated`):**
```json
{
  "status": "Authenticated",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "client_id": "01HQXYZ123456789ABCDEF0123",
    "permissions": ["ReadEntities", "WriteEntities", "ReadBlobs", "WriteBlobs", "ReadHistory"],
    "expires_at": "2026-11-26T23:45:00Z",
    "api_version": "1.4.0"
  }
}
```

---

### 1.3 `CloseSession`
Terminates an active session.

**Request:**
```json
{
  "action": "CloseSession",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB"
  }
}
```

**Response (`SessionClosed`):**
```json
{
  "status": "SessionClosed",
  "payload": null
}
```

---

## 2. Entity Operations

### 2.1 `CreateEntity`
Creates a new entity record.

**Request:**
```json
{
  "action": "CreateEntity",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "entity_type": "receipts",
    "properties": [
      ["store", {"Text": "Lidl"}],
      ["total", {"Decimal": "124.50"}],
      ["timestamp", {"DateTime": "2026-11-25T20:15:00Z"}],
      ["is_scanned", {"Bool": true}],
      ["item_count", {"Integer": 4}]
    ]
  }
}
```

**Response (`EntityCreated`):**
```json
{
  "status": "EntityCreated",
  "payload": "01HQXYZENTITY1234567890ABCD"
}
```

---

### 2.2 `GetEntity`
Retrieves an entity by its ULID identifier.

**Request:**
```json
{
  "action": "GetEntity",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "entity_id": "01HQXYZENTITY1234567890ABCD"
  }
}
```

**Response (`Entity`):**
```json
{
  "status": "Entity",
  "payload": {
    "id": "01HQXYZENTITY1234567890ABCD",
    "entity_type": "receipts",
    "properties": {
      "store": {"Text": "Lidl"},
      "total": {"Decimal": "124.50"}
    },
    "created_at": "2026-11-25T20:15:00Z",
    "updated_at": "2026-11-25T20:15:00Z"
  }
}
```
*(If entity does not exist, `payload` is `null`)*

---

### 2.3 `UpdateEntity`
Mutates entity properties.

**Request:**
```json
{
  "action": "UpdateEntity",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "entity_id": "01HQXYZENTITY1234567890ABCD",
    "set_properties": [
      ["total", {"Decimal": "129.99"}]
    ],
    "remove_properties": ["item_count"]
  }
}
```

**Response (`EntityUpdated`):**
```json
{
  "status": "EntityUpdated",
  "payload": "01HQXYZENTITY1234567890ABCD"
}
```

---

### 2.4 `DeleteEntity`
Deletes an entity record.

**Request:**
```json
{
  "action": "DeleteEntity",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "entity_id": "01HQXYZENTITY1234567890ABCD"
  }
}
```

**Response (`EntityDeleted`):**
```json
{
  "status": "EntityDeleted",
  "payload": "01HQXYZENTITY1234567890ABCD"
}
```

---

## 3. Relation Operations

### 3.1 `CreateRelation`
Supports both binary relations (`source`/`target`) and multimember relations with roles (`members`).

**Request (Binary):**
```json
{
  "action": "CreateRelation",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "relation_type": "item_of",
    "source": "01HQXYZITEM1234567890ABCDEF",
    "target": "01HQXYZRECEIPT1234567890ABCD"
  }
}
```

**Request (Multimember):**
```json
{
  "action": "CreateRelation",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "relation_type": "categorized_under",
    "members": [
      {"entity_id": "01HQXYZRECEIPT1234567890ABCD", "role": "receipt"},
      {"entity_id": "01HQXYZSTORE1234567890ABCDEF", "role": "merchant"},
      {"entity_id": "01HQXYZCAT1234567890ABCDEF12", "role": "category"}
    ]
  }
}
```

**Response (`RelationCreated`):**
```json
{
  "status": "RelationCreated",
  "payload": "01HQXYZREL1234567890ABCDEF0"
}
```

---

### 3.2 `GetRelation` / `DeleteRelation`
- `GetRelation`: `{"action":"GetRelation", "payload": {"session_id":"...", "relation_id":"..."}}` $\to$ `{"status":"Relation", "payload": { ... }}`
- `DeleteRelation`: `{"action":"DeleteRelation", "payload": {"session_id":"...", "relation_id":"..."}}` $\to$ `{"status":"RelationDeleted", "payload": "..."}`

---

## 4. CAS Blob Storage Operations

### 4.1 `PutBlob`
Stores unencrypted binary data in Content-Addressed Storage.

**Request:**
```json
{
  "action": "PutBlob",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "data": [137, 80, 78, 71, ...],
    "media_type": "image/png"
  }
}
```

**Response (`BlobCreated`):**
```json
{
  "status": "BlobCreated",
  "payload": {
    "blob_id": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "size": 1048576,
    "media_type": "image/png",
    "created_at": "2026-11-25T20:20:00Z"
  }
}
```

---

### 4.2 `GetBlob`
Retrieves raw blob data.

**Request:**
```json
{
  "action": "GetBlob",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "blob_id": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }
}
```

**Response (`Blob`):**
```json
{
  "status": "Blob",
  "payload": [137, 80, 78, 71, ...]
}
```

---

## 5. Synchronization & Offline Queue Operations

### 5.1 `GetPendingChanges`
Retrieves offline operations queued for the client cursor.

**Request:**
```json
{
  "action": "GetPendingChanges",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "limit": 100
  }
}
```

**Response (`Changes`):**
```json
{
  "status": "Changes",
  "payload": {
    "changes": [
      {
        "id": "01HQXYZCHANGE1234567890ABCD",
        "operation": { ... },
        "timestamp": "2026-11-25T20:25:00Z"
      }
    ],
    "latest_change_id": "01HQXYZCHANGE1234567890ABCD"
  }
}
```

---

### 5.2 `AcknowledgeChanges`
Advances durable client cursor.

**Request:**
```json
{
  "action": "AcknowledgeChanges",
  "payload": {
    "session_id": "01HQXYZSESSION9876543210AB",
    "change_id": "01HQXYZCHANGE1234567890ABCD"
  }
}
```

**Response (`ChangesAcknowledged`):**
```json
{
  "status": "ChangesAcknowledged",
  "payload": {
    "last_ack_change_id": "01HQXYZCHANGE1234567890ABCD"
  }
}
```

---

## 6. Error Response

When an error occurs, the server responds with:
```json
{
  "status": "Error",
  "payload": "Description of error or failure"
}
```
