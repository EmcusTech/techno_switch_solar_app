import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/utils/constants/ble_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'ble_frame.dart';
import 'aes_key.dart' as aes;
import 'ble_crypto.dart';
import 'ble_encryption_config.dart';
import 'ble_process.dart';
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

const String BLE_AUTHN_MSG = StringConstants.bleAuthMsg;

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
  final Uuid serviceUuid = Uuid.parse(StringConstants.bleServiceUuid);
  final Uuid notifyUuid = Uuid.parse(StringConstants.bleNotifyUuid);
  final Uuid writeUuid = Uuid.parse(StringConstants.bleWriteUuid);

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
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.logRetrieval;

    resetLogRetrievalState();
    resetProtocolState();
    bleProcess.resetProcessState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
    bleStateMachineState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startSessionAccessCodeValidation() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
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
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.liveEventsRetrieval;

    resetLiveEventsRetrievalState();
    resetProtocolState();
    bleProcess.resetProcessState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    otaProcessState = OtaProcessState.sendLiveEventsRetrievalFetchCmdPkt;
    bleCurrentState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
    bleStateMachineState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> stopLiveEventsRetrieval() async {
    bleProcess.stopLiveEventSetup();
  }

  Future<void> startExtOutFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.extOutFetch;

    resetExtOutState();
    resetProtocolExtOutState();
    bleProcess.resetProcessExtOutState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startExtOutApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.extOutApply;

    resetExtOutState();
    resetProtocolExtOutState();
    bleProcess.resetProcessExtOutState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startInputSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.inputSetupFetch;

    resetInputSetupState();
    resetProtocolInputSetupState();
    bleProcess.resetProcessInputSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startInputSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.inputSetupApply;

    resetInputSetupState();
    resetProtocolInputSetupState();
    bleProcess.resetProcessInputSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRelaySetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.relaySetupFetch;

    resetRelaySetupState();
    resetProtocolRelaySetupState();
    bleProcess.resetProcessRelaySetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRelaySetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.relaySetupApply;

    resetRelaySetupState();
    resetProtocolRelaySetupState();
    bleProcess.resetProcessRelaySetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startZoneSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.zoneSetupFetch;

    resetZoneSetupState();
    resetProtocolZoneSetupState();
    bleProcess.resetProcessZoneSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startZoneSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.zoneSetupApply;

    resetRelaySetupState();
    resetProtocolZoneSetupState();
    bleProcess.resetProcessZoneSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRadioSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.radioSetupFetch;

    resetRadioSetupState();
    resetProtocolRadioSetupState();
    bleProcess.resetProcessRadioSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startRadioSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.radioSetupApply;

    resetRadioSetupState();
    resetProtocolRadioSetupState();
    bleProcess.resetProcessRadioSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startModuleSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.moduleSetupFetch;

    resetModuleSetupState();
    resetProtocolModuleSetupState();
    bleProcess.resetProcessModuleSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startLBusSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.lBusSetupFetch;

    resetLBusSetupState();
    resetProtocolLBusSetupState();
    bleProcess.resetProcessLBusSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startLBusSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.lBusSetupApply;

    resetLBusSetupState();
    resetProtocolLBusSetupState();
    bleProcess.resetProcessLBusSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startSounderSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.sounderSetupFetch;

    resetSounderSetupState();
    resetProtocolSounderSetupState();
    bleProcess.resetProcessSounderSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startSounderSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.sounderSetupApply;

    resetSounderSetupState();
    resetProtocolSounderSetupState();
    bleProcess.resetProcessSounderSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startServiceDueFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.serviceDueFetch;

    resetServiceDueState();
    resetProtocolServiceDueState();
    bleProcess.resetProcessServiceDueState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startServiceDueApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.serviceDueApply;

    resetServiceDueState();
    resetProtocolServiceDueState();
    bleProcess.resetProcessServiceDueState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startAccessCodeSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.accessCodeSetupFetch;

    resetAccessCodeSetupState();
    resetProtocolAccessCodeSetupState();
    bleProcess.resetProcessAccessCodeSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startAccessCodeSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.accessCodeSetupApply;

    resetAccessCodeSetupState();
    resetProtocolAccessCodeSetupState();
    bleProcess.resetProcessAccessCodeSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startPanelInfoSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.panelInfoSetupFetch;

    resetPanelInfoSetupState();
    resetProtocolPanelInfoSetupState();
    bleProcess.resetProcessPanelInfoSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startPanelInfoSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.panelInfoSetupApply;

    resetPanelInfoSetupState();
    resetProtocolPanelInfoSetupState();
    bleProcess.resetProcessPanelInfoSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startGeneralModuleSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.generalModuleSetupFetch;

    resetGeneralModuleSetupState();
    resetProtocolGeneralModuleSetupState();
    bleProcess.resetProcessGeneralModuleSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startGeneralModuleSetupApply() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.generalModuleSetupApply;

    resetGeneralModuleSetupState();
    resetProtocolGeneralModuleSetupState();
    bleProcess.resetProcessGeneralModuleSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_APPLY_PACKET;
    bleStateMachineState = BleStates.SEND_GENERAL_MODULE_SETUP_CMD_APPLY_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> startAdcSetupFetch() async {
    if (!isConnected) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    if (notifyChar == null || writeChar == null) {
      throw Exception(StringConstants.bleCharNotInit);
    }

    currentOperationMode = BleOperationMode.adcSetupFetch;

    resetAdcSetupState();
    resetProtocolAdcSetupState();
    bleProcess.resetProcessAdcSetupState();

    if (_notifySub == null) {
      throw Exception(StringConstants.bleHandshakeIncomplete);
    }

    bleCurrentState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
    bleStateMachineState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
    bleProcess.startOtherPacketsRxTimeout(timeout: const Duration(seconds: 5));
    Get.find<BleLogController>().sendNetworkPacket();
  }

  Future<void> safeDisconnect() async {
    final deviceId = connectedDeviceId.value;
    if (deviceId.isEmpty) return;

    try {
      bleProcess.cancelRxTimeout();
      await disconnectHandler(deviceId: deviceId);
    } catch (_) {
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
      _handshakeCompleter!.completeError(
        Exception(StringConstants.bleSessionReset),
      );
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
        Exception(StringConstants.bleConnAbort),
      );
      _handshakeCompleter = null;
    }

    if (forceAbortNative || hadGatt) {
      try {
        await flutterReactiveBle.abortConnection(deviceId);
      } catch (_) {}
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
    Logger("Attempting to connect to device: ${device.id}");

    if (isConnected) {
      shutdown();
      return;
    }

    if (_connectInProgress) {
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
        Logger("BLE connect attempt $attempt / $maxRetries");

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
          Logger(StringConstants.bleConnSuccess);
          return;
        } catch (e) {
          Logger("BLE attempt $attempt failed: $e");

          await _tearDownConnectionAttempt(
            device.id,
            forceAbortNative: attempt >= maxRetries,
          );
          selectedDevice = null;
          connectedBtDevice.value = null;
          connectedDeviceId.value = '';

          resetLogRetrievalState();

          if (attempt >= maxRetries) {
            processDesc.value = StringConstants.bleMaxRetryReached;
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
      Logger(StringConstants.bleClearingGattCache);
      await flutterReactiveBle.clearGattCache(deviceId);
      Logger(StringConstants.bleClearedGattCache);
    } catch (_) {}
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
      throw Exception(StringConstants.blePermissionNotGranted);
    }

    final Completer<void> connectedCompleter = Completer();
    var ignoreInitialDisconnectedEmission = true;
    List<int> md = device.manufacturerData;

    Logger(
      "DEBUG CONNECTION: Device manufacturer data - Full array: $md, Length: ${md.length}",
    );

    if (manufacturerDataOverride != null) {
      md = [manufacturerDataOverride];
      Logger(
        "DEBUG CONNECTION: Using manufacturer data override: $manufacturerDataOverride (as array: $md)",
      );
    } else if (md.isEmpty &&
        selectedDevice != null &&
        selectedDevice!.id == device.id) {
      md = selectedDevice!.manufacturerData;
      Logger(
        "DEBUG CONNECTION: Using manufacturer data from selectedDevice - Full array: $md, Length: ${md.length}, Status byte: ${BleMsdUtils.statusByte(md)}",
      );
    } else if (md.isEmpty) {}
    final statusByte = manufacturerDataOverride ?? BleMsdUtils.statusByte(md);

    _connectionSub = flutterReactiveBle
        .connectToDevice(id: device.id, connectionTimeout: connectionTimeout)
        .listen(
          (update) async {
            if (update.connectionState == DeviceConnectionState.connected) {
              bleManufacturerData.value = statusByte;
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
                  Exception(StringConstants.disconnectHandshake),
                );
                _handshakeCompleter = null;
              }

              if (!connectedCompleter.isCompleted) {
                connectedCompleter.completeError(
                  Exception(StringConstants.disconnectConn),
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
    if (_notifySub != null) {
      try {
        await _notifySub?.cancel();
      } catch (e) {}
      _notifySub = null;
    }

    if (!isConnected) {
      return;
    }

    if (notifyChar == null) {
      return;
    }

    try {
      _notifySub = flutterReactiveBle
          .subscribeToCharacteristic(notifyChar!)
          .listen(
            (data) => notificationHandler(Uint8List.fromList(data)),
            onError: (e) {
              _notifySub = null;
            },
          );

      await Future.delayed(const Duration(milliseconds: 300));

      if (isChipInBootLoader != true) {
        bleProcess.requestENCKey();
      } else {
        bleStateMachineState = BleStates.SEND_AUTHN_MSG;
        bleCurrentState = BleStates.SEND_AUTHN_MSG;
        bleProcess.sendAuthPacket();
      }
    } catch (e) {
      _notifySub = null;
      rethrow;
    }
  }

  Future<void> disconnectConnectedDevice() async {
    receivedPanelName.value = "";
    if (!isConnected) {
      return;
    }

    fbp.BluetoothDevice? device = connectedBtDevice.value;

    if (device == null && selectedDevice != null) {
      device = fbp.BluetoothDevice.fromId(selectedDevice!.id);
    }

    try {
      if (device != null) {
        await device.disconnect();
      } else {
        return;
      }
    } catch (e) {
    } finally {
      final deviceId = device?.remoteId.str ?? connectedDeviceId.value;
      connectedBtDevice.value = null;
      await disconnectHandler(deviceId: deviceId);
    }
  }

  Future<void> disconnectHandler({String? deviceId}) async {
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
    final dynamic key = bleAESKey[StringConstants.bleAeskey];
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
    final List<int> key = bleAESKey[StringConstants.bleAeskey] as List<int>;
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

  bool _isFirmwareTransferState(BleStates state) {
    return state == BleStates.SEND_JUMP_FIRMWARE_PACKET ||
        state == BleStates.SEND_START_FIRMWARE_PACKET ||
        state == BleStates.SEND_FIRMWARE_PACKET ||
        state == BleStates.SEND_END_FIRMWARE_PACKET;
  }

  Uint8List _decryptIncomingFrame(Uint8List data) {
    final List<int> key = bleAESKey[StringConstants.bleAeskey] as List<int>;
    return BleCrypto.transformRx(data, key);
  }

  Future<void> notificationHandler(Uint8List data) async {
    if ((bleProcess.isOtaCompleted ||
            otaProcessState == OtaProcessState.notInUse) &&
        isBleDisconnected) {
      return;
    }

    txData = 1;
    bleProcess.cancelRxTimeout();
    _pollInFlight = false;

    if (_shouldDecryptIncomingFrame()) {
      data = _decryptIncomingFrame(data);
    }

    if (_isFirmwareTransferState(bleCurrentState)) {
      // OTA TX is driven from firmware_upgrade_bottom_sheet; ignore RX here.
      return;
    }

    if (bleCurrentState == BleStates.REQ_ENCY_KEY) {
      bleRxFrame = bleParseAndUpdateRxFrame(data, data.length);
      if (bleValidateRxFrame(bleRxFrame)) {
        final List<int> payload = bleRxFrame.payload;
        bleAESKey[StringConstants
            .bleAeskey] = BleCrypto.extractKeyFromHandshakePayload(payload);

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
        } else {
          bleFirmwareVersion.value = '';
        }

        await Future.delayed(Duration(milliseconds: 300));
        bleStateMachineState = BleStates.SEND_AUTHN_MSG;
        bleCurrentState = BleStates.SEND_AUTHN_MSG;

        bleProcess.sendAuthPacket();
      }
    } else if (bleCurrentState == BleStates.SEND_AUTHN_MSG) {
      bleRxFrame = bleParseAndUpdateRxFrame(data, data.length);

      if (bleValidateRxFrame(bleRxFrame)) {
        await Future.delayed(Duration(seconds: 1));

        if (currentOperationMode == BleOperationMode.none) {
          bleCurrentState = BleStates.IDLE;
          bleStateMachineState = BleStates.IDLE;
          if (_handshakeCompleter != null &&
              !_handshakeCompleter!.isCompleted) {
            _handshakeCompleter!.complete();
          }
        } else if (currentOperationMode == BleOperationMode.firmwareUpgrade) {
          bleCurrentState = BleStates.SEND_START_FIRMWARE_PACKET;
          bleStateMachineState = BleStates.SEND_START_FIRMWARE_PACKET;
        } else if (currentOperationMode == BleOperationMode.logRetrieval) {
          bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
          bleStateMachineState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.extOutFetch) {
          bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.extOutApply) {
          bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_EXT_OUT_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.inputSetupFetch) {
          bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.inputSetupApply) {
          bleCurrentState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_INPUT_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.relaySetupFetch) {
          bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.relaySetupApply) {
          bleCurrentState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_RELAY_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.zoneSetupFetch) {
          bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.zoneSetupApply) {
          bleCurrentState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_ZONE_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.radioSetupFetch) {
          bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.radioSetupApply) {
          bleCurrentState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_RADIO_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.moduleSetupFetch) {
          bleCurrentState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_MODULE_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.lBusSetupFetch) {
          bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.lBusSetupApply) {
          bleCurrentState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_L_BUS_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.sounderSetupFetch) {
          bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.sounderSetupApply) {
          bleCurrentState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState = BleStates.SEND_SOUNDER_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.serviceDueFetch) {
          bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState =
              BleStates.SEND_SERVICE_DUE_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.serviceDueApply) {
          bleCurrentState = BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState =
              BleStates.SEND_SERVICE_DUE_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.accessCodeSetupFetch) {
          bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState =
              BleStates.SEND_ACCESS_CODE_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.accessCodeSetupApply) {
          bleCurrentState = BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState =
              BleStates.SEND_ACCESS_CODE_SETUP_CMD_APPLY_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.panelInfoSetupFetch) {
          bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState =
              BleStates.SEND_PANEL_INFO_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.panelInfoSetupApply) {
          bleCurrentState = BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
          bleStateMachineState =
              BleStates.SEND_PANEL_INFO_SETUP_CMD_APPLY_PACKET;
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
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode ==
            BleOperationMode.liveEventsRetrieval) {
          bleCurrentState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
          bleStateMachineState = BleStates.PROCESS_PANEL_LIVE_EVENTS_READ;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        } else if (currentOperationMode == BleOperationMode.adcSetupFetch) {
          bleCurrentState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
          bleStateMachineState = BleStates.SEND_ADC_SETUP_CMD_FETCH_PACKET;
          bleProcess.startOtherPacketsRxTimeout(
            timeout: const Duration(seconds: 5),
          );
          Get.find<BleLogController>().sendNetworkPacket();
        }
      }
    } else {
      receivedPollCount++;
      bleParseAndUpdateRxFrame(data, data.length);

      if (bleValidateRxFrame(bleRxFrame)) {
        await bleProcess.bleRxFrameProcess(bleRxFrame);
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

    int chk1 = (255 - ((sum1 + sum2) % 255)) & BleConstants.base;
    int chk2 = (255 - ((sum1 + chk1) % 255)) & BleConstants.base;

    return (chk1 << 8) | chk2;
  }

  List<int> convertToBytes(dynamic data) {
    if (data is List<int>) return data;
    if (data is String) return data.codeUnits;
    throw Exception(StringConstants.invalidDataByteConv);
  }

  static crcCcittFalse(
    List<int> data, {
    int poly = 0x1021,
    int initVal = BleConstants.baseFF,
  }) {
    int crc = initVal;

    for (int byte in data) {
      crc ^= (byte << 8) & BleConstants.baseFF;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ poly) & BleConstants.baseFF;
        } else {
          crc = (crc << 1) & BleConstants.baseFF;
        }
      }
    }
    return crc & BleConstants.baseFF;
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
    frameBuff[enBLE_CMD_MSB_POS] = (cmd >> 8) & BleConstants.base;
    frameBuff[enBLE_CMD_LSB_POS] = cmd & BleConstants.base;
    frameBuff[enBLE_TOF_POS] = typeOfFrame;
    frameBuff[enBLE_DATA_LEN_MSB_POS] = (dataLen >> 8) & BleConstants.base;
    frameBuff[enBLE_DATA_LEN_LSB_POS] = dataLen & BleConstants.base;

    for (int i = 0; i < dataLen; i++) {
      frameBuff[enBLE_DATA_POS + i] = data[i];
    }

    int crc = crcCcittFalse(frameBuff.sublist(0, enBLE_DATA_POS + dataLen));

    frameBuff[enBLE_DATA_POS + dataLen] = (crc >> 8) & BleConstants.base;
    frameBuff[enBLE_DATA_POS + 1 + dataLen] = crc & BleConstants.base;
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
      Logger("Sending data failed with error: $e");
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

    await sendData(frameBytes, encrypt: encrypt);
  }

  Future<void> sendAesKeyReq() async {
    List<int> reqFrame = bleFrameFormat(0x1000, 0x01, 1, [0x00]);

    Uint8List reqFrameBytes = aes.convertToBytes(reqFrame);

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

    Uint8List frameBytes = Uint8List.fromList(authnMsgFrame);

    await sendData(frameBytes);
  }

  Future<void> sendNetworkPacket() async {
    bleProcess.isNetworkPacketProcess.value = true;
    u8TxPktCnt = 0;

    List<int> u8Pkt = List.filled(216, 0);
    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.net;
    u8Pkt[4] = BleConstants.txPkNoInit;
    u8Pkt[5] = BleConstants.rxPkNoInit;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.moduleId;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Network Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPollPacket() async {
    if (bleProcess.isOtaCompleted &&
        otaProcessState == OtaProcessState.notInUse) {
      return;
    }

    if (_pollInFlight) {
      return;
    }
    _pollInFlight = true;

    List<int> pollPkt = List.filled(216, 0);
    pollPkt[0] = BleConstants.sot;
    pollPkt[1] = BleConstants.des;
    pollPkt[2] = BleConstants.ori;
    pollPkt[3] = BleConstants.type.poll;
    pollPkt[4] = (u8TxPktCnt + 1) & BleConstants.base;
    pollPkt[5] = (u8RxPktCnt & BleConstants.base);
    pollPkt[6] = BleConstants.network.radio;
    pollPkt[11] = BleConstants.socket.radio;

    int checksum = toolsFletcherChecksum(pollPkt.sublist(0, 216 - 3));

    pollPkt[213] = (checksum >> 8) & BleConstants.base;
    pollPkt[214] = checksum & BleConstants.base;
    pollPkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Poll Packet Command time: ${DateTime.now().toIso8601String()}, packet: ${pollPkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, pollPkt);
  }

  void resetPollInFlight() {
    _pollInFlight = false;
  }

  Future<void> sendAccessKeyPkt() async {
    u8TxPktCnt += 1;

    List<int> pkt = List.filled(216, 0);

    String accessKeyString = accessKey.value;
    List<int> accessKeyBytes = accessKeyString.codeUnits;
    accessKeyLength.value = accessKeyBytes.length;

    for (int i = 0; i < accessKeyLength.value; i++) {
      if (i < accessKeyLength.value) {
        pkt[14 + i] = accessKeyBytes[i];
      }
    }

    pkt[0] = BleConstants.sot;
    pkt[1] = BleConstants.des;
    pkt[2] = BleConstants.ori;
    pkt[3] = BleConstants.type.nrm;
    pkt[4] = u8TxPktCnt & BleConstants.base;
    pkt[5] = u8RxPktCnt & BleConstants.base;
    pkt[6] = BleConstants.network.radio;
    pkt[10] = BleConstants.mode.instruction.ctrl;
    pkt[11] = BleConstants.socket.radio;
    pkt[12] = BleConstants.command.ctrlAcces;
    pkt[13] = accessKeyLength.value & BleConstants.base;

    int checksum = toolsFletcherChecksum(pkt.sublist(0, 216 - 3));

    pkt[213] = (checksum >> 8) & BleConstants.base;
    pkt[214] = checksum & BleConstants.base;
    pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Access Command time: ${DateTime.now().toIso8601String()}, packet: ${pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, pkt);
  }

  Future<void> sendStartCntrlCmdPkt() async {
    u8TxPktCnt += 1;

    Uint8List u8Pkt = Uint8List(216);
    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.ctrl;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.ctrlResEventReport;
    u8Pkt[13] = BleConstants.ctrlResEvtReport.evtBufferMask.radioEvtPrinter;
    u8Pkt[14] = BleConstants.ctrlResEvtReport.evtBufferMode.start;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    Logger(
      "TX/RX: TRANSMIT: Start Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendStopCntrlCmdPkt() async {
    u8TxPktCnt += 1;

    Uint8List u8Pkt = Uint8List(216);
    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.ctrl;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.ctrlResEventReport;
    u8Pkt[13] = BleConstants.ctrlResEvtReport.evtBufferMask.radioEvtPrinter;
    u8Pkt[14] = BleConstants.ctrlResEvtReport.evtBufferMode.stop;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;
    Logger(
      "TX/RX: TRANSMIT: Stop Control Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendJumpFirmwarePacket({bool withoutResponse = true}) async {
    if (!isConnected || writeChar == null) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    final Uint8List jumpFrame = aes.convertToBytes(
      bleFrameFormat(
        BleConstants.command.bleJump,
        BleConstants.firmware.firmwareType,
        BleConstants.firmware.firmwarelen,
        [BleConstants.firmware.firmwareData],
      ),
    );
    final Uint8List dataToSend = _transformOutgoingFrame(
      jumpFrame,
      encrypt: true,
    );
    try {
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
      throw Exception(StringConstants.deviceNotConnected);
    }

    List<int> startFrame = bleFrameFormat(
      BleConstants.command.startFirmware,
      BleConstants.firmware.firmwareType,
      BleConstants.firmware.firmwarelen,
      [BleConstants.firmware.firmwareData],
    );
    try {
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: startFrame,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEndFirmwarePacket() async {
    if (!isConnected || writeChar == null) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    List<int> endFrame = bleFrameFormat(
      BleConstants.command.endFirmware,
      BleConstants.firmware.firmwareType,
      BleConstants.firmware.firmwarelen,
      [BleConstants.firmware.firmwareData],
    );
    try {
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: endFrame,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendFirmwarePacket(
    Uint8List packet, {
    bool? isFirstPacketAfterSkip = false,
  }) async {
    if (!isConnected || writeChar == null) {
      throw Exception(StringConstants.deviceNotConnected);
    }

    List<int> firmwareFrame = bleFrameFormat(
      isFirstPacketAfterSkip == true
          ? BleConstants.command.sendFirstFirmwarePktAfterSkip
          : BleConstants.command.sendFirmware,
      BleConstants.firmware.firmwareType,
      packet.toList().length,
      packet.toList(),
    );

    try {
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: firmwareFrame,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendFirmwarePackets(
    List<Uint8List> packets, {
    Duration interPacketDelay = const Duration(milliseconds: 20),
    void Function(int sent, int total)? onProgress,
  }) async {
    if (!isConnected || writeChar == null) {
      throw Exception(StringConstants.deviceNotConnected);
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.extOut;
    u8Pkt[13] = BleConstants.extZoneNo;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Ext Out fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.extOut;
    u8Pkt[13] = BleConstants.extZoneNo;
    u8Pkt[14] = int.parse(extZoneMode.value, radix: 16);
    u8Pkt[15] = BleConstants.extZoneTriggerArea;
    u8Pkt[16] = extZoneActuatorType.value;
    u8Pkt[17] = (autoDelay >> 8) & BleConstants.base;
    u8Pkt[18] = autoDelay & BleConstants.base;
    u8Pkt[19] = (manDelay >> 8) & BleConstants.base;
    u8Pkt[20] = manDelay & BleConstants.base;
    u8Pkt[21] = (releasePeriod >> 8) & BleConstants.base;
    u8Pkt[22] = releasePeriod & BleConstants.base;
    u8Pkt[23] = (resetDelay >> 8) & BleConstants.base;
    u8Pkt[24] = resetDelay & BleConstants.base;
    u8Pkt[25] = extZoneAction.value;
    u8Pkt[26] = extZoneFunction.value;
    u8Pkt[27] = BleConstants.extZoneValveDelay;
    u8Pkt[28] = BleConstants.extZoneExtractionTimeHigh;
    u8Pkt[29] = BleConstants.extZoneExtractionTimeLow;
    u8Pkt[30] = BleConstants.extZoneExtractionDelayHigh;
    u8Pkt[31] = BleConstants.extZoneExtractionDelayLow;
    u8Pkt[40] = extZoneTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Ext Out apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendFetchDipSettingPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.dipSetting;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Dip Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendInputSetupFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.inputSetup;
    u8Pkt[13] = BleConstants.inputSetupNoHigh;
    u8Pkt[14] = BleConstants.inputSetupNoLow;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Input Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendInputSetupApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String inputText = inputSetupText.value;
    final List<int> inputTextBytes = inputText.codeUnits;
    final inputTextLength = inputTextBytes.length;
    final initialindex = 26;

    for (int i = 0; i < inputTextLength; i++) {
      u8Pkt[initialindex + i] = inputTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.inputSetup;
    u8Pkt[13] = BleConstants.inputSetupNoHigh;
    u8Pkt[14] = BleConstants.inputSetupNoLow;
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
    u8Pkt[15] = inputModeByte & BleConstants.base;
    u8Pkt[16] = BleConstants.inputSetupType;
    u8Pkt[20] = BleConstants.inputSetupTypeParams;
    u8Pkt[21] = BleConstants.inputSetupTypeParams;
    u8Pkt[22] = BleConstants.inputSetupTypeParams;
    u8Pkt[23] = inputSetupGroup.value;
    u8Pkt[24] = inputSetupFunction.value;
    u8Pkt[25] = inputTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Input Setup Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupFetchFirstCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.relaySetup;
    u8Pkt[13] = BleConstants.firstOutputNoHigh;
    u8Pkt[14] = BleConstants.firstOutputNoLow;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: First Relay Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupFetchSecondCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.relaySetup;
    u8Pkt[13] = BleConstants.secondOutputNoHigh;
    u8Pkt[14] = BleConstants.secondtOutputNoLow;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Second Relay Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRelaySetupFetchThirdCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.relaySetup;
    u8Pkt[13] = BleConstants.thirdOutputNoHigh;
    u8Pkt[14] = BleConstants.thirdtOutputNoLow;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Third Relay Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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
      return int.parse(raw, radix: 16) & BleConstants.base;
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
      return int.parse(t, radix: 16) & BleConstants.base;
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
      return int.parse(raw, radix: 16) & BleConstants.base;
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
      return int.parse(raw, radix: 16) & BleConstants.base;
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
      return int.parse(raw, radix: 16) & BleConstants.base;
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
      return int.parse(h, radix: 16) & BleConstants.base;
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.relaySetup;
    u8Pkt[13] = BleConstants.firstOutputNoHigh;
    u8Pkt[14] = BleConstants.firstOutputNoLow;
    u8Pkt[15] = _relayOutputModeByteForApply(
      modeHex: relayOneMode,
      enabled: isRelayOneSetupEnabled.value,
      test: isRelayOneSetupTest.value,
    );
    u8Pkt[16] = BleConstants.outputSetupType;
    u8Pkt[20] = BleConstants.firstOutputSetupTypeParams;
    u8Pkt[22] =
        relayOneSetupDynamicText.value.isNotEmpty
            ? _parseRelayDynamicFieldByte(relayOneSetupDynamicText.value)
            : BleConstants.init;
    u8Pkt[23] = relayOneSetupGroup.value;
    u8Pkt[24] = relayOneSetupFunction.value;
    u8Pkt[25] = outputTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Relay Setup Apply First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.relaySetup;
    u8Pkt[13] = BleConstants.secondOutputNoHigh;
    u8Pkt[14] = BleConstants.secondtOutputNoLow;
    u8Pkt[15] = _relayOutputModeByteForApply(
      modeHex: relayTwoMode,
      enabled: isRelayTwoSetupEnabled.value,
      test: isRelayTwoSetupTest.value,
    );
    u8Pkt[16] = BleConstants.outputSetupType;
    u8Pkt[20] = BleConstants.secondOutputSetupTypeParams;
    u8Pkt[22] =
        relayTwoSetupDynamicText.value.isNotEmpty
            ? _parseRelayDynamicFieldByte(relayTwoSetupDynamicText.value)
            : BleConstants.init;
    u8Pkt[23] = relayTwoSetupGroup.value;
    u8Pkt[24] = relayTwoSetupFunction.value;
    u8Pkt[25] = outputTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Relay Setup Apply Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.relaySetup;
    u8Pkt[13] = BleConstants.thirdOutputNoHigh;
    u8Pkt[14] = BleConstants.thirdtOutputNoLow;
    u8Pkt[15] = _relayOutputModeByteForApply(
      modeHex: relayThreeMode,
      enabled: isRelayThreeSetupEnabled.value,
      test: isRelayThreeSetupTest.value,
    );
    u8Pkt[16] = BleConstants.outputSetupType;
    u8Pkt[20] = BleConstants.thirdOutputSetupTypeParams;
    u8Pkt[22] =
        relayThreeSetupDynamicText.value.isNotEmpty
            ? _parseRelayDynamicFieldByte(relayThreeSetupDynamicText.value)
            : BleConstants.init;
    u8Pkt[23] = relayThreeSetupGroup.value;
    u8Pkt[24] = relayThreeSetupFunction.value;
    u8Pkt[25] = outputTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Relay Setup Apply Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupFetchFirstCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.zoneSetup;
    u8Pkt[13] = BleConstants.firstZoneSetupNo;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Zone Setup Fetch First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupFetchSecondCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.zoneSetup;
    u8Pkt[13] = BleConstants.secondZoneSetupNo;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Zone Setup Fetch Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendZoneSetupFetchThirdCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.zoneSetup;
    u8Pkt[13] = BleConstants.thirdZoneSetupNo;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Zone Setup Fetch Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.zoneSetup;
    u8Pkt[13] = BleConstants.firstZoneSetupNo;
    u8Pkt[14] =
        zoneOneSetupMode.value.isNotEmpty
            ? int.parse(zoneOneSetupMode.value, radix: 16)
            : BleConstants.init;
    u8Pkt[15] = zoneOneSetupDetectionMode.value & BleConstants.base;
    u8Pkt[16] =
        zoneOneSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneOneSetupVerificationTime.value)
            : BleConstants.init;
    u8Pkt[17] =
        zoneOneSetupDetectionMode.value == 3
            ? BleConstants.extZoneValveDelay
            : BleConstants.init;
    u8Pkt[18] = zoneTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Zone Setup Apply First Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.zoneSetup;
    u8Pkt[13] = BleConstants.secondZoneSetupNo;
    u8Pkt[14] =
        zoneTwoSetupMode.value.isNotEmpty
            ? int.parse(zoneTwoSetupMode.value, radix: 16)
            : BleConstants.init;
    u8Pkt[15] = zoneTwoSetupDetectionMode.value & BleConstants.base;
    u8Pkt[16] =
        zoneTwoSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneTwoSetupVerificationTime.value)
            : BleConstants.init;
    u8Pkt[17] =
        zoneTwoSetupDetectionMode.value == 3
            ? BleConstants.extZoneValveDelay
            : BleConstants.init;
    u8Pkt[18] = zoneTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Zone Setup Apply Second Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.zoneSetup;
    u8Pkt[13] = BleConstants.thirdZoneSetupNo;
    u8Pkt[14] =
        zoneThreeSetupMode.value.isNotEmpty
            ? int.parse(zoneThreeSetupMode.value, radix: 16)
            : BleConstants.init;
    u8Pkt[15] = zoneThreeSetupDetectionMode.value & BleConstants.base;
    u8Pkt[16] =
        zoneThreeSetupVerificationTime.value.isNotEmpty
            ? int.parse(zoneThreeSetupVerificationTime.value)
            : BleConstants.init;
    u8Pkt[17] =
        zoneThreeSetupDetectionMode.value == 3
            ? BleConstants.extZoneValveDelay
            : BleConstants.init;
    u8Pkt[18] = zoneTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Zone Setup Apply Third Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendRadioSetupFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.radioSetup;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Radio Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
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

    final List<int> radioNoTextBytes =
        radioNoText.split('').map((e) => int.parse(e)).toList();

    final radioNoTextLength = radioNoTextBytes.length;

    final initialSetupNoindex = 37;
    for (int i = 0; i < 8; i++) {
      if (i < radioNoTextLength) {
        u8Pkt[initialSetupNoindex + i] =
            radioNoTextBytes[i] & BleConstants.base;
      } else {
        u8Pkt[initialSetupNoindex + i] = BleConstants.init;
      }
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.radioSetup;
    u8Pkt[13] =
        isRadioSetupEnabled.value
            ? BleConstants.radioSetupEnabled
            : BleConstants.radioSetupDisabled;
    u8Pkt[14] = radioSetupModule.value & BleConstants.base;
    u8Pkt[15] =
        isRadioSetupAdvertised.value
            ? BleConstants.radioSetupAdvertised
            : BleConstants.radioSetupNotAdvertised;
    u8Pkt[16] =
        isRadioSetupConnected.value
            ? BleConstants.radioSetupConnected
            : BleConstants.radioSetupNotConnected;
    u8Pkt[17] =
        isRadioSetupProgrammed.value
            ? BleConstants.radioSetupProgrammed
            : BleConstants.radioSetupNotProgrammed;
    u8Pkt[18] =
        isRadioSetupBooted.value
            ? BleConstants.radioSetupBooted
            : BleConstants.radioSetupNotBooted;
    u8Pkt[19] =
        isRadioSetupServiced.value
            ? BleConstants.radioSetupServiced
            : BleConstants.radioSetupNotServiced;
    u8Pkt[20] = radioNameTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Radio Setup Apply Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendModuleSetupFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.module;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.moduleSetup;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: Module Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendLBusSetupFetchCmdPkt({required int lBusNo}) async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.lBusSetup;
    u8Pkt[13] = lBusNo;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    Logger(
      "TX/RX: TRANSMIT: L Bus Setup Fetch Command time: ${DateTime.now().toIso8601String()}, packet: ${u8Pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}",
      type: LogType.ble,
    );

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendLBusEnabledBusDataFetchCmdPkt({required int lBusNo}) async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[8] = lBusNo;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.lBusEnabledBusData;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendLBusSetupApplyCmdPkt({required int lBusNo}) async {
    Uint8List u8Pkt = Uint8List(216);

    final data = lBusSetupDataList.value[lBusNo - 1];
    final String lBusDeviceText = data.deviceText;
    final List<int> lBusDeviceTextBytes = lBusDeviceText.codeUnits;
    final lBusDeviceTextLength = lBusDeviceTextBytes.length;

    final initialindex = 23;

    for (int i = 0; i < lBusDeviceTextLength; i++) {
      if (i < lBusDeviceTextLength) {
        u8Pkt[initialindex + i] = lBusDeviceTextBytes[i];
      }
    }

    final statusConfig = LBusRepeaterStatusConfig(
      enable:
          data.enabled == 'Yes'
              ? LBusRepeaterEnable.enabled
              : LBusRepeaterEnable.disabled,
      idLed: data.idLed == 'Yes' ? LBusIdLed.on : LBusIdLed.off,
    );

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.lBusSetup;
    u8Pkt[13] = lBusNo;
    u8Pkt[14] =
        lBusSetupDataList.value[lBusNo - 1].product == 'Rhino103R'
            ? 0x16
            : 0x00;
    u8Pkt[17] = LBusRepeaterStatusCodec.encode(statusConfig);
    u8Pkt[18] = 0x01;
    u8Pkt[19] = 0x64;
    u8Pkt[20] = lBusNo == 1 ? 0x00 : 0x02;
    u8Pkt[21] = lBusNo == 1 ? 0x50 : 0x58;
    u8Pkt[22] = lBusDeviceTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupRelayFetchCmdPkt({
    required int outputMaxZone,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupRelay;
    u8Pkt[13] = BleConstants.firstOutputNoHigh;
    u8Pkt[14] = outputMaxZone;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupGeneralFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupGeneral;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupZoneFetchCmdPkt({
    required int zoneMaxZone,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupZone;
    u8Pkt[13] = zoneMaxZone;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupExtOutFetchCmdPkt({
    required int extMaxZone,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupExtOut;
    u8Pkt[13] = BleConstants.firstExtOutNoLow;
    u8Pkt[14] = extMaxZone;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupRelayApplyCmdPkt({
    required int outputMaxZone,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

    String outputText = "";
    int outputNo = 0;
    int function = 0;
    int group = 0;

    if (outputMaxZone == 1) {
      outputText = sounderOneOutputText.value;
      outputNo = sounderOneFunctionNo.value;
      function = sounderOneRelayFunction.value;
      group = sounderOneRelayFunctionGroup.value;
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
      u8Pkt[initialindex + i] = outputTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupRelay;
    u8Pkt[13] = BleConstants.sounderSetupRelayNoHigh;
    u8Pkt[14] = outputMaxZone;
    u8Pkt[15] = _sounderRelayOutputModeByteForApply(
      outputMaxZone: outputMaxZone,
    );
    u8Pkt[16] = 0x02;
    u8Pkt[20] = outputMaxZone;
    u8Pkt[21] = 0x01;
    u8Pkt[22] = outputNo;
    u8Pkt[23] = group;
    u8Pkt[24] = function;
    u8Pkt[25] = outputTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupGeneralApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupGeneral;
    u8Pkt[13] = BleConstants.sounderSetupGeneralNoHigh;
    u8Pkt[14] = _sounderGeneralEquipmentModeByteForApply();
    u8Pkt[15] = sounderGeneralAction.value;
    u8Pkt[18] = (sounderGeneralDelay.value >> 8) & BleConstants.base;
    u8Pkt[19] = sounderGeneralDelay.value & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupZoneApplyCmdPkt({
    required int zoneMaxZone,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

    int zoneAction = 0;

    if (zoneMaxZone == 1) {
      zoneAction = zoneOneAction.value;
    } else if (zoneMaxZone == 2) {
      zoneAction = zoneTwoAction.value;
    } else if (zoneMaxZone == 3) {
      zoneAction = zoneThreeAction.value;
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupZone;
    u8Pkt[13] = zoneMaxZone;
    u8Pkt[14] = BleConstants.sounderSetupZoneNoHigh;
    u8Pkt[15] = _sounderZoneModeByteForApply(zoneMaxZone: zoneMaxZone);
    u8Pkt[16] = zoneAction;
    u8Pkt[19] = (sounderGeneralDelay.value >> 8) & BleConstants.base;
    u8Pkt[20] = sounderGeneralDelay.value & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendSounderSetupExtOutApplyCmdPkt({
    required int extMaxZone,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

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

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.sounderSetupExtOut;
    u8Pkt[13] = BleConstants.sounderSetupExtOutNoLow;
    u8Pkt[14] = extMaxZone;
    u8Pkt[15] = _sounderExtOutModeByteForApply(extMaxZone: extMaxZone);
    u8Pkt[16] = extOutCountdownAction;
    u8Pkt[17] = extOutHoldAction;
    u8Pkt[18] = extOutReleaseAction;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendServiceDueFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.serviceDue;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendServiceDueApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

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
      u8Pkt[serviceDueCompanyTextInitialIndex + i] =
          serviceDueCompanyTextBytes[i];
    }

    for (int i = 0; i < serviceDueContactTextLength; i++) {
      u8Pkt[serviceDueContactTextInitialIndex + i] =
          serviceDueContactTextBytes[i];
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.serviceDue;
    u8Pkt[13] = (serviceDueYear.value >> 8) & BleConstants.base;
    u8Pkt[14] = serviceDueYear.value & BleConstants.base;
    u8Pkt[15] = serviceDueMonth.value & BleConstants.base;
    u8Pkt[16] = serviceDueDay.value & BleConstants.base;
    u8Pkt[17] = serviceDueHour.value & BleConstants.base;
    u8Pkt[18] = serviceDueMinute.value & BleConstants.base;
    u8Pkt[19] = serviceDueReminder.value;
    u8Pkt[20] = serviceDueCompanyTextLength & BleConstants.base;
    u8Pkt[34] = serviceDueContactTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendAccessCodeSetupFetchCmdPkt({
    required int accessCodeNo,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.request.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.accessCodeSetup;
    u8Pkt[13] = accessCodeNo;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendAccessCodeSetupApplyCmdPkt({
    required int accessCodeNo,
  }) async {
    Uint8List u8Pkt = Uint8List(216);

    final data = accessCodeSetupDataList.value[accessCodeNo - 1];
    final String accessCodeText = data.accessCode;
    final List<int> accessCodeTextBytes = accessCodeText.codeUnits;
    final accessCodeTextLength = accessCodeTextBytes.length;

    final initialindex = 16;

    for (int i = 0; i < accessCodeTextLength; i++) {
      if (i < accessCodeTextLength) {
        u8Pkt[initialindex + i] = accessCodeTextBytes[i];
      }
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = BleConstants.des;
    u8Pkt[2] = BleConstants.ori;
    u8Pkt[3] = BleConstants.type.nrm;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = BleConstants.network.radio;
    u8Pkt[10] = BleConstants.mode.instruction.dbSetup;
    u8Pkt[11] = BleConstants.socket.radio;
    u8Pkt[12] = BleConstants.command.accessCodeSetup;
    u8Pkt[13] = data.accessCodeNo;
    u8Pkt[14] = data.accessLevel;
    u8Pkt[15] = accessCodeTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = BleConstants.eot;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPanelInfoPanelIdFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x08;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPanelInfoDateTimeFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x03;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x01;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPanelInfoEventReminderDelayFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x09;
    u8Pkt[13] = 0x04;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPanelInfoPanelIdApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    final String panelNameText = panelInfoPanelName.value;
    final List<int> panelNameTextBytes = panelNameText.codeUnits;
    final panelNameTextLength = panelNameTextBytes.length;
    final initialindex = 19;

    for (int i = 0; i < panelNameTextLength; i++) {
      if (i < panelNameTextLength) {
        u8Pkt[initialindex + i] = panelNameTextBytes[i];
      }
    }

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x08;
    u8Pkt[16] = panelInfoPanelNo.value;
    u8Pkt[18] = panelNameTextLength & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPanelInfoDateTimeApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x83;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x01;
    u8Pkt[13] = (panelInfoYear.value >> 8) & BleConstants.base;
    u8Pkt[14] = panelInfoYear.value & BleConstants.base;
    u8Pkt[15] = panelInfoMonth.value & BleConstants.base;
    u8Pkt[16] = panelInfoDay.value & BleConstants.base;
    u8Pkt[17] = panelInfoHour.value & BleConstants.base;
    u8Pkt[18] = panelInfoMinute.value & BleConstants.base;
    u8Pkt[19] = panelInfoSecond.value & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendPanelInfoEventReminderDelayApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x09;
    u8Pkt[13] = 0x04;
    u8Pkt[14] = 0x01;
    u8Pkt[15] = (panelInfoEventReminderDelay.value >> 8) & BleConstants.base;
    u8Pkt[16] = panelInfoEventReminderDelay.value & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleLvlTimeOutFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x09;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleSilenceBuzzerLvlFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x09;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleSilenceSounderLvlFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x0A;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleResetLvlFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x0C;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleFaultLatchingFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x01;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x12;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleLvlTimeOutApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x09;
    u8Pkt[14] = 0x01;
    u8Pkt[15] = (generalModuleLvlTimeOut.value >> 8) & BleConstants.base;
    u8Pkt[16] = generalModuleLvlTimeOut.value & BleConstants.base;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleSilenceBuzzerLvlApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x09;
    u8Pkt[14] = generalModuleSilenceBuzzerLvl.value + 1;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleSilenceSounderLvlApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x0A;
    u8Pkt[14] = generalModuleSilenceSounderLvl.value + 2;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleResetLvlApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x0C;
    u8Pkt[14] = generalModuleResetLvl.value + 2;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendGeneralModuleFaultLatchingApplyCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x81;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x15;
    u8Pkt[13] = 0x12;
    u8Pkt[14] = generalModuleFaultLatching.value;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }

  Future<void> sendDiagnosticsSetupFetchCmdPkt() async {
    Uint8List u8Pkt = Uint8List(216);

    u8TxPktCnt += 1;

    u8Pkt[0] = BleConstants.sot;
    u8Pkt[1] = 0x01;
    u8Pkt[2] = 0x00;
    u8Pkt[3] = 0x01;
    u8Pkt[4] = u8TxPktCnt & BleConstants.base;
    u8Pkt[5] = u8RxPktCnt & BleConstants.base;
    u8Pkt[6] = 0x00;
    u8Pkt[10] = 0x00;
    u8Pkt[11] = 0x00;
    u8Pkt[12] = 0x09;

    int checksum = toolsFletcherChecksum(u8Pkt.sublist(0, 213));

    u8Pkt[213] = (checksum >> 8) & BleConstants.base;
    u8Pkt[214] = checksum & BleConstants.base;
    u8Pkt[215] = 0xFD;

    await sendSmallDataFrame(0x1000, 216, u8Pkt);
  }
}
