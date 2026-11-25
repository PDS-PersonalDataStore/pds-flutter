import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'pds_flutter_platform_interface.dart';
import 'src/pds_api.g.dart';

/// Implementation of [PdsFlutterPlatform] using Pigeon-generated [PdsHostApi]
/// and [EventChannel] for streaming change notifications.
class MethodChannelPdsFlutter extends PdsFlutterPlatform {
  @visibleForTesting
  final PdsHostApi hostApi;

  @visibleForTesting
  final EventChannel eventChannel;

  MethodChannelPdsFlutter({
    PdsHostApi? hostApi,
    EventChannel? eventChannel,
  })  : hostApi = hostApi ?? PdsHostApi(),
        eventChannel = eventChannel ?? const EventChannel('top.tau2c/pds/events');

  @override
  Future<bool> connect() => hostApi.connect();

  @override
  Future<bool> disconnect() => hostApi.disconnect();

  @override
  Future<bool> isConnected() => hostApi.isConnected();

  @override
  Future<bool> isReady() => hostApi.isReady();

  @override
  Future<String> executeRawRequest(String requestJson) =>
      hostApi.executeRawRequest(requestJson);

  @override
  Future<String> registerClient(String clientName, [Uint8List? publicKey]) =>
      hostApi.registerClient(clientName, publicKey);

  @override
  Future<String?> getClientId() => hostApi.getClientId();

  @override
  Future<bool> isAuthorized() => hostApi.isAuthorized();

  @override
  Future<void> clearClientIdentity() => hostApi.clearClientIdentity();

  @override
  Future<bool> setLogLevel(String logLevel) => hostApi.setLogLevel(logLevel);

  @override
  Future<String> getLogLevel() => hostApi.getLogLevel();

  @override
  Future<String> getPendingChanges(String sessionId, {int? limit}) =>
      hostApi.getPendingChanges(sessionId, limit);

  @override
  Future<String> acknowledgeChanges(String sessionId, String changeId) =>
      hostApi.acknowledgeChanges(sessionId, changeId);

  @override
  Future<String> getClientCursor(String sessionId) =>
      hostApi.getClientCursor(sessionId);

  @override
  Future<String> createRelation({
    required String sessionId,
    required String relationType,
    required String sourceEntityId,
    required String targetEntityId,
  }) =>
      hostApi.createRelation(
        sessionId,
        relationType,
        sourceEntityId,
        targetEntityId,
      );

  @override
  Future<String> createMultimemberRelation({
    required String sessionId,
    required String relationType,
    required String membersJson,
  }) =>
      hostApi.createMultimemberRelation(
        sessionId,
        relationType,
        membersJson,
      );

  @override
  Future<String> putBlob({
    required String sessionId,
    required Uint8List data,
    String? mediaType,
  }) =>
      hostApi.putBlob(sessionId, data, mediaType);

  @override
  Future<Uint8List> getBlob({
    required String sessionId,
    required String blobId,
  }) =>
      hostApi.getBlob(sessionId, blobId);

  @override
  Future<String> putEncryptedBlob({
    required String sessionId,
    required Uint8List plaintext,
    required String keyAlias,
    String? mediaType,
  }) =>
      hostApi.putEncryptedBlob(sessionId, plaintext, keyAlias, mediaType);

  @override
  Future<Uint8List> getEncryptedBlob({
    required String sessionId,
    required String blobId,
    required String keyAlias,
  }) =>
      hostApi.getEncryptedBlob(sessionId, blobId, keyAlias);

  @override
  Future<bool> isPdsInstalled() => hostApi.isPdsInstalled();

  @override
  Future<bool> installPdsApk(String apkUriString) =>
      hostApi.installPdsApk(apkUriString);

  @override
  Stream<String> watchChanges({String entityType = '*'}) {
    return eventChannel
        .receiveBroadcastStream({'entityType': entityType})
        .map((event) => event.toString());
  }

  @override
  Future<String> listClients() => hostApi.listClients();

  @override
  Future<bool> revokeClient(String clientId) => hostApi.revokeClient(clientId);

  @override
  Future<bool> removeClient(String clientId) => hostApi.removeClient(clientId);

  @override
  Future<PdsAuthResult> requestAuthorization({
    required String clientName,
    Uint8List? publicKey,
    List<String>? permissions,
  }) async {
    final dto = await hostApi.requestAuthorization(
      clientName,
      publicKey,
      permissions,
    );
    return PdsAuthResult(
      isAuthorized: dto.isAuthorized,
      clientId: dto.clientId,
      grantedPermissions: dto.grantedPermissions.cast<String>(),
    );
  }
}
