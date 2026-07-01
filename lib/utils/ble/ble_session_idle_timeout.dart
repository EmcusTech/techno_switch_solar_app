import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_session_idle_policy.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

/// Resets a 5-minute idle timer on any pointer down while BLE is connected,
/// handshake is complete, and [BleSessionIdlePolicy.suppressIdleDisconnect] is false;
/// on expiry calls [BleManager.disconnectConnectedDevice].
class BleSessionIdleTimeout extends StatefulWidget {
  const BleSessionIdleTimeout({super.key, required this.child});

  final Widget child;

  static const Duration idleDuration = Duration(minutes: 5);

  @override
  State<BleSessionIdleTimeout> createState() => _BleSessionIdleTimeoutState();
}

class _BleSessionIdleTimeoutState extends State<BleSessionIdleTimeout> {
  Timer? _timer;
  late final BleLogController _bleController;

  @override
  void initState() {
    super.initState();
    _bleController = Get.find<BleLogController>();
    _bleController.bleManager.isConnectedNotifier.addListener(
      _onConnectionOrHandshakeChanged,
    );
    _bleController.bleManager.handshakeCompleteNotifier.addListener(
      _onConnectionOrHandshakeChanged,
    );
    BleSessionIdlePolicy.suppressIdleDisconnect.addListener(
      _onSuppressPolicyChanged,
    );
    _syncTimerArmedState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bleController.bleManager.isConnectedNotifier.removeListener(
      _onConnectionOrHandshakeChanged,
    );
    _bleController.bleManager.handshakeCompleteNotifier.removeListener(
      _onConnectionOrHandshakeChanged,
    );
    BleSessionIdlePolicy.suppressIdleDisconnect.removeListener(
      _onSuppressPolicyChanged,
    );
    super.dispose();
  }

  void _onConnectionOrHandshakeChanged() {
    _syncTimerArmedState();
  }

  void _onSuppressPolicyChanged() {
    _syncTimerArmedState();
  }

  bool get _shouldArm {
    final m = _bleController.bleManager;
    return m.isConnectedNotifier.value &&
        m.handshakeCompleteNotifier.value &&
        !BleSessionIdlePolicy.suppressIdleDisconnect.value;
  }

  void _syncTimerArmedState() {
    if (!_shouldArm) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _scheduleIdleDisconnect();
  }

  void _scheduleIdleDisconnect() {
    _timer?.cancel();
    _timer = Timer(BleSessionIdleTimeout.idleDuration, () async {
      final m = _bleController.bleManager;
      if (m.isConnectedNotifier.value && m.handshakeCompleteNotifier.value) {
        await m.disconnectConnectedDevice();
      }
    });
  }

  void _onUserActivity() {
    if (_shouldArm) {
      _scheduleIdleDisconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserActivity(),
      child: widget.child,
    );
  }
}
