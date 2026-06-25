import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';

class BleNotifyDataHandler extends GetxController {
  int pollPacketCount = 0;
  bool passkeyAccepted = false;
  Timer? _continuousPollTimer;
  Timer? _pollPacketResponseTimer;
  int lastKnownRxCounter = 0;

  final Rx<BleStateMachine> currentBleState = BleStateMachine.none.obs;
  final Rx<EncryptionDecryptionState> encryptionDecryptionState =
      EncryptionDecryptionState.disabled.obs;
  final Rx<ConnectionScreenState> currentConnectionScreenState =
      ConnectionScreenState.homeScreen.obs;
  final Rx<LargePacketModule> currentLargePacketModule =
      LargePacketModule.devices.obs;
  final Rx<SystemBuildStatus> systemBuildStatus = SystemBuildStatus.none.obs;
  final Rx<BuildModule> currentBuildSystemModule = BuildModule.installation.obs;

  List<Uint8List> lOnGoinglargePacketsList = <Uint8List>[];
  int lOngoingsequenceNumber = 0;
  int retryCount = 1;
  int maxRetryCount = 3;
  List<int>? dataPacketBuffer = <int>[];

  static const String invalidPassword = '09';

  final StreamController<BleHandshakeEvent> _handshakeController =
      StreamController<BleHandshakeEvent>.broadcast();

  Stream<BleHandshakeEvent> get handshakeEvents => _handshakeController.stream;

  void resetRetryCount() {
    retryCount = 1;
    update();
  }

  void increaseRetryCount() {
    retryCount++;
    update();
  }

  bool checkIfRetryReached() => retryCount >= maxRetryCount;

  @override
  void onClose() {
    _continuousPollTimer?.cancel();
    _pollPacketResponseTimer?.cancel();
    _handshakeController.close();
    super.onClose();
  }
}

class BleHandshakeEvent {
  const BleHandshakeEvent(
    this.type, {
    this.state,
    this.message,
    this.deviceName,
  });

  final BleHandshakeEventType type;
  final BleStateMachine? state;
  final String? message;
  final String? deviceName;

  factory BleHandshakeEvent.stateChanged(BleStateMachine state) =>
      BleHandshakeEvent(BleHandshakeEventType.stateChanged, state: state);

  factory BleHandshakeEvent.encryptionKey() =>
      const BleHandshakeEvent(BleHandshakeEventType.encryptionKeyReceived);

  factory BleHandshakeEvent.authenticated() =>
      const BleHandshakeEvent(BleHandshakeEventType.authenticated);

  factory BleHandshakeEvent.passkeyPrompt({String? deviceName}) =>
      BleHandshakeEvent(
        BleHandshakeEventType.passkeyRequested,
        deviceName: deviceName,
      );

  factory BleHandshakeEvent.passkeyAccepted() =>
      const BleHandshakeEvent(BleHandshakeEventType.passkeyAccepted);

  factory BleHandshakeEvent.error(String message) =>
      BleHandshakeEvent(BleHandshakeEventType.error, message: message);
}

enum BleHandshakeEventType {
  stateChanged,
  encryptionKeyReceived,
  authenticated,
  passkeyRequested,
  passkeyAccepted,
  error,
}

enum ConnectionScreenState {
  homeScreen,
  installationScreen,
  maintanence,
  projectDetails,
  panelReplace,
  buildPartialScreen,
}

enum SystemBuildStatus { none, started, completed, failed }

enum BuildModule {
  installation,
  maintenanceAdd,
  editDevice,
  editProperties,
  editPendingBitProperties,
  editExpanderProperties,
  editExpanderPendingBitProperties,
  bulkEdit,
  skipPartialDevices,
  updateCandE,
  maintanaceZoneUpdate,
  removeDevice,
  retryRemoveDevice,
  replaceDevice,
  replaceExpander,
  replaceExpanderFailed,
  sendPartialRemoveDeviceProcedure,
  panelReplace,
}

enum LargePacketModule {
  devices,
  panelNetworkData,
  firmWareUpgrade,
  sendingProjectData,
  sendingZoneData,
}

enum EncryptionDecryptionState { disabled, enabled }

enum BleStateMachine {
  none,
  requestedPasskey,
  passkeyEntered,
  reqEncryptionKey,
  timeOut,
  sendingAuthMessage,
  requestingNetworkPacket,
  sendingPollPacket,
  sendingPasskeyPacket,
  sendingControlResEventReport,
  receivingEventLogs,
  sendingDummyPacket,
  connected,

  createProject,
  installationStep1Completed,
  installationStep2Completed,
  installationStep3Completed,

  sendingPanelConfig,
  sendingProjectData,
  sendingExpanderConfig,
  updateExpanderConfig,
  buildSystem,
  stopBuildSystem,
  panelVersionSend,
  procedureCommandSent,
  getSystemOnlineStatus,
  linkStatusCommand,
  systemBuildSuccess,
  systemBuildFailed,
  sendingZoneData,

  connectCommandSend,

  dataSyncRequest,
  dataStartRequest,
  sendingLargePacketOnGoing,
  largeDataResended,
  dataEndRequest,
  mcuSelection,
  eraseFirmware,
  eofImageData,
  waitingForBuildReady,
  updateBleProcess,
  updatePanelNetworkDataProcess,
  sendingEmptyDeviceData,
  putDeviceToLinkMode,

  expanderPassKeySent,

  requestedForPanelConfig,
  requestedForDeviceConfig,
  requestedForProjectData,
  requestedForExpanderData,
  requestedForZoneData,
  respondedDataSyncRequest,
  respondedToDataStart,
  respondToEndPacket,

  getAllDeviceStatusState,
  getSingleDeviceStatusState,
  getSingleDeviceStatusStateForPendingBit,
  getAllDeviceVersionsState,
  getProjectState,
  requestedForMcuVersions,

  requestedForNetworkData,
  requestedForExpanderParentAddress,
  requestedForNetworkDataCRC,
  checkMismatchForNetworkDataCRC,
  startPanelReplacementSession,
  closePanelReplacementSession,
  closeOldPanelReplacementSession,

  addDeviceState,
  removeDevice,
  replaceDevice,
  editDevice,

  changeDeviceAddress,
  editDeviceProperties,
  editDevicePendingBitProperties,
  editExpanderProperties,
  editExpanderPendingBitProperties,
  bulkEditLedUpdate,
  identifyDevices,

  retryRemoveDeviceState,
  skipRemoveDeviceState,
  retryAddDeviceState,

  updateDevicePointData,
  updateExpanderPropertyData,
  updateExpanderPendingBitPropertyData,
  updateDevicePropertiesData,
  updateDevicePendingBitPropertiesData,
  updatingProjectData,
  updatingBuildStateData,
  updatingPanelData,

  requestedForEventLogs,
  requestedForDiagnosticLogs,
  requestedForEventLogsFilterData,
  requestedForEventLogsFilterDataWithSectionNumber,
  requestedPanelStatus,

  updatePanelDateTimeState,
  updatePanelDateTimeBeforeBuildState,
  requestedForConfigCrc,
  requestedForPanelConfigStatus,
  requestedForDeviceVersions,

  firmwareUploadStatus,
  rfTestCMD,
  enableAnalogValue,
  enableAnalogValueInOnline,
  disableAnalogValue,
  disableAnalogValueWithoutResponse,
  disableAnalogValueForBuildSystem,
  disableAnalogValueFollowWithConnectCMD,

  disableAnalogValueExpanderProperties,
  disableAnalogValueSendingPanelNetworkData,
  disableAnalogValueExpanderPendingBitProperties,
  disableAnalogValueEditProperties,
  disableAnalogValueEditPendingBitProperties,
  disableAnalogValueRemoveCommand,
  disableAnalogValueForFetchPanelData,
  disableAnalogValueReplaceCommand,
  disableAnalogAddZone,

  resetBleTrack,
}
