import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/app/app_state.dart';

class AppServices {
  static BleManager get _bleManager => Get.find<BleManager>();

  static bool get isConnected => _bleManager.isConnected;

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
