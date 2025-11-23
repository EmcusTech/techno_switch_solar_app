/*
* Project      : technoswitch_solar_app
* File         : ble_notify_data_handler.dart
* Description  : Simplified GetX controller that manages the Technoswitch BLE
*                handshake (encryption exchange, auth message and passkey flow).
*                The older project specific navigation/hooks have been removed
*                so the rest of the app can integrate it freely.
*/

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/bt_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'package:techno_switch_solar_app/utils/storage/encryption_key_store.dart';

class BleNotifyDataHandler extends GetxController {
  final DataTransferManager _dataTransferManager = DataTransferManager();

  /// Observables used across the Bluetooth helpers.
  final Rx<BleStateMachine> currentBleState = BleStateMachine.none.obs;
  final Rx<EncryptionDecryptionState> encryptionDecryptionState =
      EncryptionDecryptionState.disabled.obs;
  final Rx<ConnectionScreenState> currentConnectionScreenState =
      ConnectionScreenState.homeScreen.obs;
  final Rx<LargePacketModule> currentLargePacketModule =
      LargePacketModule.devices.obs;
  final Rx<SystemBuildStatus> systemBuildStatus = SystemBuildStatus.none.obs;
  final Rx<BuildModule> currentBuildSystemModule = BuildModule.installation.obs;

  /// Legacy properties referenced by other helpers (large data transfer).
  List<Uint8List> lOnGoinglargePacketsList = <Uint8List>[];
  int lOngoingsequenceNumber = 0;
  int retryCount = 1;
  int maxRetryCount = 3;
  List<int>? dataPacketBuffer = <int>[];

  static const String _ack = '02';
  static const String _nack = '03';
  static const String _authenticationRequired = '05';
  static const String _timeout = '08';
  static const String _invalidPassword = '09';

  final StreamController<BleHandshakeEvent> _handshakeController =
      StreamController<BleHandshakeEvent>.broadcast();

  Stream<BleHandshakeEvent> get handshakeEvents => _handshakeController.stream;

  /// Enable notifications on the currently connected BLE device.
  Future<void> enableNotifyForCallBack() async {
    final BluetoothDevice? connectedDevice =
        await BtUtils().getConnectedDevices();
    if (connectedDevice == null) {
      Logger('BLE notify handler: no connected device found.');
      _emitEvent(
        BleHandshakeEvent.error('Device disconnected before handshake'),
      );
      return;
    }

    BtUtils().enableNotifications(
      connectedDevice,
      (List<int> data) {
        if (connectedDevice.isConnected) {
          _handleNotifyData(data, connectedDevice);
        }
      },
      notifyEnabledcallback: (bool enabled) {
        if (!enabled) {
          _emitEvent(
            BleHandshakeEvent.error(
              'Unable to enable notifications on primary characteristic',
            ),
          );
          return;
        }

        _dataTransferManager.requestEncryptionKey(
          dataWritten: (bool isWritten) {
            if (isWritten) {
              currentBleState(BleStateMachine.reqEncryptionKey);
              _emitStateChange('Requesting encryption key');
            }
          },
        );
      },
    );
  }

  /// Sends the user provided passkey back to the panel.
  Future<void> submitPasskey(String passkey) async {
    if (passkey.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Passkey cannot be empty'));
      return;
    }
    _dataTransferManager.sendingPasskeyToBle(
      passkey,
      dataWritten: (bool isWritten) {
        if (isWritten) {
          currentBleState(BleStateMachine.passkeyEntered);
          _emitStateChange('Passkey sent to panel');
        }
      },
    );
  }

  void resetRetryCount() {
    retryCount = 1;
    update();
  }

  void increaseRetryCount() {
    retryCount++;
    update();
  }

  bool checkIfRetryReached() => retryCount >= maxRetryCount;

  void _handleNotifyData(List<int> rxData, BluetoothDevice device) async {
    if (rxData.isEmpty) {
      return;
    }

    // Stop any outstanding timers – we received a response.
    _dataTransferManager.stopResponseTimer();

    FrameData? frame;
    final bool shouldDecrypt =
        encryptionDecryptionState.value == EncryptionDecryptionState.enabled &&
        currentBleState.value != BleStateMachine.reqEncryptionKey;

    if (shouldDecrypt) {
      try {
        frame = await DataHandler().decryptTheDataPacketWithoutConversion(
          rxData,
        );
      } catch (e) {
        Logger('BLE notify: failed to decrypt frame $e');
      }
    } else {
      frame = _dataTransferManager.parseRxFrame(rxData);
    }

    if (frame == null) {
      _emitEvent(BleHandshakeEvent.error('Unable to parse BLE frame'));
      return;
    }

    _processFrame(frame, device);
  }

  void _processFrame(FrameData frame, BluetoothDevice connectedDevice) {
    final bool isValid = DataHandler().frameValidation(
      frame,
      errorCode: (String error) {
        Logger('BLE frame validation error: $error');
      },
    );
    if (!isValid) {
      _emitEvent(BleHandshakeEvent.error('Invalid frame received'));
      return;
    }

    switch (currentBleState.value) {
      case BleStateMachine.reqEncryptionKey:
        _handleEncryptionReqResponse(frame);
        break;
      case BleStateMachine.sendingAuthMessage:
        _handleAuthMsgResponse(frame);
        break;
      case BleStateMachine.requestedPasskey:
        _handlePassKeyRequestResponse(frame, connectedDevice);
        break;
      case BleStateMachine.passkeyEntered:
        _handlePasskeyResponse(frame);
        break;
      default:
        // For now we only care about the connect/auth flow.
        Logger(
          'BLE notify: frame received for state ${currentBleState.value.name}',
        );
        break;
    }
  }

  Future<void> _handleEncryptionReqResponse(FrameData frame) async {
    if (frame.payloadData.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Empty encryption response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _authenticationRequired) {
      _emitEvent(BleHandshakeEvent.error('Authentication required by panel'));
      return;
    }

    final String keyHex =
        frame.payloadData.map((String byte) => byte.toLowerCase()).join();
    await EncryptionKeyStore.instance.saveKey(keyHex);
    encryptionDecryptionState(EncryptionDecryptionState.enabled);

    _emitEvent(
      BleHandshakeEvent(
        BleHandshakeEventType.encryptionKeyReceived,
        state: currentBleState.value,
      ),
    );

    _dataTransferManager.sendAuthPacket(
      dataWritten: (bool isWritten) {
        if (isWritten) {
          currentBleState(BleStateMachine.sendingAuthMessage);
          _emitStateChange('Sent authentication message');
        }
      },
    );
  }

  void _handleAuthMsgResponse(FrameData frame) {
    if (frame.payloadData.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Empty auth response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _ack) {
      _emitEvent(BleHandshakeEvent.authenticated());
      _dataTransferManager.requestingPassKeyToBle(
        dataWritten: (bool isWritten) {
          if (isWritten) {
            currentBleState(BleStateMachine.requestedPasskey);
            _emitEvent(BleHandshakeEvent.passkeyPrompt());
          }
        },
      );
    } else if (status == _nack) {
      _emitEvent(BleHandshakeEvent.error('Auth message rejected by panel'));
    } else {
      _emitEvent(BleHandshakeEvent.error('Unexpected auth response: $status'));
    }
  }

  void _handlePassKeyRequestResponse(FrameData frame, BluetoothDevice device) {
    if (frame.payloadData.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Empty passkey request response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _ack) {
      final String deviceName = BtUtils().getBTDeviceName(device);
      _emitEvent(BleHandshakeEvent.passkeyPrompt(deviceName: deviceName));
    } else if (status == _timeout) {
      currentBleState(BleStateMachine.timeOut);
      _emitEvent(BleHandshakeEvent.error('Passkey request timed out'));
    } else {
      _emitEvent(
        BleHandshakeEvent.error('Passkey request failed with status $status'),
      );
    }
  }

  void _handlePasskeyResponse(FrameData frame) {
    if (frame.payloadData.isEmpty) {
      _emitEvent(BleHandshakeEvent.error('Empty passkey response'));
      return;
    }

    final String status = frame.payloadData.first;
    if (status == _ack) {
      currentBleState(BleStateMachine.connected);
      _emitEvent(BleHandshakeEvent.passkeyAccepted());
      _emitStateChange('Handshake completed');
    } else if (status == _invalidPassword) {
      _emitEvent(BleHandshakeEvent.error('Invalid passkey'));
    } else if (status == _timeout) {
      currentBleState(BleStateMachine.timeOut);
      _emitEvent(BleHandshakeEvent.error('Passkey validation timed out'));
    } else {
      _emitEvent(
        BleHandshakeEvent.error('Unexpected passkey response: $status'),
      );
    }
  }

  void _emitStateChange([String? message]) {
    _emitEvent(
      BleHandshakeEvent(
        BleHandshakeEventType.stateChanged,
        state: currentBleState.value,
        message: message,
      ),
    );
  }

  void _emitEvent(BleHandshakeEvent event) {
    if (_handshakeController.isClosed) {
      return;
    }
    _handshakeController.add(event);
  }

  @override
  void onClose() {
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

/// ---------------- Enums retained from the legacy implementation ----------------

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
  //used for connection
  none,
  requestedPasskey,
  passkeyEntered,
  reqEncryptionKey,
  timeOut,
  sendingAuthMessage,
  connected,

  //used for create project
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

  // Large packet states
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

  // expander pass key
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
