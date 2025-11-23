import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

class TechnoswitchBleService {
  TechnoswitchBleService._() {
    if (Get.isRegistered<BleNotifyDataHandler>()) {
      _bleHandler = Get.find<BleNotifyDataHandler>();
    } else {
      _bleHandler = Get.put(BleNotifyDataHandler(), permanent: true);
    }
  }

  static final TechnoswitchBleService _instance = TechnoswitchBleService._();

  factory TechnoswitchBleService() => _instance;
  static TechnoswitchBleService get instance => _instance;

  final BtUtils _btUtils = BtUtils();
  late final BleNotifyDataHandler _bleHandler;
  bool _isConnected = false;

  BleNotifyDataHandler get controller => _bleHandler;
  Stream<BleHandshakeEvent> get handshakeEvents => _bleHandler.handshakeEvents;
  bool get isConnected => _isConnected;

  /// Scans for nearby BLE devices and returns the first batch of results.
  Future<List<ScanResult>> scanForDevices() async {
    final Completer<List<ScanResult>> completer = Completer<List<ScanResult>>();

    await _btUtils.scanDevices((List<ScanResult> results) {
      if (!completer.isCompleted) {
        completer.complete(List<ScanResult>.from(results));
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.complete(<ScanResult>[]);
        }
        return <ScanResult>[];
      },
    );
  }

  /// Connects to the provided [device] and kicks off the handshake flow.
  Future<bool> connectToDevice(BluetoothDevice device) async {
    final Completer<bool> completer = Completer<bool>();

    await _btUtils.connectToDevice(device, (bool connected) {
      if (!completer.isCompleted) {
        completer.complete(connected);
      }
    });

    final bool connected = await completer.future;
    if (!connected) {
      Logger('TechnoswitchBleService: failed to connect to device');
      return false;
    }

    await _bleHandler.enableNotifyForCallBack();
    _isConnected = true;
    return true;
  }

  Future<void> disconnect() async {
    await _btUtils.disconnect();
    _isConnected = false;
    _bleHandler.currentBleState(BleStateMachine.none);
  }

  Future<void> submitPasskey(String passkey) =>
      _bleHandler.submitPasskey(passkey);
}
