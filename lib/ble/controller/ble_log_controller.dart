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
}
