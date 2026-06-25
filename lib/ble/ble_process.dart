import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/models/adc_domain_values_model.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/ext_out_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/general_quipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/input_mode_util.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'package:techno_switch_solar_app/utils/relay_mode_util.dart';
import 'package:techno_switch_solar_app/utils/ext_zone_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_equipment_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_mode_util.dart';
import 'ble_manager.dart';
import 'ble_frame.dart';
import '../models/log_model.dart';
import '../models/l_bus_setup_data_model.dart';
import '../utils/event_constants.dart';
import '../utils/adc_parser.dart';
import '../utils/storage/peripheral_setup_cache.dart';
import '../utils/timestamp_converter.dart';

class BleProcess {
  final BleManager bleManager;
  Timer? _rxTimeoutTimer;
  Timer? _otherPacketsRxTimeoutTimer;
  Timer? _operationDeadlineTimer;
  Timer? _accessKeyPollDeadlineTimer;
  DateTime? _accessKeyPollStartedAt;

  static const Duration bleOperationDeadlineDuration = Duration(seconds: 10);

  static const Duration accessKeyPollTimeoutDuration = Duration(seconds: 5);

  int checkForNetworkPacketRsp = 0;
  int checkForCtrlCmdRsp = 0;
  int checkForExtCmdFetchRes = 0;
  int checkForExtCmdApplyRes = 0;
  int checkDipSetCmdRsp = 0;
  int checkForAccessKeyCmdRsp = 0;
  int checkForInputSetupFetchRes = 0;
  int checkForInputSetupApplyRes = 0;
  int checkForRelaySetupFetchRes = 0;
  int checkForRelaySetupApplyRes = 0;
  int relaySetupFetchCommandStep = 0;
  int relaySetupApplyCommandStep = 0;
  int checkForZoneSetupFetchRes = 0;
  int checkForZoneSetupApplyRes = 0;
  int zoneSetupFetchCommandStep = 0;
  int zoneSetupApplyCommandStep = 0;
  int checkForRadioSetupFetchRes = 0;
  int checkForRadioSetupApplyRes = 0;
  int checkForModuleSetupFetchRes = 0;
  int checkForLBusSetupFetchRes = 0;
  int lBusSetupFetchCommandStep = 0;
  int lBusSetupDataFetchCommandStep = 0;
  int checkForLBusSetupApplyRes = 0;
  int lBusSetupApplyCommandStep = 0;
  int checkForSounderSetupFetchRes = 0;
  int checkForSounderSetupApplyRes = 0;
  int sounderSetupFetchRelayCommandStep = 0;
  int sounderSetupFetchZoneCommandStep = 1;
  int sounderSetupFetchExtOutCommandStep = 1;
  int sounderSetupApplyRelayCommandStep = 0;
  int sounderSetupApplyGeneralCommandStep = 0;
  int sounderSetupApplyZoneCommandStep = 0;
  int sounderSetupApplyExtOutCommandStep = 0;
  int checkForServiceDueFetchRes = 0;
  int checkForServiceDueApplyRes = 0;
  int checkForAccessCodeSetupFetchRes = 0;
  int accessCodeSetupFetchCommandStep = 0;
  int checkForAccessCodeSetupApplyRes = 0;
  int accessCodeSetupApplyCommandStep = 0;
  int checkForPanelInfoSetupFetchRes = 0;
  int checkForPanelInfoSetupApplyRes = 0;
  int panelInfoSetupApplyCommandStep = 0;
  int checkForGeneralModuleSetupFetchRes = 0;
  int checkForGeneralModuleSetupApplyRes = 0;
  int generalModuleSetupApplyCommandStep = 0;
  int checkForLiveEventsRetrievalRes = 0;
  int checkForAdcSetupFetchRes = 0;
  int validEventLogNum = 0;
  int read1000Logs = 0;
  bool logRetreivalEnded = false;

  DateTime? logStartingTime;
  DateTime? logEndTime;

  bool _isStateMachineRunning = false;
  bool _restartRequested = false;

  bool isOtaCompleted = false;

  static const int maxRxRetries = 3;
  int rxTimeoutRetryCount = 0;
  int nackRetryCount = 0;
  static const int maxNetworkFlowRestarts = 3;
  int networkFlowRestartCount = 0;
  bool _networkFlowFailureHandling = false;
  final ValueNotifier<String?> communicationFailureMessage =
      ValueNotifier<String?>(null);

  void clearCommunicationFailure() {
    final hadMessage = communicationFailureMessage.value;
    communicationFailureMessage.value = null;
    if (hadMessage != null && processDesc.value == hadMessage) {
      processDesc.value = '';
    }
    isAccessKeyValid.value = null;
    maxOtherPacketsRetriesReached.value = false;
    resetNetworkFlowRestartCount();
  }

  void publishCommunicationFailure(String message) {
    communicationFailureMessage.value = message;
    processDesc.value = message;
    isAccessKeyValid.value = false;
    maxOtherPacketsRetriesReached.value = true;
    isSessionAccessCodeValidationOnly = false;
  }

  void resetNetworkFlowRestartCount() {
    networkFlowRestartCount = 0;
    maxOtherPacketsRetriesReached.value = false;
  }

  final ValueNotifier<int> validEventLogCount = ValueNotifier<int>(0);

  final ValueNotifier<int> read1000LogsCount = ValueNotifier<int>(0);

  final ValueNotifier<List<LogModel>> validEventLogs =
      ValueNotifier<List<LogModel>>([]);

  final ValueNotifier<bool> isValidLogRecieved = ValueNotifier<bool>(false);

  final ValueNotifier<String> processDesc = ValueNotifier<String>("");

  final ValueNotifier<String> panelName = ValueNotifier<String>("");

  final ValueNotifier<String> connectedDeviceId = ValueNotifier<String>("");

  final ValueNotifier<bool> maxBleConnectionRetriesReached =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> maxOtherPacketsRetriesReached = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool?> isAccessKeyValid = ValueNotifier<bool?>(null);

  final ValueNotifier<String> accessKey = ValueNotifier<String>("");

  final ValueNotifier<int> accessKeyLength = ValueNotifier<int>(0);

  final ValueNotifier<bool> sessionAccessCodeReady = ValueNotifier<bool>(false);

  bool isSessionAccessCodeValidationOnly = false;

  void clearSessionAccessCode() {
    sessionAccessCodeReady.value = false;
    accessKey.value = "";
    accessKeyLength.value = 0;
    isAccessKeyValid.value = null;
    processDesc.value = "";
  }

  void clearPeripheralApplyDoneFlags() {
    isExtOutApplyDone.value = false;
    isInputSetupApplyDone.value = false;
    isRelaySetupApplyDone.value = false;
    isZoneSetupApplyDone.value = false;
    isRadioSetupApplyDone.value = false;
    isLBusSetupApplyDone.value = false;
    isSounderSetupApplyDone.value = false;
    isServiceDueApplyDone.value = false;
    isAccessCodeSetupApplyDone.value = false;
    isPanelInfoSetupApplyDone.value = false;
    isGeneralModuleSetupApplyDone.value = false;
  }

  void setSessionAccessCode(String code) {
    accessKey.value = code;
    sessionAccessCodeReady.value = true;
  }

  final ValueNotifier<int> bleManufacturerData = ValueNotifier<int>(0);

  final ValueNotifier<String> extZoneMode = ValueNotifier<String>("18");

  final ValueNotifier<int> isExtZoneEnabled = ValueNotifier<int>(0);

  final ValueNotifier<int> extZoneHoldMode = ValueNotifier<int>(0);

  final ValueNotifier<int> isResetAllowed = ValueNotifier<int>(0);

  final ValueNotifier<int> extZoneActuatorType = ValueNotifier<int>(0);

  final ValueNotifier<int> extZoneFunction = ValueNotifier<int>(0);

  final ValueNotifier<int> extZoneCountdownAuto = ValueNotifier<int>(10);

  final ValueNotifier<int> extZoneCountdownMan = ValueNotifier<int>(15);

  final ValueNotifier<int> extZoneReleaseTime = ValueNotifier<int>(10);

  final ValueNotifier<int> extZoneResetDelay = ValueNotifier<int>(5);

  final ValueNotifier<int> extZoneAction = ValueNotifier<int>(0);

  final ValueNotifier<String> extZoneText = ValueNotifier<String>(
    "EXT-Out-Text------001",
  );

  final ValueNotifier<bool> isExtOutCommandFetchActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isExtOutCommandApplyActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isExtOutApplyButtonActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isExtOutApplyDone = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isInputSetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<String> inputSetupText = ValueNotifier<String>("");

  final ValueNotifier<int> inputSetupGroup = ValueNotifier<int>(0);

  final ValueNotifier<int> inputSetupFunction = ValueNotifier<int>(0);

  final ValueNotifier<bool> isInputSetupEnabled = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isInputSetupTest = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isInputSetupInverted = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isInputSetupApplyActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isInputSetupApplyDone = ValueNotifier<bool>(false);

  final ValueNotifier<String> inputMode = ValueNotifier<String>("");

  final ValueNotifier<bool> isRelaySetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isRelaySetupCommandApplyActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<String> relayOneSetupOutputText = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<int> relayOneSetupGroup = ValueNotifier<int>(0);

  final ValueNotifier<int> relayOneSetupFunction = ValueNotifier<int>(0);

  final ValueNotifier<String> relayOneSetupDynamicText = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<bool> isRelayOneSetupEnabled = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isRelayOneSetupTest = ValueNotifier<bool>(false);

  final ValueNotifier<String> relayTwoSetupOutputText = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<int> relayTwoSetupGroup = ValueNotifier<int>(0);

  final ValueNotifier<int> relayTwoSetupFunction = ValueNotifier<int>(0);

  final ValueNotifier<String> relayTwoSetupDynamicText = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<bool> isRelayTwoSetupEnabled = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isRelayTwoSetupTest = ValueNotifier<bool>(false);

  final ValueNotifier<String> relayThreeSetupOutputText = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<int> relayThreeSetupGroup = ValueNotifier<int>(0);

  final ValueNotifier<int> relayThreeSetupFunction = ValueNotifier<int>(0);

  final ValueNotifier<String> relayThreeSetupDynamicText =
      ValueNotifier<String>("");

  final ValueNotifier<bool> isRelayThreeSetupEnabled = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isRelayThreeSetupTest = ValueNotifier<bool>(false);

  final ValueNotifier<String> relayOneMode = ValueNotifier<String>("");

  final ValueNotifier<String> relayTwoMode = ValueNotifier<String>("");

  final ValueNotifier<String> relayThreeMode = ValueNotifier<String>("");

  final ValueNotifier<bool> isRelaySetupApplyDone = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isZoneSetupFetchCommandActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isZoneSetupCommandApplyActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isZoneSetupApplyDone = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isZoneOneSetupEnabled = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isZoneOneSetupTest = ValueNotifier<bool>(false);

  final ValueNotifier<String> zoneOneSetupText = ValueNotifier<String>("");

  final ValueNotifier<int> zoneOneSetupType = ValueNotifier<int>(0);

  final ValueNotifier<int> zoneOneSetupDetectionMode = ValueNotifier<int>(0);

  final ValueNotifier<String> zoneOneSetupMode = ValueNotifier<String>("");

  final ValueNotifier<String> zoneOneSetupVerificationTime =
      ValueNotifier<String>("");

  final ValueNotifier<bool> isZoneTwoSetupEnabled = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isZoneTwoSetupTest = ValueNotifier<bool>(false);

  final ValueNotifier<String> zoneTwoSetupText = ValueNotifier<String>("");

  final ValueNotifier<int> zoneTwoSetupType = ValueNotifier<int>(0);

  final ValueNotifier<int> zoneTwoSetupDetectionMode = ValueNotifier<int>(0);

  final ValueNotifier<String> zoneTwoSetupMode = ValueNotifier<String>("");

  final ValueNotifier<String> zoneTwoSetupVerificationTime =
      ValueNotifier<String>("");

  final ValueNotifier<bool> isZoneThreeSetupEnabled = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isZoneThreeSetupTest = ValueNotifier<bool>(false);

  final ValueNotifier<String> zoneThreeSetupText = ValueNotifier<String>("");

  final ValueNotifier<int> zoneThreeSetupType = ValueNotifier<int>(0);

  final ValueNotifier<int> zoneThreeSetupDetectionMode = ValueNotifier<int>(0);

  final ValueNotifier<String> zoneThreeSetupMode = ValueNotifier<String>("");

  final ValueNotifier<String> zoneThreeSetupVerificationTime =
      ValueNotifier<String>("");

  final ValueNotifier<bool> isRadioSetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isRadioSetupCommandApplyActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isRadioSetupApplyDone = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isRadioSetupEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<int> radioSetupModule = ValueNotifier<int>(0);
  final ValueNotifier<String> radioSetupName = ValueNotifier<String>("");
  final ValueNotifier<String> radioSetupNo = ValueNotifier<String>("");
  final ValueNotifier<bool> isRadioSetupAdvertised = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRadioSetupConnected = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRadioSetupServiced = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRadioSetupProgrammed = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isRadioSetupBooted = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isModuleSetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<int> moduleNo = ValueNotifier<int>(0);
  final ValueNotifier<bool> moduleEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> moduleProduct = ValueNotifier<String>("");
  final ValueNotifier<int> moduleId = ValueNotifier<int>(0);
  final ValueNotifier<int> moduleRevision = ValueNotifier<int>(0);
  final ValueNotifier<String> moduleHardware = ValueNotifier<String>("");
  final ValueNotifier<String> moduleFirmware = ValueNotifier<String>("");
  final ValueNotifier<String> moduleDate = ValueNotifier<String>("");
  final ValueNotifier<int> moduleProtocol = ValueNotifier<int>(0);

  final ValueNotifier<bool> isLBusSetupFetchCommandActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isLBusSetupApplyCommandActive = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<bool> isLBusSetupApplyDone = ValueNotifier<bool>(false);

  final ValueNotifier<List<LBusSetupData>> lBusSetupDataList =
      ValueNotifier<List<LBusSetupData>>(
        List.generate(31, (_) => const LBusSetupData()),
      );

  final ValueNotifier<List<int>> enabledLBusNumbers = ValueNotifier<List<int>>(
    [],
  );

  final ValueNotifier<bool> isLbusFetchHasErrors = ValueNotifier<bool>(false);

  final ValueNotifier<List<String>> lbusFetchErrors =
      ValueNotifier<List<String>>([]);

  final ValueNotifier<bool> isSounderSetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isSounderSetupApplyCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isSounderSetupApplyDone = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<int> sounderOneRelayFunctionGroup = ValueNotifier<int>(0);
  final ValueNotifier<int> sounderOneRelayFunction = ValueNotifier<int>(0);
  final ValueNotifier<int> sounderOneFunctionNo = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderOneOutputText = ValueNotifier<String>("");
  final ValueNotifier<bool> isSounderOneEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSounderOneTest = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSounderOneNormal = ValueNotifier<bool>(false);
  final ValueNotifier<String> sounderOneRelayOutputMode = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<int> sounderTwoRelayFunctionGroup = ValueNotifier<int>(0);
  final ValueNotifier<int> sounderTwoRelayFunction = ValueNotifier<int>(0);
  final ValueNotifier<int> sounderTwoFunctionNo = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderTwoOutputText = ValueNotifier<String>("");
  final ValueNotifier<bool> isSounderTwoEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSounderTwoTest = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSounderTwoNormal = ValueNotifier<bool>(false);
  final ValueNotifier<String> sounderTwoRelayOutputMode = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<int> sounderThreeRelayFunctionGroup = ValueNotifier<int>(
    0,
  );
  final ValueNotifier<int> sounderThreeRelayFunction = ValueNotifier<int>(0);
  final ValueNotifier<int> sounderThreeFunctionNo = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderThreeOutputText = ValueNotifier<String>(
    "",
  );
  final ValueNotifier<bool> isSounderThreeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSounderThreeTest = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSounderThreeNormal = ValueNotifier<bool>(false);
  final ValueNotifier<String> sounderThreeRelayOutputMode =
      ValueNotifier<String>("");

  final ValueNotifier<bool> isSounderGeneralEnabled = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<String> sounderGeneralMode = ValueNotifier<String>("");
  final ValueNotifier<bool> isSounderGeneralTest = ValueNotifier<bool>(false);
  final ValueNotifier<int> sounderGeneralAction = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSounderGeneralDelay = ValueNotifier<bool>(false);
  final ValueNotifier<int> sounderGeneralDelay = ValueNotifier<int>(0);

  final ValueNotifier<bool> isZoneOneEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isZoneOneTest = ValueNotifier<bool>(false);
  final ValueNotifier<int> zoneOneAction = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderZoneOneMode = ValueNotifier<String>("");

  final ValueNotifier<bool> isZoneTwoEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isZoneTwoTest = ValueNotifier<bool>(false);
  final ValueNotifier<int> zoneTwoAction = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderZoneTwoMode = ValueNotifier<String>("");

  final ValueNotifier<bool> isZoneThreeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isZoneThreeTest = ValueNotifier<bool>(false);
  final ValueNotifier<int> zoneThreeAction = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderZoneThreeMode = ValueNotifier<String>("");
  final ValueNotifier<bool> isExtOutOneEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isExtOutOneTest = ValueNotifier<bool>(false);
  final ValueNotifier<int> extoutOneCountdownAction = ValueNotifier<int>(0);
  final ValueNotifier<int> extoutOneHoldAction = ValueNotifier<int>(0);
  final ValueNotifier<int> extoutOneReleaseAction = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderExtOutOneMode = ValueNotifier<String>("");

  final ValueNotifier<bool> isExtOutTwoEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isExtOutTwoTest = ValueNotifier<bool>(false);
  final ValueNotifier<int> extoutTwoCountdownAction = ValueNotifier<int>(0);
  final ValueNotifier<int> extoutTwoHoldAction = ValueNotifier<int>(0);
  final ValueNotifier<int> extoutTwoReleaseAction = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderExtOutTwoMode = ValueNotifier<String>("");

  final ValueNotifier<bool> isExtOutThreeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isExtOutThreeTest = ValueNotifier<bool>(false);
  final ValueNotifier<int> extoutThreeCountdownAction = ValueNotifier<int>(0);
  final ValueNotifier<int> extoutThreeHoldAction = ValueNotifier<int>(0);
  final ValueNotifier<int> extoutThreeReleaseAction = ValueNotifier<int>(0);
  final ValueNotifier<String> sounderExtOutThreeMode = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<bool> isServiceDueFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isServiceDueApplyCommandActive =
      ValueNotifier<bool>(false);
  final ValueNotifier<bool> isServiceDueApplyDone = ValueNotifier<bool>(false);
  final ValueNotifier<int> serviceDueYear = ValueNotifier<int>(0);
  final ValueNotifier<int> serviceDueMonth = ValueNotifier<int>(0);
  final ValueNotifier<int> serviceDueDay = ValueNotifier<int>(0);
  final ValueNotifier<int> serviceDueHour = ValueNotifier<int>(0);
  final ValueNotifier<int> serviceDueMinute = ValueNotifier<int>(0);
  final ValueNotifier<String> serviceDueCompany = ValueNotifier<String>("");
  final ValueNotifier<String> serviceDueContact = ValueNotifier<String>("");
  final ValueNotifier<int> serviceDueReminder = ValueNotifier<int>(0);

  final ValueNotifier<bool> isAccessCodeSetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isAccessCodeSetupApplyCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isAccessCodeSetupApplyDone = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<List<AccessCodeSetupData>> accessCodeSetupDataList =
      ValueNotifier<List<AccessCodeSetupData>>(
        List.generate(8, (_) => const AccessCodeSetupData()),
      );

  final ValueNotifier<bool> isPanelInfoSetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isPanelInfoSetupApplyCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isPanelInfoSetupApplyDone = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<int> panelInfoPanelNo = ValueNotifier<int>(0);
  final ValueNotifier<String> panelInfoPanelName = ValueNotifier<String>("");
  final ValueNotifier<int> panelInfoYear = ValueNotifier<int>(0);
  final ValueNotifier<int> panelInfoMonth = ValueNotifier<int>(0);
  final ValueNotifier<int> panelInfoDay = ValueNotifier<int>(0);
  final ValueNotifier<int> panelInfoHour = ValueNotifier<int>(0);
  final ValueNotifier<int> panelInfoMinute = ValueNotifier<int>(0);
  final ValueNotifier<int> panelInfoSecond = ValueNotifier<int>(0);
  final ValueNotifier<int> panelInfoEventReminderDelay = ValueNotifier<int>(0);

  final ValueNotifier<bool> isGeneralModuleSetupFetchCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isGeneralModuleSetupApplyCommandActive =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> isGeneralModuleSetupApplyDone = ValueNotifier<bool>(
    false,
  );

  final ValueNotifier<int> generalModuleLvlTimeOut = ValueNotifier<int>(0);
  final ValueNotifier<int> generalModuleSilenceBuzzerLvl = ValueNotifier<int>(
    0,
  );
  final ValueNotifier<int> generalModuleSilenceSounderLvl = ValueNotifier<int>(
    0,
  );
  final ValueNotifier<int> generalModuleResetLvl = ValueNotifier<int>(0);
  final ValueNotifier<int> generalModuleFaultLatching = ValueNotifier<int>(0);

  final ValueNotifier<bool> isAdcSetupFetchCommandActive = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<double> sounderOneAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> sounderTwoAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> sounderThreeAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> dischargeAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> vauxAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> vinAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> progInputAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> holdInputAdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> zone1AdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> zone2AdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> zone3AdcValue = ValueNotifier<double>(0);
  final ValueNotifier<double> earthAdcValue = ValueNotifier<double>(0);

  final ValueNotifier<bool> isNetworkPacketProcess = ValueNotifier<bool>(true);
  final ValueNotifier<String> receivedPanelName = ValueNotifier<String>("");
  final ValueNotifier<String> receivedHardwareVersion = ValueNotifier<String>(
    "",
  );
  final ValueNotifier<String> receivedFirmwareVersion = ValueNotifier<String>(
    "",
  );
  final ValueNotifier<String> receivedFirmwareDate = ValueNotifier<String>("");
  final ValueNotifier<String> receivedProtocolVersion = ValueNotifier<String>(
    "",
  );

  final ValueNotifier<bool> isEventLogRetrievalFetchCommandActive =
      ValueNotifier<bool>(false);

  BleStates bleCurrentState = BleStates.IDLE;
  DeviceConnectState deviceConnectState = DeviceConnectState.notConnected;

  bool processNextOtaFrame = true;
  int txData = 1;

  int pollWaitRspTimeoutCnt = 0;

  int receivedPollCount = 0;

  BleProcess(this.bleManager);

  Future<void> bleRxFrameProcess(BleRxFrame rx) async {
    rxTimeoutRetryCount = 0;
    pollWaitRspTimeoutCnt = 0;
    nackRetryCount = 0;
    resetNetworkFlowRestartCount();

    bleManager.u8RxPktCnt = rx.payload[4];

    Logger(
      "Rx pkt count: $bleManager.u8RxPktCnt (STATE: ${bleManager.otaProcessState.name}",
      type: LogType.ble,
    );

    if (rx.payload[3] == 0x03) {
      Logger(StringConstants.nackPacket, type: LogType.ble);
      isOtaCompleted = true;
      processNextOtaFrame = false;
      bleManager.otaProcessState = OtaProcessState.notInUse;
      cancelOperationDeadline();
      cancelRxTimeout();
      return;
    }

    if (rx.payload[10] == 0x83 &&
        rx.payload[12] == 0x02 &&
        rx.payload[13] == 0x0A &&
        !isNetworkPacketProcess.value) {
      Logger(StringConstants.wrongPassword, type: LogType.ble);
      clearSessionAccessCode();
      resetProcessState();
      processDesc.value = StringConstants.wrongPassword;
      isAccessKeyValid.value = false;
      return;
    }

    switch (bleManager.otaProcessState) {
      case OtaProcessState.sendNetworkPacket:
        checkForNetworkPacketRsp = 1;

      case OtaProcessState.sendPollPacket:
        bleManager.otaProcessState = OtaProcessState.sendAccessKeyPacket;
        startRxTimeout();
        await bleManager.sendAccessKeyPkt();
        break;

      case OtaProcessState.sendAccessKeyPacket:
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        checkForAccessKeyCmdRsp = 1;
        startAccessKeyPollDeadline();
        break;

      case OtaProcessState.sendContinuousPollPacket:
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        break;

      case OtaProcessState.sendControlCmdPacket:
        if (logRetreivalEnded) {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
        } else {
          bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        }
        checkForCtrlCmdRsp = 1;
        break;

      case OtaProcessState.sendStopCntrlCmdPkt:
        if (checkForCtrlCmdRsp == 1) {
          logRetreivalEnded = true;
          isEventLogRetrievalFetchCommandActive.value = false;
          bleManager.otaProcessState = OtaProcessState.sendStopCntrlCmdPkt;
          break;
        } else {
          bleManager.otaProcessState = OtaProcessState.sendControlCmdPacket;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendStartCntrlCmdPkt();
          break;
        }

      case OtaProcessState.notInUse:
        break;

      case OtaProcessState.sendExtOutSetupFetchCmdPkt:
        checkForExtCmdFetchRes = 1;
        break;

      case OtaProcessState.sendExtOutSetupApplyCmdPkt:
        checkForExtCmdApplyRes = 1;

      case OtaProcessState.sendDipSettingFetchCmd:
        checkDipSetCmdRsp = 1;

      case OtaProcessState.sendInputSetupFetchCmdPkt:
        checkForInputSetupFetchRes = 1;
        break;

      case OtaProcessState.sendInputSetupApplyCmdPkt:
        checkForInputSetupApplyRes = 1;
        break;

      case OtaProcessState.sendRelaySetupFetchCmdPkt:
        checkForRelaySetupFetchRes = 1;
        break;

      case OtaProcessState.sendRelaySetupApplyCmdPkt:
        checkForRelaySetupApplyRes = 1;
        break;

      case OtaProcessState.sendZoneSetupFetchCmdPkt:
        checkForZoneSetupFetchRes = 1;
        break;

      case OtaProcessState.sendZoneSetupApplyCmdPkt:
        checkForZoneSetupApplyRes = 1;
        break;

      case OtaProcessState.sendRadioSetupFetchCmdPkt:
        checkForRadioSetupFetchRes = 1;
        break;

      case OtaProcessState.sendRadioSetupApplyCmdPkt:
        checkForRadioSetupApplyRes = 1;
        break;

      case OtaProcessState.sendModuleSetupFetchCmdPkt:
        checkForModuleSetupFetchRes = 1;
        break;

      case OtaProcessState.sendLBusSetupFetchCmdPkt:
        checkForLBusSetupFetchRes = 1;
        break;

      case OtaProcessState.sendLBusSetupApplyCmdPkt:
        checkForLBusSetupApplyRes = 1;
        break;

      case OtaProcessState.sendSounderSetupFetchCmdPkt:
        checkForSounderSetupFetchRes = 1;
        break;

      case OtaProcessState.sendSounderSetupApplyCmdPkt:
        checkForSounderSetupApplyRes = 1;
        break;

      case OtaProcessState.sendServiceDueFetchCmdPkt:
        checkForServiceDueFetchRes = 1;
        break;

      case OtaProcessState.sendServiceDueApplyCmdPkt:
        checkForServiceDueApplyRes = 1;
        break;

      case OtaProcessState.sendAccessCodeSetupFetchCmdPkt:
        checkForAccessCodeSetupFetchRes = 1;
        break;

      case OtaProcessState.sendAccessCodeSetupApplyCmdPkt:
        checkForAccessCodeSetupApplyRes = 1;
        break;

      case OtaProcessState.sendPanelInfoSetupFetchCmdPkt:
        checkForPanelInfoSetupFetchRes = 1;
        break;

      case OtaProcessState.sendPanelInfoSetupApplyCmdPkt:
        checkForPanelInfoSetupApplyRes = 1;
        break;

      case OtaProcessState.sendGeneralModuleSetupFetchCmdPkt:
        checkForGeneralModuleSetupFetchRes = 1;
        break;

      case OtaProcessState.sendGeneralModuleSetupApplyCmdPkt:
        checkForGeneralModuleSetupApplyRes = 1;
        break;

      case OtaProcessState.sendLiveEventsRetrievalFetchCmdPkt:
        checkForLiveEventsRetrievalRes = 1;
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        break;

      case OtaProcessState.sendAdcSetupFetchCmdPkt:
        checkForAdcSetupFetchRes = 1;
        break;

      case OtaProcessState.otaWaitRsp:
        break;
    }

    if (checkForNetworkPacketRsp == 1) {
      if (receivedPanelName.value.isEmpty) {
        receivedPanelName.value = extractStringFromPayload(
          rx.payload,
          startIndex: 16,
        );
        _applyNetworkPacketVersionFields(rx.payload);
      }

      bleManager.otaProcessState = OtaProcessState.sendPollPacket;
      isNetworkPacketProcess.value = false;
      checkForNetworkPacketRsp = 0;
      _otherPacketsRxTimeoutTimer?.cancel();
      _otherPacketsRxTimeoutTimer = null;
      startRxTimeout();
      await bleManager.sendPollPacket();
    }

    if (checkForLiveEventsRetrievalRes == 1) {
      if (rx.payload[10] == 0x02 && rx.payload[12] == 0x02) {
        int rxLastEvtLogNum =
            rx.payload[19] |
            (rx.payload[18] << 8) |
            (rx.payload[17] << 16) |
            (rx.payload[16] << 24);
        try {
          LogModel? parsedLog = _parseEventLogFromPayload(
            rx.payload,
            rxLastEvtLogNum,
          );
          if (parsedLog != null && parsedLog.eventId != "0") {
            isValidLogRecieved.value = true;
            final currentLogs = List<LogModel>.from(validEventLogs.value);
            currentLogs.add(parsedLog);
            validEventLogs.value = currentLogs;
          }
        } catch (_) {}
      }

      await Future.delayed(Duration(milliseconds: 300));

      startRxTimeout();
      await bleManager.sendPollPacket();
    }

    if (checkForAccessKeyCmdRsp == 1) {
      if (rx.payload[13] != 0x0a &&
          String.fromCharCodes(
                rx.payload.sublist(14, 14 + accessKeyLength.value),
              ) ==
              accessKey.value) {
        cancelAccessKeyPollDeadline();
        if (isInputSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendInputSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadInputSetup;
          startRxTimeout();
          await bleManager.sendInputSetupFetchCmdPkt();
        } else if (isExtOutCommandFetchActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendExtOutSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadExtOutSetup;
          startRxTimeout();
          await bleManager.sendExtOutSetupFetchCmdPkt();
        } else if (isExtOutCommandApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendExtOutSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.applyingExtOutSetup;
          startRxTimeout();
          await bleManager.sendExtOutSetupApplyCmdPkt();
        } else if (isInputSetupApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendInputSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.applyingInputSetup;
          startRxTimeout();
          await bleManager.sendInputSetupApplyCmdPkt();
        } else if (isRelaySetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRelaySetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          relaySetupFetchCommandStep = 1;
          processDesc.value = "${StringConstants.downloadingRelay} 1/3";
          startRxTimeout();
          await bleManager.sendRelaySetupFetchFirstCmdPkt();
        } else if (isRelaySetupCommandApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRelaySetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          relaySetupApplyCommandStep = 1;
          processDesc.value = "${StringConstants.applyingRelay} 1/3";
          startRxTimeout();
          await bleManager.sendRelaySetupApplyFirstCmdPkt();
        } else if (isZoneSetupFetchCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendZoneSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          zoneSetupFetchCommandStep = 1;
          processDesc.value = "${StringConstants.downloadingZone} 1/3";
          startRxTimeout();
          await bleManager.sendZoneSetupFetchFirstCmdPkt();
        } else if (isZoneSetupCommandApplyActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendZoneSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          zoneSetupApplyCommandStep = 1;
          processDesc.value = "${StringConstants.applyingZone} 1/3";
          startRxTimeout();
          await bleManager.sendZoneSetupApplyFirstCmdPkt();
        } else if (isRadioSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRadioSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadingRadio;
          startRxTimeout();
          await bleManager.sendRadioSetupFetchCmdPkt();
        } else if (isRadioSetupCommandApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRadioSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.applyingRadio;
          startRxTimeout();
          await bleManager.sendRadioSetupApplyCmdPkt();
        } else if (isModuleSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendModuleSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadingModule;
          startRxTimeout();
          await bleManager.sendModuleSetupFetchCmdPkt();
        } else if (isLBusSetupFetchCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendLBusSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          lBusSetupFetchCommandStep = 1;
          lBusSetupDataFetchCommandStep = 1;
          processDesc.value = "${StringConstants.downloadingLBus} 1/31";
          startRxTimeout();
          await bleManager.sendLBusSetupFetchCmdPkt(lBusNo: 1);
        } else if (isLBusSetupApplyCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendLBusSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          lBusSetupApplyCommandStep = 1;
          processDesc.value = "${StringConstants.applyingLBus} 1/31";
          startRxTimeout();
          await bleManager.sendLBusSetupApplyCmdPkt(lBusNo: 1);
        } else if (isSounderSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendSounderSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          sounderSetupFetchRelayCommandStep = 1;
          sounderSetupFetchZoneCommandStep = 1;
          sounderSetupFetchExtOutCommandStep = 1;
          processDesc.value = "${StringConstants.downloadingSounderRelays} 1/3";
          startRxTimeout();
          await bleManager.sendSounderSetupRelayFetchCmdPkt(outputMaxZone: 1);
        } else if (isSounderSetupApplyCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendSounderSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          sounderSetupApplyRelayCommandStep = 1;
          sounderSetupApplyZoneCommandStep = 1;
          sounderSetupApplyExtOutCommandStep = 1;
          sounderSetupApplyGeneralCommandStep = 1;
          processDesc.value = "${StringConstants.applyingSounderRelays} 1/3";
          startRxTimeout();
          await bleManager.sendSounderSetupRelayApplyCmdPkt(outputMaxZone: 1);
        } else if (isServiceDueFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendServiceDueFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadingServiceDue;
          startRxTimeout();
          await bleManager.sendServiceDueFetchCmdPkt();
        } else if (isServiceDueApplyCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendServiceDueApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.applyingServiceDue;
          startRxTimeout();
          await bleManager.sendServiceDueApplyCmdPkt();
        } else if (isAccessCodeSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendAccessCodeSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          accessCodeSetupFetchCommandStep = 1;
          processDesc.value = "${StringConstants.downloadingAccessCodeOne} 1/8";
          startRxTimeout();
          await bleManager.sendAccessCodeSetupFetchCmdPkt(accessCodeNo: 1);
        } else if (isAccessCodeSetupApplyCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendAccessCodeSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          accessCodeSetupApplyCommandStep = 1;
          processDesc.value = "${StringConstants.applyingAccessCodeOne} 1/8";
          startRxTimeout();
          await bleManager.sendAccessCodeSetupApplyCmdPkt(accessCodeNo: 1);
        } else if (isPanelInfoSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendPanelInfoSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadingPanelInfo;
          startRxTimeout();
          await bleManager.sendPanelInfoPanelIdFetchCmdPkt();
        } else if (isPanelInfoSetupApplyCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendPanelInfoSetupApplyCmdPkt;
          panelInfoSetupApplyCommandStep = 1;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.applyingPanelInfo;
          startRxTimeout();
          await bleManager.sendPanelInfoPanelIdApplyCmdPkt();
        } else if (isGeneralModuleSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendGeneralModuleSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadingGeneralModule;
          startRxTimeout();
          await bleManager.sendGeneralModuleLvlTimeOutFetchCmdPkt();
        } else if (isGeneralModuleSetupApplyCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendGeneralModuleSetupApplyCmdPkt;
          generalModuleSetupApplyCommandStep = 1;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.applyingGeneralModuleTimeOut;
          startRxTimeout();
          await bleManager.sendGeneralModuleLvlTimeOutApplyCmdPkt();
        } else if (isAdcSetupFetchCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendAdcSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          processDesc.value = StringConstants.downloadingAdcSetup;
          startRxTimeout();
          await bleManager.sendDiagnosticsSetupFetchCmdPkt();
        } else if (isEventLogRetrievalFetchCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendStopCntrlCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendStopCntrlCmdPkt();
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForAccessKeyCmdRsp = 0;
          isAccessKeyValid.value = true;
        }
      } else if (rx.payload[13] == 0x0a &&
          String.fromCharCodes(
                rx.payload.sublist(14, 14 + accessKeyLength.value),
              ) ==
              accessKey.value) {
        cancelAccessKeyPollDeadline();
        clearSessionAccessCode();
        resetProcessState();
        processDesc.value = StringConstants.wrongPassword;
        isAccessKeyValid.value = false;
        return;
      } else {
        if (_accessKeyPollStartedAt != null &&
            DateTime.now().difference(_accessKeyPollStartedAt!) >=
                accessKeyPollTimeoutDuration) {
          _onAccessKeyPollTimeout();
          return;
        }
        startRxTimeout(bumpOperationDeadline: false);
        await bleManager.sendPollPacket();
      }
    }

    if (checkDipSetCmdRsp == 1) {
      if (rx.payload[12] == 0x1C) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkDipSetCmdRsp = 0;
        if (rx.payload[14] == 0x00) {
          isExtOutApplyButtonActive.value = true;
        } else {
          isExtOutApplyButtonActive.value = false;
        }
        isExtOutCommandFetchActive.value = false;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForAdcSetupFetchRes == 1) {
      if (rx.payload[12] == 0x09) {
        isAccessKeyValid.value = true;
        try {
          final parsed = AdcParser.parse(rx.payload);
          final adc = AdcValues.fromList(parsed);
          updateNotifiers(adc);
        } catch (_) {}

        if (!isAdcSetupFetchCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForAdcSetupFetchRes = 0;
          processDesc.value = StringConstants.adcSetupFetchCompleted;
        } else {
          startRxTimeout();
          await bleManager.sendDiagnosticsSetupFetchCmdPkt();
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForGeneralModuleSetupFetchRes == 1) {
      if (rx.payload[12] == 0x09) {
        processDesc.value =
            StringConstants.downloadingGeneralModuleSilenceBuzzerLvl;
        generalModuleLvlTimeOut.value = rx.payload[15] << 8 | rx.payload[16];
        startRxTimeout();
        await bleManager.sendGeneralModuleSilenceBuzzerLvlFetchCmdPkt();
      } else if (rx.payload[12] == 0x15 && rx.payload[13] == 0x09) {
        processDesc.value =
            StringConstants.downloadingGeneralModuleSilenceSounderLvl;
        generalModuleSilenceBuzzerLvl.value = rx.payload[14] - 1;
        startRxTimeout();
        await bleManager.sendGeneralModuleSilenceSounderLvlFetchCmdPkt();
      } else if (rx.payload[12] == 0x15 && rx.payload[13] == 0x0A) {
        processDesc.value = StringConstants.downloadingGeneralModuleResetLvl;
        generalModuleSilenceSounderLvl.value = rx.payload[14] - 2;
        startRxTimeout();
        await bleManager.sendGeneralModuleResetLvlFetchCmdPkt();
      } else if (rx.payload[12] == 0x15 && rx.payload[13] == 0x0C) {
        processDesc.value =
            StringConstants.downloadingGeneralModuleFaultLatching;
        generalModuleResetLvl.value = rx.payload[14] - 2;
        startRxTimeout();
        await bleManager.sendGeneralModuleFaultLatchingFetchCmdPkt();
      } else if (rx.payload[12] == 0x15 && rx.payload[13] == 0x12) {
        generalModuleFaultLatching.value = rx.payload[14];
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForGeneralModuleSetupFetchRes = 0;
        isGeneralModuleSetupFetchCommandActive.value = false;
        isAccessKeyValid.value = true;
        processDesc.value = StringConstants.generalModuleSetupFetchCompleted;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForGeneralModuleSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          generalModuleSetupApplyCommandStep == 1) {
        generalModuleSetupApplyCommandStep = 2;
        processDesc.value =
            StringConstants.applyingGeneralModuleSilenceBuzzerLvl;
        startRxTimeout();
        await bleManager.sendGeneralModuleSilenceBuzzerLvlApplyCmdPkt();
      } else if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          generalModuleSetupApplyCommandStep == 2) {
        generalModuleSetupApplyCommandStep = 3;
        processDesc.value =
            StringConstants.applyingGeneralModuleSilenceSounderLvl;
        startRxTimeout();
        await bleManager.sendGeneralModuleSilenceSounderLvlApplyCmdPkt();
      } else if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          generalModuleSetupApplyCommandStep == 3) {
        generalModuleSetupApplyCommandStep = 4;
        processDesc.value = StringConstants.applyingGeneralModuleResetLvl;
        startRxTimeout();
        await bleManager.sendGeneralModuleResetLvlApplyCmdPkt();
      } else if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          generalModuleSetupApplyCommandStep == 4) {
        generalModuleSetupApplyCommandStep = 5;
        processDesc.value = StringConstants.applyingGeneralModuleFaultLatching;
        startRxTimeout();
        await bleManager.sendGeneralModuleFaultLatchingApplyCmdPkt();
      } else if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          generalModuleSetupApplyCommandStep == 5) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForGeneralModuleSetupApplyRes = 0;
        isGeneralModuleSetupApplyCommandActive.value = false;
        isGeneralModuleSetupApplyDone.value = true;
        isAccessKeyValid.value = true;
        processDesc.value = StringConstants.generalModuleSetupApplyCompleted;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForPanelInfoSetupFetchRes == 1) {
      if (rx.payload[12] == 0x08) {
        panelInfoPanelNo.value = rx.payload[16];
        panelInfoPanelName.value = extractStringFromPayload(
          rx.payload,
          startIndex: 18,
        );
        startRxTimeout();
        await bleManager.sendPanelInfoDateTimeFetchCmdPkt();
      } else if (rx.payload[12] == 0x01) {
        panelInfoYear.value = (rx.payload[13] << 8) | rx.payload[14];
        panelInfoMonth.value = rx.payload[15];
        panelInfoDay.value = rx.payload[16];
        panelInfoHour.value = rx.payload[17];
        panelInfoMinute.value = rx.payload[18];
        panelInfoSecond.value = rx.payload[19];
        startRxTimeout();
        await bleManager.sendPanelInfoEventReminderDelayFetchCmdPkt();
      } else if (rx.payload[12] == 0x09) {
        panelInfoEventReminderDelay.value =
            (rx.payload[15] << 8) | rx.payload[16];
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForPanelInfoSetupFetchRes = 0;
        isPanelInfoSetupFetchCommandActive.value = false;
        isAccessKeyValid.value = true;
        processDesc.value = StringConstants.panelInfoSetupFetchCompleted;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForPanelInfoSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          panelInfoSetupApplyCommandStep == 1) {
        panelInfoSetupApplyCommandStep = 2;
        startRxTimeout();
        await bleManager.sendPanelInfoDateTimeApplyCmdPkt();
      } else if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          panelInfoSetupApplyCommandStep == 2) {
        panelInfoSetupApplyCommandStep = 3;
        startRxTimeout();
        await bleManager.sendPanelInfoEventReminderDelayApplyCmdPkt();
      } else if (rx.payload[10] == 0x83 &&
          rx.payload[12] == 0x02 &&
          panelInfoSetupApplyCommandStep == 3) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForPanelInfoSetupApplyRes = 0;
        isPanelInfoSetupApplyCommandActive.value = false;
        isPanelInfoSetupApplyDone.value = true;
        isAccessKeyValid.value = true;
        processDesc.value = StringConstants.panelInfoSetupApplyCompleted;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForAccessCodeSetupFetchRes == 1) {
      if (rx.payload[12] == 0x03) {
        final accessCodeIndex = accessCodeSetupFetchCommandStep - 1;
        if (accessCodeIndex >= 0 && accessCodeIndex < 8) {
          final parsed = AccessCodeSetupData.fromPayload(rx.payload);
          final updated = List<AccessCodeSetupData>.from(
            accessCodeSetupDataList.value,
          );
          updated[accessCodeIndex] = parsed;
          accessCodeSetupDataList.value = updated;
        }

        if (accessCodeSetupFetchCommandStep >= 1 &&
            accessCodeSetupFetchCommandStep < 8) {
          final nextAccessCodeNo = accessCodeSetupFetchCommandStep + 1;
          processDesc.value =
              "${StringConstants.downloadingAccessCodeOne} $nextAccessCodeNo/8";
          accessCodeSetupFetchCommandStep = nextAccessCodeNo;
          startRxTimeout();
          await bleManager.sendAccessCodeSetupFetchCmdPkt(
            accessCodeNo: nextAccessCodeNo,
          );
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForAccessCodeSetupFetchRes = 0;
          isAccessCodeSetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
          processDesc.value = StringConstants.accessCodeSetupFetchCompleted;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForAccessCodeSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83 && rx.payload[12] == 0x02) {
        if (accessCodeSetupApplyCommandStep >= 1 &&
            accessCodeSetupApplyCommandStep < 8) {
          final nextAccessCodeNo = accessCodeSetupApplyCommandStep + 1;
          processDesc.value =
              "${StringConstants.applyingAccessCodeOne} $nextAccessCodeNo/8";
          accessCodeSetupApplyCommandStep = nextAccessCodeNo;
          startRxTimeout();
          await bleManager.sendAccessCodeSetupApplyCmdPkt(
            accessCodeNo: nextAccessCodeNo,
          );
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForAccessCodeSetupApplyRes = 0;
          isAccessCodeSetupApplyCommandActive.value = false;
          isAccessCodeSetupApplyDone.value = true;
          isAccessKeyValid.value = true;
          processDesc.value = StringConstants.accessCodeSetupApplyCompleted;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForServiceDueFetchRes == 1) {
      if (rx.payload[12] == 0x18) {
        serviceDueYear.value = (rx.payload[13] << 8) | rx.payload[14];
        serviceDueMonth.value = rx.payload[15];
        serviceDueDay.value = rx.payload[16];
        serviceDueHour.value = rx.payload[17];
        serviceDueMinute.value = rx.payload[18];
        serviceDueCompany.value = extractStringFromPayload(
          rx.payload,
          startIndex: 20,
        );
        serviceDueContact.value = extractStringFromPayload(
          rx.payload,
          startIndex: 34,
        );
        serviceDueReminder.value = rx.payload[19];
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForServiceDueFetchRes = 0;
        isServiceDueFetchCommandActive.value = false;
        isAccessKeyValid.value = true;
        processDesc.value = StringConstants.serviceDueFetchCompleted;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForServiceDueApplyRes == 1) {
      if (rx.payload[10] == 0x83 && rx.payload[12] == 0x02) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForServiceDueApplyRes = 0;
        isServiceDueApplyCommandActive.value = false;
        isServiceDueApplyDone.value = true;
        isAccessKeyValid.value = true;
        processDesc.value = StringConstants.serviceDueApplyCompleted;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForSounderSetupFetchRes == 1) {
      if (rx.payload[12] == 0x07) {
        if (sounderSetupFetchRelayCommandStep >= 1 &&
            sounderSetupFetchRelayCommandStep <= 3) {
          final nextRelayNo = sounderSetupFetchRelayCommandStep + 1;
          processDesc.value =
              "${StringConstants.downloadingSounderRelays} $nextRelayNo/3";

          if (sounderSetupFetchRelayCommandStep == 1) {
            final OutputModeConfig config = OutputModeCodec.fromHex(
              rx.payload[15].toRadixString(16),
            );
            final bool outputEnabled =
                config.outputEnable == OutputEnable.enabled;
            final bool outputMode = config.outputMode == OutputMode.test;
            final bool supervisionMode =
                config.supervisionMode == SupervisionMode.normal;
            isSounderOneEnabled.value = outputEnabled;
            isSounderOneTest.value = outputMode;
            isSounderOneNormal.value = supervisionMode;
            sounderOneRelayOutputMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            sounderOneRelayFunctionGroup.value = rx.payload[23];
            sounderOneRelayFunction.value = rx.payload[24];
            sounderOneFunctionNo.value = rx.payload[22];
            sounderOneOutputText.value = extractStringFromPayload(
              rx.payload,
              startIndex: 25,
            );
          } else if (sounderSetupFetchRelayCommandStep == 2) {
            final OutputModeConfig config = OutputModeCodec.fromHex(
              rx.payload[15].toRadixString(16),
            );
            final bool outputEnabled =
                config.outputEnable == OutputEnable.enabled;
            final bool outputMode = config.outputMode == OutputMode.test;
            final bool supervisionMode =
                config.supervisionMode == SupervisionMode.normal;
            isSounderTwoEnabled.value = outputEnabled;
            isSounderTwoTest.value = outputMode;
            isSounderTwoNormal.value = supervisionMode;
            sounderTwoRelayOutputMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            sounderTwoRelayFunctionGroup.value = rx.payload[23];
            sounderTwoRelayFunction.value = rx.payload[24];
            sounderTwoFunctionNo.value = rx.payload[22];
            sounderTwoOutputText.value = extractStringFromPayload(
              rx.payload,
              startIndex: 25,
            );
          } else if (sounderSetupFetchRelayCommandStep == 3) {
            final OutputModeConfig config = OutputModeCodec.fromHex(
              rx.payload[15].toRadixString(16),
            );
            final bool outputEnabled =
                config.outputEnable == OutputEnable.enabled;
            final bool outputMode = config.outputMode == OutputMode.test;
            final bool supervisionMode =
                config.supervisionMode == SupervisionMode.normal;
            isSounderThreeEnabled.value = outputEnabled;
            isSounderThreeTest.value = outputMode;
            isSounderThreeNormal.value = supervisionMode;
            sounderThreeRelayOutputMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            sounderThreeRelayFunctionGroup.value = rx.payload[23];
            sounderThreeRelayFunction.value = rx.payload[24];
            sounderThreeFunctionNo.value = rx.payload[22];
            sounderThreeOutputText.value = extractStringFromPayload(
              rx.payload,
              startIndex: 25,
            );
          }
          sounderSetupFetchRelayCommandStep = nextRelayNo;
          if (sounderSetupFetchRelayCommandStep <= 3) {
            startRxTimeout();
            await bleManager.sendSounderSetupRelayFetchCmdPkt(
              outputMaxZone: nextRelayNo,
            );
          } else {
            processDesc.value = StringConstants.downloadingSounderGeneral;
            startRxTimeout();
            await bleManager.sendSounderSetupGeneralFetchCmdPkt();
          }
        }
      } else if (rx.payload[12] == 0x14) {
        final GeneralEquipmentModeConfig config =
            GeneralEquipmentModeCodec.fromHex(rx.payload[14].toRadixString(16));
        final bool equipmentEnabled =
            config.equipmentEnable == EquipmentEnable.enabled;
        final bool equipmentMode = config.equipmentMode == EquipmentMode.test;
        final bool sounderDelay = config.sounderDelay == SounderDelay.enabled;
        isSounderGeneralEnabled.value = equipmentEnabled;
        isSounderGeneralTest.value = equipmentMode;
        isSounderGeneralDelay.value = sounderDelay;
        sounderGeneralMode.value = rx.payload[14]
            .toRadixString(16)
            .toUpperCase()
            .padLeft(2, '0');
        sounderGeneralAction.value = rx.payload[15];
        sounderGeneralDelay.value = rx.payload[18] << 8 | rx.payload[19];
        processDesc.value = "${StringConstants.downloadingSounderZones} 1/3";
        startRxTimeout();
        await bleManager.sendSounderSetupZoneFetchCmdPkt(zoneMaxZone: 1);
      } else if (rx.payload[12] == 0x19) {
        if (sounderSetupFetchZoneCommandStep >= 1 &&
            sounderSetupFetchZoneCommandStep <= 3) {
          final nextZoneNo = sounderSetupFetchZoneCommandStep + 1;
          processDesc.value =
              "${StringConstants.downloadingSounderZones} $nextZoneNo/3";
          if (sounderSetupFetchZoneCommandStep == 1) {
            final ZoneEquipmentModeConfig config =
                ZoneEquipmentModeCodec.fromHex(
                  rx.payload[15].toRadixString(16),
                );
            final bool zoneEnabled =
                config.zoneEnable == ZoneEquipmentEnable.enabled;
            final bool zoneMode = config.zoneMode == ZoneEquipmentMode.test;

            isZoneOneEnabled.value = zoneEnabled;
            isZoneOneTest.value = zoneMode;
            sounderZoneOneMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            zoneOneAction.value = rx.payload[16];
          } else if (sounderSetupFetchZoneCommandStep == 2) {
            final ZoneEquipmentModeConfig config =
                ZoneEquipmentModeCodec.fromHex(
                  rx.payload[15].toRadixString(16),
                );
            final bool zoneEnabled =
                config.zoneEnable == ZoneEquipmentEnable.enabled;
            final bool zoneMode = config.zoneMode == ZoneEquipmentMode.test;
            isZoneTwoEnabled.value = zoneEnabled;
            isZoneTwoTest.value = zoneMode;
            sounderZoneTwoMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            zoneTwoAction.value = rx.payload[16];
          } else if (sounderSetupFetchZoneCommandStep == 3) {
            final ZoneEquipmentModeConfig config =
                ZoneEquipmentModeCodec.fromHex(
                  rx.payload[15].toRadixString(16),
                );
            final bool zoneEnabled =
                config.zoneEnable == ZoneEquipmentEnable.enabled;
            final bool zoneMode = config.zoneMode == ZoneEquipmentMode.test;
            isZoneThreeEnabled.value = zoneEnabled;
            isZoneThreeTest.value = zoneMode;
            sounderZoneThreeMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            zoneThreeAction.value = rx.payload[16];
          }
          sounderSetupFetchZoneCommandStep = nextZoneNo;
          if (sounderSetupFetchZoneCommandStep <= 3) {
            startRxTimeout();
            await bleManager.sendSounderSetupZoneFetchCmdPkt(
              zoneMaxZone: nextZoneNo,
            );
          } else {
            processDesc.value =
                "${StringConstants.downloadingSounderExtOut} 1/3";
            startRxTimeout();
            await bleManager.sendSounderSetupExtOutFetchCmdPkt(extMaxZone: 1);
          }
        }
      } else if (rx.payload[12] == 0x1B) {
        if (sounderSetupFetchExtOutCommandStep >= 1 &&
            sounderSetupFetchExtOutCommandStep <= 3) {
          final nextExtOutNo = sounderSetupFetchExtOutCommandStep + 1;
          processDesc.value =
              "${StringConstants.downloadingSounderExtOut} $nextExtOutNo/3";
          if (sounderSetupFetchExtOutCommandStep == 1) {
            final ExtZoneEquipmentModeConfig config =
                ExtZoneEquipmentModeCodec.fromHex(
                  rx.payload[15].toRadixString(16),
                );
            final bool zoneEnabled =
                config.zoneEnable == ExtZoneEquipmentEnable.enabled;
            final bool zoneMode = config.zoneMode == ExtZoneEquipmentMode.test;

            isExtOutOneEnabled.value = zoneEnabled;
            isExtOutOneTest.value = zoneMode;
            sounderExtOutOneMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            extoutOneCountdownAction.value = rx.payload[16];
            extoutOneHoldAction.value = rx.payload[17];
            extoutOneReleaseAction.value = rx.payload[18];
          } else if (sounderSetupFetchExtOutCommandStep == 2) {
            final ExtZoneEquipmentModeConfig config =
                ExtZoneEquipmentModeCodec.fromHex(
                  rx.payload[15].toRadixString(16),
                );
            final bool zoneEnabled =
                config.zoneEnable == ExtZoneEquipmentEnable.enabled;
            final bool zoneMode = config.zoneMode == ExtZoneEquipmentMode.test;
            isExtOutTwoEnabled.value = zoneEnabled;
            isExtOutTwoTest.value = zoneMode;
            sounderExtOutTwoMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            extoutTwoCountdownAction.value = rx.payload[16];
            extoutTwoHoldAction.value = rx.payload[17];
            extoutTwoReleaseAction.value = rx.payload[18];
          } else if (sounderSetupFetchExtOutCommandStep == 3) {
            final ExtZoneEquipmentModeConfig config =
                ExtZoneEquipmentModeCodec.fromHex(
                  rx.payload[15].toRadixString(16),
                );
            final bool zoneEnabled =
                config.zoneEnable == ExtZoneEquipmentEnable.enabled;
            final bool zoneMode = config.zoneMode == ExtZoneEquipmentMode.test;
            isExtOutThreeEnabled.value = zoneEnabled;
            isExtOutThreeTest.value = zoneMode;
            sounderExtOutThreeMode.value = rx.payload[15]
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            extoutThreeCountdownAction.value = rx.payload[16];
            extoutThreeHoldAction.value = rx.payload[17];
            extoutThreeReleaseAction.value = rx.payload[18];
          }
          sounderSetupFetchExtOutCommandStep = nextExtOutNo;
          if (sounderSetupFetchExtOutCommandStep <= 3) {
            startRxTimeout();
            await bleManager.sendSounderSetupExtOutFetchCmdPkt(
              extMaxZone: nextExtOutNo,
            );
          } else {
            bleManager.otaProcessState = OtaProcessState.notInUse;
            cancelOperationDeadline();
            checkForSounderSetupFetchRes = 0;
            isSounderSetupFetchCommandActive.value = false;
            isAccessKeyValid.value = true;
            processDesc.value = StringConstants.sounderSetupFetchCompleted;
          }
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForSounderSetupFetchRes = 0;
          isSounderSetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
          processDesc.value = StringConstants.sounderSetupFetchCompleted;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForSounderSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83 && rx.payload[12] == 0x02) {
        if (sounderSetupApplyRelayCommandStep >= 1 &&
            sounderSetupApplyRelayCommandStep <= 3) {
          final nextRelayNo = sounderSetupApplyRelayCommandStep + 1;
          sounderSetupApplyRelayCommandStep = nextRelayNo;
          if (sounderSetupApplyRelayCommandStep <= 3) {
            startRxTimeout();
            processDesc.value =
                "${StringConstants.applyingSounderRelays} $nextRelayNo/3";
            await bleManager.sendSounderSetupRelayApplyCmdPkt(
              outputMaxZone: nextRelayNo,
            );
          } else {
            processDesc.value = StringConstants.applyingSounderGeneral;
            sounderSetupApplyGeneralCommandStep = 1;
            startRxTimeout();
            await bleManager.sendSounderSetupGeneralApplyCmdPkt();
          }
        } else if (sounderSetupApplyGeneralCommandStep == 1) {
          processDesc.value = "${StringConstants.applyingSounderZones} 1/3";
          sounderSetupApplyGeneralCommandStep = 0;
          sounderSetupApplyZoneCommandStep = 1;
          startRxTimeout();
          await bleManager.sendSounderSetupZoneApplyCmdPkt(zoneMaxZone: 1);
        } else if (sounderSetupApplyZoneCommandStep >= 1 &&
            sounderSetupApplyZoneCommandStep <= 3) {
          final nextZoneNo = sounderSetupApplyZoneCommandStep + 1;
          sounderSetupApplyZoneCommandStep = nextZoneNo;
          if (sounderSetupApplyZoneCommandStep <= 3) {
            processDesc.value =
                "${StringConstants.applyingSounderZones} $nextZoneNo/3";
            startRxTimeout();
            await bleManager.sendSounderSetupZoneApplyCmdPkt(
              zoneMaxZone: nextZoneNo,
            );
          } else {
            sounderSetupApplyExtOutCommandStep = 1;
            processDesc.value = "${StringConstants.applyingSounderExtOut} 1/3";
            startRxTimeout();
            await bleManager.sendSounderSetupExtOutApplyCmdPkt(extMaxZone: 1);
          }
        } else if (sounderSetupApplyExtOutCommandStep >= 1 &&
            sounderSetupApplyExtOutCommandStep <= 3) {
          final nextExtOutNo = sounderSetupApplyExtOutCommandStep + 1;
          sounderSetupApplyExtOutCommandStep = nextExtOutNo;
          if (sounderSetupApplyExtOutCommandStep <= 3) {
            processDesc.value =
                "${StringConstants.applyingSounderExtOut} $nextExtOutNo/3";
            startRxTimeout();
            await bleManager.sendSounderSetupExtOutApplyCmdPkt(
              extMaxZone: nextExtOutNo,
            );
          } else {
            bleManager.otaProcessState = OtaProcessState.notInUse;
            cancelOperationDeadline();
            checkForSounderSetupApplyRes = 0;
            isSounderSetupApplyCommandActive.value = false;
            isSounderSetupApplyDone.value = true;
            isAccessKeyValid.value = true;
          }
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForLBusSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83 && rx.payload[12] == 0x02) {
        if (lBusSetupApplyCommandStep >= 1 && lBusSetupApplyCommandStep < 31) {
          final nextBusNo = lBusSetupApplyCommandStep + 1;
          processDesc.value = "${StringConstants.applyingLBus} $nextBusNo/31";
          lBusSetupApplyCommandStep = nextBusNo;
          startRxTimeout();
          await bleManager.sendLBusSetupApplyCmdPkt(lBusNo: nextBusNo);
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForLBusSetupApplyRes = 0;
          isLBusSetupApplyCommandActive.value = false;
          isLBusSetupApplyDone.value = true;
          isAccessKeyValid.value = true;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForLBusSetupFetchRes == 1) {
      if (rx.payload[12] == 0x10) {
        final busIndex = lBusSetupFetchCommandStep - 1;
        if (busIndex >= 0 && busIndex < 31) {
          final parsed = LBusSetupData.fromPayload(rx.payload);
          final updated = List<LBusSetupData>.from(lBusSetupDataList.value);
          updated[busIndex] = parsed;
          lBusSetupDataList.value = updated;
        }

        if (lBusSetupFetchCommandStep >= 1 && lBusSetupFetchCommandStep < 31) {
          final nextBusNo = lBusSetupFetchCommandStep + 1;
          processDesc.value =
              "${StringConstants.downloadingLBus} $nextBusNo/31";
          lBusSetupFetchCommandStep = nextBusNo;
          startRxTimeout();
          await bleManager.sendLBusSetupFetchCmdPkt(lBusNo: nextBusNo);
        } else {
          enabledLBusNumbers.value = [
            for (var i = 0; i < lBusSetupDataList.value.length; i++)
              if (lBusSetupDataList.value[i].enabled == 'Yes') i + 1,
          ];

          if (enabledLBusNumbers.value.isNotEmpty) {
            lBusSetupDataFetchCommandStep = 0;
            processDesc.value =
                "${StringConstants.downloadingEnabledLBus} 1/31";
            startRxTimeout();
            await bleManager.sendLBusEnabledBusDataFetchCmdPkt(
              lBusNo: enabledLBusNumbers.value[0],
            );
          } else {
            bleManager.otaProcessState = OtaProcessState.notInUse;
            cancelOperationDeadline();
            checkForLBusSetupFetchRes = 0;
            isLBusSetupFetchCommandActive.value = false;
            isAccessKeyValid.value = true;
          }
        }
      } else if ((rx.payload[12] == 0x02 || rx.payload[12] == 0x01) &&
          lBusSetupFetchCommandStep == 31) {
        if (rx.payload[12] == 0x01) {
          if (lBusSetupDataFetchCommandStep < enabledLBusNumbers.value.length) {
            final busNo =
                enabledLBusNumbers.value[lBusSetupDataFetchCommandStep];
            final busIndex = busNo - 1;
            final existing = lBusSetupDataList.value[busIndex];
            final updated = LBusSetupData.mergeFromEnabledBusPayload(
              existing,
              rx.payload,
            );
            final list = List<LBusSetupData>.from(lBusSetupDataList.value);
            list[busIndex] = updated;
            lBusSetupDataList.value = list;
          }
        } else if (rx.payload[12] == 0x02 && rx.payload[13] == 0x14) {
          isLbusFetchHasErrors.value = true;
          lbusFetchErrors.value.add(
            (lBusSetupDataFetchCommandStep + 1).toString(),
          );
        }
        final nextIndex = lBusSetupDataFetchCommandStep + 1;
        if (nextIndex < enabledLBusNumbers.value.length) {
          lBusSetupDataFetchCommandStep = nextIndex;
          final nextBusNo = enabledLBusNumbers.value[nextIndex];
          processDesc.value =
              "${StringConstants.downloadingEnabledLBus} $nextBusNo/31";
          startRxTimeout();
          await bleManager.sendLBusEnabledBusDataFetchCmdPkt(lBusNo: nextBusNo);
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForLBusSetupFetchRes = 0;
          isLBusSetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForModuleSetupFetchRes == 1) {
      if (rx.payload[12] == 0x01) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForModuleSetupFetchRes = 0;
        moduleNo.value = rx.payload[13];
        moduleEnabled.value = true;
        moduleProduct.value = extractStringFromPayload(
          rx.payload,
          startIndex: 17,
        );
        moduleId.value = rx.payload[15];
        moduleRevision.value = rx.payload[16];
        moduleHardware.value = [
          rx.payload[30],
          rx.payload[31],
          rx.payload[32],
          rx.payload[33],
        ].join('.');
        moduleFirmware.value = [
          rx.payload[34],
          rx.payload[35],
          rx.payload[36],
          rx.payload[37],
        ].join('.');
        final year = (rx.payload[38] << 8) | rx.payload[39];
        final month = rx.payload[40];
        final day = rx.payload[41];
        moduleDate.value =
            '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year.toString().padLeft(4, '0')}';
        moduleProtocol.value = rx.payload[43];
        isAccessKeyValid.value = true;
        isModuleSetupFetchCommandActive.value = false;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRadioSetupFetchRes == 1) {
      if (rx.payload[12] == 0x1D) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForRadioSetupFetchRes = 0;
        isRadioSetupEnabled.value = rx.payload[13] == 0x01;
        radioSetupModule.value = rx.payload[14];
        radioSetupName.value = extractStringFromPayload(
          rx.payload,
          startIndex: 20,
        );
        String radioSetupNumber = "";
        for (int i = 37; i < 45; i++) {
          radioSetupNumber = radioSetupNumber + rx.payload[i].toString();
        }

        radioSetupNo.value = radioSetupNumber;
        isRadioSetupBooted.value = rx.payload[18] == 0x01;
        isRadioSetupProgrammed.value = rx.payload[17] == 0x01;
        isRadioSetupServiced.value = rx.payload[19] == 0x01;
        isRadioSetupAdvertised.value = rx.payload[15] == 0x01;
        isRadioSetupConnected.value = rx.payload[15] == 0x01;
        isAccessKeyValid.value = true;
        isRadioSetupFetchCommandActive.value = false;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRadioSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForRadioSetupApplyRes = 0;
        isAccessKeyValid.value = true;
        isRadioSetupCommandApplyActive.value = false;
        isRadioSetupApplyDone.value = true;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForExtCmdApplyRes == 1) {
      if (rx.payload[10] == 0x83) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        isAccessKeyValid.value = true;
        checkForExtCmdApplyRes = 0;
        isExtOutCommandApplyActive.value = false;
        isExtOutApplyDone.value = true;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForInputSetupFetchRes == 1) {
      if (rx.payload[12] == 0x06) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForInputSetupFetchRes = 0;
        isInputSetupFetchCommandActive.value = false;
        isAccessKeyValid.value = true;
        final InputModeConfig config = InputModeCodec.fromHex(
          rx.payload[15].toRadixString(16),
        );
        inputSetupGroup.value = rx.payload[23];
        inputSetupFunction.value = rx.payload[24];
        isInputSetupEnabled.value = config.inputEnable == InputEnable.enabled;
        isInputSetupTest.value = config.inputMode == InputMode.test;
        isInputSetupInverted.value = config.invertMode == InvertMode.inverted;
        inputMode.value = InputModeCodec.encodeHex(config);
        inputSetupText.value = extractStringFromPayload(rx.payload);
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForInputSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83) {
        isAccessKeyValid.value = true;
        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        checkForInputSetupApplyRes = 0;
        isInputSetupApplyActive.value = false;
        isInputSetupApplyDone.value = true;
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRelaySetupApplyRes == 1) {
      if (rx.payload[10] == 0x83) {
        if (relaySetupApplyCommandStep == 1) {
          processDesc.value = "${StringConstants.applyingRelay} 2/3";
          relaySetupApplyCommandStep = 2;
          startRxTimeout();
          await bleManager.sendRelaySetupApplySecondCmdPkt();
        } else if (relaySetupApplyCommandStep == 2) {
          processDesc.value = "${StringConstants.applyingRelay} 3/3";
          relaySetupApplyCommandStep = 3;
          startRxTimeout();
          await bleManager.sendRelaySetupApplyThirdCmdPkt();
        } else if (relaySetupApplyCommandStep == 3) {
          isAccessKeyValid.value = true;
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForRelaySetupApplyRes = 0;
          isRelaySetupCommandApplyActive.value = false;
          isRelaySetupApplyDone.value = true;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForExtCmdFetchRes == 1) {
      if (rx.payload[12] == 0x16) {
        bleManager.otaProcessState = OtaProcessState.sendDipSettingFetchCmd;
        checkForExtCmdFetchRes = 0;
        isAccessKeyValid.value = true;
        final ExtZoneModeConfig config = ExtZoneModeCodec.fromHex(
          rx.payload[14].toRadixString(16),
        );
        final bool zoneEnabled = config.extZoneEnable == ExtZoneEnable.enabled;
        final HoldMode holdMode = config.holdMode;
        final bool resetAllowed = config.resetAllowed;
        isExtZoneEnabled.value = zoneEnabled ? 1 : 0;
        extZoneHoldMode.value = holdMode.index;
        isResetAllowed.value = resetAllowed ? 0 : 1;
        extZoneCountdownAuto.value = (rx.payload[17] << 8) | rx.payload[18];
        extZoneCountdownMan.value = (rx.payload[19] << 8) | rx.payload[20];
        extZoneReleaseTime.value = (rx.payload[21] << 8) | rx.payload[22];
        extZoneResetDelay.value = (rx.payload[23] << 8) | rx.payload[24];
        extZoneActuatorType.value = rx.payload[16];
        extZoneAction.value = rx.payload[25];
        extZoneFunction.value = rx.payload[26];
        startRxTimeout();
        await bleManager.sendFetchDipSettingPkt();
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRelaySetupFetchRes == 1) {
      if (rx.payload[12] == 0x07) {
        if (relaySetupFetchCommandStep == 1) {
          processDesc.value = "${StringConstants.downloadingRelay} 2/3";

          final OutputModeConfig config = OutputModeCodec.fromHex(
            rx.payload[15].toRadixString(16),
          );
          final bool outputEnabled =
              config.outputEnable == OutputEnable.enabled;
          final bool outputMode = config.outputMode == OutputMode.test;
          isRelayOneSetupEnabled.value = outputEnabled;
          isRelayOneSetupTest.value = outputMode;
          relayOneMode.value = rx.payload[15]
              .toRadixString(16)
              .toUpperCase()
              .padLeft(2, '0');
          relayOneSetupOutputText.value = extractStringFromPayload(rx.payload);
          relayOneSetupDynamicText.value = rx.payload[22].toRadixString(16);
          relayOneSetupGroup.value = rx.payload[23];
          relayOneSetupFunction.value = rx.payload[24];

          relaySetupFetchCommandStep = 2;
          startRxTimeout();
          await bleManager.sendRelaySetupFetchSecondCmdPkt();
        } else if (relaySetupFetchCommandStep == 2) {
          processDesc.value = "${StringConstants.downloadingRelay} 3/3";

          final OutputModeConfig config = OutputModeCodec.fromHex(
            rx.payload[15].toRadixString(16),
          );
          final bool outputEnabled =
              config.outputEnable == OutputEnable.enabled;
          final bool outputMode = config.outputMode == OutputMode.test;
          isRelayTwoSetupEnabled.value = outputEnabled;
          isRelayTwoSetupTest.value = outputMode;
          relayTwoMode.value = rx.payload[15]
              .toRadixString(16)
              .toUpperCase()
              .padLeft(2, '0');
          relayTwoSetupOutputText.value = extractStringFromPayload(rx.payload);
          relayTwoSetupDynamicText.value = rx.payload[22].toRadixString(16);
          relayTwoSetupGroup.value = rx.payload[23];
          relayTwoSetupFunction.value = rx.payload[24];

          relaySetupFetchCommandStep = 3;
          startRxTimeout();
          await bleManager.sendRelaySetupFetchThirdCmdPkt();
        } else if (relaySetupFetchCommandStep == 3) {
          final OutputModeConfig config = OutputModeCodec.fromHex(
            rx.payload[15].toRadixString(16),
          );
          final bool outputEnabled =
              config.outputEnable == OutputEnable.enabled;
          final bool outputMode = config.outputMode == OutputMode.test;
          isRelayThreeSetupEnabled.value = outputEnabled;
          isRelayThreeSetupTest.value = outputMode;
          relayThreeMode.value = rx.payload[15]
              .toRadixString(16)
              .toUpperCase()
              .padLeft(2, '0');
          relayThreeSetupOutputText.value = extractStringFromPayload(
            rx.payload,
          );
          relayThreeSetupDynamicText.value = rx.payload[22].toRadixString(16);
          relayThreeSetupGroup.value = rx.payload[23];
          relayThreeSetupFunction.value = rx.payload[24];

          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForRelaySetupFetchRes = 0;
          isRelaySetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForZoneSetupApplyRes == 1) {
      if (rx.payload[10] == 0x83) {
        if (zoneSetupApplyCommandStep == 1) {
          processDesc.value = "${StringConstants.applyingZone} 2/3";
          zoneSetupApplyCommandStep = 2;
          startRxTimeout();
          await bleManager.sendZoneSetupApplySecondCmdPkt();
        } else if (zoneSetupApplyCommandStep == 2) {
          processDesc.value = "${StringConstants.applyingZone} 3/3";
          zoneSetupApplyCommandStep = 3;
          startRxTimeout();
          await bleManager.sendZoneSetupApplyThirdCmdPkt();
        } else if (zoneSetupApplyCommandStep == 3) {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForZoneSetupApplyRes = 0;
          isZoneSetupCommandApplyActive.value = false;
          isZoneSetupApplyDone.value = true;
          isAccessKeyValid.value = true;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForZoneSetupFetchRes == 1) {
      if (rx.payload[12] == 0x04) {
        if (zoneSetupFetchCommandStep == 1) {
          processDesc.value = "${StringConstants.downloadingZone} 2/3";
          final ZoneModeConfig config = ZoneModeCodec.fromHex(
            rx.payload[14].toRadixString(16),
          );
          final bool zoneEnabled = config.zoneEnable == ZoneEnable.enabled;
          final bool zoneTestMode = config.zoneTestMode == ZoneTestMode.test;
          final bool zoneType = config.zoneType == ZoneType.isMtl5561;
          zoneOneSetupType.value = zoneType ? 1 : 0;
          zoneOneSetupDetectionMode.value = rx.payload[15];
          isZoneOneSetupEnabled.value = zoneEnabled;
          isZoneOneSetupTest.value = zoneTestMode;
          zoneOneSetupText.value = extractStringFromPayload(
            rx.payload,
            startIndex: 18,
          );
          zoneOneSetupVerificationTime.value = rx.payload[16].toString();
          zoneSetupFetchCommandStep = 2;
          startRxTimeout();
          await bleManager.sendZoneSetupFetchSecondCmdPkt();
        } else if (zoneSetupFetchCommandStep == 2) {
          processDesc.value = "${StringConstants.downloadingZone} 3/3";
          final ZoneModeConfig config = ZoneModeCodec.fromHex(
            rx.payload[14].toRadixString(16),
          );
          final bool zoneEnabled = config.zoneEnable == ZoneEnable.enabled;
          final bool zoneTestMode = config.zoneTestMode == ZoneTestMode.test;
          final bool zoneType = config.zoneType == ZoneType.isMtl5561;
          zoneTwoSetupType.value = zoneType ? 1 : 0;
          zoneTwoSetupDetectionMode.value = rx.payload[15];
          isZoneTwoSetupEnabled.value = zoneEnabled;
          isZoneTwoSetupTest.value = zoneTestMode;
          zoneTwoSetupText.value = extractStringFromPayload(
            rx.payload,
            startIndex: 18,
          );
          zoneTwoSetupVerificationTime.value = rx.payload[16].toString();
          zoneSetupFetchCommandStep = 3;
          startRxTimeout();
          await bleManager.sendZoneSetupFetchThirdCmdPkt();
        } else if (zoneSetupFetchCommandStep == 3) {
          final ZoneModeConfig config = ZoneModeCodec.fromHex(
            rx.payload[14].toRadixString(16),
          );
          final bool zoneEnabled = config.zoneEnable == ZoneEnable.enabled;
          final bool zoneTestMode = config.zoneTestMode == ZoneTestMode.test;
          final bool zoneType = config.zoneType == ZoneType.isMtl5561;
          zoneThreeSetupType.value = zoneType ? 1 : 0;
          zoneThreeSetupDetectionMode.value = rx.payload[15];
          isZoneThreeSetupEnabled.value = zoneEnabled;
          isZoneThreeSetupTest.value = zoneTestMode;
          zoneThreeSetupText.value = extractStringFromPayload(
            rx.payload,
            startIndex: 18,
          );
          zoneThreeSetupVerificationTime.value = rx.payload[16].toString();
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForZoneSetupFetchRes = 0;
          isZoneSetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
        }
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForCtrlCmdRsp == 1) {
      if (rx.payload[3] == 0x03 && nackRetryCount < 3) {
        Get.find<BleLogController>().restartNetworkFlow();
      } else if (rx.payload[10] == 0x83) {
        isAccessKeyValid.value = true;
        if (isSessionAccessCodeValidationOnly) {
          isSessionAccessCodeValidationOnly = false;
          bleManager.otaProcessState = OtaProcessState.notInUse;
          cancelOperationDeadline();
          checkForCtrlCmdRsp = 0;
          cancelRxTimeout();
          processDesc.value = "";
        } else {
          checkForCtrlCmdRsp = 2;
          logStartingTime = DateTime.now();
          startRxTimeout();
          await bleManager.sendPollPacket();
        }
      } else if (nackRetryCount == 3) {
        isOtaCompleted = true;
        processNextOtaFrame = false;

        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelOperationDeadline();
        cancelRxTimeout();
      } else {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    } else if (checkForCtrlCmdRsp == 2) {
      receivedPollCount++;
      int rxLastEvtLogNum =
          rx.payload[19] |
          (rx.payload[18] << 8) |
          (rx.payload[17] << 16) |
          (rx.payload[16] << 24);

      processDesc.value = "";

      if (rxLastEvtLogNum != 0) {
        validEventLogNum++;
        validEventLogCount.value = validEventLogNum;
        try {
          LogModel? parsedLog = _parseEventLogFromPayload(
            rx.payload,
            rxLastEvtLogNum,
          );
          if (parsedLog != null && parsedLog.eventId != "0") {
            isValidLogRecieved.value = true;
            final currentLogs = List<LogModel>.from(validEventLogs.value);
            currentLogs.add(parsedLog);
            validEventLogs.value = currentLogs;
          }
        } catch (_) {}
      }

      if (rx.payload[12] == 0x02) {
        read1000Logs++;
        read1000LogsCount.value = read1000Logs;
      }

      if (read1000Logs != 1000) {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    processNextOtaFrame = true;

    if (read1000Logs >= 1000 && !isOtaCompleted) {
      isOtaCompleted = true;
      processNextOtaFrame = false;

      bleManager.otaProcessState = OtaProcessState.notInUse;
      cancelOperationDeadline();
      cancelRxTimeout();

      processDesc.value = "";

      logEndTime = DateTime.now();

      await bleManager.sendStopCntrlCmdPkt();
      return;
    }
  }

  void setIfChanged(ValueNotifier<double> notifier, double newValue) {
    if (notifier.value != newValue) {
      notifier.value = newValue;
    }
  }

  void updateNotifiers(AdcValues adc) {
    setIfChanged(sounderOneAdcValue, adc.sounder1);
    setIfChanged(sounderTwoAdcValue, adc.sounder2);
    setIfChanged(sounderThreeAdcValue, adc.sounder3);
    setIfChanged(dischargeAdcValue, adc.discharge);
    setIfChanged(vauxAdcValue, adc.vaux);
    setIfChanged(vinAdcValue, adc.vin);
    setIfChanged(progInputAdcValue, adc.progInput);
    setIfChanged(holdInputAdcValue, adc.holdInput);
    setIfChanged(zone1AdcValue, adc.zone1);
    setIfChanged(zone2AdcValue, adc.zone2);
    setIfChanged(zone3AdcValue, adc.zone3);
    setIfChanged(earthAdcValue, adc.earth);
    _persistDiagnosticCache(adc);
  }

  void _persistDiagnosticCache(AdcValues adc) {
    final id =
        bleManager.selectedDevice?.id ?? bleManager.connectedDeviceId.value;
    if (id.isEmpty) return;
    PeripheralSetupCache.saveDiagnosticSetup(id, {
      'sounder1': adc.sounder1,
      'sounder2': adc.sounder2,
      'sounder3': adc.sounder3,
      'discharge': adc.discharge,
      'vaux': adc.vaux,
      'vin': adc.vin,
      'progInput': adc.progInput,
      'holdInput': adc.holdInput,
      'zone1': adc.zone1,
      'zone2': adc.zone2,
      'zone3': adc.zone3,
      'earth': adc.earth,
    });
  }

  void stopLiveEventSetup() {
    isOtaCompleted = true;
    processNextOtaFrame = false;
    bleManager.otaProcessState = OtaProcessState.notInUse;
    cancelOperationDeadline();
    cancelRxTimeout();
    processDesc.value = "";
  }

  String extractStringFromPayload(List<int> payload, {int startIndex = 25}) {
    if (startIndex < 0 || startIndex >= payload.length) {
      return '';
    }
    final int declared = payload[startIndex];
    final int stringStart = startIndex + 1;
    final int endExclusive = stringStart + declared;
    if (declared < 0 || endExclusive > payload.length) {
      return '';
    }
    if (declared == 0) {
      return '';
    }
    final List<int> stringBytes = payload.sublist(stringStart, endExclusive);
    try {
      return utf8.decode(stringBytes);
    } catch (e) {
      return '';
    }
  }

  void _applyNetworkPacketVersionFields(List<int> payload) {
    const int startIndex = 16;
    if (startIndex >= payload.length) return;
    final int declared = payload[startIndex];
    final int nameEnd = startIndex + 1 + declared;
    if (declared < 0 || nameEnd > payload.length) return;
    int off = nameEnd;
    if (off < payload.length && payload[off] == 0x20) {
      off++;
    }
    if (off + 14 > payload.length) {
      return;
    }
    receivedHardwareVersion.value =
        '${payload[off]}.${payload[off + 1]}.${payload[off + 2]}.${payload[off + 3]}';
    receivedFirmwareVersion.value =
        '${payload[off + 4]}.${payload[off + 5]}.${payload[off + 6]}.${payload[off + 7]}';
    final int year = (payload[off + 8] << 8) | payload[off + 9];
    final int month = payload[off + 10];
    final int day = payload[off + 11];
    receivedFirmwareDate.value =
        '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-$year';
    final int proto = (payload[off + 12] << 8) | payload[off + 13];
    receivedProtocolVersion.value = proto.toString();
  }

  void resetProcessState() {
    isSessionAccessCodeValidationOnly = false;
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;
    checkForExtCmdFetchRes = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRadioSetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    checkDipSetCmdRsp = 0;
    isExtOutApplyButtonActive.value = false;
    isExtOutCommandFetchActive.value = false;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;
    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    resetNetworkFlowRestartCount();
    _networkFlowFailureHandling = false;

    logStartingTime = null;
    logEndTime = null;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
    cancelAccessKeyPollDeadline();

    validEventLogCount.value = 0;
    read1000LogsCount.value = 0;
    validEventLogs.value = [];
    isValidLogRecieved.value = false;
    panelName.value = "";
  }

  void resetProcessExtOutState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupApplyRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForRadioSetupFetchRes = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessInputSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForAccessKeyCmdRsp = 0;
    checkForRadioSetupFetchRes = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessRelaySetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRadioSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessZoneSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    checkForRadioSetupFetchRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessRadioSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessModuleSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessLBusSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessSounderSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessServiceDueState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessAccessCodeSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessPanelInfoSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessGeneralModuleSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  void resetProcessAdcSetupState() {
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    checkDipSetCmdRsp = 0;
    checkForExtCmdFetchRes = 0;
    checkForInputSetupFetchRes = 0;
    checkForRelaySetupApplyRes = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;
    checkForRadioSetupFetchRes = 0;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    checkForSounderSetupFetchRes = 0;
    checkForSounderSetupApplyRes = 0;
    checkForServiceDueFetchRes = 0;
    checkForAccessCodeSetupFetchRes = 0;
    accessCodeSetupFetchCommandStep = 0;
    checkForAccessCodeSetupApplyRes = 0;
    accessCodeSetupApplyCommandStep = 0;
    isLbusFetchHasErrors.value = false;
    lbusFetchErrors.value.clear();
    checkForPanelInfoSetupFetchRes = 0;
    checkForPanelInfoSetupApplyRes = 0;
    checkForGeneralModuleSetupFetchRes = 0;
    checkForGeneralModuleSetupApplyRes = 0;
    checkForLiveEventsRetrievalRes = 0;
    processDesc.value = "";
    checkForAdcSetupFetchRes = 0;

    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;
    isNetworkPacketProcess.value = true;

    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    cancelOperationDeadline();
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> bleProcess() async {
    switch (bleManager.bleStateMachineState) {
      case BleStates.PROCESS_PANEL_EVT_LOG_READ:
        bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
        await handleTsEvtLogRead();
        break;

      case BleStates.PROCESS_WAIT_RSP:
        break;

      case BleStates.IDLE:
        break;

      default:
        break;
    }

    if (!bleManager.isConnected) {
      await bleManager.disconnectHandler(deviceId: connectedDeviceId.value);
    }
  }

  requestENCKey() async {
    bleCurrentState = BleStates.REQ_ENCY_KEY;
    bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
    await bleManager.sendAesKeyReq();
  }

  sendAuthPacket() async {
    await bleManager.sendAuthnMsg();
    bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
    bleCurrentState = BleStates.SEND_AUTHN_MSG;
  }

  sendExtOutApplyPacket() async {
    processDesc.value = StringConstants.sendingExtOutPacket;
    await bleManager.sendExtOutSetupApplyCmdPkt();
    bleManager.bleStateMachineState =
        BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
  }

  bool _shouldBumpOperationDeadline() {
    if (isOtaCompleted) return false;
    if (checkForCtrlCmdRsp == 2) return false;
    return true;
  }

  void cancelOperationDeadline() {
    _operationDeadlineTimer?.cancel();
    _operationDeadlineTimer = null;
  }

  void _restartOperationDeadlineTimer() {
    if (isOtaCompleted) return;
    _operationDeadlineTimer?.cancel();
    _operationDeadlineTimer = Timer(
      bleOperationDeadlineDuration,
      _onOperationDeadlineExceeded,
    );
  }

  void _onOperationDeadlineExceeded() {
    _operationDeadlineTimer = null;
    if (isOtaCompleted) return;
    if (checkForCtrlCmdRsp == 2) return;
    if (checkForAccessKeyCmdRsp == 1) {
      _onAccessKeyPollTimeout();
      return;
    }

    processDesc.value = StringConstants.operationTimedOut;
    unawaited(handleNetworkFlowNoResponse());
  }

  void startAccessKeyPollDeadline() {
    cancelAccessKeyPollDeadline();
    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;
    _accessKeyPollStartedAt = DateTime.now();
    _accessKeyPollDeadlineTimer = Timer(
      accessKeyPollTimeoutDuration,
      _onAccessKeyPollTimeout,
    );
  }

  void cancelAccessKeyPollDeadline() {
    _accessKeyPollDeadlineTimer?.cancel();
    _accessKeyPollDeadlineTimer = null;
    _accessKeyPollStartedAt = null;
  }

  void _onAccessKeyPollTimeout() {
    final duringAccessKeyPoll = checkForAccessKeyCmdRsp == 1;
    final sessionValidation = isSessionAccessCodeValidationOnly;
    if (!duringAccessKeyPoll && !sessionValidation) return;

    cancelAccessKeyPollDeadline();
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;
    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;
    cancelOperationDeadline();

    checkForAccessKeyCmdRsp = 0;
    bleManager.otaProcessState = OtaProcessState.notInUse;
    bleManager.resetPollInFlight();
    isSessionAccessCodeValidationOnly = false;
    processNextOtaFrame = false;

    processDesc.value = StringConstants.somethingWentWrong;
    isAccessKeyValid.value = false;
  }

  void cancelRxTimeout() {
    _rxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer?.cancel();
    cancelOperationDeadline();
  }

  LogModel? _parseEventLogFromPayload(List<int> payload, int eventLogNum) {
    try {
      if (payload.length < 130) {
        return null;
      }

      List<int> timestamp = payload.sublist(25, 29);
      int timestampDecimal =
          timestamp[3] |
          (timestamp[2] << 8) |
          (timestamp[1] << 16) |
          (timestamp[0] << 24);

      DateTime eventTime =
          timestampDecimal != 0x00
              ? TimestampConverter.clockTimeFromTimeStamp(timestampDecimal)
              : DateTime.now();

      String evtTextAscii = "";
      if (payload.length >= 124) {
        List<int> evtText = payload.sublist(55, 137);
        if (evtText.length > 1 && evtText[1] != 0x00) {
          int textLen = evtText[1];
          if (textLen > 0 && textLen < evtText.length - 2) {
            List<int> evtTextValue = evtText.sublist(2, 2 + textLen);
            evtTextAscii = String.fromCharCodes(evtTextValue);
          }
        }
      }

      String panelSource = "";
      if (payload.length >= 31) {
        if (payload[22] == EventConstants.evtTypeNetworkAddress) {
          panelSource =
              payload[42] == 0
                  ? "Module"
                  : payload[42] == 1
                  ? "Panel No. ${payload[43]}"
                  : payload[42] == 2
                  ? "Repeater No. ${payload[43]}"
                  : payload[42] == 3
                  ? "SOLAR"
                  : payload[42] == 4
                  ? "Server No. ${payload[43]}"
                  : payload[42] == 5
                  ? "Bluetooth"
                  : "";
        } else if (payload[22] == EventConstants.evtTypeAccess) {
          panelSource =
              payload[42] == 0
                  ? "Control"
                  : payload[42] == 1
                  ? "Keyboard"
                  : payload[42] == 2
                  ? "SOLAR"
                  : payload[42] == 3
                  ? "Server"
                  : payload[42] == 4
                  ? "Bluetooth"
                  : "";
        } else {
          panelSource = StringConstants.panelNo1;
        }
      }

      return LogModel(
        panelText: panelSource,
        eventId: eventLogNum.toString(),
        eventDateTime: eventTime,
        panelNo: payload.isNotEmpty ? payload[13].toString() : null,
        lBusNo: payload.length > 1 ? payload[14].toString() : null,
        moduleNo: payload.length > 2 ? payload[15].toString() : null,
        eventStatus:
            payload.length > 10
                ? EventConstants.getEventStatusValue(payload[23])
                : null,
        eventClass:
            payload.length > 7
                ? EventConstants.getEventClassValue(payload[20])
                : null,
        eventSource: panelSource,
        eventType:
            payload.length > 9
                ? EventConstants.getEventType(payload[22])
                : null,
        eventSubType:
            payload.length > 11
                ? EventConstants.getEventDescription(
                  payload[22],
                  payload[22] == EventConstants.evtTypeRestart
                      ? payload[42]
                      : payload[24],
                )
                : null,
        identifier:
            payload.length >= 32
                ? EventConstants.getEventIdentifier(
                  payload[22],
                  payload[42],
                  payload[43],
                  payload[44],
                  payload[29],
                  payload[31],
                  payload[33],
                )
                : null,
        text: evtTextAscii,
        isValid: timestampDecimal != 0x00,
        retrievedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _rxTimeoutTimer?.cancel();
    cancelOperationDeadline();
    cancelAccessKeyPollDeadline();
    validEventLogCount.dispose();
    validEventLogs.dispose();
    read1000LogsCount.dispose();
    isValidLogRecieved.dispose();
  }

  void startRxTimeout({bool bumpOperationDeadline = true}) {
    maxOtherPacketsRetriesReached.value = false;
    if (isOtaCompleted) return;

    if (_shouldBumpOperationDeadline()) {
      if (bumpOperationDeadline) {
        _restartOperationDeadlineTimer();
      }
    } else {
      cancelOperationDeadline();
    }

    _rxTimeoutTimer?.cancel();

    _rxTimeoutTimer = Timer(const Duration(seconds: 2), () async {
      if (isOtaCompleted) return;

      rxTimeoutRetryCount++;

      processDesc.value =
          "${StringConstants.noResponseFromDevice} ($rxTimeoutRetryCount/$maxRxRetries)";

      if (rxTimeoutRetryCount >= maxRxRetries) {
        processDesc.value = StringConstants.deviceNotResponding;
        unawaited(handleNetworkFlowNoResponse());
        return;
      }

      bleManager.resetPollInFlight();
      processNextOtaFrame = true;

      await handleTsEvtLogRead();
    });
  }

  void restartInitialNetworkFlow() {
    startOtherPacketsRxTimeout(timeout: const Duration(seconds: 12));
    Get.find<BleLogController>().restartNetworkFlow();
  }

  Future<void> handleNetworkFlowNoResponse() async {
    if (_networkFlowFailureHandling || isOtaCompleted) return;

    if (checkForAccessKeyCmdRsp == 1 || isSessionAccessCodeValidationOnly) {
      _onAccessKeyPollTimeout();
      return;
    }

    networkFlowRestartCount++;
    processDesc.value =
        '${StringConstants.noResponseFromDevice} ($networkFlowRestartCount/$maxNetworkFlowRestarts)';

    if (networkFlowRestartCount < maxNetworkFlowRestarts) {
      restartInitialNetworkFlow();
      return;
    }

    _networkFlowFailureHandling = true;
    maxOtherPacketsRetriesReached.value = true;
    cancelRxTimeout();
    isOtaCompleted = true;
    processNextOtaFrame = false;
    bleManager.otaProcessState = OtaProcessState.notInUse;
    await Get.find<BleLogController>().onNetworkFlowFailed();
    _networkFlowFailureHandling = false;
  }

  void startOtherPacketsRxTimeout({Duration? timeout}) {
    if (checkForAccessKeyCmdRsp == 1) {
      return;
    }

    _rxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer?.cancel();
    cancelOperationDeadline();

    _otherPacketsRxTimeoutTimer = Timer(
      timeout ?? const Duration(seconds: 12),
      () {
        unawaited(handleNetworkFlowNoResponse());
      },
    );
  }

  Future<void> handleTsEvtLogRead() async {
    if (isOtaCompleted ||
        bleManager.otaProcessState == OtaProcessState.notInUse) {
      return;
    }

    if (processNextOtaFrame) {
      startRxTimeout();
      processNextOtaFrame = false;

      switch (bleManager.otaProcessState) {
        case OtaProcessState.sendNetworkPacket:
          processDesc.value = StringConstants.sendingNetworkPacket;
          await bleManager.sendNetworkPacket();
          break;
        case OtaProcessState.sendPollPacket:
          await bleManager.sendPollPacket();
          break;
        case OtaProcessState.sendAccessKeyPacket:
          await bleManager.sendAccessKeyPkt();
          break;
        case OtaProcessState.sendControlCmdPacket:
          await bleManager.sendStartCntrlCmdPkt();
          break;
        case OtaProcessState.sendStopCntrlCmdPkt:
          await bleManager.sendStopCntrlCmdPkt();
          break;
        case OtaProcessState.sendContinuousPollPacket:
          await bleManager.sendPollPacket();
          break;
        case OtaProcessState.notInUse:
          break;
        case OtaProcessState.otaWaitRsp:
          break;
        case OtaProcessState.sendExtOutSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendDipSettingFetchCmd:
          break;
        case OtaProcessState.sendExtOutSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendInputSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendInputSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendRelaySetupFetchCmdPkt:
          break;
        case OtaProcessState.sendRelaySetupApplyCmdPkt:
          break;
        case OtaProcessState.sendZoneSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendZoneSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendRadioSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendRadioSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendModuleSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendLBusSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendLBusSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendSounderSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendSounderSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendServiceDueFetchCmdPkt:
          break;
        case OtaProcessState.sendServiceDueApplyCmdPkt:
          break;
        case OtaProcessState.sendAccessCodeSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendAccessCodeSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendPanelInfoSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendPanelInfoSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendGeneralModuleSetupFetchCmdPkt:
          break;
        case OtaProcessState.sendGeneralModuleSetupApplyCmdPkt:
          break;
        case OtaProcessState.sendLiveEventsRetrievalFetchCmdPkt:
          break;
        case OtaProcessState.sendAdcSetupFetchCmdPkt:
          break;
      }
      startRxTimeout();
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> runStateMachine() async {
    if (_isStateMachineRunning) return;

    _isStateMachineRunning = true;

    while (!isOtaCompleted && !_restartRequested) {
      try {
        await bleProcess();
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        break;
      }
    }

    _isStateMachineRunning = false;
    _restartRequested = false;
  }
}
