import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_service.dart';

class BleLogController extends GetxController {
  final BleManager bleManager = Get.find<BleManager>();

  /// Shared process instance
  late final BleProcess bleProcess = bleManager.bleProcess;

  /// 🔥 UPDATED: Accept ScannedBleDevice, not just BluetoothDevice
  Future<void> connectToDevice({required ScannedBleDevice scanned}) async {
    await bleManager.connectToKnownDevice(
      device: scanned.device,
      advData: scanned.advData,
      rssi: scanned.rssi,
    );
  }

  Future<void> enableNotify() async {
    await bleManager.registerNotifyHandler();
  }

  /// Start log retrieval process
  Future<void> startLogRetrieval() async {
    await bleManager.startLogRetrieval();
  }

  Future<void> sendNetworkPacket() async {
    await bleManager.sendNetworkPacket();
  }

  void startContinouspolling() {
    bleProcess.runStateMachine();
  }

  bool get isConnected => bleManager.isConnected;

  Future<void> restartNetworkFlow() async {
    print("---------------- Restarting the network flow ----------------");
    await Future.delayed(const Duration(seconds: 7));
    await sendNetworkPacket();
  }

  /// 🚨 FATAL BLE ERROR ENTRY POINT
  void onBleFatalError(String message) {
    print("❌ BLE FATAL ERROR: $message");

    bleProcess.cancelRxTimeout();

    Get.snackbar(
      "Connection Lost",
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );

    bleProcess.resetProcessState();
    bleManager.resetProtocolState();
    bleManager.shutdown();
  }

  Future<void> restartLogRetrieval() async {
    final bleProcess = bleManager.bleProcess;

    print("🔄 Restarting BLE log retrieval");

    bleProcess.resetProcessState();
    bleManager.resetProtocolState();

    await bleManager.sendNetworkPacket();
    bleProcess.runStateMachine();
  }
}
