# App Services Usage Guide

## Overview

`AppServices` is a thin singleton wrapper around the live BLE stack. It provides a single place to check connection status and disconnect when navigating away from a session.

## Architecture

### AppServices (`lib/services/app_services.dart`)

- **`isConnected`** — reads `BleManager.isConnected` via GetX
- **`disconnect()`** — calls `BleManager.disconnectConnectedDevice()` and resets `AppState`
- **`dispose()`** — disconnects if needed and disposes `AppState` (app lifecycle)

```dart
if (AppServices.isConnected) {
  await AppServices.disconnect();
}
```

### AppState (`lib/services/app_state.dart`)

Holds global `ValueNotifier`s used for session reset on navigation. Call `AppState.reset()` when leaving a BLE flow; call `AppState.dispose()` on app shutdown.

### BleManager (`lib/ble/ble_manager.dart`)

Primary BLE implementation used for scanning, handshake, log retrieval, firmware OTA, and panel configuration. Registered in `main.dart`:

```dart
Get.put<BleManager>(BleManager(), permanent: true);
Get.put(BleLogController());
```

## Typical navigation cleanup

```dart
if (AppServices.isConnected) {
  await AppServices.disconnect();
}
AppState.reset();
```

See `NavigationService` and `HomeScreen` for examples.
