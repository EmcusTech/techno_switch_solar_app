import 'dart:async';
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

  Future<void> disconnect() async {
    await _btUtils.disconnect();
    _isConnected = false;
    _bleHandler.currentBleState(BleStateMachine.none);
  }

  Future<void> submitPasskey(String passkey) =>
      _bleHandler.submitPasskey(passkey);
}
