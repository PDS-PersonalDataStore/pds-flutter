# pds_flutter

Flutter plugin for personal data store (PDS) Android IPC via Binder and AIDL (`IPdsService.aidl`).

## Features

- **IPC Service Binding**: Binds to background `top.tau2c.pds.core` system service.
- **Entity Storage**: CRUD operations (`put`, `get`, `query`, `delete`) using JSON protocols.
- **Content-Addressed Storage (CAS)**: Binary blob storage and retrieval (`putBlob`, `getBlob`).
- **Reactive Changes**: Stream real-time database mutations via Binder callbacks (`watchChanges`).
- **Durable Sessions**: Offline sync cursors (`getPendingChanges`, `acknowledgeChanges`).
- **Client Authorization Dialog**: Request interactive user authorization via PDS dialog (`requestAuthorization`).
- **Client Management**: List and revoke authorized clients (`listClients`, `revokeClient`, `removeClient`).
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

## Architecture

The plugin implements the following communication flow:

1. **Dart API**: High-level async interface (`PdsClient`).
2. **Platform Channel**: MethodChannel communication to Android platform layer.
3. **Android Client (`PdsAndroidClient.kt`)**: Binds to `top.tau2c.pds.core.PdsService` intent.
4. **AIDL Interface**: IPC calls via generated `IPdsService` Binder interface and `IPdsChangeListener`.

## License

See [LICENSE](LICENSE).
