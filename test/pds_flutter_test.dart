import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pds_flutter/pds_flutter.dart';
import 'package:pds_flutter/pds_flutter_platform_interface.dart';
import 'package:pds_flutter/pds_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPdsFlutterPlatform
    with MockPlatformInterfaceMixin
    implements PdsFlutterPlatform {
  @override
  Future<bool> connect() => Future.value(true);

  @override
  Future<bool> disconnect() => Future.value(true);

  @override
  Future<bool> isConnected() => Future.value(true);

  @override
  Future<bool> isReady() => Future.value(true);

  @override
  Future<String> executeRawRequest(String requestJson) =>
      Future.value('{"status":"Success"}');

  @override
  Future<String> registerClient(String clientName, [Uint8List? publicKey]) =>
      Future.value('01J00000000000000000000000');

  @override
  Future<String?> getClientId() => Future.value('01J00000000000000000000000');

  @override
  Future<bool> isAuthorized() => Future.value(true);

  @override
  Future<void> clearClientIdentity() => Future.value();

  @override
  Future<String> authenticate([String apiVersion = '1.4.0']) =>
      Future.value('sess_123');

  @override
  Future<String?> getSessionId() => Future.value('sess_123');

  @override
  Future<bool> closeSession([String? sessionId]) => Future.value(true);

  @override
  Future<String> putEntity(String entityType, String dataJson, [String? sessionId]) =>
      Future.value('{"status":"EntityCreated","payload":"ent_123"}');

  @override
  Future<String> getEntity(String entityId, [String? sessionId]) =>
      Future.value('{"status":"Entity","payload":{"id":"$entityId"}}');

  @override
  Future<String> updateEntity(
    String entityId, {
    String? setPropertiesJson,
    String? removePropertiesJson,
    String? sessionId,
  }) =>
      Future.value('{"status":"EntityUpdated","payload":"$entityId"}');

  @override
  Future<String> deleteEntity(String entityId, [String? sessionId]) =>
      Future.value('{"status":"EntityDeleted","payload":"$entityId"}');

  @override
  Future<bool> setLogLevel(String logLevel) => Future.value(true);

  @override
  Future<String> getLogLevel() => Future.value('debug');

  @override
  Future<String> getPendingChanges(String sessionId, {int? limit}) =>
      Future.value('[]');

  @override
  Future<String> acknowledgeChanges(String sessionId, String changeId) =>
      Future.value('{"status":"Success"}');

  @override
  Future<String> getClientCursor(String sessionId) =>
      Future.value('{"cursor":0}');

  @override
  Future<bool> isPdsInstalled() => Future.value(true);

  @override
  Future<bool> installPdsApk(String apkUriString) => Future.value(true);

  @override
  Stream<String> watchChanges({String entityType = '*'}) =>
      Stream.value('[{"action":"put"}]');

  @override
  Future<String> listClients() => Future.value('[]');

  @override
  Future<bool> revokeClient(String clientId) => Future.value(true);

  @override
  Future<bool> removeClient(String clientId) => Future.value(true);

  @override
  Future<String> createRelation({
    required String sessionId,
    required String relationType,
    required String sourceEntityId,
    required String targetEntityId,
  }) =>
      Future.value('{"status":"Success"}');

  @override
  Future<String> createMultimemberRelation({
    required String sessionId,
    required String relationType,
    required String membersJson,
  }) =>
      Future.value('{"status":"Success"}');

  @override
  Future<String> putBlob({
    required String sessionId,
    required Uint8List data,
    String? mediaType,
  }) =>
      Future.value('{"status":"Success","blob_id":"b_123"}');

  @override
  Future<Uint8List> getBlob({
    required String sessionId,
    required String blobId,
  }) =>
      Future.value(Uint8List.fromList([1, 2, 3]));

  @override
  Future<String> putEncryptedBlob({
    required String sessionId,
    required Uint8List plaintext,
    required String keyAlias,
    String? mediaType,
  }) =>
      Future.value('{"status":"Success","blob_id":"b_enc_123"}');

  @override
  Future<Uint8List> getEncryptedBlob({
    required String sessionId,
    required String blobId,
    required String keyAlias,
  }) =>
      Future.value(Uint8List.fromList([4, 5, 6]));

  @override
  Future<PdsAuthResult> requestAuthorization({
    required String clientName,
    Uint8List? publicKey,
    List<String>? permissions,
  }) =>
      Future.value(
        const PdsAuthResult(
          isAuthorized: true,
          clientId: '01J00000000000000000000000',
          grantedPermissions: ['ReadEntities', 'WriteEntities'],
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final PdsFlutterPlatform initialPlatform = PdsFlutterPlatform.instance;

  test('$MethodChannelPdsFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPdsFlutter>());
  });

  test('connect calls platform connect', () async {
    final fakePlatform = MockPdsFlutterPlatform();
    PdsFlutterPlatform.instance = fakePlatform;
    final client = PdsClient(platform: fakePlatform);

    expect(await client.connect(), true);
    expect(await client.isConnected(), true);
    expect(await client.isReady(), true);
    expect(await client.getClientId(), '01J00000000000000000000000');
    expect(await client.isAuthorized(), true);
    await client.clearClientIdentity();
    expect(await client.setLogLevel('trace'), true);
    expect(await client.getLogLevel(), 'debug');
    expect(await client.registerClient('Test App'), '01J00000000000000000000000');
    expect(await client.authenticate(), 'sess_123');
    expect(await client.getSessionId(), 'sess_123');
    expect(await client.put('receipts', {'store': 'Lidl'}), '{"status":"EntityCreated","payload":"ent_123"}');
    expect(await client.get('receipts', 'ent_123'), '{"status":"Entity","payload":{"id":"ent_123"}}');
    expect(await client.delete('receipts', 'ent_123'), true);
    expect(await client.closeSession(), true);
    expect(
      await client.createRelation(
        sessionId: 'session_1',
        relationType: 'item_of',
        sourceEntityId: 'item_1',
        targetEntityId: 'receipt_1',
      ),
      '{"status":"Success"}',
    );
    expect(
      await client.createMultimemberRelation(
        sessionId: 'session_1',
        relationType: 'participant',
        membersJson: '[{"entity_id":"user_1","role":"owner"}]',
      ),
      '{"status":"Success"}',
    );
    expect(
      await client.putBlobWithSession(
        sessionId: 'session_1',
        data: Uint8List.fromList([1, 2, 3]),
      ),
      '{"status":"Success","blob_id":"b_123"}',
    );
    expect(
      await client.getBlobWithSession(
        sessionId: 'session_1',
        blobId: 'b_123',
      ),
      Uint8List.fromList([1, 2, 3]),
    );
    expect(
      await client.putEncryptedBlob(
        sessionId: 'session_1',
        plaintext: Uint8List.fromList([4, 5, 6]),
        keyAlias: 'key_1',
      ),
      '{"status":"Success","blob_id":"b_enc_123"}',
    );
    expect(
      await client.getEncryptedBlob(
        sessionId: 'session_1',
        blobId: 'b_enc_123',
        keyAlias: 'key_1',
      ),
      Uint8List.fromList([4, 5, 6]),
    );
  });
}
