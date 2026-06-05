import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/widgets/ble_communication_failure_dialog.dart';

class BleLogController extends GetxController {
  final BleManager bleManager = Get.find<BleManager>();
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
    final int resolvedMaxRetries = fastReconnect ? 3 : 5;
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

  Future<void> startLogRetrieval() async {
    await bleManager.startLogRetrieval();
  }

  Future<void> startSessionAccessCodeValidation() async {
    await bleManager.startSessionAccessCodeValidation();
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

  Future<void> stopLiveEventSetup() async {
    await bleManager.stopLiveEventsRetrieval();
  }

  Future<void> startAdcSetupFetch() async {
    await bleManager.startAdcSetupFetch();
  }

  sendNetworkPacket() async {
    await bleManager.sendNetworkPacket();
  }

  sendAccessKeyPacket() async {
    await bleManager.sendAccessKeyPkt();
  }

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
    if (bleProcess.networkFlowRestartCount >=
        BleProcess.maxNetworkFlowRestarts) {
      return;
    }
    print(
      "------------------------Restarting the network FLow-------------------------------",
    );
    await Future.delayed(const Duration(seconds: 7));
    if (bleProcess.networkFlowRestartCount >=
        BleProcess.maxNetworkFlowRestarts) {
      return;
    }
    await sendNetworkPacket();
  }

  Future<void> onNetworkFlowFailed() async {
    const message = BleCommunicationFailureDialog.defaultMessage;
    print('BLE network flow failed after max retries');

    bleProcess.cancelRxTimeout();
    bleProcess.isOtaCompleted = true;
    bleProcess.processNextOtaFrame = false;
    bleManager.otaProcessState = OtaProcessState.notInUse;

    try {
      await bleManager.disconnectConnectedDevice();
    } catch (e) {
      print('disconnect on network flow failure: $e');
    }
    await bleManager.shutdown();
    bleManager.resetProtocolState();
    bleProcess.resetProcessState();
    bleProcess.isOtaCompleted = true;
    bleProcess.processNextOtaFrame = false;
    bleProcess.publishCommunicationFailure(message);
  }

  Future<void> onBleFatalError(String message) async {
    print("BLE FATAL ERROR: $message");
    bleProcess.cancelRxTimeout();
    bleProcess.isSessionAccessCodeValidationOnly = false;
    try {
      await bleManager.disconnectConnectedDevice();
    } catch (_) {}
    await bleManager.shutdown();
    bleProcess.resetProcessState();
    bleManager.resetProtocolState();
    bleProcess.isOtaCompleted = true;
    bleProcess.publishCommunicationFailure(message);
  }

  Future<void> restartLogRetrieval() async {
    final bleManager = Get.find<BleManager>();
    final bleProcess = bleManager.bleProcess;

    print("Restarting BLE log retrieval");

    bleProcess.resetProcessState();
    bleManager.resetProtocolState();

    await bleManager.sendNetworkPacket();
    bleProcess.runStateMachine();
  }
}
