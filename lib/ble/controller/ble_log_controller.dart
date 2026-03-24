import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';

class BleLogController extends GetxController {
  final BleManager bleManager = Get.find<BleManager>();
  // Reuse the shared BleProcess instance from the manager so all screens
  // listen to the same ValueNotifiers.
  late final BleProcess bleProcess = bleManager.bleProcess;

  connectToDevice({
    required DiscoveredDevice device,
    int? manufacturerDataOverride,
    bool fastReconnect = false,
    bool skipConnectionHandshake = false,
    int? maxRetries,
    Duration? retryDelay,
    Duration? connectionTimeout,
  }) async {
    final int resolvedMaxRetries = fastReconnect ? 3 : 10;
    final Duration resolvedRetryDelay =
        retryDelay ??
        (fastReconnect
            ? const Duration(milliseconds: 300)
            : const Duration(seconds: 1));
    final Duration resolvedConnectionTimeout =
        connectionTimeout ??
        (fastReconnect
            ? const Duration(seconds: 4)
            : const Duration(seconds: 10));

    await bleManager.connectToKnownDevice(
      device: device,
      manufacturerDataOverride: manufacturerDataOverride,
      skipConnectionHandshake: skipConnectionHandshake,
      maxRetries: resolvedMaxRetries,
      retryDelay: resolvedRetryDelay,
      connectionTimeout: resolvedConnectionTimeout,
    );
  }

  enableNotify() async {
    await bleManager.registerNotifyHandler();
  }

  /// Start log retrieval process
  /// This initializes the protocol state and begins the encryption handshake
  /// which will eventually start retrieving logs from the device
  Future<void> startLogRetrieval() async {
    await bleManager.startLogRetrieval();
  }

  Future<void> startExtOutFetch() async {
    await bleManager.startExtOutFetch();
  }

  Future<void> startExtOutApply() async {
    await bleManager.startExtOutApply();
  }

  Future<void> startInputSetupFetch() async {
    await bleManager.startInputSetupFetch();
  }

  Future<void> startInputSetupApply() async {
    await bleManager.startInputSetupApply();
  }

  Future<void> startRelaySetupFetch() async {
    await bleManager.startRelaySetupFetch();
  }

  Future<void> startRelaySetupApply() async {
    await bleManager.startRelaySetupApply();
  }

  Future<void> startZoneSetupFetch() async {
    await bleManager.startZoneSetupFetch();
  }

  Future<void> startZoneSetupApply() async {
    await bleManager.startZoneSetupApply();
  }

  Future<void> startRadioSetupFetch() async {
    await bleManager.startRadioSetupFetch();
  }

  Future<void> startRadioSetupApply() async {
    await bleManager.startRadioSetupApply();
  }

  Future<void> startModuleSetupFetch() async {
    await bleManager.startModuleSetupFetch();
  }

  Future<void> startLBusSetupFetch() async {
    await bleManager.startLBusSetupFetch();
  }

  Future<void> startLBusSetupApply() async {
    await bleManager.startLBusSetupApply();
  }

  Future<void> startSounderSetupFetch() async {
    await bleManager.startSounderSetupFetch();
  }

  Future<void> startSounderSetupApply() async {
    await bleManager.startSounderSetupApply();
  }

  Future<void> startServiceDueFetch() async {
    await bleManager.startServiceDueFetch();
  }

  Future<void> startServiceDueApply() async {
    await bleManager.startServiceDueApply();
  }

  Future<void> startAccessCodeSetupFetch() async {
    await bleManager.startAccessCodeSetupFetch();
  }

  Future<void> startAccessCodeSetupApply() async {
    await bleManager.startAccessCodeSetupApply();
  }

  Future<void> startPanelInfoSetupFetch() async {
    await bleManager.startPanelInfoSetupFetch();
  }

  Future<void> startPanelInfoSetupApply() async {
    await bleManager.startPanelInfoSetupApply();
  }

  Future<void> startGeneralModuleSetupFetch() async {
    await bleManager.startGeneralModuleSetupFetch();
  }

  Future<void> startGeneralModuleSetupApply() async {
    await bleManager.startGeneralModuleSetupApply();
  }

  Future<void> startLiveEventSetup() async {
    await bleManager.startLiveEventsRetrieval();
  }

  sendNetworkPacket() async {
    await bleManager.sendNetworkPacket();
  }

  sendAccessKeyPacket() async {
    await bleManager.sendAccessKeyPkt();
  }

  // startExtOut() async {
  //   await bleManager.startExtOut();
  // }

  sendExtOutApplyCommand() async {
    await bleManager.sendExtOutSetupApplyCmdPkt();
  }

  sendExtOutFetchCommand() async {
    await bleManager.sendExtOutSetupFetchCmdPkt();
  }

  startContinouspolling() {
    bleProcess.runStateMachine();
  }

  bool get isConnected => bleManager.isConnected;

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
