import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';

class BleLogController extends GetxController {
  final BleManager bleManager = Get.find<BleManager>();
  late final BleProcess bleProcess = BleProcess(bleManager);

  connectToDevice({required DiscoveredDevice device}) async {
    await bleManager.connectToKnownDevice(device: device);
  }

  enableNotify() async {
    await bleManager.registerNotifyHandler();
  }

  sendNetworkPacket() async {
    await bleManager.sendNetworkPacket();
  }

  startContinouspolling() {
    bleProcess.runStateMachine();
  }

  restartNetworkFlow() async {
    print(
      "------------------------Restarting the network FLow-------------------------------",
    );
    await Future.delayed(Duration(seconds: 7));
    sendNetworkPacket();
  }

  //FATAL BLE ERROR ENTRY POINT
  void onBleFatalError(String message) {
    print("BLE FATAL ERROR: $message");

    // Optional: stop any running state machine
    bleProcess.cancelRxTimeout();

    // Navigate user back to scan screen OR show dialog
    // You decide UI behavior here
    Get.snackbar(
      "Connection Lost",
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );

    // Optional hard reset of internal states
    bleProcess.resetProcessState();
    bleManager.resetProtocolState();
    bleManager.shutdown();
  }

  Future<void> restartLogRetrieval() async {
    final bleManager = Get.find<BleManager>();
    final bleProcess = bleManager.bleProcess;

    print("🔄 Restarting BLE log retrieval");

    bleProcess.resetProcessState();
    bleManager.resetProtocolState();

    // Kick off again
    await bleManager.sendNetworkPacket();
    bleProcess.runStateMachine();
  }
}
