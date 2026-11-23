import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pds_flutter/pds_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelPdsFlutter();
  const channel = MethodChannel('top.tau2c.pds/client');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'connect':
          return true;
        case 'disconnect':
          return true;
        case 'isConnected':
          return true;
        case 'isReady':
          return true;
        case 'executeRawRequest':
          return '{"status":"Success"}';
        case 'isPdsInstalled':
          return true;
        case 'installPdsApk':
          return true;
        case 'listClients':
          return '[]';
        case 'revokeClient':
          return true;
        case 'removeClient':
          return true;
        case 'requestAuthorization':
          return {
            'status': 'authorized',
            'clientId': '01J00000000000000000000000',
            'grantedPermissions': ['ReadEntities', 'WriteEntities'],
          };
        case 'createRelation':
          return '{"status":"Success","relation_id":"rel_123"}';
        case 'createMultimemberRelation':
          return '{"status":"Success","relation_id":"rel_456"}';
        case 'putBlob':
          return '{"status":"Success","blob_id":"b_123"}';
        case 'getBlob':
          return Uint8List.fromList([1, 2, 3]);
        case 'putEncryptedBlob':
          return '{"status":"Success","blob_id":"b_enc_123"}';
        case 'getEncryptedBlob':
          return Uint8List.fromList([4, 5, 6]);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('connect', () async {
    expect(await platform.connect(), true);
  });

  test('isConnected', () async {
    expect(await platform.isConnected(), true);
  });

  test('executeRawRequest', () async {
    final response = await platform.executeRawRequest('{"action":"ping"}');
    expect(response, '{"status":"Success"}');
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
    final authResult = await platform.requestAuthorization(clientName: 'Test App');
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
