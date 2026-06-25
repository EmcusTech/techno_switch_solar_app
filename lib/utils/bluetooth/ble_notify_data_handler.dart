import 'dart:async';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;

class BleNotifyDataHandler extends GetxController {
  final DataTransferManager _dataTransferManager = DataTransferManager();

  int _pktTxCnt = 0;
  final int _pktRxCnt = 0;
  int _lastFeaturePacketCounter = 0;
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

  // Future<void> submitPasskey(String passkey) async {
  //   logger.Logger('========================================');
  //   logger.Logger('SUBMITTING PASSKEY');
  //   logger.Logger('========================================');
  //   logger.Logger('Passkey value: "$passkey"');
  //   logger.Logger('Passkey length: ${passkey.length} characters');

  //   if (passkey.isEmpty) {
  //     logger.Logger('Passkey submission - ERROR: Passkey cannot be empty');
  //     _emitEvent(BleHandshakeEvent.error('Passkey cannot be empty'));
  //     return;
  //   }

  //   pollPacketCount = 0;
  //   passkeyAccepted = false;
  //   _pktTxCnt = _lastFeaturePacketCounter + 1;
  //   _lastFeaturePacketCounter = _pktTxCnt;

  //   logger.Logger('Passkey submission - Calling sendingPasskeyToBle()');
  //   logger.Logger(
  //     'Passkey submission - TX Counter: $_pktTxCnt (from last feature packet), RX Counter: $_pktRxCnt',
  //   );

  //   currentBleState(BleStateMachine.sendingPasskeyPacket);
  //   _dataTransferManager.sendingPasskeyToBle(
  //     passkey,
  //     pktTxCnt: _pktTxCnt,
  //     pktRxCnt: _pktRxCnt,
  //     dataWritten: (bool isWritten) {
  //       if (isWritten) {
  //         logger.Logger('Passkey submission - Frame written successfully');
  //         logger.Logger('Passkey submission - State: sendingPasskeyPacket');
  //         logger.Logger(
  //           'Passkey submission - Waiting for acknowledgment response...',
  //         );
  //       } else {
  //         logger.Logger(
  //           'Passkey submission - WARNING: Frame write may have failed',
  //         );
  //       }
  //     },
  //   );
  //   logger.Logger('========================================\n');
  // }

  void resetRetryCount() {
    retryCount = 1;
    update();
  }

  void increaseRetryCount() {
    retryCount++;
    update();
  }

  bool checkIfRetryReached() => retryCount >= maxRetryCount;

  void _emitEvent(BleHandshakeEvent event) {
    if (_handshakeController.isClosed) {
      return;
    }
    _handshakeController.add(event);
  }

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
