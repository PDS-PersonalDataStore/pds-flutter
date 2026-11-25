# pds_flutter

Flutter plugin for personal data store (PDS) Android IPC via Binder and AIDL (`IPdsService.aidl`).

## Features

- **IPC Service Binding**: Binds to background `top.tau2c.pds.core` system service.
- **Entity Storage**: CRUD operations (`put`, `get`, `query`, `delete`) using JSON protocols.
- **Content-Addressed Storage (CAS)**: Binary blob storage and retrieval (`putBlob`, `getBlob`).
- **Encrypted Blobs (E2EE)**: Zero-knowledge client-side AES-256-GCM encryption with AndroidKeyStore (`putEncryptedBlob`, `getEncryptedBlob`).
- **Reactive Changes**: Stream real-time database mutations via Binder callbacks (`watchChanges`).
- **Durable Sessions**: Offline sync cursors (`getPendingChanges`, `acknowledgeChanges`).
- **Entity Relations**: Binary and multimember relations (`createRelation`, `createMultimemberRelation`).
- **Client Authorization Dialog**: Request interactive user authorization via PDS dialog (`requestAuthorization`).
- **Client Identity Persistence**: Automatic Ed25519 identity key generation and local authorization persistence (`getClientId`, `isAuthorized`, `clearClientIdentity`).
- **Client Management**: List and revoke authorized clients (`listClients`, `revokeClient`, `removeClient`).
- **Native Tracing Controls**: Set and inspect native runtime log levels (`setLogLevel`, `getLogLevel`).
- **PDS Lifecycle Helper**: Detect installation status and invoke package installer (`isPdsInstalled`, `installPdsApk`).

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  pds_flutter:
    git:
      url: https://github.com/Tau2C/pds-flutter.git
      ref: master
```

## Android Configuration

Add service query permissions to your app's `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <queries>
        <package android:name="top.tau2c.pds.core" />
    </queries>
</manifest>
```

## Usage Example

```dart
import 'package:pds_flutter/pds_flutter.dart';

Future<void> main() async {
  final client = PdsClient();

  // 1. Check if PDS Core service APK is installed
  final isInstalled = await client.isPdsInstalled();
  if (!isInstalled) {
    print('PDS Core app is not installed');
    return;
  }

  // 2. Connect to the background Android Binder service
  final connected = await client.connect();
  if (!connected) {
    print('Failed to bind to PDS Core service');
    return;
  }

  // 3. Request user authorization interactively
  final authResult = await client.requestAuthorization(
    clientName: 'My Flutter App',
    permissions: const ['read', 'write'],
  );
  if (!authResult.isAuthorized) {
    print('User denied authorization');
    return;
  }
  print('Authorized with client ID: ${authResult.clientId}');

  // 4. Store a receipt record
  final response = await client.put('receipts', {
    'id': '01JG...',
    'store': 'Lidl',
    'total': 45.99,
    'currency': 'PLN',
  });
  print('Saved record: $response');

  // 5. Watch real-time changes
  client.watchChanges(entityType: 'receipts').listen((eventJson) {
    print('Received change event: $eventJson');
  });

  // 6. Query records
  final queryResult = await client.query('receipts');
  print('Receipts query: $queryResult');

  // 7. Disconnect
  await client.disconnect();
}
```

## Documentation

- [Architecture Guide](docs/architecture.md): Multi-layer IPC architecture, Pigeon typed host API, and Binder service integration.
- [Error Handling Guide](docs/error-handling.md): Common exceptions, error codes, and recovery strategies.
- [API Reference](docs/api-reference.md): Detailed reference of all methods and parameters.

## Architecture

The plugin implements the following communication flow:

1. **Dart API**: High-level async interface (`PdsClient`).
2. **Pigeon Typed Host API**: Auto-generated type-safe IPC layer (`PdsHostApi`).
3. **Android Plugin Layer (`PdsFlutterPlugin.kt`)**: Activity-aware foreground launcher and stream handler.
4. **Android Client (`PdsAndroidClient.kt`)**: Binds to `top.tau2c.pds.core.PdsService` intent with `PdsCryptoManager` E2EE.
5. **AIDL Interface**: IPC calls via generated `IPdsService` Binder interface and `IPdsChangeListener`.

See [docs/architecture.md](docs/architecture.md) for full architectural diagrams and details.

## License

See [LICENSE](LICENSE).
