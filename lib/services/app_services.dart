import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/services/app_state.dart';

class AppServices {
  AppServices._internal();

  static final AppServices _instance = AppServices._internal();

  factory AppServices() => _instance;

  static BleManager get _bleManager => Get.find<BleManager>();

  static bool get isConnected => _bleManager.isConnected;

  static Future<void> initialize() async {}

  static Future<void> dispose() async {
    if (_bleManager.isConnected) {
      await _bleManager.disconnectConnectedDevice();
    }
    AppState.dispose();
  }

  static Future<void> disconnect() async {
    if (_bleManager.isConnected) {
      await _bleManager.disconnectConnectedDevice();
    }
    AppState.reset();
  }
}
