# Error Handling Guide

This guide covers error handling strategies, error codes, and failure recovery when interacting with PDS Core via `pds_flutter`.

## Overview

Calls to `PdsClient` communicate with external Android Binder services. Errors can originate from:
1. Flutter platform channel communication (`PlatformException`).
2. Service binding states (PDS Core uninstalled or not bound).
3. Foreground activity requirements (authorization dialogs).
4. PDS Core protocol errors (validation failures or permission denials).

---

## Common Exceptions and Error Codes

### 1. Connection Errors

#### `IllegalStateException: PDS Client is not initialized`
- **Cause**: Method invoked before the Android plugin finishes engine attachment.
- **Resolution**: Ensure Flutter bindings are initialized before calling `PdsClient`.

#### Service Not Connected (`connect()` returns `false`)
- **Cause**: The PDS Core package `top.tau2c.pds.core` is not installed, or package visibility permissions are missing.
- **Resolution**:
  1. Verify `<queries>` tag is present in `AndroidManifest.xml`:
     ```xml
     <manifest xmlns:android="http://schemas.android.com/apk/res/android">
         <queries>
             <package android:name="top.tau2c.pds.core" />
         </queries>
     </manifest>
     ```
  2. Check package installation using `client.isPdsInstalled()`. If missing, install PDS Core via `client.installPdsApk(path)`.

---

### 2. Authorization Errors

#### `NO_ACTIVITY`
- **Cause**: `requestAuthorization` was invoked from a background service or before a Flutter `Activity` was attached to the engine.
- **Resolution**: Call `requestAuthorization` only from foreground UI contexts (e.g., inside a Flutter Widget lifecycle method).

#### `ALREADY_REQUESTING`
- **Cause**: A previous authorization request is still displayed to the user.
- **Resolution**: Do not invoke `requestAuthorization` concurrently. Await the first call before issuing another.

#### Authorization Denied (`authResult.isAuthorized == false`)
- **Cause**: The user tapped "Deny" or dismissed the dialog.
- **Resolution**: Gracefully disable features requiring PDS storage or explain to the user why permissions are needed.

---

### 3. Cryptographic Errors (`PdsCryptoManager`)

#### `KeyStoreException` / `GeneralSecurityException`
- **Cause**: Hardware key generation or retrieval failed in `AndroidKeyStore`.
- **Resolution**: Ensure the device supports AES-256 hardware keystore operations. Use unique and valid alphanumeric key aliases.

#### Ciphertext Too Short / Decryption Failure
- **Cause**: Payload corruption or attempting to decrypt with a key alias different from the one used for encryption.
- **Resolution**: Verify that the correct `keyAlias` is passed to `getEncryptedBlob`.

---

## Best Practices for Robust Handling

```dart
import 'package:flutter/services.dart';
import 'package:pds_flutter/pds_flutter.dart';

Future<void> safeStoreRecord(PdsClient client, Map<String, dynamic> record) async {
  try {
    // 1. Verify connection
    if (!await client.isConnected()) {
      final connected = await client.connect();
      if (!connected) {
        throw StateError('Cannot connect to PDS Core service.');
      }
    }

    // 2. Perform write
    final recordId = await client.put('receipts', record);
    print('Record stored with ID: $recordId');

  } on PlatformException catch (e) {
    print('Platform IPC error [${e.code}]: ${e.message}');
  } on StateError catch (e) {
    print('State error: ${e.message}');
  } catch (e) {
    print('Unexpected error: $e');
  }
}
```
