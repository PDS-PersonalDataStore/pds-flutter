# Architecture Guide

This document describes the design and IPC communication flow of the `pds_flutter` plugin.

## High-Level Overview

`pds_flutter` connects Flutter client applications with the central Personal Data Store (`PDS Core`) background service running on Android.

```
+-----------------------------------------------------------+
|                     Flutter App (Dart)                   |
|  +--------------------+       +------------------------+  |
|  |     PdsClient      | ----> |  PdsFlutterPlatform    |  |
|  +--------------------+       +------------------------+  |
|                                            |              |
|                               +------------------------+  |
|                               |   MethodChannelPds     |  |
|                               |  (Pigeon PdsHostApi)   |  |
|                               +------------------------+  |
+--------------------------------------------|--------------+
                                             | Platform Channels / Pigeon
+--------------------------------------------v--------------+
|                   Android Plugin Layer (Kotlin)           |
|  +-----------------------------------------------------+  |
|  |                  PdsFlutterPlugin                   |  |
|  |   - Implements Pigeon PdsHostApi                    |  |
|  |   - ActivityAware (interactive auth popup dialog)   |  |
|  |   - EventChannel (watchChanges listener stream)     |  |
|  +-----------------------------------------------------+  |
|                            |                              |
|  +-----------------------------------------------------+  |
|  |                  PdsAndroidClient                   |  |
|  |   - ServiceConnection to top.tau2c.pds.core         |  |
|  |   - PdsCryptoManager (AES-256-GCM KeyStore)         |  |
|  +-----------------------------------------------------+  |
+----------------------------|------------------------------+
                             | Binder IPC (IPdsService.aidl)
+----------------------------v------------------------------+
|                     PDS Core Background App               |
|  +-----------------------------------------------------+  |
|  |                     PdsService                      |  |
|  |   - AIDL Stub implementation                        |  |
|  |   - Permission validation                           |  |
|  +-----------------------------------------------------+  |
|                            | JNI                          |
|  +-------------------------v---------------------------+  |
|  |               Native Storage Engine (Rust)          |  |
|  |   - SQLite / Sled storage                           |  |
|  |   - Content-Addressed Storage (CAS)                 |  |
|  |   - Multimember relations (Engine 1.5)              |  |
|  +-----------------------------------------------------+  |
+-----------------------------------------------------------+
```

## Communication Layers

### 1. High-Level Dart Client (`lib/pds_flutter.dart`)
- Provides `PdsClient` as the primary user-facing API.
- Implements convenience wrappers for JSON serialization, entity CRUD, CAS binary storage, and E2EE encrypted blobs.
- Manages real-time subscriptions via Dart `Stream<String>`.

### 2. Typed Pigeon Host API (`lib/src/pds_api.g.dart`)
- Auto-generated type-safe IPC layer using Pigeon (`pigeons/pds_api.dart`).
- Replaces dynamic string dictionaries with strongly typed calls and data transfer objects (`PdsAuthResultDto`).
- Enforces compile-time checks across the Flutter/Android boundary.

### 3. Android Plugin Bridge (`android/.../PdsFlutterPlugin.kt`)
- Implements `PdsHostApi` in Kotlin.
- Implements `ActivityAware` and `ActivityResultListener` to launch `top.tau2c.pds.core.REQUEST_AUTHORIZATION` for user consent.
- Implements `EventChannel.StreamHandler` to deliver asynchronous database mutation notifications from AIDL callbacks to Flutter.

### 4. Client SDK (`android/.../PdsAndroidClient.kt`)
- Manages Android `ServiceConnection` lifecycle for binding to `top.tau2c.pds.core.PdsService`.
- Includes `PdsCryptoManager` for hardware-backed AES-256-GCM encryption and decryption using `AndroidKeyStore`.
- Communicates directly with AIDL interfaces (`IPdsService` and `IPdsChangeListener`).

### 5. Binder IPC & AIDL Interface
- Defined in `IPdsService.aidl`.
- Provides transactional methods for client registration, request execution, blob management, client revoking, and change listener callbacks.
- PDS Core enforces permission checks (`top.tau2c.pds.permission.ACCESS_PDS`) and interactive user authorization per calling UID.
