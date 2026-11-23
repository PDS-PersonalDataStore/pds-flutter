import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'pds_flutter_platform_interface.dart';

/// Implementation of [PdsFlutterPlatform] using MethodChannel and EventChannel
class MethodChannelPdsFlutter extends PdsFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('top.tau2c.pds/client');

  @visibleForTesting
  final eventChannel = const EventChannel('top.tau2c.pds/events');

  @override
  Future<bool> connect() async {
    final connected = await methodChannel.invokeMethod<bool>('connect');
    return connected ?? false;
  }

  @override
  Future<bool> disconnect() async {
    final disconnected = await methodChannel.invokeMethod<bool>('disconnect');
    return disconnected ?? false;
  }

  @override
  Future<bool> isConnected() async {
    final connected = await methodChannel.invokeMethod<bool>('isConnected');
    return connected ?? false;
  }

  @override
  Future<bool> isReady() async {
    final ready = await methodChannel.invokeMethod<bool>('isReady');
    return ready ?? false;
  }

  @override
  Future<String> executeRawRequest(String requestJson) async {
    final response = await methodChannel.invokeMethod<String>(
      'executeRawRequest',
      {'requestJson': requestJson},
    );
    return response ?? '';
  }

  @override
  Future<String> registerClient(String clientName, Uint8List publicKey) async {
    final clientId = await methodChannel.invokeMethod<String>(
      'register',
      {'clientName': clientName, 'publicKey': publicKey},
    );
    return clientId ?? '';
  }

  @override
  Future<String> getPendingChanges(String sessionId, {int? limit}) async {
    final result = await methodChannel.invokeMethod<String>(
      'getPendingChanges',
      {'sessionId': sessionId, 'limit': ?limit},
    );
    return result ?? '';
  }

  @override
  Future<String> acknowledgeChanges(String sessionId, String changeId) async {
    final result = await methodChannel.invokeMethod<String>(
      'acknowledgeChanges',
      {'sessionId': sessionId, 'changeId': changeId},
    );
    return result ?? '';
  }

  @override
  Future<String> getClientCursor(String sessionId) async {
    final result = await methodChannel.invokeMethod<String>(
      'getClientCursor',
      {'sessionId': sessionId},
    );
    return result ?? '';
  }

  @override
  Future<String> createRelation({
    required String sessionId,
    required String relationType,
    required String sourceEntityId,
    required String targetEntityId,
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'createRelation',
      {
        'sessionId': sessionId,
        'relationType': relationType,
        'sourceEntityId': sourceEntityId,
        'targetEntityId': targetEntityId,
      },
    );
    return result ?? '';
  }

  @override
  Future<String> createMultimemberRelation({
    required String sessionId,
    required String relationType,
    required String membersJson,
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'createMultimemberRelation',
      {
        'sessionId': sessionId,
        'relationType': relationType,
        'membersJson': membersJson,
      },
    );
    return result ?? '';
  }

  @override
  Future<String> putBlob({
    required String sessionId,
    required Uint8List data,
    String? mediaType,
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'putBlob',
      {
        'sessionId': sessionId,
        'data': data,
        'mediaType': ?mediaType,
      },
    );
    return result ?? '';
  }

  @override
  Future<Uint8List> getBlob({
    required String sessionId,
    required String blobId,
  }) async {
    final result = await methodChannel.invokeMethod<Uint8List>(
      'getBlob',
      {
        'sessionId': sessionId,
        'blobId': blobId,
      },
    );
    return result ?? Uint8List(0);
  }

  @override
  Future<String> putEncryptedBlob({
    required String sessionId,
    required Uint8List plaintext,
    required String keyAlias,
    String? mediaType,
  }) async {
    final result = await methodChannel.invokeMethod<String>(
      'putEncryptedBlob',
      {
        'sessionId': sessionId,
        'plaintext': plaintext,
        'keyAlias': keyAlias,
        'mediaType': ?mediaType,
      },
    );
    return result ?? '';
  }

  @override
  Future<Uint8List> getEncryptedBlob({
    required String sessionId,
    required String blobId,
    required String keyAlias,
  }) async {
    final result = await methodChannel.invokeMethod<Uint8List>(
      'getEncryptedBlob',
      {
        'sessionId': sessionId,
        'blobId': blobId,
        'keyAlias': keyAlias,
      },
    );
    return result ?? Uint8List(0);
  }

  @override
  Future<bool> isPdsInstalled() async {
    final installed = await methodChannel.invokeMethod<bool>('isPdsInstalled');
    return installed ?? false;
  }

  @override
  Future<bool> installPdsApk(String apkUriString) async {
    final success = await methodChannel.invokeMethod<bool>(
      'installPdsApk',
      {'apkUriString': apkUriString},
    );
    return success ?? false;
  }

  @override
  Stream<String> watchChanges({String entityType = '*'}) {
    return eventChannel
        .receiveBroadcastStream({'entityType': entityType})
        .map((event) => event.toString());
  }

  @override
  Future<String> listClients() async {
    final result = await methodChannel.invokeMethod<String>('listClients');
    return result ?? '[]';
  }

  @override
  Future<bool> revokeClient(String clientId) async {
    final result = await methodChannel.invokeMethod<bool>(
      'revokeClient',
      {'clientId': clientId},
    );
    return result ?? false;
  }

  @override
  Future<bool> removeClient(String clientId) async {
    final result = await methodChannel.invokeMethod<bool>(
      'removeClient',
      {'clientId': clientId},
    );
    return result ?? false;
  }

  @override
  Future<PdsAuthResult> requestAuthorization({
    required String clientName,
    Uint8List? publicKey,
    List<String>? permissions,
  }) async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
      'requestAuthorization',
      {
        'clientName': clientName,
        'publicKey': publicKey,
        'permissions': permissions,
      },
    );
    if (result == null) {
      return const PdsAuthResult(isAuthorized: false);
    }
    return PdsAuthResult.fromMap(result);
  }
}
