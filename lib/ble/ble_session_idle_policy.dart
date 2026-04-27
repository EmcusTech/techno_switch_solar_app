import 'package:flutter/foundation.dart';

/// Global policy for [BleSessionIdleTimeout] and project dashboard connection UX.
///
/// When [suppressIdleDisconnect] is true, the idle timer does not run (e.g. during
/// the create-site wizard). [ProjectDashboardScreen] clears this so the timer
/// applies on the dashboard.
///
/// [suppressFirmwareDisconnectUi] is set while the firmware bottom sheet is
/// performing expected disconnects (jump / end / reconnect).
class BleSessionIdlePolicy {
  BleSessionIdlePolicy._();

  static final ValueNotifier<bool> suppressIdleDisconnect =
      ValueNotifier<bool>(false);

  /// When true, [ProjectDashboardScreen] does not pop modal overlays (e.g. firmware
  /// bottom sheet) or show the unexpected "Bluetooth disconnected" dialog, because
  /// disconnects are expected during firmware jump, end packet, and reconnect.
  static final ValueNotifier<bool> suppressFirmwareDisconnectUi =
      ValueNotifier<bool>(false);
}
