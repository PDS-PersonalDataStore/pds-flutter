import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pds_api.g.dart',
  dartOptions: DartOptions(),
  dartPackageName: 'pds_flutter',
  kotlinOut:
      'android/src/main/kotlin/top/tau2c/pds/flutter/pds_flutter/PdsApi.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'top.tau2c.pds.flutter.pds_flutter',
  ),
))
class PdsAuthResultDto {
  final bool isAuthorized;
  final String? clientId;
  final List<String> grantedPermissions;

  const PdsAuthResultDto({
    required this.isAuthorized,
    this.clientId,
    this.grantedPermissions = const [],
  });
}

@HostApi()
abstract class PdsHostApi {
  @async
  bool connect();

  bool disconnect();

  bool isConnected();

  bool isReady();

  @async
  String executeRawRequest(String requestJson);

  @async
  String registerClient(String clientName, Uint8List? publicKey);

  String? getClientId();

  bool isAuthorized();

  void clearClientIdentity();

  @async
  String authenticate(String apiVersion);

  String? getSessionId();

  @async
  bool closeSession(String? sessionId);

  @async
  String putEntity(String entityType, String dataJson, String? sessionId);

  @async
  String getEntity(String entityId, String? sessionId);

  @async
  String updateEntity(
    String entityId,
    String? setPropertiesJson,
    String? removePropertiesJson,
    String? sessionId,
  );

  @async
  String deleteEntity(String entityId, String? sessionId);

  @async
  String getPendingChanges(String sessionId, int? limit);

  @async
  String acknowledgeChanges(String sessionId, String changeId);

  @async
  String getClientCursor(String sessionId);

  @async
  String createRelation(
    String sessionId,
    String relationType,
    String sourceEntityId,
    String targetEntityId,
  );

  @async
  String createMultimemberRelation(
    String sessionId,
    String relationType,
    String membersJson,
  );

  @async
  String putBlob(String sessionId, Uint8List data, String? mediaType);

  @async
  Uint8List getBlob(String sessionId, String blobId);

  @async
  String putEncryptedBlob(
    String sessionId,
    Uint8List plaintext,
    String keyAlias,
    String? mediaType,
  );

  @async
  Uint8List getEncryptedBlob(
    String sessionId,
    String blobId,
    String keyAlias,
  );

  bool isPdsInstalled();

  bool installPdsApk(String apkUriString);

  String listClients();

  bool revokeClient(String clientId);

  bool removeClient(String clientId);

  @async
  bool setLogLevel(String logLevel);

  @async
  String getLogLevel();

  @async
  PdsAuthResultDto requestAuthorization(
    String clientName,
    Uint8List? publicKey,
    List<String>? permissions,
  );
}
