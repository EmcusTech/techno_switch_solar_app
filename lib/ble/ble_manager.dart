import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'ble_frame.dart';
import 'aes_key.dart' as aes;
import 'ble_process.dart';
import 'dart:typed_data';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/l_bus_payload_config.dart';

const int BLE_FAILED = 0;
const int BLE_SUCCESS = 1;

const int enBLE_SOF_MSB = 0xAA;
const int enBLE_SOF_LSB = 0x55;
const int enBLE_EOF_MSB = 0xEE;
const int enBLE_EOF_LSB = 0xBB;

const int enBLE_SOF_MSB_POS = 0;
const int enBLE_SOF_LSB_POS = 1;
const int enBLE_CMD_MSB_POS = 2;
const int enBLE_CMD_LSB_POS = 3;
const int enBLE_TOF_POS = 4;
const int enBLE_DATA_LEN_MSB_POS = 5;
const int enBLE_DATA_LEN_LSB_POS = 6;
const int enBLE_DATA_POS = 7;

const int BLE_FRAME_FILED_SIZE = 11; // total overhead for frame

enum BleStates {
  REQ_ENCY_KEY,
  SEND_AUTHN_MSG,
  PROCESS_PANEL_EVT_LOG_READ,
  PROCESS_WAIT_RSP,
  IDLE,
  SEND_START_FIRMWARE_PACKET,
  SEND_END_FIRMWARE_PACKET,
  SEND_FIRMWARE_PACKET,
  SEND_JUMP_FIRMWARE_PACKET,
  SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET,
  SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET,
  SEND_INPUT_SETUP_CMD_FETCH_PACKET,
  SEND_INPUT_SETUP_CMD_APPLY_PACKET,
  SEND_RELAY_SETUP_CMD_FETCH_PACKET,
  SEND_RELAY_SETUP_CMD_APPLY_PACKET,
  SEND_ZONE_SETUP_CMD_FETCH_PACKET,
  SEND_ZONE_SETUP_CMD_APPLY_PACKET,
  SEND_RADIO_SETUP_CMD_FETCH_PACKET,
  SEND_RADIO_SETUP_CMD_APPLY_PACKET,
  SEND_MODULE_SETUP_CMD_FETCH_PACKET,
  SEND_L_BUS_SETUP_CMD_FETCH_PACKET,
  SEND_L_BUS_SETUP_CMD_APPLY_PACKET,
  SEND_SOUNDER_SETUP_CMD_FETCH_PACKET,
  SEND_SOUNDER_SETUP_CMD_APPLY_PACKET,
  // add other states
}

enum DeviceConnectState { notConnected, registerNotifyHandler, running }

enum OtaProcessState {
  sendNetworkPacket,
  sendPollPacket,
  sendAccessKeyPacket,
  sendControlCmdPacket,
  sendStopCntrlCmdPkt,
  sendContinuousPollPacket,
  otaWaitRsp,
  notInUse,
  sendExtOutSetupFetchCmdPkt,
  sendExtOutSetupApplyCmdPkt,
  sendDipSettingFetchCmd,
  sendInputSetupFetchCmdPkt,
  sendInputSetupApplyCmdPkt,
  sendRelaySetupFetchCmdPkt,
  sendRelaySetupApplyCmdPkt,
  sendZoneSetupFetchCmdPkt,
  sendZoneSetupApplyCmdPkt,
  sendRadioSetupFetchCmdPkt,
  sendRadioSetupApplyCmdPkt,
  sendModuleSetupFetchCmdPkt,
  sendLBusSetupFetchCmdPkt,
  sendLBusSetupApplyCmdPkt,
  sendSounderSetupFetchCmdPkt,
  sendSounderSetupApplyCmdPkt,
}

enum BleOperationMode {
  none, // No active operation
  firmwareUpgrade, // Firmware upgrade in progress
  logRetrieval, // Event log retrieval in progress
  extOutFetch,
  extOutApply,
  inputSetupFetch,
  inputSetupApply,
  relaySetupFetch,
  relaySetupApply,
  zoneSetupFetch,
  zoneSetupApply,
  radioSetupFetch,
  radioSetupApply,
  moduleSetupFetch,
  lBusSetupFetch,
  lBusSetupApply,
  sounderSetupFetch,
  sounderSetupApply,
}

const String BLE_AUTHN_MSG = "TECHNOSWITCH-AUTH-APP";

class BleManager {
  int u8TxPktCnt = 0;
  int u8RxPktCnt = 0;
  // BLE state variables
  BleStates bleCurrentState = BleStates.REQ_ENCY_KEY;
  BleStates bleStateMachineState = BleStates.REQ_ENCY_KEY;

  // Operation mode tracking
  BleOperationMode currentOperationMode = BleOperationMode.none;

  Map<String, dynamic> bleAESKey = {};
  BleRxFrame bleRxFrame = BleRxFrame();
  int txData = 0;

  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();

  final Uuid serviceUuid = Uuid.parse("D973F2F0-B19E-11E2-9E96-0800200C9A66");
  final Uuid notifyUuid = Uuid.parse("D973F2F1-B19E-11E2-9E96-0800200C9A66");
  final Uuid writeUuid = Uuid.parse("D973F2F2-B19E-11E2-9E96-0800200C9A66");

  DiscoveredDevice? selectedDevice;
  QualifiedCharacteristic? notifyChar;
  QualifiedCharacteristic? writeChar;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  // Prevent duplicate poll writes while waiting for notify
  bool _pollInFlight = false;
  int receivedPollCount = 0;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  bool _connectedOnce = false;
  // ignore: unused_field
  bool _isGattConnected = false;
  StreamSubscription<List<int>>? _notifySub;
  bool isBleDisconnected = true;
  bool isLogRetrievalDoneOnce = false;

  // BLE state machine
  late BleProcess bleProcess;

  BleManager() {
    flutterReactiveBle.logLevel = LogLevel.verbose;
    bleProcess = BleProcess(this);
  }

  ValueNotifier<String> get processDesc => bleProcess.processDesc;

  ValueNotifier<bool> get maxBleConnectionRetriesReached =>
      bleProcess.maxBleConnectionRetriesReached;

  ValueNotifier<bool> get maxOtherPacketsRetriesReached =>
      bleProcess.maxOtherPacketsRetriesReached;

  ValueNotifier<String> get connectedDeviceId => bleProcess.connectedDeviceId;

  ValueNotifier<String> get panelName => bleProcess.panelName;

  final ValueNotifier<bool> _isConnectedNotifier = ValueNotifier<bool>(false);

  ValueNotifier<bool> get isConnectedNotifier => _isConnectedNotifier;

  /// True when encryption + auth handshake is complete. UI should keep connection
  /// popup visible and disable tiles until this is true.
  final ValueNotifier<bool> handshakeCompleteNotifier = ValueNotifier<bool>(
    false,
  );

  /// BLE firmware version from encryption key response payload (e.g. "00.00.0001")
  final ValueNotifier<String> bleFirmwareVersion = ValueNotifier<String>('');

  Completer<void>? _handshakeCompleter;

  bool get isConnected => _isConnectedNotifier.value;

  // Hold onto the connected BluetoothDevice so any screen can disconnect cleanly
  final ValueNotifier<fbp.BluetoothDevice?> connectedBtDevice =
      ValueNotifier<fbp.BluetoothDevice?>(null);

  ValueNotifier<String> get accessKey => bleProcess.accessKey;

  ValueNotifier<bool?> get isAccessKeyValid => bleProcess.isAccessKeyValid;

  ValueNotifier<int> get bleManufacturerData => bleProcess.bleManufacturerData;

  ValueNotifier<String> get extZoneMode => bleProcess.extZoneMode;

  ValueNotifier<int> get extZoneActuatorType => bleProcess.extZoneActuatorType;

  ValueNotifier<int> get extZoneFunction => bleProcess.extZoneFunction;

  ValueNotifier<int> get extZoneCountdownAuto =>
      bleProcess.extZoneCountdownAuto;

  ValueNotifier<int> get extZoneCountdownMan => bleProcess.extZoneCountdownMan;

  ValueNotifier<int> get extZoneReleaseTime => bleProcess.extZoneReleaseTime;

  ValueNotifier<int> get extZoneResetDelay => bleProcess.extZoneResetDelay;

  ValueNotifier<int> get extZoneAction => bleProcess.extZoneAction;

  ValueNotifier<String> get extZoneText => bleProcess.extZoneText;

  ValueNotifier<int> get isExtZoneEnabled => bleProcess.isExtZoneEnabled;

  ValueNotifier<int> get extZoneHoldMode => bleProcess.extZoneHoldMode;

  ValueNotifier<int> get isResetAllowed => bleProcess.isResetAllowed;

  ValueNotifier<int> get inputSetupGroup => bleProcess.inputSetupGroup;

  ValueNotifier<int> get inputSetupFunction => bleProcess.inputSetupFunction;

  ValueNotifier<bool> get isInputSetupEnabled => bleProcess.isInputSetupEnabled;

  ValueNotifier<bool> get isInputSetupTest => bleProcess.isInputSetupTest;

  ValueNotifier<bool> get isInputSetupInverted =>
      bleProcess.isInputSetupInverted;

  ValueNotifier<String> get inputSetupText => bleProcess.inputSetupText;

  ValueNotifier<String> get inputMode => bleProcess.inputMode;

  ValueNotifier<bool> get isRelayOneSetupEnabled =>
      bleProcess.isRelayOneSetupEnabled;
  ValueNotifier<bool> get isRelayOneSetupTest => bleProcess.isRelayOneSetupTest;
  ValueNotifier<String> get relayOneSetupOutputText =>
      bleProcess.relayOneSetupOutputText;
  ValueNotifier<String> get relayOneSetupDynamicText =>
      bleProcess.relayOneSetupDynamicText;
  ValueNotifier<int> get relayOneSetupGroup => bleProcess.relayOneSetupGroup;
  ValueNotifier<int> get relayOneSetupFunction =>
      bleProcess.relayOneSetupFunction;
  ValueNotifier<bool> get isRelayTwoSetupEnabled =>
      bleProcess.isRelayTwoSetupEnabled;
  ValueNotifier<bool> get isRelayTwoSetupTest => bleProcess.isRelayTwoSetupTest;
  ValueNotifier<String> get relayTwoSetupOutputText =>
      bleProcess.relayTwoSetupOutputText;
  ValueNotifier<String> get relayTwoSetupDynamicText =>
      bleProcess.relayTwoSetupDynamicText;
  ValueNotifier<int> get relayTwoSetupGroup => bleProcess.relayTwoSetupGroup;
  ValueNotifier<int> get relayTwoSetupFunction =>
      bleProcess.relayTwoSetupFunction;
  ValueNotifier<bool> get isRelayThreeSetupEnabled =>
      bleProcess.isRelayThreeSetupEnabled;
  ValueNotifier<bool> get isRelayThreeSetupTest =>
      bleProcess.isRelayThreeSetupTest;
  ValueNotifier<String> get relayThreeSetupOutputText =>
      bleProcess.relayThreeSetupOutputText;
  ValueNotifier<String> get relayThreeSetupDynamicText =>
      bleProcess.relayThreeSetupDynamicText;
  ValueNotifier<int> get relayThreeSetupGroup =>
      bleProcess.relayThreeSetupGroup;
  ValueNotifier<int> get relayThreeSetupFunction =>
      bleProcess.relayThreeSetupFunction;

  ValueNotifier<String> get relayOneMode => bleProcess.relayOneMode;

  ValueNotifier<String> get relayTwoMode => bleProcess.relayTwoMode;

  ValueNotifier<String> get relayThreeMode => bleProcess.relayThreeMode;

  ValueNotifier<bool> get isZoneOneSetupEnabled =>
      bleProcess.isZoneOneSetupEnabled;
  ValueNotifier<bool> get isZoneOneSetupTest => bleProcess.isZoneOneSetupTest;
  ValueNotifier<String> get zoneOneSetupText => bleProcess.zoneOneSetupText;
  ValueNotifier<int> get zoneOneSetupType => bleProcess.zoneOneSetupType;
  ValueNotifier<int> get zoneOneSetupDetectionMode =>
      bleProcess.zoneOneSetupDetectionMode;
  ValueNotifier<String> get zoneOneSetupMode => bleProcess.zoneOneSetupMode;
  ValueNotifier<String> get zoneOneSetupVerificationTime =>
      bleProcess.zoneOneSetupVerificationTime;

  ValueNotifier<bool> get isZoneTwoSetupEnabled =>
      bleProcess.isZoneTwoSetupEnabled;
  ValueNotifier<bool> get isZoneTwoSetupTest => bleProcess.isZoneTwoSetupTest;
  ValueNotifier<String> get zoneTwoSetupText => bleProcess.zoneTwoSetupText;
  ValueNotifier<int> get zoneTwoSetupType => bleProcess.zoneTwoSetupType;
  ValueNotifier<int> get zoneTwoSetupDetectionMode =>
      bleProcess.zoneTwoSetupDetectionMode;
  ValueNotifier<String> get zoneTwoSetupMode => bleProcess.zoneTwoSetupMode;
  ValueNotifier<String> get zoneTwoSetupVerificationTime =>
      bleProcess.zoneTwoSetupVerificationTime;

  ValueNotifier<bool> get isZoneThreeSetupEnabled =>
      bleProcess.isZoneThreeSetupEnabled;
  ValueNotifier<bool> get isZoneThreeSetupTest =>
      bleProcess.isZoneThreeSetupTest;
  ValueNotifier<String> get zoneThreeSetupText => bleProcess.zoneThreeSetupText;
  ValueNotifier<int> get zoneThreeSetupType => bleProcess.zoneThreeSetupType;
  ValueNotifier<int> get zoneThreeSetupDetectionMode =>
      bleProcess.zoneThreeSetupDetectionMode;
  ValueNotifier<String> get zoneThreeSetupMode => bleProcess.zoneThreeSetupMode;
  ValueNotifier<String> get zoneThreeSetupVerificationTime =>
      bleProcess.zoneThreeSetupVerificationTime;
  ValueNotifier<bool> get isZoneSetupFetchCommandActive =>
      bleProcess.isZoneSetupFetchCommandActive;
  ValueNotifier<bool> get isRadioSetupFetchCommandActive =>
      bleProcess.isRadioSetupFetchCommandActive;
  ValueNotifier<bool> get isRadioSetupEnabled => bleProcess.isRadioSetupEnabled;
  ValueNotifier<int> get radioSetupModule => bleProcess.radioSetupModule;
  ValueNotifier<String> get radioSetupName => bleProcess.radioSetupName;
  ValueNotifier<String> get radioSetupNo => bleProcess.radioSetupNo;
  ValueNotifier<bool> get isRadioSetupBooted => bleProcess.isRadioSetupBooted;
  ValueNotifier<bool> get isRadioSetupProgrammed =>
      bleProcess.isRadioSetupProgrammed;
  ValueNotifier<bool> get isRadioSetupServiced =>
      bleProcess.isRadioSetupServiced;
  ValueNotifier<bool> get isRadioSetupAdvertised =>
      bleProcess.isRadioSetupAdvertised;
  ValueNotifier<bool> get isRadioSetupConnected =>
      bleProcess.isRadioSetupConnected;
  ValueNotifier<bool> get isRadioSetupCommandApplyActive =>
      bleProcess.isRadioSetupCommandApplyActive;

  ValueNotifier<bool> get isModuleSetupFetchCommandActive =>
      bleProcess.isModuleSetupFetchCommandActive;

  ValueNotifier<int> get moduleNo => bleProcess.moduleNo;
  ValueNotifier<bool> get moduleEnabled => bleProcess.moduleEnabled;
  ValueNotifier<String> get moduleProduct => bleProcess.moduleProduct;
  ValueNotifier<int> get moduleId => bleProcess.moduleId;
  ValueNotifier<int> get moduleRevision => bleProcess.moduleRevision;
  ValueNotifier<String> get moduleHardware => bleProcess.moduleHardware;
  ValueNotifier<String> get moduleFirmware => bleProcess.moduleFirmware;
  ValueNotifier<String> get moduleDate => bleProcess.moduleDate;
  ValueNotifier<int> get moduleProtocol => bleProcess.moduleProtocol;
  ValueNotifier<bool> get isLBusSetupFetchCommandActive =>
      bleProcess.isLBusSetupFetchCommandActive;
  ValueNotifier<List<LBusSetupData>> get lBusSetupDataList =>
      bleProcess.lBusSetupDataList;
  ValueNotifier<bool> get isLBusSetupApplyCommandActive =>
      bleProcess.isLBusSetupApplyCommandActive;

  ValueNotifier<int> get sounderOneRelayFunctionGroup =>
      bleProcess.sounderOneRelayFunctionGroup;
  ValueNotifier<int> get sounderOneRelayFunction =>
      bleProcess.sounderOneRelayFunction;
  ValueNotifier<int> get sounderOneFunctionNo =>
      bleProcess.sounderOneFunctionNo;
  ValueNotifier<String> get sounderOneOutputText =>
      bleProcess.sounderOneOutputText;

  ValueNotifier<int> get sounderTwoRelayFunctionGroup =>
      bleProcess.sounderTwoRelayFunctionGroup;
  ValueNotifier<int> get sounderTwoRelayFunction =>
      bleProcess.sounderTwoRelayFunction;
  ValueNotifier<int> get sounderTwoFunctionNo =>
      bleProcess.sounderTwoFunctionNo;
  ValueNotifier<String> get sounderTwoOutputText =>
      bleProcess.sounderTwoOutputText;

  ValueNotifier<int> get sounderThreeRelayFunctionGroup =>
      bleProcess.sounderThreeRelayFunctionGroup;
  ValueNotifier<int> get sounderThreeRelayFunction =>
      bleProcess.sounderThreeRelayFunction;
  ValueNotifier<int> get sounderThreeFunctionNo =>
      bleProcess.sounderThreeFunctionNo;
  ValueNotifier<String> get sounderThreeOutputText =>
      bleProcess.sounderThreeOutputText;

  ValueNotifier<bool> get isSounderOneEnabled => bleProcess.isSounderOneEnabled;
  ValueNotifier<bool> get isSounderOneTest => bleProcess.isSounderOneTest;
  ValueNotifier<bool> get isSounderOneNormal => bleProcess.isSounderOneNormal;
  ValueNotifier<bool> get isSounderTwoEnabled => bleProcess.isSounderTwoEnabled;
  ValueNotifier<bool> get isSounderTwoTest => bleProcess.isSounderTwoTest;
  ValueNotifier<bool> get isSounderTwoNormal => bleProcess.isSounderTwoNormal;
  ValueNotifier<bool> get isSounderThreeEnabled =>
      bleProcess.isSounderThreeEnabled;
  ValueNotifier<bool> get isSounderThreeTest => bleProcess.isSounderThreeTest;
  ValueNotifier<bool> get isSounderThreeNormal =>
      bleProcess.isSounderThreeNormal;

  ValueNotifier<bool> get isSounderGeneralEnabled =>
      bleProcess.isSounderGeneralEnabled;
  ValueNotifier<bool> get isSounderGeneralTest =>
      bleProcess.isSounderGeneralTest;
  ValueNotifier<int> get sounderGeneralAction =>
      bleProcess.sounderGeneralAction;
  ValueNotifier<bool> get isSounderGeneralDelay =>
      bleProcess.isSounderGeneralDelay;
  ValueNotifier<int> get sounderGeneralDelay => bleProcess.sounderGeneralDelay;

  ValueNotifier<bool> get isZoneOneEnabled => bleProcess.isZoneOneEnabled;
  ValueNotifier<bool> get isZoneOneTest => bleProcess.isZoneOneTest;
  ValueNotifier<int> get zoneOneAction => bleProcess.zoneOneAction;
  ValueNotifier<bool> get isZoneTwoEnabled => bleProcess.isZoneTwoEnabled;
  ValueNotifier<bool> get isZoneTwoTest => bleProcess.isZoneTwoTest;
  ValueNotifier<int> get zoneTwoAction => bleProcess.zoneTwoAction;
  ValueNotifier<bool> get isZoneThreeEnabled => bleProcess.isZoneThreeEnabled;
  ValueNotifier<bool> get isZoneThreeTest => bleProcess.isZoneThreeTest;
  ValueNotifier<int> get zoneThreeAction => bleProcess.zoneThreeAction;
  ValueNotifier<bool> get isExtOutOneEnabled => bleProcess.isExtOutOneEnabled;
  ValueNotifier<bool> get isExtOutOneTest => bleProcess.isExtOutOneTest;
  ValueNotifier<int> get extoutOneCountdownAction =>
      bleProcess.extoutOneCountdownAction;
  ValueNotifier<int> get extoutOneHoldAction => bleProcess.extoutOneHoldAction;
  ValueNotifier<int> get extoutOneReleaseAction =>
      bleProcess.extoutOneReleaseAction;
  ValueNotifier<bool> get isExtOutTwoEnabled => bleProcess.isExtOutTwoEnabled;
  ValueNotifier<bool> get isExtOutTwoTest => bleProcess.isExtOutTwoTest;
  ValueNotifier<int> get extoutTwoCountdownAction =>
      bleProcess.extoutTwoCountdownAction;
  ValueNotifier<int> get extoutTwoHoldAction => bleProcess.extoutTwoHoldAction;
  ValueNotifier<int> get extoutTwoReleaseAction =>
      bleProcess.extoutTwoReleaseAction;
  ValueNotifier<bool> get isExtOutThreeEnabled =>
      bleProcess.isExtOutThreeEnabled;
  ValueNotifier<bool> get isExtOutThreeTest => bleProcess.isExtOutThreeTest;
  ValueNotifier<int> get extoutThreeCountdownAction =>
      bleProcess.extoutThreeCountdownAction;
  ValueNotifier<int> get extoutThreeHoldAction =>
      bleProcess.extoutThreeHoldAction;
  ValueNotifier<int> get extoutThreeReleaseAction =>
      bleProcess.extoutThreeReleaseAction;

  ValueNotifier<String> get sounderOneRelayOutputMode =>
      bleProcess.sounderOneRelayOutputMode;
  ValueNotifier<String> get sounderTwoRelayOutputMode =>
      bleProcess.sounderTwoRelayOutputMode;
  ValueNotifier<String> get sounderThreeRelayOutputMode =>
      bleProcess.sounderThreeRelayOutputMode;

  void resetProtocolState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolExtOutState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolInputSetupState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolRelaySetupState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolZoneSetupState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolRadioSetupState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolModuleSetupState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolLBusSetupState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolSounderSetupState() {
    // Packet counters
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;

    // Poll guards
    _pollInFlight = false;

    // OTA state
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetFirmwareState() {
    bleCurrentState = BleStates.SEND_START_FIRMWARE_PACKET;
    bleStateMachineState = BleStates.SEND_START_FIRMWARE_PACKET;
    currentOperationMode = BleOperationMode.firmwareUpgrade;
  }

  void setFirmwareState(BleStates state) {
    bleCurrentState = state;
    bleStateMachineState = state;
    currentOperationMode = BleOperationMode.firmwareUpgrade;
  }

  /// Reset log retrieval protocol state
  /// This resets the BLE state machine to initial state for log retrieval
  void resetLogRetrievalState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.logRetrieval;
  }

  void resetExtOutState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.extOutFetch;
  }

  void resetInputSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.inputSetupFetch;
  }

  void resetRelaySetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.relaySetupFetch;
  }

  void resetRadioSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.radioSetupFetch;
  }

  void resetModuleSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.moduleSetupFetch;
  }

  void resetLBusSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.lBusSetupFetch;
  }

  void resetZoneSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.zoneSetupFetch;
  }

  void resetSounderSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.sounderSetupFetch;
  }

  /// Initialize and start log retrieval process
  /// Call this method when you want to start log retrieval after connection
  /// This will reset the protocol state and begin the encryption handshake
  Future<void> startLogRetrieval() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.logRetrieval;

    // Reset protocol state to initial values
    resetLogRetrievalState();
    resetProtocolState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessState();

    // Handshake (encryption + auth) is done at connection time - proceed directly
    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with log retrieval");
    bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
    bleStateMachineState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startExtOutFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.extOutFetch;

    // Reset protocol state to initial values
    resetExtOutState();
    resetProtocolExtOutState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessExtOutState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with ext out fetch");
    bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startExtOutApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.extOutApply;

    // Reset protocol state to initial values
    resetExtOutState();
    resetProtocolExtOutState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessExtOutState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with ext out apply");
    bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startInputSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.inputSetupFetch;

    // Reset protocol state to initial values
    resetInputSetupState();
    resetProtocolInputSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessInputSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with input setup fetch");
    bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startInputSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.inputSetupApply;

    // Reset protocol state to initial values
    resetInputSetupState();
    resetProtocolInputSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessInputSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with input setup apply");
    bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRelaySetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.relaySetupFetch;

    // Reset protocol state to initial values
    resetRelaySetupState();
    resetProtocolRelaySetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessRelaySetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with relay setup fetch");
    bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRelaySetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.relaySetupApply;

    // Reset protocol state to initial values
    resetRelaySetupState();
    resetProtocolRelaySetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessRelaySetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with relay setup apply");
    bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startZoneSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.zoneSetupFetch;

    // Reset protocol state to initial values
    resetZoneSetupState();
    resetProtocolZoneSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessZoneSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with zone setup fetch");
    bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startZoneSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.zoneSetupApply;

    // Reset protocol state to initial values
    resetRelaySetupState();
    resetProtocolZoneSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessZoneSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with zone setup apply");
    bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRadioSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.radioSetupFetch;

    // Reset protocol state to initial values
    resetRadioSetupState();
    resetProtocolRadioSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessRadioSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with radio setup fetch");
    bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRadioSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.radioSetupApply;

    // Reset protocol state to initial values
    resetRadioSetupState();
    resetProtocolRadioSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessRadioSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with radio setup apply");
    bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startModuleSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.moduleSetupFetch;

    // Reset protocol state to initial values
    resetModuleSetupState();
    resetProtocolModuleSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessModuleSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with module setup fetch");
    bleCurrentState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startLBusSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.lBusSetupFetch;

    // Reset protocol state to initial values
    resetLBusSetupState();
    resetProtocolLBusSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessLBusSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with L-Bus setup fetch");
    bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startLBusSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.lBusSetupApply;

    // Reset protocol state to initial values
    resetLBusSetupState();
    resetProtocolLBusSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessLBusSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with L-Bus setup apply");
    bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startSounderSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.sounderSetupFetch;

    // Reset protocol state to initial values
    resetSounderSetupState();
    resetProtocolSounderSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessSounderSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with Sounder setup fetch");
    bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startSounderSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    // Set operation mode to log retrieval
    currentOperationMode = BleOperationMode.sounderSetupApply;

    // Reset protocol state to initial values
    resetSounderSetupState();
    resetProtocolSounderSetupState();

    // IMPORTANT: Reset process state to clear isOtaCompleted flag
    // This ensures polls aren't blocked after firmware upgrade
    bleProcess.resetProcessSounderSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }
    print("Proceeding with Sounder setup apply");
    bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }
  // Future<void> startExtOut() async {
  //   if (!isConnected) {
  //     throw Exception("Device not connected. Cannot start log retrieval.");
  //   }

  //   if (notifyChar == null || writeChar == null) {
  //     throw Exception(
  //       "BLE characteristics not initialized. Cannot start log retrieval.",
  //     );
  //   }

  //   // Set operation mode to log retrieval
  //   currentOperationMode = BleOperationMode.extOut;

  //   // Reset protocol state to initial values
  //   resetExtOutState();
  //   resetProtocolExtOutState();

  //   // IMPORTANT: Reset process state to clear isOtaCompleted flag
  //   // This ensures polls aren't blocked after firmware upgrade
  //   bleProcess.resetProcessExtOutState();

  //   // Always ensure notify handler is registered (especially after reconnection)
  //   // Check if subscription is null or if log retrieval hasn't been done once
  //   if (_notifySub == null) {
  //     print("Registering notify handler for ext out");
  //     await registerNotifyHandler(isExtOut: true);
  //     // Give a small delay after registration to ensure subscription is active
  //     await Future.delayed(const Duration(milliseconds: 200));
  //   } else {
  //     print("Notify handler already registered, proceeding with ext out");
  //     bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_PACKET;
  //     bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_PACKET;
  //     print("Current state: $bleStateMachineState");
  //     // Send Network Packet
  //     bleProcess.startOtherPacketsRxTimeout(
  //       timeout: const Duration(seconds: 5),
  //     );
  //     Get.find<BleLogController>().sendExtOutApplyCommand();
  //   }
  // }

  Future<void> safeDisconnect() async {
    final deviceId = connectedDeviceId.value;
    if (deviceId.isEmpty) return;

    try {
      bleProcess.cancelRxTimeout();
      await disconnectHandler(deviceId: deviceId);
    } catch (e) {
      debugPrint("Safe disconnect failed: $e");
    } finally {
      connectedDeviceId.value = "";
    }
  }

  /// SCAN & CONNECT
  Future<void> connectToKnownDevice({
    int maxRetries = 10,
    Duration retryDelay = const Duration(seconds: 1),
    Duration connectionTimeout = const Duration(seconds: 10),
    required DiscoveredDevice device,
    int? manufacturerDataOverride,
    bool skipConnectionHandshake = false,
  }) async {
    int attempt = 0;

    print("Attempting to connect to device: ${device.id}");

    if (isConnected) {
      print("Return from here");
      shutdown();
      return;
    }

    while (attempt < maxRetries) {
      maxBleConnectionRetriesReached.value = false;
      attempt++;
      print("BLE connect attempt $attempt / $maxRetries");

      try {
        selectedDevice = device;
        // Keep a handle to the actual BluetoothDevice (fallback to fromId when not present)
        connectedBtDevice.value =
            device.device ?? fbp.BluetoothDevice.fromId(device.id);
        // Reset connection flag before each attempt to ensure completer gets completed
        _connectedOnce = false;
        await _connectOnce(
          device,
          manufacturerDataOverride: manufacturerDataOverride,
          connectionTimeout: connectionTimeout,
          skipConnectionHandshake: skipConnectionHandshake,
        );
        print("BLE connected successfully");
        return; // ✅ SUCCESS
      } catch (e) {
        print("BLE attempt $attempt failed: $e");

        await _notifySub?.cancel();
        await _connectionSub?.cancel();

        _notifySub = null;
        _connectionSub = null;
        _connectedOnce = false;
        _isGattConnected = false;
        selectedDevice = null;

        // ---- RESET PROTOCOL STATE ----
        resetLogRetrievalState();

        if (attempt >= maxRetries) {
          print("Max BLE retry attempts reached");
          processDesc.value =
              "Max BLE retry attempts reached, please scan again and connect.";
          maxBleConnectionRetriesReached.value = true;
          rethrow;
        }

        // BLE stack cooldown (important)
        if (retryDelay > Duration.zero) {
          await Future.delayed(retryDelay);
        }
      }
    }
  }

  Future<void> _refreshGattIfNeeded(String deviceId) async {
    //Only works in Android
    if (!Platform.isAndroid) return;

    try {
      print("Clearing GATT cache...");
      await flutterReactiveBle.clearGattCache(deviceId);
      print("GATT cache cleared");
    } catch (e) {
      print("GATT cache clear failed: $e");
    }
  }

  Future<void> _connectOnce(
    DiscoveredDevice device, {
    int? manufacturerDataOverride,
    Duration connectionTimeout = const Duration(seconds: 10),
    bool skipConnectionHandshake = false,
  }) async {
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan, // still required on Android 12+
      Permission.location,
    ].request();

    if (await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      throw Exception("Bluetooth permissions not granted");
    }

    final Completer<void> connectedCompleter = Completer();

    // IMPORTANT: Store manufacturer data from scan result BEFORE connecting
    // Manufacturer data is only available from scan results in flutter_blue_plus,
    // not from connected devices. If device.manufacturerData is empty, try to
    // get it from selectedDevice if available, or use override if provided
    List<int> md = device.manufacturerData;
    print(
      "DEBUG CONNECTION: Device manufacturer data - Full array: $md, Length: ${md.length}",
    );

    if (manufacturerDataOverride != null) {
      md = [manufacturerDataOverride];
      print(
        "DEBUG CONNECTION: Using manufacturer data override: $manufacturerDataOverride (as array: $md)",
      );
    } else if (md.isEmpty &&
        selectedDevice != null &&
        selectedDevice!.id == device.id) {
      md = selectedDevice!.manufacturerData;
      print(
        "DEBUG CONNECTION: Using manufacturer data from selectedDevice - Full array: $md, Length: ${md.length}, Last byte: ${md.isNotEmpty ? md.last : 0}",
      );
    } else if (md.isEmpty) {
      print(
        "DEBUG CONNECTION: WARNING - Manufacturer data is empty for device ${device.id}, will use default 0",
      );
    }
    final lastByte = md.isNotEmpty ? md.last : 0;
    print(
      "DEBUG CONNECTION: Final manufacturer data array: $md, Last byte: $lastByte",
    );

    _connectionSub = flutterReactiveBle
        .connectToDevice(id: device.id, connectionTimeout: connectionTimeout)
        .listen(
          (update) async {
            print("Connection state: ${update.connectionState}");

            if (update.connectionState == DeviceConnectionState.connected) {
              // Use the manufacturer data we preserved from scan result
              print(
                "DEBUG CONNECTION: Setting bleManufacturerData - Full array: $md, Last byte: $lastByte",
              );
              bleManufacturerData.value = lastByte;
              print(
                "DEBUG CONNECTION: bleManufacturerData.value is now: ${bleManufacturerData.value}",
              );
              _isConnectedNotifier.value = true;
              isBleDisconnected = false;
              connectedDeviceId.value = device.id;
              _isGattConnected = true;

              if (_connectedOnce) return;
              _connectedOnce = true;

              //Let Android finish bonding internally
              await Future.delayed(const Duration(milliseconds: 300));

              // //GATT CACHE REFRESH (Android only)
              // await _refreshGattIfNeeded(device.id);

              //Small safety delay
              // await Future.delayed(const Duration(milliseconds: 200));

              notifyChar = QualifiedCharacteristic(
                characteristicId: notifyUuid,
                serviceId: serviceUuid,
                deviceId: device.id,
              );

              writeChar = QualifiedCharacteristic(
                characteristicId: writeUuid,
                serviceId: serviceUuid,
                deviceId: device.id,
              );

              await flutterReactiveBle.requestMtu(
                deviceId: device.id,
                mtu: 256,
              );

              bleProcess.deviceConnectState =
                  DeviceConnectState.registerNotifyHandler;

              // Log retrieval will now be started manually via startLogRetrieval()
              // Removed automatic call: Get.find<BleLogController>().enableNotify();

              if (!connectedCompleter.isCompleted) {
                connectedCompleter.complete();
              }

              // await Future.delayed(const Duration(seconds: 10), () {
              //   shutdown(device.id);
              // });
            }

            if (update.connectionState == DeviceConnectionState.disconnected) {
              _isConnectedNotifier.value = false;
              handshakeCompleteNotifier.value = false;
              bleFirmwareVersion.value = '';
              isBleDisconnected = true;
              _isGattConnected = false;
              _connectedOnce = false;

              await _notifySub?.cancel();
              _notifySub = null;

              // Reset log retrieval flag so notify handler is re-registered on reconnect
              isLogRetrievalDoneOnce = false;

              // Unblock any waiters if handshake was in progress
              if (_handshakeCompleter != null &&
                  !_handshakeCompleter!.isCompleted) {
                _handshakeCompleter!.completeError(
                  Exception("Disconnected during handshake"),
                );
                _handshakeCompleter = null;
              }

              if (!connectedCompleter.isCompleted) {
                connectedCompleter.completeError(
                  Exception("Disconnected during connection"),
                );
                processDesc.value = "Disconnected during connection";
              }
            }
          },
          onError: (e) {
            if (!connectedCompleter.isCompleted) {
              connectedCompleter.completeError(e);
            }
          },
        );

    await connectedCompleter.future;

    final isBootLoaderMode = lastByte == 1;
    if (!skipConnectionHandshake && !isBootLoaderMode) {
      handshakeCompleteNotifier.value = false;
      _handshakeCompleter = Completer<void>();
      currentOperationMode = BleOperationMode.none;
      await registerNotifyHandler();
      try {
        await _handshakeCompleter!.future;
        handshakeCompleteNotifier.value = true;
      } finally {
        _handshakeCompleter = null;
      }
    } else if (isBootLoaderMode) {
      handshakeCompleteNotifier.value = true;
    }
  }

  /// REGISTER NOTIFICATIONS
  Future<void> registerNotifyHandler({
    bool? isChipInBootLoader = false,
    bool? isExtOut = false,
  }) async {
    print("Register notify handler");

    // Cancel existing subscription if any (e.g., from previous connection)
    if (_notifySub != null) {
      print("Cancelling existing notify subscription before re-registering");
      try {
        await _notifySub?.cancel();
      } catch (e) {
        print("Error cancelling existing subscription: $e");
      }
      _notifySub = null;
    }

    if (!isConnected) {
      print("Device disconnected before notification start");
      return;
    }

    if (notifyChar == null) {
      print("Notify characteristic not initialized");
      return;
    }

    try {
      // Subscribe to notifications
      _notifySub = flutterReactiveBle
          .subscribeToCharacteristic(notifyChar!)
          .listen(
            (data) => notificationHandler(Uint8List.fromList(data)),
            onError: (e) {
              print("Notification subscription error: $e");
              // Reset subscription on error so it can be re-registered
              _notifySub = null;
            },
          );

      print("Listening for notifications...");
      await Future.delayed(const Duration(milliseconds: 300));
      print("---Notification handler registered----");
      // if (isExtOut == true) {
      //   bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_PACKET;
      //   bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_PACKET;
      //   bleProcess.sendExtOutPacket();
      // } else

      if (isChipInBootLoader != true) {
        // Request encryption key for both firmware upgrade (first connection) and log retrieval
        bleProcess.requestENCKey();
      } else {
        // Bootloader mode - skip encryption key request and go directly to auth
        bleStateMachineState = BleStates.SEND_AUTHN_MSG;
        bleCurrentState = BleStates.SEND_AUTHN_MSG;
        bleProcess.sendAuthPacket();
      }
    } catch (e) {
      print("Failed to register notify handler: $e");
      _notifySub = null;
      rethrow;
    }
  }

  /// DISCONNECT
  Future<void> disconnectConnectedDevice() async {
    if (!isConnected) {
      return;
    }

    // Resolve device to disconnect (prefer the stored handle, fallback to ID)
    fbp.BluetoothDevice? device = connectedBtDevice.value;
    if (device == null && selectedDevice != null) {
      device = fbp.BluetoothDevice.fromId(selectedDevice!.id);
    }

    try {
      if (device != null) {
        print("Disconnecting device using fbp: $device");
        await device.disconnect();
      }
    } catch (e) {
      print("Error disconnecting device: $e");
    } finally {
      print("Disconnecting device finally: $device");
      final deviceId = device?.remoteId.str ?? connectedDeviceId.value;
      connectedBtDevice.value = null;
      await disconnectHandler(deviceId: deviceId);
    }
  }

  Future<void> disconnectHandler({String? deviceId}) async {
    print("Disconnecting device...");
    if (deviceId != null && deviceId.isNotEmpty) {
      //GATT CACHE REFRESH (Android only)
      await _refreshGattIfNeeded(deviceId);
    }

    await _notifySub?.cancel();
    await _connectionSub?.cancel();

    _notifySub = null;
    _connectionSub = null;

    _isGattConnected = false;
    _connectedOnce = false;
    selectedDevice = null;
    connectedBtDevice.value = null;
    _isConnectedNotifier.value = false;
    handshakeCompleteNotifier.value = false;
    bleFirmwareVersion.value = '';
  }

  /// SHUTDOWN
  Future<void> shutdown({String? deviceId}) async {
    print("Shutdown BLE");
    if (deviceId != null && deviceId.isNotEmpty) {
      //GATT CACHE REFRESH (Android only)
      await _refreshGattIfNeeded(deviceId);
    }

    // Cancel all subscriptions
    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connectionSub?.cancel();

    // Cancel any pending timeouts in BleProcess
    bleProcess.cancelRxTimeout();

    // Reset all state
    resetProtocolState();
    bleProcess.resetProcessState();

    // Reset BLE state machine
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;

    // Clear encryption key
    bleAESKey.clear();

    // Reset operation mode
    currentOperationMode = BleOperationMode.none;

    // Reset connection state
    _scanSub = null;
    _notifySub = null;
    _connectionSub = null;
    _isGattConnected = false;
    _connectedOnce = false;
    selectedDevice = null;
    notifyChar = null;
    writeChar = null;
    isBleDisconnected = true;
    _isConnectedNotifier.value = false;
    handshakeCompleteNotifier.value = false;
    bleFirmwareVersion.value = '';
    isLogRetrievalDoneOnce = false;

    if (_handshakeCompleter != null && !_handshakeCompleter!.isCompleted) {
      _handshakeCompleter!.completeError(Exception("BLE shutdown"));
      _handshakeCompleter = null;
    }
  }

  // ----------------------
  // Notification Handler
  // ----------------------

  Future<void> notificationHandler(Uint8List data) async {
    if ((bleProcess.isOtaCompleted ||
            otaProcessState == OtaProcessState.notInUse) &&
        isBleDisconnected) {
      print("RX ignored after OTA completion");
      return;
    }

    print(
      "TX/RX: --------notify received----- RX TIME:${DateTime.now().toIso8601String()}",
    );

    txData = 1;
    bleProcess.cancelRxTimeout();
    _pollInFlight = false;

    print("bleCurrentState: $bleCurrentState");
    // if (bleCurrentState == BleStates.SEND_EXT_OUT_SETUP_CMD_PACKET) {
    //   print("Ext out fetch response");
    //   print(
    //     "data: ${data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    //   );
    // } else
    if (bleCurrentState == BleStates.SEND_JUMP_FIRMWARE_PACKET) {
      print("Jump firmware packet response");
      print(
        "data: ${data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
    } else if (bleCurrentState == BleStates.SEND_START_FIRMWARE_PACKET) {
      print("Start firmware packet response");
      print("Ack/Nack: ${data[7]}");
      print(
        "data: ${data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
    } else if (bleCurrentState == BleStates.SEND_FIRMWARE_PACKET) {
      print("Firmware packet response");
      print(
        "data: ${data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
    } else if (bleCurrentState == BleStates.SEND_END_FIRMWARE_PACKET) {
      print("End firmware packet response");
      print(
        "data: ${data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
    } else if (bleCurrentState == BleStates.REQ_ENCY_KEY) {
      print("Encryption key req response");
      bleRxFrame = bleParseAndUpdateRxFrame(data, data.length);
      print(
        "SOF:${bleRxFrame.sof},${bleRxFrame.cmd},${bleRxFrame.tof},${bleRxFrame.payloadLen},${bleRxFrame.payload},${bleRxFrame.crc},${bleRxFrame.calculatedCrc},${bleRxFrame.crc},${bleRxFrame.eof}",
      );
      if (bleValidateRxFrame(bleRxFrame)) {
        print("Validation success");
        bleAESKey["AES_KEY"] = bleRxFrame.payload;
        print("Received key: ${bleAESKey['AES_KEY']}");

        // Parse BLE firmware version from payload (last 10 bytes: "XX.XX.XXXX")
        final payload = bleRxFrame.payload;
        if (payload.length >= 10) {
          final versionBytes = payload.sublist(payload.length - 10);
          final version = String.fromCharCodes(versionBytes);
          bleFirmwareVersion.value = version;
          print("BLE firmware version: $version");
        } else {
          bleFirmwareVersion.value = '';
        }

        await Future.delayed(Duration(milliseconds: 300));
        bleStateMachineState = BleStates.SEND_AUTHN_MSG;
        bleCurrentState = BleStates.SEND_AUTHN_MSG;

        print("handler bleStateMachineState: $bleStateMachineState");
        bleProcess.sendAuthPacket();
      } else {
        print("Validation failed");
      }
    } else if (bleCurrentState == BleStates.SEND_AUTHN_MSG) {
      print("Authn msg response");
      // Uint8List decryptedData = aes.aesDecrypt(bleAESKey["AES_KEY"], data);
      bleRxFrame = bleParseAndUpdateRxFrame(data, data.length);

      if (bleValidateRxFrame(bleRxFrame)) {
        print("AUTH KEY Validation success");
        await Future.delayed(Duration(seconds: 1));

        // Route to appropriate state based on operation mode
        if (currentOperationMode == BleOperationMode.none) {
          // Connection handshake complete - device ready for operations
          bleCurrentState = BleStates.IDLE;
          bleStateMachineState = BleStates.IDLE;
          print("Connection handshake complete - device ready for operations");
          if (_handshakeCompleter != null &&
              !_handshakeCompleter!.isCompleted) {
            _handshakeCompleter!.complete();
          }
        } else if (currentOperationMode == BleOperationMode.firmwareUpgrade) {
          // Firmware upgrade path
          bleCurrentState = BleStates.SEND_START_FIRMWARE_PACKET;
          bleStateMachineState = BleStates.SEND_START_FIRMWARE_PACKET;
          print("Current state: $bleStateMachineState (Firmware Upgrade)");
        } else if (currentOperationMode == BleOperationMode.logRetrieval) {
          // Log retrieval path
          bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
          bleStateMachineState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
          print("Current state: $bleStateMachineState (Log Retrieval)");

          // Send Network Packet for log retrieval
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.extOutFetch) {
          bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Ext Out Fetch)");
          // Send Network Packet for Ext Out Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.extOutApply) {
          bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
          print("Current state : $bleStateMachineState (Ext Out Apply)");
          // Send Network Packet for Ext Out Apply
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.inputSetupFetch) {
          bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Input Setup Fetch)");
          // Send Network Packet for Input Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.inputSetupApply) {
          bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Input Setup Apply)");
          // Send Network Packet for Input Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.relaySetupFetch) {
          bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Relay Setup Fetch)");
          // Send Network Packet for Input Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.relaySetupApply) {
          bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Relay Setup Apply)");
          // Send Network Packet for Relay Setup Apply
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.zoneSetupFetch) {
          bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Zone Setup Fetch)");
          // Send Network Packet for Zone Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.zoneSetupApply) {
          bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Zone Setup Apply)");
          // Send Network Packet for Zone Setup Apply
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.radioSetupFetch) {
          bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Radio Setup Fetch)");
          // Send Network Packet for Radio Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.radioSetupApply) {
          bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Radio Setup Apply)");
          // Send Network Packet for Radio Setup Apply
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.moduleSetupFetch) {
          bleCurrentState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Module Setup Fetch)");
          // Send Network Packet for Module Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.lBusSetupFetch) {
          bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (L-Bus Setup Fetch)");
          // Send Network Packet for L-Bus Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.lBusSetupApply) {
          bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (L-Bus Setup Apply)");
          // Send Network Packet for L-Bus Setup Apply
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.sounderSetupFetch) {
          bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Sounder Setup Fetch)");
          // Send Network Packet for Sounder Setup Fetch
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.sounderSetupApply) {
          bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Sounder Setup Apply)");
          // Send Network Packet for Sounder Setup Apply
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        }
      } else {
        print("Validation failed");
      }
    } else {
      receivedPollCount++;
      print("The Received RX count is : $receivedPollCount");
      // Uint8List decryptedData = aes.aesDecrypt(bleAESKey["AES_KEY"], data);
      bleParseAndUpdateRxFrame(data, data.length);

      if (bleValidateRxFrame(bleRxFrame)) {
        await bleProcess.bleRxFrameProcess(bleRxFrame);
      } else {
        print(
          "<<<<<<<<<<<<<<<< RECEIVED FRAME VALIDATION FAILED >>>>>>>>>>>>>>>>>>>>>>>>>>",
        );
      }
    }
  }

  // ----------------------
  // Function to register notifications
  // ----------------------
  void registerNotificationListener(characteristic) {
    characteristic.value.listen((data) async {
      await notificationHandler(data);
    });
  }

  // other BLE functions: connect, write, send frame, etc.

  /// HANDLERS FOR BLE STATE MACHINE
  OtaProcessState otaProcessState = OtaProcessState.sendNetworkPacket;

  int toolsFletcherChecksum(List<int> buffer) {
    int length = buffer.length;
    if (length == 0) return 0;

    int sum1 = 0;
    int sum2 = 0;

    for (var b in buffer) {
      sum1 = (sum1 + b) % 255;
      sum2 = (sum2 + sum1) % 255;
    }

    int chk1 = (255 - ((sum1 + sum2) % 255)) & 0xFF;
    int chk2 = (255 - ((sum1 + chk1) % 255)) & 0xFF;

    return (chk1 << 8) | chk2;
  }

  List<int> convertToBytes(dynamic data) {
    if (data is List<int>) return data;
    if (data is String) return data.codeUnits;
    throw Exception("Unsupported data type for conversion to bytes");
  }

  static crcCcittFalse(
    List<int> data, {
    int poly = 0x1021,
    int initVal = 0xFFFF,
  }) {
    int crc = initVal;

    for (int byte in data) {
      crc ^= (byte << 8) & 0xFFFF;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc & 0xFFFF;
  }

  List<int> bleFrameFormat(
    int cmd,
    int typeOfFrame,
    int dataLen,
    List<int> data,
  ) {
    if (cmd <= 0 || typeOfFrame <= 0 || dataLen <= 0 || data.isEmpty) {
      return [];
    }

    List<int> frameBuff = List.filled(dataLen + BLE_FRAME_FILED_SIZE, 0);

    // Start of frame
    frameBuff[enBLE_SOF_MSB_POS] = enBLE_SOF_MSB;
    frameBuff[enBLE_SOF_LSB_POS] = enBLE_SOF_LSB;

    // Command
    frameBuff[enBLE_CMD_MSB_POS] = (cmd >> 8) & 0xFF;
    frameBuff[enBLE_CMD_LSB_POS] = cmd & 0xFF;

    // Type of frame
    frameBuff[enBLE_TOF_POS] = typeOfFrame;

    // Data length
    frameBuff[enBLE_DATA_LEN_MSB_POS] = (dataLen >> 8) & 0xFF;
    frameBuff[enBLE_DATA_LEN_LSB_POS] = dataLen & 0xFF;

    // Copy actual data
    for (int i = 0; i < dataLen; i++) {
      frameBuff[enBLE_DATA_POS + i] = data[i];
    }

    // CRC
    int crc = crcCcittFalse(frameBuff.sublist(0, enBLE_DATA_POS + dataLen));
    frameBuff[enBLE_DATA_POS + dataLen] = (crc >> 8) & 0xFF;
    frameBuff[enBLE_DATA_POS + 1 + dataLen] = crc & 0xFF;

    // End of frame
    frameBuff[enBLE_DATA_POS + 2 + dataLen] = enBLE_EOF_MSB;
    frameBuff[enBLE_DATA_POS + 3 + dataLen] = enBLE_EOF_LSB;

    return frameBuff;
  }

  Future<void> sendData(Uint8List frame, {bool encrypt = true}) async {
    if (!isConnected || writeChar == null) return;

    try {
      Uint8List dataToSend;

      //Encryption and Decryption is disabled
      // Encrypt if in proper state
      // await Future.delayed(const Duration(milliseconds: 300));
      // if (encrypt && (bleCurrentState.index > BleStates.REQ_ENCY_KEY.index)) {
      //   dataToSend = aes.aesEncrypt(bleAESKey["AES_KEY"], frame);
      //   print("Sending encrypted data: length ${dataToSend.length}");
      // } else {
      //   dataToSend = frame;
      //   print("Sending plain data: length ${dataToSend.length}");
      // }

      dataToSend = frame;
      print("Sending plain data: length ${dataToSend.length}");

      print(
        "::::::Data Written:::$dataToSend::TX Time${DateTime.now().toIso8601String()}}",
      );
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: dataToSend,
      );
    } catch (e) {
      print("Send data failed: $e");
    }
  }

  Future<void> sendSmallDataFrame(
    int cmd,
    int length,
    List<int> data, {
    bool encrypt = true,
  }) async {
    if (writeChar == null) return;

    List<int> frame = bleFrameFormat(
      cmd,
      0x01,
      length,
      data,
    ); // 0x01 is small frame type
    Uint8List frameBytes = aes.convertToBytes(frame);

    try {
      //Encrption and Decryption is disabled
      // if (encrypt) {
      //   List<int> encryptedData = aes.aesEncrypt(
      //     bleAESKey["AES_KEY"],
      //     frameBytes,
      //   );
      //   // await Future.delayed(const Duration(milliseconds: 300));
      //   print(
      //     "::::::Data Written:::$encryptedData::TX Time${DateTime.now().toIso8601String()}}",
      //   );
      //   await flutterReactiveBle.writeCharacteristicWithResponse(
      //     writeChar!,
      //     value: encryptedData,
      //   );
      // } else {
      //   print("::::::Data Written:::::");
      //   await flutterReactiveBle.writeCharacteristicWithResponse(
      //     writeChar!,
      //     value: frameBytes,
      //   );
      // }

      print("::::::Data Written:::::");
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: frameBytes,
      );
    } catch (e) {
      print("Send frame failed: $e");
    }
  }

  Future<void> sendAesKeyReq() async {
    // Build BLE frame (same as Python: ble_frame_format(0x1000, 0x01, 1, [0x00]))
    List<int> reqFrame = bleFrameFormat(0x1000, 0x01, 1, [0x00]);

    // Convert to Uint8List
    Uint8List reqFrameBytes = aes.convertToBytes(reqFrame);

    print("Framed key req Frame: $reqFrame after bytes convert $reqFrameBytes");

    print("TX/RX: TRANSMIT: enc key request : $reqFrameBytes");

    // Send using BLE
    await sendData(reqFrameBytes);
  }

  Future<void> sendAuthnMsg() async {
    if (writeChar == null) return;

    // Convert message string to bytes
    List<int> msgBytes = BLE_AUTHN_MSG.codeUnits;

    // Create BLE frame
    List<int> authnMsgFrame = bleFrameFormat(
      0x1000,
      0x02,
      msgBytes.length,
      msgBytes,
    );

    print("Framed Authn Msg: $authnMsgFrame");

    // Convert to Uint8List for BLE
    Uint8List frameBytes = Uint8List.fromList(authnMsgFrame);
    print(
      "TX/RX: TRANSMIT: Auth Frame bytes: ${frameBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    // Send using your sendData function which handles encryption
    await sendData(frameBytes);
  }

  Future<void> sendNetworkPacket() async {
    u8TxPktCnt = 0;

    List<int> u8Pkt = List.filled(216, 0);
    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x04; // pkt type
    u8Pkt[4] = 0x00; // tx pkt num
    u8Pkt[5] = 0x00; // rx pkt num
    u8Pkt[6] = 0x05; // network number
    u8Pkt[11] = 0x02; // socket number
    u8Pkt[12] = 0x01;

    // Checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));
    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Network Packet time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );
    // print(u8Pkt.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' '));

    await sendSmallDataFrame(0x1000, 216, u8Pkt); // see step 4
  }

  Future<void> sendPollPacket() async {
    if (bleProcess.isOtaCompleted &&
        otaProcessState == OtaProcessState.notInUse) {
      print("bleprocess.isOtaCompleted : ${bleProcess.isOtaCompleted}");
      print("otaProcessState : ${otaProcessState == OtaProcessState.notInUse}");
      print("Poll blocked (OTA completed / notInUse)");
      return;
    }
    // Guard: skip if a previous poll write is still awaiting notify
    if (_pollInFlight) {
      print("Skipping poll: previous write still in-flight");
      return;
    }
    _pollInFlight = true;
    // await Future.delayed(Duration(milliseconds: 200));
    // Create the 216-byte poll packet
    List<int> pollPkt = List.filled(216, 0);
    pollPkt[0] = 0xFE;
    pollPkt[1] = 0x01;
    pollPkt[2] = 0x00;

    // Update packet numbers
    pollPkt[4] = (u8TxPktCnt + 1) & 0xFF; // tx pkt num
    pollPkt[5] = (u8RxPktCnt & 0xFF); // rx pkt num
    print(
      "Sending poll pkt rx cnt pollPkt[5] value:${pollPkt[5]},u8RxPktCnt:${u8RxPktCnt}",
    );
    // Network + socket
    pollPkt[6] = 0x00; // network number
    pollPkt[11] = 0x00; // socket number

    // Compute checksum over first 213 bytes
    int checksum = toolsFletcherChecksum(pollPkt.sublist(0, 216 - 3));

    pollPkt[213] = (checksum >> 8) & 0xFF;
    pollPkt[214] = checksum & 0xFF;
    pollPkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Poll Packet time: ${DateTime.now().toIso8601String()}, packet: ${pollPkt.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   pollPkt
    //       .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, pollPkt);
  }

  // Allow BleProcess to clear in-flight on timeout
  void resetPollInFlight() {
    _pollInFlight = false;
  }

  Future<void> sendAccessKeyPkt() async {
    u8TxPktCnt += 1;

    // Create 216-byte packet
    List<int> pkt = List.filled(216, 0);
    pkt[0] = 0xFE;
    pkt[1] = 0x01;
    pkt[2] = 0x00;

    pkt[3] = 0x01; // pkt type
    pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    pkt[6] = 0x00; // network number
    pkt[10] = 0x83; // mode
    pkt[11] = 0x00; // socket number
    pkt[12] = 0x04;
    pkt[13] = 0x04;

    // "1974"
    List<int> accessKeyBytes = accessKey.value.codeUnits;
    pkt[14] = accessKeyBytes[0];
    pkt[15] = accessKeyBytes[1];
    pkt[16] = accessKeyBytes[2];
    pkt[17] = accessKeyBytes[3];

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(pkt.sublist(0, 216 - 3));

    pkt[213] = (checksum >> 8) & 0xFF;
    pkt[214] = checksum & 0xFF;
    pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Access Key Packet time: ${DateTime.now().toIso8601String()}, packet: ${pkt.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ').toString()}",
    );
    // print(
    //   pkt
    //       .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' ')
    //       .toString(),
    // );

    await sendSmallDataFrame(0x1000, 216, pkt);
  }

  Future<void> sendStartCntrlCmdPkt() async {
    // Update global counters
    u8TxPktCnt += 1;

    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);
    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x83; // mode
    u8_pkt[11] = 0x04; // socket number
    u8_pkt[12] = 0x0B; // command byte 1
    u8_pkt[13] = 0x03; // command byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Start Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendStopCntrlCmdPkt() async {
    // Update global counters
    u8TxPktCnt += 1;

    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);
    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x83; // mode
    u8_pkt[11] = 0x04; // socket number
    u8_pkt[12] = 0x0B; // command byte 1
    u8_pkt[13] = 0x03; // command byte 2
    u8_pkt[14] = 0x01; // Event Buffer Mode -> Stop

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Stop Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  /// Sends a jump firmware packet with Technoswitch framing.
  /// Uses write without response by default to avoid waiting on a rebooting device.
  Future<void> sendJumpFirmwarePacket({bool withoutResponse = true}) async {
    if (!isConnected || writeChar == null) {
      throw Exception("BLE not connected or write characteristic missing");
    }

    List<int> jumpFrame = bleFrameFormat(0x1002, 0x02, 1, [0x00]);
    try {
      if (withoutResponse) {
        await flutterReactiveBle.writeCharacteristicWithoutResponse(
          writeChar!,
          value: jumpFrame,
        );
      } else {
        await flutterReactiveBle.writeCharacteristicWithResponse(
          writeChar!,
          value: jumpFrame,
        );
      }
      print(
        "TX/RX: TRANSMIT: Jump Firmware Packet time: ${DateTime.now().toIso8601String()}, packet: ${jumpFrame.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
    } catch (e) {
      print("Send Jump firmware packet failed: $e");
      rethrow;
    }
  }

  Future<void> registerNotifyHandlerForFirmwareUpgrade({
    bool isChipInBootLoader = false,
  }) async {
    // Set operation mode before registering
    currentOperationMode = BleOperationMode.firmwareUpgrade;
    await registerNotifyHandler(isChipInBootLoader: isChipInBootLoader);
  }

  // packages/modules/Bluetooth/system/stack/include/gatt_api.h
  /// Sends a start firmware packet with Technoswitch framing.
  Future<void> sendStartFirmwarePacket() async {
    if (!isConnected || writeChar == null) {
      throw Exception("BLE not connected or write characteristic missing");
    }
    // await registerNotifyHandler(isStartFirmware: true);

    List<int> startFrame = bleFrameFormat(0x1001, 0x02, 1, [0x00]);
    print(
      "TX/RX: TRANSMIT: Start Firmware Packet time: ${DateTime.now().toIso8601String()}, packet: ${startFrame.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    try {
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: startFrame,
      );
    } catch (e) {
      print("Send firmware packet failed: Start Firmware Packet $e");
      rethrow;
    }
  }

  /// Sends a end firmware packet with Technoswitch framing.
  Future<void> sendEndFirmwarePacket() async {
    if (!isConnected || writeChar == null) {
      throw Exception("BLE not connected or write characteristic missing");
    }

    List<int> endFrame = bleFrameFormat(0x1004, 0x02, 1, [0x00]);
    try {
      print(
        "TX/RX: TRANSMIT: End Firmware Packet time: ${DateTime.now().toIso8601String()}, packet: ${endFrame.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: endFrame,
      );
    } catch (e) {
      print("Send End firmware packet failed: $e");
      rethrow;
    }
  }

  /// Sends a firmware packet directly (no Technoswitch framing).
  /// Packet must already contain the 2-byte big-endian sequence header.
  Future<void> sendFirmwarePacket(
    Uint8List packet, {
    bool? isFirstPacketAfterSkip = false,
  }) async {
    if (!isConnected || writeChar == null) {
      throw Exception("BLE not connected or write characteristic missing");
    }
    print("isFirstPacketAfterSkip: $isFirstPacketAfterSkip");

    print("packet length: ${packet.toList().length}");

    List<int> firmwareFrame = bleFrameFormat(
      isFirstPacketAfterSkip == true ? 0x1003 : 0x1002,
      0x02,
      packet.toList().length,
      packet.toList(),
    );

    try {
      print(
        "TX/RX: TRANSMIT: Firmware Packet time: ${DateTime.now().toIso8601String()}, packet: ${firmwareFrame.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: firmwareFrame,
      );
    } catch (e) {
      print("Send firmware packet failed: Firmware Packet $e");
      rethrow;
    }
  }

  /// Sends a list of firmware packets sequentially with an optional delay.
  Future<void> sendFirmwarePackets(
    List<Uint8List> packets, {
    Duration interPacketDelay = const Duration(milliseconds: 20),
    void Function(int sent, int total)? onProgress,
  }) async {
    if (!isConnected || writeChar == null) {
      throw Exception("BLE not connected or write characteristic missing");
    }

    for (int i = 0; i < packets.length; i++) {
      await sendFirmwarePacket(packets[i]);
      onProgress?.call(i + 1, packets.length);
      if (i + 1 < packets.length) {
        await Future.delayed(interPacketDelay);
      }
    }
  }

  Future<void> sendExtOutSetupFetchCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x16; // command byte 1
    u8_pkt[13] = 0x01; // ext max zone

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Ext Out Fetch command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendExtOutSetupApplyCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final int autoDelay = extZoneCountdownAuto.value;
    final int manDelay = extZoneCountdownMan.value;
    final int releasePeriod = extZoneReleaseTime.value;
    final int resetDelay = extZoneResetDelay.value;
    final String extZoneString = extZoneText.value;
    final List<int> extZoneTextBytes = extZoneString.codeUnits;
    final extZoneTextLength = extZoneTextBytes.length;

    final initialindex = 41;

    for (int i = 0; i < extZoneTextLength; i++) {
      u8_pkt[initialindex + i] = extZoneTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x16; // command byte 1
    u8_pkt[13] = 0x01; // ext max zone
    u8_pkt[14] = int.parse(extZoneMode.value, radix: 16); // ext zone mode
    u8_pkt[15] = 0x01; // ext zone trigger area
    u8_pkt[16] = extZoneActuatorType.value; // ext zone actuator type
    u8_pkt[17] =
        (autoDelay >> 8) & 0xFF; // ext zone automatic release delay first byte
    u8_pkt[18] =
        autoDelay & 0xFF; // ext zone automatic release delay second byte
    u8_pkt[19] =
        (manDelay >> 8) & 0xFF; // ext zone manual release delay first byte
    u8_pkt[20] = manDelay & 0xFF; // ext zone manual release delay second byte
    u8_pkt[21] =
        (releasePeriod >> 8) & 0xFF; // ext zone release period first byte
    u8_pkt[22] = releasePeriod & 0xFF; // ext zone release period second byte
    u8_pkt[23] = (resetDelay >> 8) & 0xFF; // ext zone reset delay first byte
    u8_pkt[24] = resetDelay & 0xFF; // ext zone reset delay second byte
    u8_pkt[25] = extZoneAction.value; // ext zone output mode
    u8_pkt[26] = extZoneFunction.value; // ext zone function
    u8_pkt[27] = 0x1E; // ext zone valve delay
    u8_pkt[28] = 0x00; // ext zone extraction time first byte
    u8_pkt[29] = 0x3C; // ext zone extraction time second byte
    u8_pkt[30] = 0x03; // ext zone extraction delay first byte
    u8_pkt[31] = 0x84; // ext zone extraction delay second byte
    u8_pkt[32] = 0x00; // ext zone line resistenace value first byte
    u8_pkt[33] = 0x00; // ext zone line resistenace value seond byte
    u8_pkt[34] = 0x00; // ext zone line resistenace value third byte
    u8_pkt[35] = 0x00; // ext zone line resistenace value fourth byte
    u8_pkt[36] = 0x00; // ext zone line resistenace fraction
    u8_pkt[37] = 0x00; // ext zone line resistenace unit
    u8_pkt[38] = 0x00; // ext zone line resistenace count first byte
    u8_pkt[39] = 0x00; // ext zone line resistenace count second byte
    u8_pkt[40] = extZoneTextLength & 0xFF; // ext zone text length

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Ext Out command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendFetchDipSettingPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x1C; // command byte 1

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Fetch Dip setting command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendInputSetupFetchCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x06; // command byte 1
    u8_pkt[13] = 0x00; // input max zone byte 1
    u8_pkt[14] = 0x01; // input max zone byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Ext Out Fetch command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendInputSetupApplyCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final int group = inputSetupGroup.value;
    final int function = inputSetupFunction.value;
    final String inputText = inputSetupText.value;
    final List<int> inputTextBytes = inputText.codeUnits;
    final inputTextLength = inputTextBytes.length;

    final initialindex = 26;

    for (int i = 0; i < inputTextLength; i++) {
      u8_pkt[initialindex + i] = inputTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x06; // command byte 1
    u8_pkt[13] = 0x00; // max inputs byte 1
    u8_pkt[14] = 0x01; // max inputs byte 1
    u8_pkt[15] = int.parse(inputMode.value, radix: 16); // input mode
    u8_pkt[16] = 0x02;
    u8_pkt[17] = 0x00;
    u8_pkt[18] = 0x00;
    u8_pkt[19] = 0x00;
    u8_pkt[20] = 0x01;
    u8_pkt[21] = 0x01;
    u8_pkt[22] = 0x01;
    u8_pkt[23] = inputSetupGroup.value;
    u8_pkt[24] = inputSetupFunction.value;
    u8_pkt[25] = inputTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Input Setup Apply command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRelaySetupFetchFirstCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command byte 1
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = 0x04; // output max zone byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Fetch First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRelaySetupFetchSecondCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command byte 1
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = 0x05; // output max zone byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Fetch Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRelaySetupFetchThirdCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command byte 1
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = 0x06; // output max zone byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Fetch Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRelaySetupApplyFirstCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String outputText = relayOneSetupOutputText.value;
    final List<int> outputTextBytes = outputText.codeUnits;
    final outputTextLength = outputTextBytes.length;

    final initialindex = 26;
    for (int i = 0; i < outputTextLength; i++) {
      u8_pkt[initialindex + i] = outputTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command byte 1
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = 0x04; // output max zone byte 2
    u8_pkt[15] = int.parse(relayOneMode.value, radix: 16);
    u8_pkt[16] = 0x01;
    u8_pkt[17] = 0x00;
    u8_pkt[18] = 0x00;
    u8_pkt[19] = 0x00;
    u8_pkt[20] = 0x03;
    u8_pkt[21] = 0x00;
    u8_pkt[22] =
        relayOneSetupDynamicText.value.isNotEmpty
            ? int.parse(relayOneSetupDynamicText.value, radix: 16)
            : 0x00;
    u8_pkt[23] = relayOneSetupGroup.value;
    u8_pkt[24] = relayOneSetupFunction.value;
    u8_pkt[25] = outputTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Apply First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRelaySetupApplySecondCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String outputText = relayTwoSetupOutputText.value;
    final List<int> outputTextBytes = outputText.codeUnits;
    final outputTextLength = outputTextBytes.length;

    final initialindex = 26;
    for (int i = 0; i < outputTextLength; i++) {
      u8_pkt[initialindex + i] = outputTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command byte 1
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = 0x05; // output max zone byte 2
    u8_pkt[15] = int.parse(relayTwoMode.value, radix: 16);
    u8_pkt[16] = 0x01;
    u8_pkt[17] = 0x00;
    u8_pkt[18] = 0x00;
    u8_pkt[19] = 0x00;
    u8_pkt[20] = 0x04;
    u8_pkt[21] = 0x00;
    u8_pkt[22] =
        relayTwoSetupDynamicText.value.isNotEmpty
            ? int.parse(relayTwoSetupDynamicText.value, radix: 16)
            : 0x00;
    u8_pkt[23] = relayTwoSetupGroup.value;
    u8_pkt[24] = relayTwoSetupFunction.value;
    u8_pkt[25] = outputTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Apply Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRelaySetupApplyThirdCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String outputText = relayThreeSetupOutputText.value;
    final List<int> outputTextBytes = outputText.codeUnits;
    final outputTextLength = outputTextBytes.length;

    final initialindex = 26;
    for (int i = 0; i < outputTextLength; i++) {
      u8_pkt[initialindex + i] = outputTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command byte 1
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = 0x06; // output max zone byte 2
    u8_pkt[15] = int.parse(relayThreeMode.value, radix: 16);
    u8_pkt[16] = 0x01;
    u8_pkt[17] = 0x00;
    u8_pkt[18] = 0x00;
    u8_pkt[19] = 0x00;
    u8_pkt[20] = 0x05;
    u8_pkt[21] = 0x00;
    u8_pkt[22] =
        relayThreeSetupDynamicText.value.isNotEmpty
            ? int.parse(relayThreeSetupDynamicText.value, radix: 16)
            : 0x00;
    u8_pkt[23] = relayThreeSetupGroup.value;
    u8_pkt[24] = relayThreeSetupFunction.value;
    u8_pkt[25] = outputTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Apply Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendZoneSetupFetchFirstCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x04; // command byte 1
    u8_pkt[13] = 0x01; // output max zone

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Fetch First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendZoneSetupFetchSecondCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x04; // command byte 1
    u8_pkt[13] = 0x02; // output max zone

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Fetch Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendZoneSetupFetchThirdCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x04; // command byte 1
    u8_pkt[13] = 0x03; // output max zone

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Fetch Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendZoneSetupApplyFirstCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String zoneText = zoneOneSetupText.value;
    final List<int> zoneTextBytes = zoneText.codeUnits;
    final zoneTextLength = zoneTextBytes.length;

    final initialindex = 19;
    for (int i = 0; i < zoneTextLength; i++) {
      u8_pkt[initialindex + i] = zoneTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x04; // command byte 1
    u8_pkt[13] = 0x01; // output max zone
    u8_pkt[14] =
        zoneOneSetupMode.value.isNotEmpty
            ? int.parse(zoneOneSetupMode.value, radix: 16)
            : 0x00;
    u8_pkt[15] = zoneOneSetupDetectionMode.value & 0xFF;
    print(
      "zoneOneSetupDetectionMode.value: ${zoneOneSetupDetectionMode.value}",
    );
    print(
      "zoneOneSetupVerificationTime.value: ${zoneOneSetupVerificationTime.value}",
    );
    u8_pkt[16] =
        zoneOneSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneOneSetupVerificationTime.value)
            : 0x00;
    u8_pkt[17] =
        zoneOneSetupDetectionMode.value == 3
            ? 0x1E
            : 0x00; // need to check this
    u8_pkt[18] = zoneTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Apply First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendZoneSetupApplySecondCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String zoneText = zoneTwoSetupText.value;
    final List<int> zoneTextBytes = zoneText.codeUnits;
    final zoneTextLength = zoneTextBytes.length;

    final initialindex = 19;
    for (int i = 0; i < zoneTextLength; i++) {
      u8_pkt[initialindex + i] = zoneTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x04; // command byte 1
    u8_pkt[13] = 0x02; // output max zone
    u8_pkt[14] =
        zoneTwoSetupMode.value.isNotEmpty
            ? int.parse(zoneTwoSetupMode.value, radix: 16)
            : 0x00;
    u8_pkt[15] = zoneTwoSetupDetectionMode.value & 0xFF;
    print(
      "zoneTwoSetupDetectionMode.value: ${zoneTwoSetupDetectionMode.value}",
    );
    print(
      "zoneTwoSetupVerificationTime.value: ${zoneTwoSetupVerificationTime.value}",
    );
    u8_pkt[16] =
        zoneTwoSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneTwoSetupVerificationTime.value)
            : 0x00;
    u8_pkt[17] =
        zoneTwoSetupDetectionMode.value == 3
            ? 0x1E
            : 0x00; // need to check this
    u8_pkt[18] = zoneTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Apply Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendZoneSetupApplyThirdCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String zoneText = zoneThreeSetupText.value;
    final List<int> zoneTextBytes = zoneText.codeUnits;
    final zoneTextLength = zoneTextBytes.length;

    final initialindex = 19;
    for (int i = 0; i < zoneTextLength; i++) {
      u8_pkt[initialindex + i] = zoneTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x04; // command byte 1
    u8_pkt[13] = 0x03; // output max zone
    u8_pkt[14] =
        zoneThreeSetupMode.value.isNotEmpty
            ? int.parse(zoneThreeSetupMode.value, radix: 16)
            : 0x00;
    u8_pkt[15] = zoneThreeSetupDetectionMode.value & 0xFF;
    print(
      "zoneThreeSetupDetectionMode.value: ${zoneThreeSetupDetectionMode.value}",
    );
    print(
      "zoneThreeSetupVerificationTime.value: ${zoneThreeSetupVerificationTime.value}",
    );
    u8_pkt[16] =
        zoneThreeSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneThreeSetupVerificationTime.value)
            : 0x00;
    u8_pkt[17] =
        zoneThreeSetupDetectionMode.value == 3
            ? 0x1E
            : 0x00; // need to check this
    u8_pkt[18] = zoneTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Apply Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRadioSetupFetchCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x1D; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Radio Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendRadioSetupApplyCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String radioNameText = radioSetupName.value;
    final List<int> radioNameTextBytes = radioNameText.codeUnits;
    final radioNameTextLength = radioNameTextBytes.length;

    final initialindex = 21;
    for (int i = 0; i < 16; i++) {
      if (i < radioNameTextLength) {
        u8_pkt[initialindex + i] = radioNameTextBytes[i];
      } else {
        u8_pkt[initialindex + i] = 0x20;
      }
    }

    final String radioNoText = radioSetupNo.value.trim();
    print("radioNoText: $radioNoText");

    // Convert each character to actual numeric value
    final List<int> radioNoTextBytes =
        radioNoText.split('').map((e) => int.parse(e)).toList();

    print("radioNoTextBytes (numeric): $radioNoTextBytes");

    final radioNoTextLength = radioNoTextBytes.length;

    final initialSetupNoindex = 37;
    for (int i = 0; i < 8; i++) {
      if (i < radioNoTextLength) {
        u8_pkt[initialSetupNoindex + i] = radioNoTextBytes[i] & 0xFF;
      } else {
        u8_pkt[initialSetupNoindex + i] = 0x00; // pad with 0
      }
    }
    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x1D; // command
    u8_pkt[13] = isRadioSetupEnabled.value ? 0x01 : 0x00;
    u8_pkt[14] = radioSetupModule.value & 0xFF;
    u8_pkt[15] = isRadioSetupAdvertised.value ? 0x01 : 0x00;
    u8_pkt[16] = isRadioSetupConnected.value ? 0x01 : 0x00;
    u8_pkt[17] = isRadioSetupProgrammed.value ? 0x01 : 0x00;
    u8_pkt[18] = isRadioSetupBooted.value ? 0x01 : 0x00;
    u8_pkt[19] = isRadioSetupServiced.value ? 0x01 : 0x00;
    u8_pkt[20] = radioNameTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Radio Setup Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    // print(
    //   u8_pkt
    //       .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    //       .join(' '),
    // );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendModuleSetupFetchCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x00; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x01; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Module Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendLBusSetupFetchCmdPkt({required int lBusNo}) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x10; // command
    u8_pkt[13] = lBusNo; // L-Bus No

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: L-Bus Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendLBusSetupApplyCmdPkt({required int lBusNo}) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final data = lBusSetupDataList.value[lBusNo - 1];

    final String lBusDeviceText = data.deviceText;
    final List<int> lBusDeviceTextBytes = lBusDeviceText.codeUnits;
    final lBusDeviceTextLength = lBusDeviceTextBytes.length;

    print("lBusDeviceText: $lBusDeviceText");
    print("lBusProduct: ${data.product}");

    final initialindex = 23;
    for (int i = 0; i < lBusDeviceTextLength; i++) {
      if (i < lBusDeviceTextLength) {
        u8_pkt[initialindex + i] = lBusDeviceTextBytes[i];
      }
    }

    final statusConfig = LBusRepeaterStatusConfig(
      enable:
          data.enabled == 'Yes'
              ? LBusRepeaterEnable.enabled
              : LBusRepeaterEnable.disabled,
      idLed: data.idLed == 'Yes' ? LBusIdLed.on : LBusIdLed.off,
    );

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x10; // command
    u8_pkt[13] = lBusNo; // L-Bus No
    u8_pkt[14] =
        lBusSetupDataList.value[lBusNo - 1].product == 'Rhino103R'
            ? 0x16
            : 0x00;
    u8_pkt[17] = LBusRepeaterStatusCodec.encode(statusConfig);
    u8_pkt[18] = 0x01;
    u8_pkt[19] = 0x64;
    u8_pkt[20] = lBusNo == 1 ? 0x00 : 0x02;
    u8_pkt[21] = lBusNo == 1 ? 0x50 : 0x58;
    u8_pkt[22] = lBusDeviceTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: L-Bus Setup Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupRelayFetchCmdPkt({
    required int outputMaxZone,
  }) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = outputMaxZone; // output max zone byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup Relay $outputMaxZone Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupGeneralFetchCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x14; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup General Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupZoneFetchCmdPkt({
    required int zoneMaxZone,
  }) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x19; // command
    u8_pkt[13] = zoneMaxZone; // ext max zone
    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup Zone $zoneMaxZone Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupExtOutFetchCmdPkt({
    required int extMaxZone,
  }) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x01; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x1B; // command
    u8_pkt[13] = 0x01;
    u8_pkt[14] = extMaxZone; // ext max zone
    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup Ext Out $extMaxZone Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupRelayApplyCmdPkt({
    required int outputMaxZone,
  }) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    String outputText = "";
    int outputNo = 0;
    String outputMode = "";
    if (outputMaxZone == 1) {
      outputText = sounderOneOutputText.value;
      outputNo = sounderOneFunctionNo.value;
      outputMode = sounderOneRelayOutputMode.value;
    } else if (outputMaxZone == 2) {
      outputText = sounderTwoOutputText.value;
      outputNo = sounderTwoFunctionNo.value;
      outputMode = sounderTwoRelayOutputMode.value;
    } else if (outputMaxZone == 3) {
      outputText = sounderThreeOutputText.value;
      outputNo = sounderThreeFunctionNo.value;
      outputMode = sounderThreeRelayOutputMode.value;
    }
    final List<int> outputTextBytes = outputText.codeUnits;
    final outputTextLength = outputTextBytes.length;

    final initialindex = 26;
    for (int i = 0; i < outputTextLength; i++) {
      u8_pkt[initialindex + i] = outputTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8_pkt[0] = 0xFE;
    u8_pkt[1] = 0x01;
    u8_pkt[2] = 0x00;

    u8_pkt[3] = 0x01; // pkt type
    u8_pkt[4] = u8TxPktCnt & 0xFF; // tx pkt num
    u8_pkt[5] = u8RxPktCnt & 0xFF; // rx pkt num
    u8_pkt[6] = 0x00; // network number
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x07; // command
    u8_pkt[13] = 0x00; // output max zone byte 1
    u8_pkt[14] = outputMaxZone; // output max zone byte 2
    u8_pkt[15] = int.parse(outputMode, radix: 16);
    u8_pkt[16] = 0x02;
    u8_pkt[20] = outputMaxZone;
    u8_pkt[21] = 0x01;
    u8_pkt[22] = outputNo;
    u8_pkt[23] = u8_pkt[25] = outputTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup Relay $outputMaxZone Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }
}
