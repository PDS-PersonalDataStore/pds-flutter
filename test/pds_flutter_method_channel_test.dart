import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pds_flutter/pds_flutter_method_channel.dart';
import 'package:pds_flutter/src/pds_api.g.dart';

// ignore: non_constant_identifier_names
class FakePdsHostApi implements PdsHostApi {
  @override
  // ignore: non_constant_identifier_names
  BinaryMessenger? get pigeonVar_binaryMessenger => null;

  @override
  // ignore: non_constant_identifier_names
  String get pigeonVar_messageChannelSuffix => '';

  @override
  Future<bool> connect() async => true;

  @override
  Future<bool> disconnect() async => true;

  @override
  Future<bool> isConnected() async => true;

  @override
  Future<bool> isReady() async => true;

  @override
  Future<String> executeRawRequest(String requestJson) async =>
      '{"status":"Success"}';

  @override
  Future<String> registerClient(String clientName, Uint8List? publicKey) async =>
      '01J00000000000000000000000';

  @override
  Future<String?> getClientId() async => '01J00000000000000000000000';

  @override
  Future<bool> isAuthorized() async => true;

  @override
  Future<void> clearClientIdentity() async {}

  @override
  Future<String> authenticate(String apiVersion) async => 'sess_123';

  @override
  Future<String?> getSessionId() async => 'sess_123';

  @override
  Future<bool> closeSession(String? sessionId) async => true;

  @override
  Future<String> putEntity(String entityType, String dataJson, String? sessionId) async =>
      '{"status":"EntityCreated","payload":"ent_123"}';

  @override
  Future<String> getEntity(String entityId, String? sessionId) async =>
      '{"status":"Entity","payload":{"id":"$entityId"}}';

  @override
  Future<String> updateEntity(
    String entityId,
    String? setPropertiesJson,
    String? removePropertiesJson,
    String? sessionId,
  ) async =>
      '{"status":"EntityUpdated","payload":"$entityId"}';

  @override
  Future<String> deleteEntity(String entityId, String? sessionId) async =>
      '{"status":"EntityDeleted","payload":"$entityId"}';

  @override
  Future<bool> setLogLevel(String logLevel) async => true;

  @override
  Future<String> getLogLevel() async => 'debug';

  @override
  Future<String> getPendingChanges(String sessionId, int? limit) async => '[]';

  @override
  Future<String> acknowledgeChanges(
          String sessionId, String changeId) async =>
      '{"status":"Success"}';

  @override
  Future<String> getClientCursor(String sessionId) async => '{"cursor":0}';

  @override
  Future<String> createRelation(
    String sessionId,
    String relationType,
    String sourceEntityId,
    String targetEntityId,
  ) async =>
      '{"status":"Success","relation_id":"rel_123"}';

  @override
  Future<String> createMultimemberRelation(
    String sessionId,
    String relationType,
    String membersJson,
  ) async =>
      '{"status":"Success","relation_id":"rel_456"}';

  @override
  Future<String> putBlob(
    String sessionId,
    Uint8List data,
    String? mediaType,
  ) async =>
      '{"status":"Success","blob_id":"b_123"}';

  @override
  Future<Uint8List> getBlob(String sessionId, String blobId) async =>
      Uint8List.fromList([1, 2, 3]);

  @override
  Future<String> putEncryptedBlob(
    String sessionId,
    Uint8List plaintext,
    String keyAlias,
    String? mediaType,
  ) async =>
      '{"status":"Success","blob_id":"b_enc_123"}';

  @override
  Future<Uint8List> getEncryptedBlob(
    String sessionId,
    String blobId,
    String keyAlias,
  ) async =>
      Uint8List.fromList([4, 5, 6]);

  @override
  Future<bool> isPdsInstalled() async => true;

  @override
  Future<bool> installPdsApk(String apkUriString) async => true;

  @override
  Future<String> listClients() async => '[]';

  @override
  Future<bool> revokeClient(String clientId) async => true;

  @override
  Future<bool> removeClient(String clientId) async => true;

  @override
  Future<PdsAuthResultDto> requestAuthorization(
    String clientName,
    Uint8List? publicKey,
    List<String>? permissions,
  ) async =>
      PdsAuthResultDto(
        isAuthorized: true,
        clientId: '01J00000000000000000000000',
        grantedPermissions: ['ReadEntities', 'WriteEntities'],
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePdsHostApi fakeHostApi;
  late MethodChannelPdsFlutter platform;

  setUp(() {
    fakeHostApi = FakePdsHostApi();
    platform = MethodChannelPdsFlutter(hostApi: fakeHostApi);
  });

  test('connect', () async {
    expect(await platform.connect(), true);
  });

  test('disconnect', () async {
    expect(await platform.disconnect(), true);
  });

  test('isConnected', () async {
    expect(await platform.isConnected(), true);
  });

  test('isReady', () async {
    expect(await platform.isReady(), true);
  });

  test('executeRawRequest', () async {
    final response = await platform.executeRawRequest('{"action":"ping"}');
    expect(response, '{"status":"Success"}');
  });

  test('registerClient', () async {
    final response = await platform.registerClient(
      'Test App',
      Uint8List(32),
    );
    expect(response, '01J00000000000000000000000');
  });

  test('getClientId', () async {
    expect(await platform.getClientId(), '01J00000000000000000000000');
  });

  test('isAuthorized', () async {
    expect(await platform.isAuthorized(), true);
  });

  test('clearClientIdentity', () async {
    await platform.clearClientIdentity();
  });

  test('authenticate and session management', () async {
    expect(await platform.authenticate(), 'sess_123');
    expect(await platform.getSessionId(), 'sess_123');
    expect(await platform.closeSession(), true);
  });

  test('entity operations', () async {
    expect(
      await platform.putEntity('receipts', '{"store":"Lidl"}'),
      '{"status":"EntityCreated","payload":"ent_123"}',
    );
    expect(
      await platform.getEntity('ent_123'),
      '{"status":"Entity","payload":{"id":"ent_123"}}',
    );
    expect(
      await platform.updateEntity('ent_123', setPropertiesJson: '[["store",{"Text":"Biedronka"}]]'),
      '{"status":"EntityUpdated","payload":"ent_123"}',
    );
    expect(
      await platform.deleteEntity('ent_123'),
      '{"status":"EntityDeleted","payload":"ent_123"}',
    );
  });

  test('setLogLevel', () async {
    expect(await platform.setLogLevel('debug'), true);
  });

  test('getLogLevel', () async {
    expect(await platform.getLogLevel(), 'debug');
  });

  test('isPdsInstalled', () async {
    expect(await platform.isPdsInstalled(), true);
  });

  test('installPdsApk', () async {
    expect(await platform.installPdsApk('content://test.apk'), true);
  });

  test('listClients', () async {
    expect(await platform.listClients(), '[]');
  });

  test('revokeClient', () async {
    expect(await platform.revokeClient('test_client_id'), true);
  });

  test('removeClient', () async {
    expect(await platform.removeClient('test_client_id'), true);
  });

  test('requestAuthorization', () async {
    final authResult =
        await platform.requestAuthorization(clientName: 'Test App');
    expect(authResult.isAuthorized, true);
    expect(authResult.clientId, '01J00000000000000000000000');
    expect(authResult.grantedPermissions, ['ReadEntities', 'WriteEntities']);
  });

  test('createRelation', () async {
    final response = await platform.createRelation(
      sessionId: 'sess_1',
      relationType: 'belongs_to',
      sourceEntityId: 'ent_1',
      targetEntityId: 'ent_2',
    );
    expect(response, '{"status":"Success","relation_id":"rel_123"}');
  });

  test('createMultimemberRelation', () async {
    final response = await platform.createMultimemberRelation(
      sessionId: 'sess_1',
      relationType: 'members_of',
      membersJson: '[{"entity_id":"ent_1","role":"admin"}]',
    );
    expect(response, '{"status":"Success","relation_id":"rel_456"}');
  });

  test('putBlob', () async {
    final response = await platform.putBlob(
      sessionId: 'sess_1',
      data: Uint8List.fromList([1, 2, 3]),
      mediaType: 'image/png',
    );
    expect(response, '{"status":"Success","blob_id":"b_123"}');
  });

  test('getBlob', () async {
    final bytes = await platform.getBlob(
      sessionId: 'sess_1',
      blobId: 'b_123',
    );
    expect(bytes, Uint8List.fromList([1, 2, 3]));
  });

  test('putEncryptedBlob', () async {
    final response = await platform.putEncryptedBlob(
      sessionId: 'sess_1',
      plaintext: Uint8List.fromList([4, 5, 6]),
      keyAlias: 'key_master',
    );
    expect(response, '{"status":"Success","blob_id":"b_enc_123"}');
  });

  test('getEncryptedBlob', () async {
    final bytes = await platform.getEncryptedBlob(
      sessionId: 'sess_1',
      blobId: 'b_enc_123',
      keyAlias: 'key_master',
    );
    expect(bytes, Uint8List.fromList([4, 5, 6]));
  });
}
