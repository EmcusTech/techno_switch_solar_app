import 'dart:async';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';

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

  Future<List<DiscoveredDevice>> scanForDevices({
    Duration duration = const Duration(seconds: 15),
  }) async {
    final List<DiscoveredDevice> devices = [];

    final StreamSubscription sub = _btUtils.scanResultsStream.listen((results) {
      devices
        ..clear()
        ..addAll(results);
    });

    await Future.delayed(duration);

    await sub.cancel();

    return List.unmodifiable(devices);
  }

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
