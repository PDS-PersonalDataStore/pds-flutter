import 'dart:convert';
import 'dart:typed_data';
import 'pds_flutter_platform_interface.dart';
export 'pds_flutter_platform_interface.dart' show PdsAuthResult;

/// High-level Flutter client for interacting with the PDS Core service.
class PdsClient {
  final PdsFlutterPlatform _platform;

  PdsClient({PdsFlutterPlatform? platform})
      : _platform = platform ?? PdsFlutterPlatform.instance;

  /// Binds to the background PDS Core service.
  Future<bool> connect() => _platform.connect();

  /// Unbinds from the PDS Core service.
  Future<bool> disconnect() => _platform.disconnect();

  /// Checks if bound to PDS Core.
  Future<bool> isConnected() => _platform.isConnected();

  /// Checks if PDS Core storage engine is initialized and ready.
  Future<bool> isReady() => _platform.isReady();

  /// Executes a raw JSON request against PDS Core.
  Future<String> executeRawRequest(String requestJson) =>
      _platform.executeRawRequest(requestJson);

  /// Registers this client application with its public key.
  /// If [publicKey] is omitted, the client identity key managed by the SDK is used.
  Future<String> registerClient(String clientName, [Uint8List? publicKey]) =>
      _platform.registerClient(clientName, publicKey);

  /// Gets the stored client ID if authorized.
  Future<String?> getClientId() => _platform.getClientId();

  /// Checks if the client identity is registered and authorized.
  Future<bool> isAuthorized() => _platform.isAuthorized();

  /// Clears stored client identity and authorization state.
  Future<void> clearClientIdentity() => _platform.clearClientIdentity();

  /// Sets the native PDS tracing log level.
  Future<bool> setLogLevel(String logLevel) => _platform.setLogLevel(logLevel);

  /// Gets the current native PDS tracing log level.
  Future<String> getLogLevel() => _platform.getLogLevel();

  /// Stores a record of the given entity type in PDS.
  Future<String> put(String entityType, Map<String, dynamic> data) async {
    final req = jsonEncode({
      'action': 'put',
      'entity_type': entityType,
      'data': data,
    });
    return executeRawRequest(req);
  }

  /// Retrieves a record by entity type and record ID.
  Future<String?> get(String entityType, String id) async {
    final req = jsonEncode({
      'action': 'get',
      'entity_type': entityType,
      'id': id,
    });
    final res = await executeRawRequest(req);
    return res.isEmpty ? null : res;
  }

  /// Queries records of the given entity type with an optional filter.
  Future<String> query(String entityType, [Map<String, dynamic>? filter]) async {
    final req = jsonEncode({
      'action': 'query',
      'entity_type': entityType,
      'filter': ?filter,
    });
    return executeRawRequest(req);
  }

  /// Deletes a record by entity type and ID.
  Future<bool> delete(String entityType, String id) async {
    final req = jsonEncode({
      'action': 'delete',
      'entity_type': entityType,
      'id': id,
    });
    final res = await executeRawRequest(req);
    return res.contains('"status":"Success"');
  }

  /// Stores raw binary data in PDS content-addressed storage (CAS).
  Future<String> putBlob(Uint8List data) async {
    final base64Data = base64Encode(data);
    final req = jsonEncode({
      'action': 'put_blob',
      'data_base64': base64Data,
    });
    return executeRawRequest(req);
  }

  /// Retrieves raw binary data by its content hash.
  Future<Uint8List?> getBlob(String hash) async {
    final req = jsonEncode({
      'action': 'get_blob',
      'hash': hash,
    });
    final res = await executeRawRequest(req);
    try {
      final map = jsonDecode(res) as Map<String, dynamic>;
      final b64 = map['data_base64'] as String?;
      if (b64 != null) {
        return base64Decode(b64);
      }
    } catch (_) {}
    return null;
  }

  /// Subscribes to real-time change events.
  Stream<String> watchChanges({String entityType = '*'}) =>
      _platform.watchChanges(entityType: entityType);

  /// Retrieves pending changes for an offline/reconnecting client session.
  Future<String> getPendingChanges(String sessionId, {int? limit}) =>
      _platform.getPendingChanges(sessionId, limit: limit);

  /// Acknowledges processed changes to advance durable client cursor.
  Future<String> acknowledgeChanges(String sessionId, String changeId) =>
      _platform.acknowledgeChanges(sessionId, changeId);

  /// Reads durable client cursor position.
  Future<String> getClientCursor(String sessionId) =>
      _platform.getClientCursor(sessionId);

  /// Creates a binary relation between source and target entities.
  Future<String> createRelation({
    required String sessionId,
    required String relationType,
    required String sourceEntityId,
    required String targetEntityId,
  }) =>
      _platform.createRelation(
        sessionId: sessionId,
        relationType: relationType,
        sourceEntityId: sourceEntityId,
        targetEntityId: targetEntityId,
      );

  /// Creates a multimember relation with custom roles (Engine 1.5).
  Future<String> createMultimemberRelation({
    required String sessionId,
    required String relationType,
    required String membersJson,
  }) =>
      _platform.createMultimemberRelation(
        sessionId: sessionId,
        relationType: relationType,
        membersJson: membersJson,
      );

  /// Stores raw binary data as a content-addressed blob with a session.
  Future<String> putBlobWithSession({
    required String sessionId,
    required Uint8List data,
    String? mediaType,
  }) =>
      _platform.putBlob(
        sessionId: sessionId,
        data: data,
        mediaType: mediaType,
      );

  /// Retrieves raw binary data by blob ID with a session.
  Future<Uint8List> getBlobWithSession({
    required String sessionId,
    required String blobId,
  }) =>
      _platform.getBlob(
        sessionId: sessionId,
        blobId: blobId,
      );

  /// Encrypts data client-side with AES-256-GCM via Android KeyStore
  /// and stores ciphertext in PDS Core (Zero-Knowledge E2EE).
  Future<String> putEncryptedBlob({
    required String sessionId,
    required Uint8List plaintext,
    required String keyAlias,
    String? mediaType,
  }) =>
      _platform.putEncryptedBlob(
        sessionId: sessionId,
        plaintext: plaintext,
        keyAlias: keyAlias,
        mediaType: mediaType,
      );

  /// Retrieves an encrypted blob from PDS Core and decrypts it client-side
  /// using the specified Android KeyStore key alias.
  Future<Uint8List> getEncryptedBlob({
    required String sessionId,
    required String blobId,
    required String keyAlias,
  }) =>
      _platform.getEncryptedBlob(
        sessionId: sessionId,
        blobId: blobId,
        keyAlias: keyAlias,
      );

  /// Checks if PDS Core package is installed on the device.
  Future<bool> isPdsInstalled() => _platform.isPdsInstalled();

  /// Prompts Android system package installer to install PDS Core from APK URI.
  Future<bool> installPdsApk(String apkUriString) =>
      _platform.installPdsApk(apkUriString);

  /// Returns JSON list of all registered client applications.
  Future<String> listClients() => _platform.listClients();

  /// Revokes permissions of a client application.
  Future<bool> revokeClient(String clientId) =>
      _platform.revokeClient(clientId);

  /// Removes a client application record completely.
  Future<bool> removeClient(String clientId) =>
      _platform.removeClient(clientId);

  /// Requests interactive client authorization via PDS Core popup dialog.
  Future<PdsAuthResult> requestAuthorization({
    required String clientName,
    Uint8List? publicKey,
    List<String>? permissions,
  }) =>
      _platform.requestAuthorization(
        clientName: clientName,
        publicKey: publicKey,
        permissions: permissions,
      );
}

/// Alias for PdsClient to maintain compatibility with plugin conventions.
typedef PdsFlutter = PdsClient;
