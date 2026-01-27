import 'dart:async';

// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;

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
  Future<List<DiscoveredDevice>> scanForDevices({
    Duration duration = const Duration(seconds: 15),
  }) async {
    final List<DiscoveredDevice> devices = [];

    //this starts the scan process, the moment we kisten to the stream, we are actively starting
    //scan process
    final StreamSubscription sub = _btUtils.scanResultsStream.listen((results) {
      devices
        ..clear()
        ..addAll(results);
    });

    await Future.delayed(duration);

    //this stops the scan process
    await sub.cancel();

    return List.unmodifiable(devices);

    // final Completer<List<ScanResult>> completer = Completer<List<ScanResult>>();

    // await _btUtils.scanDevices((List<ScanResult> results) {
    //   if (!completer.isCompleted) {
    //     completer.complete(List<ScanResult>.from(results));
    //   }
    // });

    // return completer.future.timeout(
    //   const Duration(seconds: 15),
    //   onTimeout: () {
    //     if (!completer.isCompleted) {
    //       completer.complete(<ScanResult>[]);
    //     }
    //     return <ScanResult>[];
    //   },
    // );
  }

  /// Connects to the provided [device] and kicks off the handshake flow.
  Stream<DeviceConnectionState> connectToDevice(
    DiscoveredDevice device,
  ) async* {
    final stream = _btUtils.connectToDevice(device);

    await for (final state in stream) {
      if (state == DeviceConnectionState.connected) {
        await _bleHandler.enableNotifyForCallBack(device: device);
        _isConnected = true;
      }
      yield state;
    }
  }

  Future<void> disconnect() async {
    await _btUtils.disconnect();
    _isConnected = false;
    _bleHandler.currentBleState(BleStateMachine.none);
  }

  Future<void> submitPasskey(String passkey) =>
      _bleHandler.submitPasskey(passkey);
}
