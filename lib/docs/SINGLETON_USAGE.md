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

Placeholder for session cleanup hooks. Call `AppState.reset()` when leaving a BLE flow; call `AppState.dispose()` on app shutdown.

### Dependency registration (`lib/bindings/initial_binding.dart`)

`InitialBinding` is the **single registration point** for app-wide GetX
dependencies. It is invoked once from `main()` before `runApp`, replacing the
previous scattered `Get.put` calls.

```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BleManager>(BleManager(), permanent: true);
    Get.lazyPut<BleLogController>(() => BleLogController(), fenix: true);
  }
}
```

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  InitialBinding().dependencies();
  // ...
  runApp(const MyApp());
}
```

Guidelines:

- Register app-wide dependencies only in `InitialBinding`. Do not call
  `Get.put` directly from screens or widgets.
- Feature-scoped controllers get their own binding (e.g. `FirmwareBinding`
  for `UpdatesController`) and are removed with `Get.delete` when the feature
  closes.

### BleManager (`lib/ble/ble_manager.dart`)

Primary BLE implementation used for scanning, handshake, log retrieval,
firmware OTA, and panel configuration. It is a `GetxService` (app-lifetime,
registered `permanent: true`) and is resolved via `Get.find<BleManager>()`.

## Dependency resolution conventions

- **No file-level globals.** Do not declare top-level
  `final BleManager ble = Get.find<BleManager>();`. Resolve dependencies inside
  the `State` (or `GetxController`) that needs them, e.g.

```dart
class _MyScreenState extends State<MyScreen> {
  final BleManager ble = Get.find<BleManager>();
  // ...
}
```

- Prefer resolving BLE access through `BleLogController` (which exposes
  `bleManager`) rather than calling both `Get.find<BleManager>()` and
  `Get.find<BleLogController>()` in the same widget.
- **Known follow-up:** `BleManager` and `BleLogController` reference each other
  via `Get.find` (circular DI). This is intentional for now; do not refactor BLE
  internals as part of DI cleanup.

## Reactive widget conventions

Pick the builder by *what* state is changing:

| State source | Builder to use |
| --- | --- |
| BLE device/session state (`ValueNotifier` in `BleProcess`, e.g. `isConnectedNotifier`, `processDesc`) | `ValueListenableBuilder` (unchanged) |
| `GetxController` with `.obs` fields (`UpdatesController`) | `Obx` |
| `GetxController` using coarse `update()` (`CreateProjectController`) | `GetBuilder<T>` |

BLE `ValueNotifier`s are deliberately **not** converted to `.obs`; keep using
`ValueListenableBuilder` for them.

## Controller layer (UI/logic separation)

Screens and bottom sheets should keep only layout + user-intent in their
widgets; non-presentational logic lives in a `GetxController`.

- **One controller per screen/sheet.** It owns state and orchestration and
  talks to services/`BleManager`.
- **Controllers hold NO `BuildContext`.** Navigation and dialogs stay in the
  View. When a flow needs a mid-flow decision, the controller returns a
  result/enum and the View performs the dialog/navigation (decision-result
  pattern).
- **Services are the I/O layer.** Controllers call `PanelService`,
  `SiteService`, `FirmwareUpgradeService`, etc.; Views never instantiate them.
- **Lifecycle.** Register via a `Bindings` class (or `Get.put` in `initState`)
  and `Get.delete` when the screen/sheet closes. Dispose owned
  `TextEditingController`s in `onClose()`.

### Peripheral config sheets

The relay/zone/input/sounder/general/etc. bottom sheets share one lifecycle
(`load -> cache-hit applyCachedData / cache-miss loadFromManager`;
`commit -> validate -> pushToManager -> save`). That skeleton lives in
`PeripheralModeController` (`lib/controllers/peripheral/peripheral_mode_controller.dart`);
each sheet's controller extends it and implements only the model-specific
mapping. The sheet widget rebuilds via `GetBuilder<T>`.

## Typical navigation cleanup

```dart
if (AppServices.isConnected) {
  await AppServices.disconnect();
}
AppState.reset();
```

See `NavigationService` and `HomeScreen` for examples.
