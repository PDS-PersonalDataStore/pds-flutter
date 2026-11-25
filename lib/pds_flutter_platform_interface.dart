import 'dart:typed_data';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'pds_flutter_method_channel.dart';

abstract class PdsFlutterPlatform extends PlatformInterface {
  PdsFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static PdsFlutterPlatform _instance = MethodChannelPdsFlutter();

  static PdsFlutterPlatform get instance => _instance;

  static set instance(PdsFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> connect() {
    throw UnimplementedError('connect() has not been implemented.');
  }

  Future<bool> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  Future<bool> isConnected() {
    throw UnimplementedError('isConnected() has not been implemented.');
  }

  Future<bool> isReady() {
    throw UnimplementedError('isReady() has not been implemented.');
  }

  Future<String> executeRawRequest(String requestJson) {
    throw UnimplementedError('executeRawRequest() has not been implemented.');
  }

  Future<String> registerClient(String clientName, [Uint8List? publicKey]) {
    throw UnimplementedError('registerClient() has not been implemented.');
  }

  Future<String?> getClientId() {
    throw UnimplementedError('getClientId() has not been implemented.');
  }

  Future<bool> isAuthorized() {
    throw UnimplementedError('isAuthorized() has not been implemented.');
  }

  Future<void> clearClientIdentity() {
    throw UnimplementedError('clearClientIdentity() has not been implemented.');
  }

  Future<bool> setLogLevel(String logLevel) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }

  Future<String> getLogLevel() {
    throw UnimplementedError('getLogLevel() has not been implemented.');
  }

  Future<String> getPendingChanges(String sessionId, {int? limit}) {
    throw UnimplementedError('getPendingChanges() has not been implemented.');
  }

  Future<String> acknowledgeChanges(String sessionId, String changeId) {
    throw UnimplementedError('acknowledgeChanges() has not been implemented.');
  }

  Future<String> getClientCursor(String sessionId) {
    throw UnimplementedError('getClientCursor() has not been implemented.');
  }

  Future<String> createRelation({
    required String sessionId,
    required String relationType,
    required String sourceEntityId,
    required String targetEntityId,
  }) {
    throw UnimplementedError('createRelation() has not been implemented.');
  }

  Future<String> createMultimemberRelation({
    required String sessionId,
    required String relationType,
    required String membersJson,
  }) {
    throw UnimplementedError('createMultimemberRelation() has not been implemented.');
  }

  Future<String> putBlob({
    required String sessionId,
    required Uint8List data,
    String? mediaType,
  }) {
    throw UnimplementedError('putBlob() has not been implemented.');
  }

  Future<Uint8List> getBlob({
    required String sessionId,
    required String blobId,
  }) {
    throw UnimplementedError('getBlob() has not been implemented.');
  }

  Future<String> putEncryptedBlob({
    required String sessionId,
    required Uint8List plaintext,
    required String keyAlias,
    String? mediaType,
  }) {
    throw UnimplementedError('putEncryptedBlob() has not been implemented.');
  }

  Future<Uint8List> getEncryptedBlob({
    required String sessionId,
    required String blobId,
    required String keyAlias,
  }) {
    throw UnimplementedError('getEncryptedBlob() has not been implemented.');
  }

  Future<bool> isPdsInstalled() {
    throw UnimplementedError('isPdsInstalled() has not been implemented.');
  }

  Future<bool> installPdsApk(String apkUriString) {
    throw UnimplementedError('installPdsApk() has not been implemented.');
  }

  Stream<String> watchChanges({String entityType = '*'}) {
    throw UnimplementedError('watchChanges() has not been implemented.');
  }

  Future<String> listClients() {
    throw UnimplementedError('listClients() has not been implemented.');
  }

  Future<bool> revokeClient(String clientId) {
    throw UnimplementedError('revokeClient() has not been implemented.');
  }

  Future<bool> removeClient(String clientId) {
    throw UnimplementedError('removeClient() has not been implemented.');
  }

  Future<PdsAuthResult> requestAuthorization({
    required String clientName,
    Uint8List? publicKey,
    List<String>? permissions,
  }) {
    throw UnimplementedError('requestAuthorization() has not been implemented.');
  }
}

/// Result returned from interactive PDS authorization popup dialog.
class PdsAuthResult {
  final bool isAuthorized;
  final String? clientId;
  final List<String> grantedPermissions;

  const PdsAuthResult({
    required this.isAuthorized,
    this.clientId,
    this.grantedPermissions = const [],
  });

  factory PdsAuthResult.fromMap(Map<dynamic, dynamic> map) {
    final status = map['status'] as String?;
    final clientId = map['clientId'] as String?;
    final granted = (map['grantedPermissions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return PdsAuthResult(
      isAuthorized: status == 'authorized',
      clientId: clientId,
      grantedPermissions: granted,
    );
  }
}
