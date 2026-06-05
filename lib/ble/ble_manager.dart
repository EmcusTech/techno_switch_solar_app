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
import 'ble_crypto.dart';
import 'ble_encryption_config.dart';
import 'ble_process.dart';
import 'dart:typed_data';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/utils/input_mode_util.dart';
import 'package:techno_switch_solar_app/utils/relay_mode_util.dart';
import 'package:techno_switch_solar_app/utils/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/l_bus_payload_config.dart';
import 'package:techno_switch_solar_app/utils/ble_msd_utils.dart';

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

const int BLE_FRAME_FILED_SIZE = 11;

enum BleStates {
  REQ_ENCY_KEY,
  SEND_AUTHN_MSG,
  PROCESS_PANEL_EVT_LOG_READ,
  PROCESS_PANEL_LIVE_EVENTS_READ,
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
  SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET,
  SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET,
  SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET,
  SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET,
  SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET,
  SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET,
  SEND_GENERAL_MODULE_SETUP_CMD_FETCH_PACKET,
  SEND_GENERAL_MODULE_SETUP_CMD_APPLY_PACKET,
  SEND_ADC_SETUP_CMD_FETCH_PACKET,
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
  sendServiceDueFetchCmdPkt,
  sendServiceDueApplyCmdPkt,
  sendAccessCodeSetupFetchCmdPkt,
  sendAccessCodeSetupApplyCmdPkt,
  sendPanelInfoSetupFetchCmdPkt,
  sendPanelInfoSetupApplyCmdPkt,
  sendGeneralModuleSetupFetchCmdPkt,
  sendGeneralModuleSetupApplyCmdPkt,
  sendLiveEventsRetrievalFetchCmdPkt,
  sendAdcSetupFetchCmdPkt,
}

enum BleOperationMode {
  none,
  firmwareUpgrade,
  logRetrieval,
  liveEventsRetrieval,
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
  serviceDueFetch,
  serviceDueApply,
  accessCodeSetupFetch,
  accessCodeSetupApply,
  panelInfoSetupFetch,
  panelInfoSetupApply,
  generalModuleSetupFetch,
  generalModuleSetupApply,
  adcSetupFetch,
}

const String BLE_AUTHN_MSG = "TECHNOSWITCH-AUTH-APP";

class BleManager {
  int u8TxPktCnt = 0;
  int u8RxPktCnt = 0;

  BleStates bleCurrentState = BleStates.REQ_ENCY_KEY;
  BleStates bleStateMachineState = BleStates.REQ_ENCY_KEY;
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
  bool _pollInFlight = false;
  int receivedPollCount = 0;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  bool _connectedOnce = false;
  bool _connectInProgress = false;
  bool get isConnectInProgress => _connectInProgress;
  DateTime? _lastDisconnectAt;
  bool _isGattConnected = false;
  StreamSubscription<List<int>>? _notifySub;
  bool isBleDisconnected = true;
  bool isLogRetrievalDoneOnce = false;
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

  final ValueNotifier<bool> handshakeCompleteNotifier = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<String> bleFirmwareVersion = ValueNotifier<String>('');

  final ValueNotifier<String> bleHardwareVersion = ValueNotifier<String>('');

  Completer<void>? _handshakeCompleter;

  bool get isConnected => _isConnectedNotifier.value;

  final ValueNotifier<fbp.BluetoothDevice?> connectedBtDevice =
      ValueNotifier<fbp.BluetoothDevice?>(null);

  ValueNotifier<String> get accessKey => bleProcess.accessKey;

  ValueNotifier<int> get accessKeyLength => bleProcess.accessKeyLength;

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

  ValueNotifier<List<AccessCodeSetupData>> get accessCodeSetupDataList =>
      bleProcess.accessCodeSetupDataList;

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
  ValueNotifier<String> get sounderGeneralMode => bleProcess.sounderGeneralMode;

  ValueNotifier<String> get sounderZoneOneMode => bleProcess.sounderZoneOneMode;
  ValueNotifier<String> get sounderZoneTwoMode => bleProcess.sounderZoneTwoMode;
  ValueNotifier<String> get sounderZoneThreeMode =>
      bleProcess.sounderZoneThreeMode;

  ValueNotifier<String> get sounderExtOutOneMode =>
      bleProcess.sounderExtOutOneMode;
  ValueNotifier<String> get sounderExtOutTwoMode =>
      bleProcess.sounderExtOutTwoMode;
  ValueNotifier<String> get sounderExtOutThreeMode =>
      bleProcess.sounderExtOutThreeMode;

  ValueNotifier<int> get serviceDueYear => bleProcess.serviceDueYear;
  ValueNotifier<int> get serviceDueMonth => bleProcess.serviceDueMonth;
  ValueNotifier<int> get serviceDueDay => bleProcess.serviceDueDay;
  ValueNotifier<int> get serviceDueHour => bleProcess.serviceDueHour;
  ValueNotifier<int> get serviceDueMinute => bleProcess.serviceDueMinute;
  ValueNotifier<String> get serviceDueCompany => bleProcess.serviceDueCompany;
  ValueNotifier<String> get serviceDueContact => bleProcess.serviceDueContact;
  ValueNotifier<int> get serviceDueReminder => bleProcess.serviceDueReminder;

  ValueNotifier<int> get panelInfoPanelNo => bleProcess.panelInfoPanelNo;
  ValueNotifier<String> get panelInfoPanelName => bleProcess.panelInfoPanelName;
  ValueNotifier<int> get panelInfoYear => bleProcess.panelInfoYear;
  ValueNotifier<int> get panelInfoMonth => bleProcess.panelInfoMonth;
  ValueNotifier<int> get panelInfoDay => bleProcess.panelInfoDay;
  ValueNotifier<int> get panelInfoHour => bleProcess.panelInfoHour;
  ValueNotifier<int> get panelInfoMinute => bleProcess.panelInfoMinute;
  ValueNotifier<int> get panelInfoSecond => bleProcess.panelInfoSecond;
  ValueNotifier<int> get panelInfoEventReminderDelay =>
      bleProcess.panelInfoEventReminderDelay;

  ValueNotifier<int> get generalModuleLvlTimeOut =>
      bleProcess.generalModuleLvlTimeOut;
  ValueNotifier<int> get generalModuleSilenceBuzzerLvl =>
      bleProcess.generalModuleSilenceBuzzerLvl;
  ValueNotifier<int> get generalModuleSilenceSounderLvl =>
      bleProcess.generalModuleSilenceSounderLvl;
  ValueNotifier<int> get generalModuleResetLvl =>
      bleProcess.generalModuleResetLvl;
  ValueNotifier<int> get generalModuleFaultLatching =>
      bleProcess.generalModuleFaultLatching;

  ValueNotifier<String> get receivedPanelName => bleProcess.receivedPanelName;

  void resetProtocolState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolExtOutState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolInputSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolRelaySetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolZoneSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolRadioSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolModuleSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolLBusSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolSounderSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolServiceDueState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolAccessCodeSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolPanelInfoSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolGeneralModuleSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
    otaProcessState = OtaProcessState.sendNetworkPacket;
  }

  void resetProtocolAdcSetupState() {
    u8TxPktCnt = 0;
    u8RxPktCnt = 0;
    receivedPollCount = 0;
    _pollInFlight = false;
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

  void resetLogRetrievalState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.logRetrieval;
  }

  void resetLiveEventsRetrievalState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.logRetrieval;
  }

  void resetExtOutState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.extOutFetch;
  }

  void resetInputSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.inputSetupFetch;
  }

  void resetRelaySetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.relaySetupFetch;
  }

  void resetRadioSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.radioSetupFetch;
  }

  void resetModuleSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.moduleSetupFetch;
  }

  void resetLBusSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.lBusSetupFetch;
  }

  void resetZoneSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.zoneSetupFetch;
  }

  void resetSounderSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.sounderSetupFetch;
  }

  void resetServiceDueState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.serviceDueFetch;
  }

  void resetAccessCodeSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.accessCodeSetupFetch;
  }

  void resetPanelInfoSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.panelInfoSetupFetch;
  }

  void resetGeneralModuleSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.generalModuleSetupFetch;
  }

  void resetAdcSetupState() {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    _pollInFlight = false;
    receivedPollCount = 0;
    currentOperationMode = BleOperationMode.adcSetupFetch;
  }

  Future<void> startLogRetrieval() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.logRetrieval;

    resetLogRetrievalState();
    resetProtocolState();
    bleProcess.resetProcessState();

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

  Future<void> startSessionAccessCodeValidation() async {
    if (!isConnected) {
      throw Exception("Device not connected.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot validate access code.",
      );
    }

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    resetProtocolState();
    bleProcess.resetProcessState();
    bleProcess.isSessionAccessCodeValidationOnly = true;
    bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    await Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startLiveEventsRetrieval() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.liveEventsRetrieval;

    resetLiveEventsRetrievalState();
    resetProtocolState();
    bleProcess.resetProcessState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    otaProcessState = OtaProcessState.sendLiveEventsRetrievalFetchCmdPkt;
    print("Proceeding with live events retrieval");
    bleCurrentState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
    bleStateMachineState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> stopLiveEventsRetrieval() async {
    bleProcess.stopLiveEventSetup();
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

    currentOperationMode = BleOperationMode.extOutFetch;

    resetExtOutState();
    resetProtocolExtOutState();
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

    currentOperationMode = BleOperationMode.extOutApply;

    resetExtOutState();
    resetProtocolExtOutState();
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

    currentOperationMode = BleOperationMode.inputSetupFetch;

    resetInputSetupState();
    resetProtocolInputSetupState();
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

    currentOperationMode = BleOperationMode.inputSetupApply;

    resetInputSetupState();
    resetProtocolInputSetupState();
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

    currentOperationMode = BleOperationMode.relaySetupFetch;

    resetRelaySetupState();
    resetProtocolRelaySetupState();
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

    currentOperationMode = BleOperationMode.relaySetupApply;

    resetRelaySetupState();
    resetProtocolRelaySetupState();
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

    currentOperationMode = BleOperationMode.zoneSetupFetch;

    resetZoneSetupState();
    resetProtocolZoneSetupState();
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

    currentOperationMode = BleOperationMode.zoneSetupApply;

    resetRelaySetupState();
    resetProtocolZoneSetupState();
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

    currentOperationMode = BleOperationMode.radioSetupFetch;

    resetRadioSetupState();
    resetProtocolRadioSetupState();
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

    currentOperationMode = BleOperationMode.radioSetupApply;

    resetRadioSetupState();
    resetProtocolRadioSetupState();
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

    currentOperationMode = BleOperationMode.moduleSetupFetch;

    resetModuleSetupState();
    resetProtocolModuleSetupState();
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

    currentOperationMode = BleOperationMode.lBusSetupFetch;

    resetLBusSetupState();
    resetProtocolLBusSetupState();
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

    currentOperationMode = BleOperationMode.lBusSetupApply;

    resetLBusSetupState();
    resetProtocolLBusSetupState();
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

    currentOperationMode = BleOperationMode.sounderSetupFetch;

    resetSounderSetupState();
    resetProtocolSounderSetupState();
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

    currentOperationMode = BleOperationMode.sounderSetupApply;

    resetSounderSetupState();
    resetProtocolSounderSetupState();
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

  Future<void> startServiceDueFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.serviceDueFetch;

    resetServiceDueState();
    resetProtocolServiceDueState();
    bleProcess.resetProcessServiceDueState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with Service due fetch");
    bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startServiceDueApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.serviceDueApply;

    resetServiceDueState();
    resetProtocolServiceDueState();
    bleProcess.resetProcessServiceDueState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with Service due apply");
    bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startAccessCodeSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.accessCodeSetupFetch;

    resetAccessCodeSetupState();
    resetProtocolAccessCodeSetupState();
    bleProcess.resetProcessAccessCodeSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with Access code setup fetch");
    bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startAccessCodeSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.accessCodeSetupApply;

    resetAccessCodeSetupState();
    resetProtocolAccessCodeSetupState();
    bleProcess.resetProcessAccessCodeSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with Access code setup fetch");
    bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startPanelInfoSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.panelInfoSetupFetch;

    resetPanelInfoSetupState();
    resetProtocolPanelInfoSetupState();
    bleProcess.resetProcessPanelInfoSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with Panel info setup fetch");
    bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startPanelInfoSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.panelInfoSetupApply;

    resetPanelInfoSetupState();
    resetProtocolPanelInfoSetupState();
    bleProcess.resetProcessPanelInfoSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with Panel info setup apply");
    bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startGeneralModuleSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.generalModuleSetupFetch;

    resetGeneralModuleSetupState();
    resetProtocolGeneralModuleSetupState();
    bleProcess.resetProcessGeneralModuleSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with General module setup fetch");
    bleCurrentState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startGeneralModuleSetupApply() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.generalModuleSetupApply;

    resetGeneralModuleSetupState();
    resetProtocolGeneralModuleSetupState();
    bleProcess.resetProcessGeneralModuleSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with General module setup apply");
    bleCurrentState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_APPLY_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startAdcSetupFetch() async {
    if (!isConnected) {
      throw Exception("Device not connected. Cannot start log retrieval.");
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(
        "BLE characteristics not initialized. Cannot start log retrieval.",
      );
    }

    currentOperationMode = BleOperationMode.adcSetupFetch;

    resetAdcSetupState();
    resetProtocolAdcSetupState();
    bleProcess.resetProcessAdcSetupState();

    if (_notifySub == null) {
      throw Exception(
        "BLE handshake not complete. Please wait for connection to finish.",
      );
    }

    print("Proceeding with Adc setup fetch");
    bleCurrentState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
    print("Current state: $bleStateMachineState");
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

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

  void _resetConnectNotifiersForNewSession() {
    _isConnectedNotifier.value = false;
    handshakeCompleteNotifier.value = false;
    bleFirmwareVersion.value = '';
  }

  void _resetHandshakeSessionState() {
    bleProcess.cancelRxTimeout();
    resetProtocolState();
    bleProcess.resetProcessState();
    bleProcess.clearSessionAccessCode();
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleStateMachineState = BleStates.REQ_ENCY_KEY;
    bleAESKey.clear();
    currentOperationMode = BleOperationMode.none;
    isLogRetrievalDoneOnce = false;
    notifyChar = null;
    writeChar = null;

    if (_handshakeCompleter != null && !_handshakeCompleter!.isCompleted) {
      _handshakeCompleter!.completeError(Exception("BLE session reset"));
      _handshakeCompleter = null;
    }
  }

  Future<void> _tearDownConnectionAttempt(
    String deviceId, {
    bool forceAbortNative = false,
  }) async {
    final hadGatt = _isGattConnected || _connectedOnce;

    await _notifySub?.cancel();
    await _connectionSub?.cancel();

    _notifySub = null;
    _connectionSub = null;
    _connectedOnce = false;
    _isGattConnected = false;
    _isConnectedNotifier.value = false;
    handshakeCompleteNotifier.value = false;
    bleFirmwareVersion.value = '';

    if (_handshakeCompleter != null && !_handshakeCompleter!.isCompleted) {
      _handshakeCompleter!.completeError(
        Exception("Connection attempt aborted"),
      );
      _handshakeCompleter = null;
    }

    if (forceAbortNative || hadGatt) {
      try {
        await flutterReactiveBle.abortConnection(deviceId);
      } catch (_) {
        // Native stack may already be disconnected.
      }
    }
  }

  Future<void> _abortActiveConnectSession() async {
    final deviceId =
        selectedDevice?.id ??
        (connectedDeviceId.value.isNotEmpty ? connectedDeviceId.value : null);
    if (deviceId != null && deviceId.isNotEmpty) {
      await _tearDownConnectionAttempt(deviceId, forceAbortNative: true);
    } else {
      await _notifySub?.cancel();
      await _connectionSub?.cancel();
      _notifySub = null;
      _connectionSub = null;
      _resetConnectNotifiersForNewSession();
    }
    selectedDevice = null;
    connectedBtDevice.value = null;
    connectedDeviceId.value = '';
  }

  Future<void> connectToKnownDevice({
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 1),
    Duration connectionTimeout = const Duration(seconds: 10),
    required DiscoveredDevice device,
    int? manufacturerDataOverride,
    bool skipConnectionHandshake = false,
  }) async {
    print("Attempting to connect to device: ${device.id}");

    if (isConnected) {
      print("Return from here");
      shutdown();
      return;
    }

    if (_connectInProgress) {
      print("Aborting in-flight connect before starting a new session");
      await _abortActiveConnectSession();
    }

    _connectInProgress = true;
    maxBleConnectionRetriesReached.value = false;
    _resetConnectNotifiersForNewSession();
    _resetHandshakeSessionState();

    if (_lastDisconnectAt != null) {
      const minCooldown = Duration(milliseconds: 800);
      final elapsed = DateTime.now().difference(_lastDisconnectAt!);
      if (elapsed < minCooldown) {
        await Future.delayed(minCooldown - elapsed);
      }
    }

    int attempt = 0;

    try {
      while (attempt < maxRetries) {
        attempt++;
        print("BLE connect attempt $attempt / $maxRetries");

        try {
          selectedDevice = device;
          connectedBtDevice.value =
              device.device ?? fbp.BluetoothDevice.fromId(device.id);
          _connectedOnce = false;
          await _connectOnce(
            device,
            manufacturerDataOverride: manufacturerDataOverride,
            connectionTimeout: connectionTimeout,
            skipConnectionHandshake: skipConnectionHandshake,
          );
          print("BLE connected successfully");
          return;
        } catch (e) {
          print("BLE attempt $attempt failed: $e");

          await _tearDownConnectionAttempt(
            device.id,
            forceAbortNative: attempt >= maxRetries,
          );
          selectedDevice = null;
          connectedBtDevice.value = null;
          connectedDeviceId.value = '';

          resetLogRetrievalState();

          if (attempt >= maxRetries) {
            print("Max BLE retry attempts reached");
            processDesc.value =
                "Max BLE retry attempts reached, please scan again and connect.";
            maxBleConnectionRetriesReached.value = true;
            rethrow;
          }

          if (retryDelay > Duration.zero) {
            await Future.delayed(retryDelay);
          }
        }
      }
    } finally {
      _connectInProgress = false;
    }
  }

  Future<void> _refreshGattIfNeeded(String deviceId) async {
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
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    if (await Permission.bluetoothConnect.isDenied ||
        await Permission.location.isDenied) {
      throw Exception("Bluetooth permissions not granted");
    }

    final Completer<void> connectedCompleter = Completer();
    var ignoreInitialDisconnectedEmission = true;
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
        "DEBUG CONNECTION: Using manufacturer data from selectedDevice - Full array: $md, Length: ${md.length}, Status byte: ${BleMsdUtils.statusByte(md)}",
      );
    } else if (md.isEmpty) {
      print(
        "DEBUG CONNECTION: WARNING - Manufacturer data is empty for device ${device.id}, will use default 0",
      );
    }
    final statusByte = manufacturerDataOverride ?? BleMsdUtils.statusByte(md);
    print(
      "DEBUG CONNECTION: Final manufacturer data array: $md, Status byte: $statusByte",
    );

    _connectionSub = flutterReactiveBle
        .connectToDevice(id: device.id, connectionTimeout: connectionTimeout)
        .listen(
          (update) async {
            print("Connection state: ${update.connectionState}");

            if (update.connectionState == DeviceConnectionState.connected) {
              print(
                "DEBUG CONNECTION: Setting bleManufacturerData - Full array: $md, Status byte: $statusByte",
              );
              bleManufacturerData.value = statusByte;
              print(
                "DEBUG CONNECTION: bleManufacturerData.value is now: ${bleManufacturerData.value}",
              );
              _isConnectedNotifier.value = true;
              isBleDisconnected = false;
              connectedDeviceId.value = device.id;
              _isGattConnected = true;

              if (_connectedOnce) return;
              _connectedOnce = true;
              await Future.delayed(const Duration(milliseconds: 300));

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

              if (!connectedCompleter.isCompleted) {
                connectedCompleter.complete();
              }
            }

            if (update.connectionState == DeviceConnectionState.disconnected) {
              if (!_connectedOnce &&
                  !_isGattConnected &&
                  ignoreInitialDisconnectedEmission) {
                ignoreInitialDisconnectedEmission = false;
                return;
              }

              _isConnectedNotifier.value = false;
              handshakeCompleteNotifier.value = false;
              bleFirmwareVersion.value = '';
              isBleDisconnected = true;
              _isGattConnected = false;
              _connectedOnce = false;

              bleProcess.clearSessionAccessCode();

              await _notifySub?.cancel();
              _notifySub = null;
              isLogRetrievalDoneOnce = false;

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

    final isBootLoaderMode = statusByte == BleMsdUtils.statusBootloader;
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
    } else {
      if (isBootLoaderMode && !skipConnectionHandshake) {
        await registerNotifyHandler(isChipInBootLoader: true);
      }
      handshakeCompleteNotifier.value = true;
    }
  }

  Future<void> registerNotifyHandler({
    bool? isChipInBootLoader = false,
    bool? isExtOut = false,
  }) async {
    print("Register notify handler");

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
      _notifySub = flutterReactiveBle
          .subscribeToCharacteristic(notifyChar!)
          .listen(
            (data) => notificationHandler(Uint8List.fromList(data)),
            onError: (e) {
              print("Notification subscription error: $e");
              _notifySub = null;
            },
          );

      print("Listening for notifications...");
      await Future.delayed(const Duration(milliseconds: 300));
      print("---Notification handler registered----");

      if (isChipInBootLoader != true) {
        bleProcess.requestENCKey();
      } else {
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

  Future<void> disconnectConnectedDevice() async {
    receivedPanelName.value = "";
    if (!isConnected) {
      print("Device not connected, returning");
      return;
    }

    fbp.BluetoothDevice? device = connectedBtDevice.value;

    if (device == null && selectedDevice != null) {
      device = fbp.BluetoothDevice.fromId(selectedDevice!.id);
    }

    try {
      if (device != null) {
        print("Disconnecting device using fbp: $device");
        await device.disconnect();
      } else {
        print("Device not found, returning");
        return;
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

    await _notifySub?.cancel();
    await _connectionSub?.cancel();

    _notifySub = null;
    _connectionSub = null;

    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        await flutterReactiveBle.abortConnection(deviceId);
      } catch (_) {}
    }

    _isGattConnected = false;
    _connectedOnce = false;
    selectedDevice = null;
    connectedBtDevice.value = null;
    _isConnectedNotifier.value = false;
    handshakeCompleteNotifier.value = false;
    bleFirmwareVersion.value = '';
    _resetHandshakeSessionState();
    _lastDisconnectAt = DateTime.now();
  }

  Future<void> shutdown({String? deviceId}) async {
    print("Shutdown BLE");
    if (deviceId != null && deviceId.isNotEmpty) {
      await _refreshGattIfNeeded(deviceId);
    }

    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connectionSub?.cancel();

    _resetHandshakeSessionState();

    _scanSub = null;
    _notifySub = null;
    _connectionSub = null;
    _isGattConnected = false;
    _connectedOnce = false;
    selectedDevice = null;
    isBleDisconnected = true;
    _isConnectedNotifier.value = false;
    handshakeCompleteNotifier.value = false;
    bleFirmwareVersion.value = '';
  }

  bool _hasEncryptionKey() {
    final dynamic key = bleAESKey['AES_KEY'];
    return key is List<int> && key.length >= kBleEncryKeyByteSize;
  }

  bool _isBootloaderMode() {
    return bleManufacturerData.value == BleMsdUtils.statusBootloader;
  }

  bool _shouldEncryptOutgoing({required bool encryptParam}) {
    if (!encryptParam || _isBootloaderMode() || !_hasEncryptionKey()) {
      return false;
    }
    return BleCrypto.shouldTransform(
      encryptParam: true,
      pastEncryptionKeyExchange:
          handshakeCompleteNotifier.value ||
          bleCurrentState.index > BleStates.REQ_ENCY_KEY.index,
    );
  }

  Uint8List _transformOutgoingFrame(Uint8List frame, {bool encrypt = true}) {
    if (!_shouldEncryptOutgoing(encryptParam: encrypt)) {
      return frame;
    }
    final List<int> key = bleAESKey['AES_KEY'] as List<int>;
    return BleCrypto.transformTx(frame, key);
  }

  bool _shouldDecryptIncomingFrame() {
    if (_isBootloaderMode()) {
      return false;
    }
    return BleCrypto.shouldTransform(
          encryptParam: true,
          pastEncryptionKeyExchange:
              handshakeCompleteNotifier.value ||
              bleCurrentState.index > BleStates.REQ_ENCY_KEY.index,
        ) &&
        _hasEncryptionKey();
  }

  Uint8List _decryptIncomingFrame(Uint8List data) {
    print(
      "decryptIncomingFrame: ${data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    final List<int> key = bleAESKey['AES_KEY'] as List<int>;
    print("key: $key");
    print(
      "transformRx: ${BleCrypto.transformRx(data, key).map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );
    return BleCrypto.transformRx(data, key);
  }

  Future<void> notificationHandler(Uint8List data) async {
    if ((bleProcess.isOtaCompleted ||
            otaProcessState == OtaProcessState.notInUse) &&
        isBleDisconnected) {
      print("RX ignored after OTA completion");
      return;
    }

    txData = 1;
    bleProcess.cancelRxTimeout();
    _pollInFlight = false;

    if (_shouldDecryptIncomingFrame()) {
      data = _decryptIncomingFrame(data);
    }

    print("bleCurrentState: $bleCurrentState");
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
        final List<int> payload = bleRxFrame.payload;
        bleAESKey['AES_KEY'] = BleCrypto.extractKeyFromHandshakePayload(
          payload,
        );
        print("Received key: ${bleAESKey['AES_KEY']}");

        if (payload.length >= 10) {
          final firmwareVersionBytes = payload.sublist(
            payload.length - 28,
            payload.length - 18,
          );
          final hardwareVersionBytes = payload.sublist(
            payload.length - 18,
            payload.length - 11,
          );
          final hardwareVersion = String.fromCharCodes(hardwareVersionBytes);
          final bleVersion = String.fromCharCodes(firmwareVersionBytes);
          bleFirmwareVersion.value = bleVersion;
          bleHardwareVersion.value = hardwareVersion;
          print("BLE firmware version: $bleVersion");
          print("BLE hardware version: $hardwareVersion");
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
      print(
        "data: ${data.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      );
      bleRxFrame = bleParseAndUpdateRxFrame(data, data.length);

      if (bleValidateRxFrame(bleRxFrame)) {
        print("AUTH KEY Validation success");
        await Future.delayed(Duration(seconds: 1));

        if (currentOperationMode == BleOperationMode.none) {
          bleCurrentState = BleStates.IDLE;
          bleStateMachineState = BleStates.IDLE;
          print("Connection handshake complete - device ready for operations");
          if (_handshakeCompleter != null &&
              !_handshakeCompleter!.isCompleted) {
            _handshakeCompleter!.complete();
          }
        } else if (currentOperationMode == BleOperationMode.firmwareUpgrade) {
          bleCurrentState = BleStates.SEND_START_FIRMWARE_PACKET;
          bleStateMachineState = BleStates.SEND_START_FIRMWARE_PACKET;
          print("Current state: $bleStateMachineState (Firmware Upgrade)");
        } else if (currentOperationMode == BleOperationMode.logRetrieval) {
          bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
          bleStateMachineState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
          print("Current state: $bleStateMachineState (Log Retrieval)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.extOutFetch) {
          bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Ext Out Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.extOutApply) {
          bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
          print("Current state : $bleStateMachineState (Ext Out Apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.inputSetupFetch) {
          bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Input Setup Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.inputSetupApply) {
          bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Input Setup Apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.relaySetupFetch) {
          bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Relay Setup Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.relaySetupApply) {
          bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Relay Setup Apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.zoneSetupFetch) {
          bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Zone Setup Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.zoneSetupApply) {
          bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Zone Setup Apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.radioSetupFetch) {
          bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Radio Setup Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.radioSetupApply) {
          bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Radio Setup Apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.moduleSetupFetch) {
          bleCurrentState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Module Setup Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.lBusSetupFetch) {
          bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (L-Bus Setup Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.lBusSetupApply) {
          bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (L-Bus Setup Apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.sounderSetupFetch) {
          bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Sounder Setup Fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.sounderSetupApply) {
          bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Sounder Setup Apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.serviceDueFetch) {
          bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState =
              BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Service due fetch)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.serviceDueApply) {
          bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState =
              BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
          print("Current state: $bleStateMachineState (Service due apply)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.accessCodeSetupFetch) {
          bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState =
              BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
          print(
            "Current state: $bleStateMachineState (Access code setup fetch)",
          );
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.accessCodeSetupApply) {
          bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState =
              BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
          print(
            "Current state: $bleStateMachineState (Access code setup apply)",
          );
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.panelInfoSetupFetch) {
          bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState =
              BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
          print(
            "Current state: $bleStateMachineState (Panel info setup fetch)",
          );
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.panelInfoSetupApply) {
          bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState =
              BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
          print(
            "Current state: $bleStateMachineState (Panel info setup apply)",
          );
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.generalModuleSetupFetch) {
          bleCurrentState =
              BleStates.SEND_GENERAL_MODULE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState =
              BleStates.SEND_GENERAL_MODULE_SETUP_CMD_FETCH_PACKET;
          print(
            "Current state: $bleStateMachineState (General module setup fetch)",
          );
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.generalModuleSetupApply) {
          bleCurrentState =
              BleStates.SEND_GENERAL_MODULE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState =
              BleStates.SEND_GENERAL_MODULE_SETUP_CMD_APPLY_PACKET;
          print(
            "Current state: $bleStateMachineState (General module setup apply)",
          );
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.liveEventsRetrieval) {
          bleCurrentState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
          bleStateMachineState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
          print("Current state: $bleStateMachineState (Live events retrieval)");
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.adcSetupFetch) {
          bleCurrentState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
          print("Current state: $bleStateMachineState (Adc setup fetch)");
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

  void registerNotificationListener(characteristic) {
    characteristic.value.listen((data) async {
      await notificationHandler(data);
    });
  }

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

    frameBuff[enBLE_SOF_MSB_POS] = enBLE_SOF_MSB;
    frameBuff[enBLE_SOF_LSB_POS] = enBLE_SOF_LSB;
    frameBuff[enBLE_CMD_MSB_POS] = (cmd >> 8) & 0xFF;
    frameBuff[enBLE_CMD_LSB_POS] = cmd & 0xFF;
    frameBuff[enBLE_TOF_POS] = typeOfFrame;
    frameBuff[enBLE_DATA_LEN_MSB_POS] = (dataLen >> 8) & 0xFF;
    frameBuff[enBLE_DATA_LEN_LSB_POS] = dataLen & 0xFF;

    for (int i = 0; i < dataLen; i++) {
      frameBuff[enBLE_DATA_POS + i] = data[i];
    }

    int crc = crcCcittFalse(frameBuff.sublist(0, enBLE_DATA_POS + dataLen));

    frameBuff[enBLE_DATA_POS + dataLen] = (crc >> 8) & 0xFF;
    frameBuff[enBLE_DATA_POS + 1 + dataLen] = crc & 0xFF;
    frameBuff[enBLE_DATA_POS + 2 + dataLen] = enBLE_EOF_MSB;
    frameBuff[enBLE_DATA_POS + 3 + dataLen] = enBLE_EOF_LSB;

    return frameBuff;
  }

  Future<void> sendData(
    Uint8List frame, {
    bool encrypt = true,
    bool withoutResponse = false,
  }) async {
    if (!isConnected || writeChar == null) return;

    try {
      final Uint8List dataToSend = _transformOutgoingFrame(
        frame,
        encrypt: encrypt,
      );

      if (_shouldEncryptOutgoing(encryptParam: encrypt)) {
        print(
          'Sending encrypted data (${kBleEncryptionAlgorithm.name}): length ${dataToSend.length}',
        );
      } else {
        print("Sending plain data: length ${dataToSend.length}");
      }

      print(
        "::::::Data Written:::${dataToSend.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}::TX Time${DateTime.now().toIso8601String()}}",
      );
      if (withoutResponse) {
        await flutterReactiveBle.writeCharacteristicWithoutResponse(
          writeChar!,
          value: dataToSend,
        );
      } else {
        await flutterReactiveBle.writeCharacteristicWithResponse(
          writeChar!,
          value: dataToSend,
        );
      }
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

    List<int> frame = bleFrameFormat(cmd, 0x01, length, data);
    Uint8List frameBytes = aes.convertToBytes(frame);

    print(
      "sendSmallDataFrame: ${frameBytes.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendData(frameBytes, encrypt: encrypt);
  }

  Future<void> sendAesKeyReq() async {
    List<int> reqFrame = bleFrameFormat(0x1000, 0x01, 1, [0x00]);

    Uint8List reqFrameBytes = aes.convertToBytes(reqFrame);

    print("Framed key req Frame: $reqFrame after bytes convert $reqFrameBytes");

    print("TX/RX: TRANSMIT: enc key request : $reqFrameBytes");

    await sendData(reqFrameBytes, encrypt: false);
  }

  Future<void> sendAuthnMsg() async {
    if (writeChar == null) return;

    List<int> msgBytes = BLE_AUTHN_MSG.codeUnits;

    List<int> authnMsgFrame = bleFrameFormat(
      0x1000,
      0x02,
      msgBytes.length,
      msgBytes,
    );

    print("Framed Authn Msg: $authnMsgFrame");

    Uint8List frameBytes = Uint8List.fromList(authnMsgFrame);

    print(
      "TX/RX: TRANSMIT: Auth Frame bytes: ${frameBytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    await sendData(frameBytes);
  }

  Future<void> sendNetworkPacket() async {
    bleProcess.isNetworkPacketProcess.value = true;
    u8TxPktCnt = 0;

    List<int> u8Pkt = List.filled(216, 0);
    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x04;
    u8Pkt[4] = 0x00;
    u8Pkt[5] = 0x00;
    u8Pkt[6] = 0x05;
    u8Pkt[11] = 0x02;
    u8Pkt[12] = 0x01;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Network Packet time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPollPacket() async {
    if (bleProcess.isOtaCompleted &&
        otaProcessState == OtaProcessState.notInUse) {
      print("bleprocess.isOtaCompleted : ${bleProcess.isOtaCompleted}");
      print("otaProcessState : ${otaProcessState == OtaProcessState.notInUse}");
      print("Poll blocked (OTA completed / notInUse)");
      return;
    }

    if (_pollInFlight) {
      print("Skipping poll: previous write still in-flight");
      return;
    }
    _pollInFlight = true;

    List<int> pollPkt = List.filled(216, 0);
    pollPkt[0] = 0xFE;
    pollPkt[1] = 0x01;
    pollPkt[2] = 0x00;
    pollPkt[4] = (u8TxPktCnt + 1) & 0xFF;
    pollPkt[5] = (u8RxPktCnt & 0xFF);
    print(
      "Sending poll pkt rx cnt pollPkt[5] value:${pollPkt[5]},u8RxPktCnt:${u8RxPktCnt}",
    );
    pollPkt[6] = 0x00;
    pollPkt[11] = 0x00;

    int checksum = toolsFletcherChecksum(pollPkt.sublist(0, 216 - 3));

    pollPkt[213] = (checksum >> 8) & 0xFF;
    pollPkt[214] = checksum & 0xFF;
    pollPkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Poll Packet time: ${DateTime.now().toIso8601String()}, packet: ${pollPkt.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, pollPkt);
  }

  void resetPollInFlight() {
    _pollInFlight = false;
  }

  Future<void> sendAccessKeyPkt() async {
    u8TxPktCnt += 1;

    List<int> pkt = List.filled(216, 0);

    print("accessKey: ${accessKey.value}");
    print("accessKey length: ${accessKey.value.length}");

    String accessKeyString = accessKey.value;
    List<int> accessKeyBytes = accessKeyString.codeUnits;
    accessKeyLength.value = accessKeyBytes.length;

    for (int i = 0; i < accessKeyLength.value; i++) {
      if (i < accessKeyLength.value) {
        pkt[14 + i] = accessKeyBytes[i];
      }
    }

    print("pkt[14]: ${pkt[14]}");

    pkt[0] = 0xFE;
    pkt[1] = 0x01;
    pkt[2] = 0x00;

    pkt[3] = 0x01;
    pkt[4] = u8TxPktCnt & 0xFF;
    pkt[5] = u8RxPktCnt & 0xFF;
    pkt[6] = 0x00;
    pkt[10] = 0x83;
    pkt[11] = 0x00;
    pkt[12] = 0x04;
    pkt[13] = accessKeyLength.value & 0xFF;

    int checksum = toolsFletcherChecksum(pkt.sublist(0, 216 - 3));

    pkt[213] = (checksum >> 8) & 0xFF;
    pkt[214] = checksum & 0xFF;
    pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Access Key Packet time: ${DateTime.now().toIso8601String()}, packet: ${pkt.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ').toString()}",
    );

    await sendSmallDataFrame(0x1000, 216, pkt);
  }

  Future<void> sendStartCntrlCmdPkt() async {
    u8TxPktCnt += 1;

    Uint8List u8Pkt = Uint8List(216);
    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;

    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x83;
    u8Pkt[11] = 0x04;
    u8Pkt[12] = 0x0B;
    u8Pkt[13] = 0x03;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Start Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendStopCntrlCmdPkt() async {
    u8TxPktCnt += 1;

    Uint8List u8Pkt = Uint8List(216);
    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;

    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x83;
    u8Pkt[11] = 0x04;
    u8Pkt[12] = 0x0B;
    u8Pkt[13] = 0x03;
    u8Pkt[14] = 0x01;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Stop Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendJumpFirmwarePacket({bool withoutResponse = true}) async {
    if (!isConnected || writeChar == null) {
      throw Exception("BLE not connected or write characteristic missing");
    }

    final Uint8List jumpFrame = aes.convertToBytes(
      bleFrameFormat(0x1002, 0x02, 1, [0x00]),
    );
    final Uint8List dataToSend = _transformOutgoingFrame(
      jumpFrame,
      encrypt: true,
    );
    try {
      print(
        'Sending encrypted jump firmware packet (${kBleEncryptionAlgorithm.name}): length ${dataToSend.length}',
      );
      print(
        "::::::Data Written:::${dataToSend.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}::TX Time${DateTime.now().toIso8601String()}}",
      );
      if (withoutResponse) {
        await flutterReactiveBle.writeCharacteristicWithoutResponse(
          writeChar!,
          value: dataToSend,
        );
      } else {
        await flutterReactiveBle.writeCharacteristicWithResponse(
          writeChar!,
          value: dataToSend,
        );
      }
      print(
        "TX/RX: TRANSMIT: Jump Firmware Packet time: ${DateTime.now().toIso8601String()}",
      );
    } catch (e) {
      print("Send Jump firmware packet failed: $e");
      rethrow;
    }
  }

  Future<void> registerNotifyHandlerForFirmwareUpgrade({
    bool isChipInBootLoader = false,
  }) async {
    currentOperationMode = BleOperationMode.firmwareUpgrade;
    await registerNotifyHandler(isChipInBootLoader: isChipInBootLoader);
  }

  Future<void> sendStartFirmwarePacket() async {
    if (!isConnected || writeChar == null) {
      throw Exception("BLE not connected or write characteristic missing");
    }

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
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;

    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x16;
    u8Pkt[13] = 0x01;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Ext Out Fetch command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendExtOutSetupApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final int autoDelay = extZoneCountdownAuto.value;
    final int manDelay = extZoneCountdownMan.value;
    final int releasePeriod = extZoneReleaseTime.value;
    final int resetDelay = extZoneResetDelay.value;
    final String extZoneString = extZoneText.value;
    final List<int> extZoneTextBytes = extZoneString.codeUnits;
    final extZoneTextLength = extZoneTextBytes.length;
    final initialindex = 41;

    for (int i = 0; i < extZoneTextLength; i++) {
      u8Pkt[initialindex + i] = extZoneTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;

    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x16;
    u8Pkt[13] = 0x01;
    u8Pkt[14] = int.parse(extZoneMode.value, radix: 16);
    u8Pkt[15] = 0x01;
    u8Pkt[16] = extZoneActuatorType.value;
    u8Pkt[17] = (autoDelay >> 8) & 0xFF;
    u8Pkt[18] = autoDelay & 0xFF;
    u8Pkt[19] = (manDelay >> 8) & 0xFF;
    u8Pkt[20] = manDelay & 0xFF;
    u8Pkt[21] = (releasePeriod >> 8) & 0xFF;
    u8Pkt[22] = releasePeriod & 0xFF;
    u8Pkt[23] = (resetDelay >> 8) & 0xFF;
    u8Pkt[24] = resetDelay & 0xFF;
    u8Pkt[25] = extZoneAction.value;
    u8Pkt[26] = extZoneFunction.value;
    u8Pkt[27] = 0x1E;
    u8Pkt[28] = 0x00;
    u8Pkt[29] = 0x3C;
    u8Pkt[30] = 0x03;
    u8Pkt[31] = 0x84;
    u8Pkt[32] = 0x00;
    u8Pkt[33] = 0x00;
    u8Pkt[34] = 0x00;
    u8Pkt[35] = 0x00;
    u8Pkt[36] = 0x00;
    u8Pkt[37] = 0x00;
    u8Pkt[38] = 0x00;
    u8Pkt[39] = 0x00;
    u8Pkt[40] = extZoneTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Ext Out command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendFetchDipSettingPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x1C;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Fetch Dip setting command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendInputSetupFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x06;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x01;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Ext Out Fetch command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendInputSetupApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final int group = inputSetupGroup.value;
    final int function = inputSetupFunction.value;
    final String inputText = inputSetupText.value;
    final List<int> inputTextBytes = inputText.codeUnits;
    final inputTextLength = inputTextBytes.length;
    final initialindex = 26;

    for (int i = 0; i < inputTextLength; i++) {
      u8Pkt[initialindex + i] = inputTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;

    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x06;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x01;
    int inputModeByte;
    try {
      final raw = inputMode.value.trim();
      if (raw.isEmpty) throw FormatException('empty inputMode');
      inputModeByte = int.parse(raw, radix: 16);
    } catch (_) {
      final cfg = InputModeConfig(
        inputEnable:
            isInputSetupEnabled.value
                ? InputEnable.enabled
                : InputEnable.disabled,
        inputMode: isInputSetupTest.value ? InputMode.test : InputMode.normal,
        latchMode: LatchMode.nonLatched,
        invertMode:
            isInputSetupInverted.value
                ? InvertMode.inverted
                : InvertMode.notInverted,
      );
      inputModeByte = InputModeCodec.encode(cfg);
      bleProcess.inputMode.value = InputModeCodec.encodeHex(cfg);
    }
    u8Pkt[15] = inputModeByte & 0xFF;
    u8Pkt[16] = 0x02;
    u8Pkt[17] = 0x00;
    u8Pkt[18] = 0x00;
    u8Pkt[19] = 0x00;
    u8Pkt[20] = 0x01;
    u8Pkt[21] = 0x01;
    u8Pkt[22] = 0x01;
    u8Pkt[23] = inputSetupGroup.value;
    u8Pkt[24] = inputSetupFunction.value;
    u8Pkt[25] = inputTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Input Setup Apply command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupFetchFirstCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x07;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x04;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Fetch First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupFetchSecondCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x07;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x05;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Fetch Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupFetchThirdCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x07;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x06;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Fetch Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  int _relayOutputModeByteForApply({
    required ValueNotifier<String> modeHex,
    required bool enabled,
    required bool test,
  }) {
    try {
      final raw = modeHex.value.trim();
      if (raw.isEmpty) throw FormatException('empty relay mode');
      return int.parse(raw, radix: 16) & 0xFF;
    } catch (_) {
      final cfg = OutputModeConfig(
        outputEnable: enabled ? OutputEnable.enabled : OutputEnable.disabled,
        outputMode: test ? OutputMode.test : OutputMode.normal,
        supervisionMode: SupervisionMode.normal,
      );
      final b = OutputModeCodec.encode(cfg);
      modeHex.value = OutputModeCodec.encodeHex(cfg);
      return b;
    }
  }

  int _parseRelayDynamicFieldByte(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 0;
    try {
      return int.parse(t, radix: 16) & 0xFF;
    } catch (_) {
      return 0;
    }
  }

  int _sounderRelayOutputModeByteForApply({required int outputMaxZone}) {
    switch (outputMaxZone) {
      case 1:
        return _relayOutputModeByteForApply(
          modeHex: sounderOneRelayOutputMode,
          enabled: isSounderOneEnabled.value,
          test: isSounderOneTest.value,
        );
      case 2:
        return _relayOutputModeByteForApply(
          modeHex: sounderTwoRelayOutputMode,
          enabled: isSounderTwoEnabled.value,
          test: isSounderTwoTest.value,
        );
      default:
        return _relayOutputModeByteForApply(
          modeHex: sounderThreeRelayOutputMode,
          enabled: isSounderThreeEnabled.value,
          test: isSounderThreeTest.value,
        );
    }
  }

  int _sounderGeneralEquipmentModeByteForApply() {
    try {
      final raw = sounderGeneralMode.value.trim();
      if (raw.isEmpty) throw FormatException('empty sounder general mode');
      return int.parse(raw, radix: 16) & 0xFF;
    } catch (_) {
      final cfg = GeneralEquipmentModeConfig(
        equipmentEnable:
            isSounderGeneralEnabled.value
                ? EquipmentEnable.enabled
                : EquipmentEnable.disabled,
        equipmentMode:
            isSounderGeneralTest.value
                ? EquipmentMode.test
                : EquipmentMode.normal,
        sounderDelay:
            isSounderGeneralDelay.value
                ? SounderDelay.enabled
                : SounderDelay.disabled,
      );
      final b = GeneralEquipmentModeCodec.encode(cfg);
      sounderGeneralMode.value = GeneralEquipmentModeCodec.encodeHex(cfg);
      return b;
    }
  }

  int _sounderZoneModeByteForApply({required int zoneMaxZone}) {
    late final ValueNotifier<String> modeHex;
    late final bool enabled;
    late final bool test;
    switch (zoneMaxZone) {
      case 1:
        modeHex = sounderZoneOneMode;
        enabled = isZoneOneEnabled.value;
        test = isZoneOneTest.value;
        break;
      case 2:
        modeHex = sounderZoneTwoMode;
        enabled = isZoneTwoEnabled.value;
        test = isZoneTwoTest.value;
        break;
      default:
        modeHex = sounderZoneThreeMode;
        enabled = isZoneThreeEnabled.value;
        test = isZoneThreeTest.value;
    }
    try {
      final raw = modeHex.value.trim();
      if (raw.isEmpty) throw FormatException('empty zone mode');
      return int.parse(raw, radix: 16) & 0xFF;
    } catch (_) {
      final cfg = ZoneEquipmentModeConfig(
        zoneEnable:
            enabled
                ? ZoneEquipmentEnable.enabled
                : ZoneEquipmentEnable.disabled,
        zoneMode: test ? ZoneEquipmentMode.test : ZoneEquipmentMode.normal,
        sounderDelay: ZoneSounderDelay.disabled,
      );
      final b = ZoneEquipmentModeCodec.encode(cfg);
      modeHex.value = ZoneEquipmentModeCodec.encodeHex(cfg);
      return b;
    }
  }

  int _sounderExtOutModeByteForApply({required int extMaxZone}) {
    late final ValueNotifier<String> modeHex;
    late final bool enabled;
    late final bool test;
    switch (extMaxZone) {
      case 1:
        modeHex = sounderExtOutOneMode;
        enabled = isExtOutOneEnabled.value;
        test = isExtOutOneTest.value;
        break;
      case 2:
        modeHex = sounderExtOutTwoMode;
        enabled = isExtOutTwoEnabled.value;
        test = isExtOutTwoTest.value;
        break;
      default:
        modeHex = sounderExtOutThreeMode;
        enabled = isExtOutThreeEnabled.value;
        test = isExtOutThreeTest.value;
    }
    try {
      final raw = modeHex.value.trim();
      if (raw.isEmpty) throw FormatException('empty ext out mode');
      return int.parse(raw, radix: 16) & 0xFF;
    } catch (_) {
      final cfg = ExtZoneEquipmentModeConfig(
        zoneEnable:
            enabled
                ? ExtZoneEquipmentEnable.enabled
                : ExtZoneEquipmentEnable.disabled,
        zoneMode:
            test ? ExtZoneEquipmentMode.test : ExtZoneEquipmentMode.normal,
      );
      final h = ExtZoneEquipmentModeCodec.encodeHex(cfg);
      modeHex.value = h;
      return int.parse(h, radix: 16) & 0xFF;
    }
  }

  Future<void> sendRelaySetupApplyFirstCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String outputText = relayOneSetupOutputText.value;
    final List<int> outputTextBytes = outputText.codeUnits;
    final outputTextLength = outputTextBytes.length;
    final initialindex = 26;

    for (int i = 0; i < outputTextLength; i++) {
      u8Pkt[initialindex + i] = outputTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x07;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x04;
    u8Pkt[15] = _relayOutputModeByteForApply(
      modeHex: relayOneMode,
      enabled: isRelayOneSetupEnabled.value,
      test: isRelayOneSetupTest.value,
    );
    u8Pkt[16] = 0x01;
    u8Pkt[17] = 0x00;
    u8Pkt[18] = 0x00;
    u8Pkt[19] = 0x00;
    u8Pkt[20] = 0x03;
    u8Pkt[21] = 0x00;
    u8Pkt[22] =
        relayOneSetupDynamicText.value.isNotEmpty
            ? _parseRelayDynamicFieldByte(relayOneSetupDynamicText.value)
            : 0x00;
    u8Pkt[23] = relayOneSetupGroup.value;
    u8Pkt[24] = relayOneSetupFunction.value;
    u8Pkt[25] = outputTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Apply First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupApplySecondCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String outputText = relayTwoSetupOutputText.value;
    final List<int> outputTextBytes = outputText.codeUnits;
    final outputTextLength = outputTextBytes.length;
    final initialindex = 26;

    for (int i = 0; i < outputTextLength; i++) {
      u8Pkt[initialindex + i] = outputTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;

    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x07;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x05;
    u8Pkt[15] = _relayOutputModeByteForApply(
      modeHex: relayTwoMode,
      enabled: isRelayTwoSetupEnabled.value,
      test: isRelayTwoSetupTest.value,
    );
    u8Pkt[16] = 0x01;
    u8Pkt[17] = 0x00;
    u8Pkt[18] = 0x00;
    u8Pkt[19] = 0x00;
    u8Pkt[20] = 0x04;
    u8Pkt[21] = 0x00;
    u8Pkt[22] =
        relayTwoSetupDynamicText.value.isNotEmpty
            ? _parseRelayDynamicFieldByte(relayTwoSetupDynamicText.value)
            : 0x00;
    u8Pkt[23] = relayTwoSetupGroup.value;
    u8Pkt[24] = relayTwoSetupFunction.value;
    u8Pkt[25] = outputTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Apply Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupApplyThirdCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String outputText = relayThreeSetupOutputText.value;
    final List<int> outputTextBytes = outputText.codeUnits;
    final outputTextLength = outputTextBytes.length;
    final initialindex = 26;

    for (int i = 0; i < outputTextLength; i++) {
      u8Pkt[initialindex + i] = outputTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x07;
    u8Pkt[13] = 0x00;
    u8Pkt[14] = 0x06;
    u8Pkt[15] = _relayOutputModeByteForApply(
      modeHex: relayThreeMode,
      enabled: isRelayThreeSetupEnabled.value,
      test: isRelayThreeSetupTest.value,
    );
    u8Pkt[16] = 0x01;
    u8Pkt[17] = 0x00;
    u8Pkt[18] = 0x00;
    u8Pkt[19] = 0x00;
    u8Pkt[20] = 0x05;
    u8Pkt[21] = 0x00;
    u8Pkt[22] =
        relayThreeSetupDynamicText.value.isNotEmpty
            ? _parseRelayDynamicFieldByte(relayThreeSetupDynamicText.value)
            : 0x00;
    u8Pkt[23] = relayThreeSetupGroup.value;
    u8Pkt[24] = relayThreeSetupFunction.value;
    u8Pkt[25] = outputTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Relay Setup Apply Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupFetchFirstCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x04;
    u8Pkt[13] = 0x01;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Fetch First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupFetchSecondCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x04;
    u8Pkt[13] = 0x02;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Fetch Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupFetchThirdCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x04;
    u8Pkt[13] = 0x03;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Fetch Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupApplyFirstCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String zoneText = zoneOneSetupText.value;
    final List<int> zoneTextBytes = zoneText.codeUnits;
    final zoneTextLength = zoneTextBytes.length;
    final initialindex = 19;

    for (int i = 0; i < zoneTextLength; i++) {
      u8Pkt[initialindex + i] = zoneTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x04;
    u8Pkt[13] = 0x01;
    u8Pkt[14] =
        zoneOneSetupMode.value.isNotEmpty
            ? int.parse(zoneOneSetupMode.value, radix: 16)
            : 0x00;
    u8Pkt[15] = zoneOneSetupDetectionMode.value & 0xFF;
    print(
      "zoneOneSetupDetectionMode.value: ${zoneOneSetupDetectionMode.value}",
    );
    print(
      "zoneOneSetupVerificationTime.value: ${zoneOneSetupVerificationTime.value}",
    );
    u8Pkt[16] =
        zoneOneSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneOneSetupVerificationTime.value)
            : 0x00;
    u8Pkt[17] = zoneOneSetupDetectionMode.value == 3 ? 0x1E : 0x00;
    u8Pkt[18] = zoneTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Apply First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupApplySecondCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String zoneText = zoneTwoSetupText.value;
    final List<int> zoneTextBytes = zoneText.codeUnits;
    final zoneTextLength = zoneTextBytes.length;
    final initialindex = 19;

    for (int i = 0; i < zoneTextLength; i++) {
      u8Pkt[initialindex + i] = zoneTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x04;
    u8Pkt[13] = 0x02;
    u8Pkt[14] =
        zoneTwoSetupMode.value.isNotEmpty
            ? int.parse(zoneTwoSetupMode.value, radix: 16)
            : 0x00;
    u8Pkt[15] = zoneTwoSetupDetectionMode.value & 0xFF;
    print(
      "zoneTwoSetupDetectionMode.value: ${zoneTwoSetupDetectionMode.value}",
    );
    print(
      "zoneTwoSetupVerificationTime.value: ${zoneTwoSetupVerificationTime.value}",
    );
    u8Pkt[16] =
        zoneTwoSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneTwoSetupVerificationTime.value)
            : 0x00;
    u8Pkt[17] = zoneTwoSetupDetectionMode.value == 3 ? 0x1E : 0x00;
    u8Pkt[18] = zoneTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Apply Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupApplyThirdCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String zoneText = zoneThreeSetupText.value;
    final List<int> zoneTextBytes = zoneText.codeUnits;
    final zoneTextLength = zoneTextBytes.length;
    final initialindex = 19;

    for (int i = 0; i < zoneTextLength; i++) {
      u8Pkt[initialindex + i] = zoneTextBytes[i];
    }

    // Update global counters
    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x04;
    u8Pkt[13] = 0x03;
    u8Pkt[14] =
        zoneThreeSetupMode.value.isNotEmpty
            ? int.parse(zoneThreeSetupMode.value, radix: 16)
            : 0x00;
    u8Pkt[15] = zoneThreeSetupDetectionMode.value & 0xFF;
    print(
      "zoneThreeSetupDetectionMode.value: ${zoneThreeSetupDetectionMode.value}",
    );
    print(
      "zoneThreeSetupVerificationTime.value: ${zoneThreeSetupVerificationTime.value}",
    );
    u8Pkt[16] =
        zoneThreeSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneThreeSetupVerificationTime.value)
            : 0x00;
    u8Pkt[17] = zoneThreeSetupDetectionMode.value == 3 ? 0x1E : 0x00;
    u8Pkt[18] = zoneTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Zone Setup Apply Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRadioSetupFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x1D;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Radio Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRadioSetupApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String radioNameText = radioSetupName.value;
    final List<int> radioNameTextBytes = radioNameText.codeUnits;
    final radioNameTextLength = radioNameTextBytes.length;

    final initialindex = 21;
    for (int i = 0; i < 16; i++) {
      if (i < radioNameTextLength) {
        u8Pkt[initialindex + i] = radioNameTextBytes[i];
      } else {
        u8Pkt[initialindex + i] = 0x20;
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
        u8Pkt[initialSetupNoindex + i] = radioNoTextBytes[i] & 0xFF;
      } else {
        u8Pkt[initialSetupNoindex + i] = 0x00; // pad with 0
      }
    }
    // Update global counters
    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x1D;
    u8Pkt[13] = isRadioSetupEnabled.value ? 0x01 : 0x00;
    u8Pkt[14] = radioSetupModule.value & 0xFF;
    u8Pkt[15] = isRadioSetupAdvertised.value ? 0x01 : 0x00;
    u8Pkt[16] = isRadioSetupConnected.value ? 0x01 : 0x00;
    u8Pkt[17] = isRadioSetupProgrammed.value ? 0x01 : 0x00;
    u8Pkt[18] = isRadioSetupBooted.value ? 0x01 : 0x00;
    u8Pkt[19] = isRadioSetupServiced.value ? 0x01 : 0x00;
    u8Pkt[20] = radioNameTextLength & 0xFF;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Radio Setup Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendModuleSetupFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    // Update global counters
    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x00;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x01;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Module Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendLBusSetupFetchCmdPkt({required int lBusNo}) async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = 0xFE;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & 0xFF;
    u8Pkt[5] = u8RxPktCnt & 0xFF;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x10;
    u8Pkt[13] = lBusNo;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & 0xFF;
    u8Pkt[214] = checksum & 0xFF;
    u8Pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: L-Bus $lBusNo Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendLBusEnabledBusDataFetchCmdPkt({required int lBusNo}) async {
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
    u8_pkt[8] = lBusNo;
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x01; // command
    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: L-Bus Enabled Bus $lBusNo Data Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
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
    int function = 0;
    int group = 0;
    if (outputMaxZone == 1) {
      outputText = sounderOneOutputText.value;
      outputNo = sounderOneFunctionNo.value;
      function = sounderOneRelayFunction.value;
      group = sounderOneRelayFunctionGroup.value;
      print("Sounder One Function No: $outputNo");
    } else if (outputMaxZone == 2) {
      outputText = sounderTwoOutputText.value;
      outputNo = sounderTwoFunctionNo.value;
      function = sounderTwoRelayFunction.value;
      group = sounderTwoRelayFunctionGroup.value;
    } else if (outputMaxZone == 3) {
      outputText = sounderThreeOutputText.value;
      outputNo = sounderThreeFunctionNo.value;
      function = sounderThreeRelayFunction.value;
      group = sounderThreeRelayFunctionGroup.value;
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
    u8_pkt[15] = _sounderRelayOutputModeByteForApply(
      outputMaxZone: outputMaxZone,
    );
    u8_pkt[16] = 0x02;
    u8_pkt[20] = outputMaxZone;
    u8_pkt[21] = 0x01;
    u8_pkt[22] = outputNo;
    u8_pkt[23] = group;
    u8_pkt[24] = function;
    u8_pkt[25] = outputTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup Relay $outputMaxZone Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupGeneralApplyCmdPkt() async {
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
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x14; // command
    u8_pkt[13] = 0x00;
    u8_pkt[14] = _sounderGeneralEquipmentModeByteForApply(); // general mode
    u8_pkt[15] = sounderGeneralAction.value; // general action
    u8_pkt[18] =
        (sounderGeneralDelay.value >> 8) & 0xFF; // general delay byte 1
    u8_pkt[19] = sounderGeneralDelay.value & 0xFF; // general delay byte 2

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup General Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupZoneApplyCmdPkt({
    required int zoneMaxZone,
  }) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    int zoneAction = 0;
    if (zoneMaxZone == 1) {
      zoneAction = zoneOneAction.value;
    } else if (zoneMaxZone == 2) {
      zoneAction = zoneTwoAction.value;
    } else if (zoneMaxZone == 3) {
      zoneAction = zoneThreeAction.value;
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
    u8_pkt[12] = 0x19; // command
    u8_pkt[13] = zoneMaxZone; // ext max zone
    u8_pkt[14] = 0x00;
    u8_pkt[15] = _sounderZoneModeByteForApply(zoneMaxZone: zoneMaxZone);
    u8_pkt[16] = zoneAction;
    u8_pkt[19] =
        (sounderGeneralDelay.value >> 8) & 0xFF; // general delay byte 1
    u8_pkt[20] = sounderGeneralDelay.value & 0xFF; // general delay byte 2
    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup Zone $zoneMaxZone Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendSounderSetupExtOutApplyCmdPkt({
    required int extMaxZone,
  }) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    int extOutCountdownAction = 0;
    int extOutHoldAction = 0;
    int extOutReleaseAction = 0;
    if (extMaxZone == 1) {
      extOutCountdownAction = extoutOneCountdownAction.value;
      extOutHoldAction = extoutOneHoldAction.value;
      extOutReleaseAction = extoutOneReleaseAction.value;
    } else if (extMaxZone == 2) {
      extOutCountdownAction = extoutTwoCountdownAction.value;
      extOutHoldAction = extoutTwoHoldAction.value;
      extOutReleaseAction = extoutTwoReleaseAction.value;
    } else if (extMaxZone == 3) {
      extOutCountdownAction = extoutThreeCountdownAction.value;
      extOutHoldAction = extoutThreeHoldAction.value;
      extOutReleaseAction = extoutThreeReleaseAction.value;
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
    u8_pkt[12] = 0x1B; // command
    u8_pkt[13] = 0x01;
    u8_pkt[14] = extMaxZone; // ext max zone
    u8_pkt[15] = _sounderExtOutModeByteForApply(extMaxZone: extMaxZone);
    u8_pkt[16] = extOutCountdownAction;
    u8_pkt[17] = extOutHoldAction;
    u8_pkt[18] = extOutReleaseAction;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Sounder Setup Ext Out $extMaxZone Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendServiceDueFetchCmdPkt() async {
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
    u8_pkt[12] = 0x18; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Service due fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendServiceDueApplyCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String serviceDueCompanyText = serviceDueCompany.value;
    final String serviceDueContactText = serviceDueContact.value;

    final List<int> serviceDueCompanyTextBytes =
        serviceDueCompanyText.codeUnits;
    final List<int> serviceDueContactTextBytes =
        serviceDueContactText.codeUnits;

    final int serviceDueCompanyTextLength = serviceDueCompanyTextBytes.length;
    final int serviceDueContactTextLength = serviceDueContactTextBytes.length;

    final serviceDueCompanyTextInitialIndex = 21;
    final serviceDueContactTextInitialIndex = 35;

    for (int i = 0; i < serviceDueCompanyTextLength; i++) {
      u8_pkt[serviceDueCompanyTextInitialIndex + i] =
          serviceDueCompanyTextBytes[i];
    }
    for (int i = 0; i < serviceDueContactTextLength; i++) {
      u8_pkt[serviceDueContactTextInitialIndex + i] =
          serviceDueContactTextBytes[i];
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
    u8_pkt[12] = 0x18; // command
    u8_pkt[13] = (serviceDueYear.value >> 8) & 0xFF;
    u8_pkt[14] = serviceDueYear.value & 0xFF;
    u8_pkt[15] = serviceDueMonth.value & 0xFF;
    u8_pkt[16] = serviceDueDay.value & 0xFF;
    u8_pkt[17] = serviceDueHour.value & 0xFF;
    u8_pkt[18] = serviceDueMinute.value & 0xFF;
    u8_pkt[19] = serviceDueReminder.value;
    u8_pkt[20] = serviceDueCompanyTextLength & 0xFF;
    u8_pkt[34] = serviceDueContactTextLength & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Service due Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendAccessCodeSetupFetchCmdPkt({
    required int accessCodeNo,
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
    u8_pkt[12] = 0x03; // command
    u8_pkt[13] = accessCodeNo; // access code no

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Access Code $accessCodeNo Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendAccessCodeSetupApplyCmdPkt({
    required int accessCodeNo,
  }) async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final data = accessCodeSetupDataList.value[accessCodeNo - 1];

    final String accessCodeText = data.accessCode;
    final List<int> accessCodeTextBytes = accessCodeText.codeUnits;
    final accessCodeTextLength = accessCodeTextBytes.length;

    print("accessCodeText: $accessCodeText");
    print("accessCodeNo: ${data.accessCodeNo}");

    final initialindex = 16;
    for (int i = 0; i < accessCodeTextLength; i++) {
      if (i < accessCodeTextLength) {
        u8_pkt[initialindex + i] = accessCodeTextBytes[i];
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
    u8_pkt[12] = 0x03; // command
    u8_pkt[13] = data.accessCodeNo; // access code no
    u8_pkt[14] = data.accessLevel; // access level
    u8_pkt[15] = accessCodeTextLength & 0xFF; // access code text length

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Access Code $accessCodeNo Setup Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendPanelInfoPanelIdFetchCmdPkt() async {
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
    u8_pkt[12] = 0x08; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Panel info fetch Panel ID Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendPanelInfoDateTimeFetchCmdPkt() async {
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
    u8_pkt[10] = 0x03; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x01; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Panel info fetch DateTime Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendPanelInfoEventReminderDelayFetchCmdPkt() async {
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
    u8_pkt[12] = 0x09; // command
    u8_pkt[13] = 0x04; // delay type -> Event Reminder

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Panel info fetch Event Reminder Delay Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendPanelInfoPanelIdApplyCmdPkt() async {
    // Create 216-byte buffer
    Uint8List u8_pkt = Uint8List(216);

    final String panelNameText = panelInfoPanelName.value;
    final List<int> panelNameTextBytes = panelNameText.codeUnits;
    final panelNameTextLength = panelNameTextBytes.length;

    final initialindex = 19;
    for (int i = 0; i < panelNameTextLength; i++) {
      if (i < panelNameTextLength) {
        u8_pkt[initialindex + i] = panelNameTextBytes[i];
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
    u8_pkt[12] = 0x08; // command
    u8_pkt[16] = panelInfoPanelNo.value; // panel no
    u8_pkt[18] = panelNameTextLength & 0xFF; // panel name text length

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Panel info Apply Panel ID Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendPanelInfoDateTimeApplyCmdPkt() async {
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
    u8_pkt[10] = 0x83; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x01; // command
    u8_pkt[13] = (panelInfoYear.value >> 8) & 0xFF; // year
    u8_pkt[14] = panelInfoYear.value & 0xFF; // year
    u8_pkt[15] = panelInfoMonth.value & 0xFF; // month
    u8_pkt[16] = panelInfoDay.value & 0xFF; // day
    u8_pkt[17] = panelInfoHour.value & 0xFF; // hour
    u8_pkt[18] = panelInfoMinute.value & 0xFF; // minute
    u8_pkt[19] = panelInfoSecond.value & 0xFF; // second

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Panel info apply DateTime Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendPanelInfoEventReminderDelayApplyCmdPkt() async {
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
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x09; // command
    u8_pkt[13] = 0x04; // delay type -> Event Reminder
    u8_pkt[14] = 0x01; // delay Mode
    u8_pkt[15] =
        (panelInfoEventReminderDelay.value >> 8) &
        0xFF; // delay value first byte
    u8_pkt[16] =
        panelInfoEventReminderDelay.value & 0xFF; // delay value second byte

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Panel info apply Event Reminder Delay Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleLvlTimeOutFetchCmdPkt() async {
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
    u8_pkt[12] = 0x09; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module fetch LVL Time-out Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleSilenceBuzzerLvlFetchCmdPkt() async {
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
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x09;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module fetch Silence Buzzer LVL Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleSilenceSounderLvlFetchCmdPkt() async {
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
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x0A;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module fetch Silence Sounder LVL Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleResetLvlFetchCmdPkt() async {
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
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x0C;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module fetch Reset LVL Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleFaultLatchingFetchCmdPkt() async {
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
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x12;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module fetch Fault Latching Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleLvlTimeOutApplyCmdPkt() async {
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
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x09; // command
    u8_pkt[14] = 0x01;
    u8_pkt[15] = (generalModuleLvlTimeOut.value >> 8) & 0xFF;
    u8_pkt[16] = generalModuleLvlTimeOut.value & 0xFF;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module apply LVL Time-out Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleSilenceBuzzerLvlApplyCmdPkt() async {
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
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x09;
    u8_pkt[14] = generalModuleSilenceBuzzerLvl.value + 1;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module apply Silence Buzzer LVL Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleSilenceSounderLvlApplyCmdPkt() async {
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
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x0A;
    u8_pkt[14] = generalModuleSilenceSounderLvl.value + 2;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module apply Silence Sounder LVL Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleResetLvlApplyCmdPkt() async {
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
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x0C;
    u8_pkt[14] = generalModuleResetLvl.value + 2;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module apply Reset LVL Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendGeneralModuleFaultLatchingApplyCmdPkt() async {
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
    u8_pkt[10] = 0x81; // mode
    u8_pkt[11] = 0x00; // socket number
    u8_pkt[12] = 0x15; // command
    u8_pkt[13] = 0x12;
    u8_pkt[14] = generalModuleFaultLatching.value;

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: General module apply Fault Latching Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }

  Future<void> sendDiagnosticsSetupFetchCmdPkt() async {
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
    u8_pkt[12] = 0x09; // command

    // Compute checksum on first 213 bytes
    int checksum = toolsFletcherChecksum(u8_pkt.sublist(0, 213));

    u8_pkt[213] = (checksum >> 8) & 0xFF;
    u8_pkt[214] = checksum & 0xFF;
    u8_pkt[215] = 0xFD;

    print(
      "TX/RX: TRANSMIT: Diagnostics Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8_pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
    );

    await sendSmallDataFrame(0x1000, 216, u8_pkt);
  }
}
