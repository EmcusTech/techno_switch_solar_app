import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/input_mode_util.dart';
import 'package:techno_switch_solar_app/utils/relay_mode_util.dart';
import 'package:techno_switch_solar_app/utils/ext_zone_mode_util.dart';
import 'package:techno_switch_solar_app/utils/zone_mode_util.dart';
import 'ble_manager.dart';
import 'ble_frame.dart';
import '../models/log_model.dart';
import '../models/l_bus_setup_data_model.dart';
import '../utils/event_constants.dart';
import '../utils/timestamp_converter.dart';

class BleProcess {
  final BleManager bleManager;
  Timer? _rxTimeoutTimer;
  Timer? _otherPacketsRxTimeoutTimer;

  int checkForCtrlCmdRsp = 0;
  int checkForExtCmdFetchRes = 0;
  int checkForExtCmdApplyRes = 0;
  int checkDipSetCmdRsp = 0;
  int checkForAccessKeyCmdRsp = 0;
  int checkForInputSetupFetchRes = 0;
  int checkForInputSetupApplyRes = 0;
  int checkForRelaySetupFetchRes = 0;
  int checkForRelaySetupApplyRes = 0;
  int relaySetupFetchCommandStep = 0; // 1, 2, 3
  int relaySetupApplyCommandStep = 0; // 1, 2, 3
  int checkForZoneSetupFetchRes = 0;
  int checkForZoneSetupApplyRes = 0;
  int zoneSetupFetchCommandStep = 0; // 1, 2, 3
  int zoneSetupApplyCommandStep = 0; // 1, 2, 3
  int checkForRadioSetupFetchRes = 0;
  int checkForRadioSetupApplyRes = 0;
  int checkForModuleSetupFetchRes = 0;
  int checkForLBusSetupFetchRes = 0;
  int lBusSetupFetchCommandStep = 0; // 1, 2, 3 ... 31
  int checkForLBusSetupApplyRes = 0;
  int lBusSetupApplyCommandStep = 0; // 1, 2, 3 ... 31
  int validEventLogNum = 0;
  int read1000Logs = 0;
  bool logRetreivalEnded = false;
  // bool isExtOutCommandActive = false;

  DateTime? logStartingTime;
  DateTime? logEndTime;

  bool _isStateMachineRunning = false;
  bool _restartRequested = false;

  bool isOtaCompleted = false;

  // RX timeout retry control
  static const int maxRxRetries = 3;
  int rxTimeoutRetryCount = 0;
  int nackRetryCount = 0;

  // ValueNotifier to expose valid event log count to UI
  final ValueNotifier<int> validEventLogCount = ValueNotifier<int>(0);

  // ValueNotifier to expose read1000Logs count to UI for progress tracking
  final ValueNotifier<int> read1000LogsCount = ValueNotifier<int>(0);

  // ValueNotifier to expose list of valid event logs to UI
  final ValueNotifier<List<LogModel>> validEventLogs =
      ValueNotifier<List<LogModel>>([]);

  final ValueNotifier<bool> isValidLogRecieved = ValueNotifier<bool>(false);

  final ValueNotifier<String> processDesc = ValueNotifier<String>("");

  // ValueNotifier to expose panel name (kept for API compatibility; set externally)
  final ValueNotifier<String> panelName = ValueNotifier<String>("");

  final ValueNotifier<String> connectedDeviceId = ValueNotifier<String>("");

  final ValueNotifier<bool> maxBleConnectionRetriesReached =
      ValueNotifier<bool>(false);

  final ValueNotifier<bool> maxOtherPacketsRetriesReached = ValueNotifier<bool>(
    false,
  );

  // null = not yet validated, true/false = result
  final ValueNotifier<bool?> isAccessKeyValid = ValueNotifier<bool?>(null);

  final ValueNotifier<String> accessKey = ValueNotifier<String>("");

  final ValueNotifier<int> bleManufacturerData = ValueNotifier<int>(0);

  // Ext Out Variables

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

  // Input Setup Variables

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

  // Relay Setup Variables
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

  // Zone Setup Variables
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

  // Radio Setup Variables
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

  // Module Setup Variables
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

  // L-Bus Setup Variables
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

  // BleStates bleStateMachineState = BleStates.IDLE;
  BleStates bleCurrentState = BleStates.IDLE;
  DeviceConnectState deviceConnectState = DeviceConnectState.notConnected;

  bool processNextOtaFrame = true;
  int txData = 1;

  int pollWaitRspTimeoutCnt = 0;

  int receivedPollCount = 0;

  BleProcess(this.bleManager);

  Future<void> bleRxFrameProcess(BleRxFrame rx) async {
    //RX received → reset retry counter
    rxTimeoutRetryCount = 0;
    pollWaitRspTimeoutCnt = 0;
    nackRetryCount = 0;

    bleManager.u8RxPktCnt = rx.payload[4];

    print(
      "Rx pkt count: $bleManager.u8RxPktCnt (STATE: ${bleManager.otaProcessState.name}",
    );

    // ----- OTA STATE MACHINE -----
    switch (bleManager.otaProcessState) {
      case OtaProcessState.sendNetworkPacket:
        print("NEXT: POLL PACKET");
        // await Future.delayed(Duration(seconds: 1));
        bleManager.otaProcessState = OtaProcessState.sendPollPacket;
        startRxTimeout();
        await bleManager.sendPollPacket();
        break;

      case OtaProcessState.sendPollPacket:
        print("NEXT: ACCESS PACKET");
        // await Future.delayed(Duration(seconds: 1));
        bleManager.otaProcessState = OtaProcessState.sendAccessKeyPacket;
        startRxTimeout();
        await bleManager.sendAccessKeyPkt();
        break;

      case OtaProcessState.sendAccessKeyPacket:
        print("NEXT: CONTINUOUS POLL PACKET");
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        checkForAccessKeyCmdRsp = 1;
        break;

      case OtaProcessState.sendContinuousPollPacket:
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        break;

      case OtaProcessState.sendControlCmdPacket:
        print("Control cmd received → Next continuous poll");
        bleManager.otaProcessState =
            logRetreivalEnded
                ? OtaProcessState.notInUse
                : OtaProcessState.sendContinuousPollPacket;
        checkForCtrlCmdRsp = 1;
        //the poll for the control cmd will be send down in the if else condition's
        break;

      case OtaProcessState.sendStopCntrlCmdPkt:
        print("Sending Stop Control Command");
        processDesc.value = "Sending Stop Control Command";
        if (checkForCtrlCmdRsp == 1) {
          logRetreivalEnded = true;
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
        print("Sending Ext Out Setup Fetch Command");
        checkForExtCmdFetchRes = 1;
        break;

      case OtaProcessState.sendExtOutSetupApplyCmdPkt:
        print("Sending Ext Out Setup Apply Command");
        checkForExtCmdApplyRes = 1;

      case OtaProcessState.sendDipSettingFetchCmd:
        print("Sending Dip setting fetch cmd");
        checkDipSetCmdRsp = 1;

      case OtaProcessState.sendInputSetupFetchCmdPkt:
        print("Sending Input Setup Fetch Command");
        checkForInputSetupFetchRes = 1;
        break;

      case OtaProcessState.sendInputSetupApplyCmdPkt:
        print("Sending Input Setup Apply Command");
        checkForInputSetupApplyRes = 1;
        break;

      case OtaProcessState.sendRelaySetupFetchCmdPkt:
        print("Sending Relay Setup Fetch Command");
        checkForRelaySetupFetchRes = 1;
        break;

      case OtaProcessState.sendRelaySetupApplyCmdPkt:
        print("Sending Relay Setup Apply Command");
        checkForRelaySetupApplyRes = 1;
        break;

      case OtaProcessState.sendZoneSetupFetchCmdPkt:
        print("Sending Zone Setup Fetch Command");
        checkForZoneSetupFetchRes = 1;
        break;

      case OtaProcessState.sendZoneSetupApplyCmdPkt:
        print("Sending Zone Setup Apply Command");
        checkForZoneSetupApplyRes = 1;
        break;

      case OtaProcessState.sendRadioSetupFetchCmdPkt:
        print("Sending Radio Setup Fetch Command");
        checkForRadioSetupFetchRes = 1;
        break;

      case OtaProcessState.sendRadioSetupApplyCmdPkt:
        print("Sending Radio Setup Apply Command");
        checkForRadioSetupApplyRes = 1;
        break;

      case OtaProcessState.sendModuleSetupFetchCmdPkt:
        print("Sending Module Setup Fetch Command");
        checkForModuleSetupFetchRes = 1;
        break;

      case OtaProcessState.sendLBusSetupFetchCmdPkt:
        print("Sending L-Bus Setup Fetch Command");
        checkForLBusSetupFetchRes = 1;
        break;

      case OtaProcessState.sendLBusSetupApplyCmdPkt:
        print("Sending L-Bus Setup Apply Command");
        checkForLBusSetupApplyRes = 1;
        break;

      case OtaProcessState.otaWaitRsp:
        break;
    }

    // ----- ACCESS KEY RESPONSE -----
    if (checkForAccessKeyCmdRsp == 1) {
      print("Checking ACCESS KEY CMD RSP...");

      if (rx.payload[13] != 0x0a &&
          String.fromCharCodes(rx.payload.sublist(14, 18)) == accessKey.value) {
        // isAccessKeyValid.value = true;
        print("ACCESS KEY RECEIVED → NEXT CONTROL CMD");
        if (isInputSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendInputSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendInputSetupFetchCmdPkt();
        } else if (isExtOutCommandFetchActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendExtOutSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendExtOutSetupFetchCmdPkt();
        } else if (isExtOutCommandApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendExtOutSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendExtOutSetupApplyCmdPkt();
        } else if (isInputSetupApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendInputSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendInputSetupApplyCmdPkt();
        } else if (isRelaySetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRelaySetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          relaySetupFetchCommandStep = 1;
          startRxTimeout();
          await bleManager.sendRelaySetupFetchFirstCmdPkt();
        } else if (isRelaySetupCommandApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRelaySetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          relaySetupApplyCommandStep = 1;
          startRxTimeout();
          await bleManager.sendRelaySetupApplyFirstCmdPkt();
        } else if (isZoneSetupFetchCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendZoneSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          zoneSetupFetchCommandStep = 1;
          startRxTimeout();
          await bleManager.sendZoneSetupFetchFirstCmdPkt();
        } else if (isZoneSetupCommandApplyActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendZoneSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          zoneSetupApplyCommandStep = 1;
          startRxTimeout();
          await bleManager.sendZoneSetupApplyFirstCmdPkt();
        } else if (isRadioSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRadioSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendRadioSetupFetchCmdPkt();
        } else if (isRadioSetupCommandApplyActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendRadioSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendRadioSetupApplyCmdPkt();
        } else if (isModuleSetupFetchCommandActive.value) {
          bleManager.otaProcessState =
              OtaProcessState.sendModuleSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendModuleSetupFetchCmdPkt();
        } else if (isLBusSetupFetchCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendLBusSetupFetchCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          lBusSetupFetchCommandStep = 1;
          startRxTimeout();
          await bleManager.sendLBusSetupFetchCmdPkt(lBusNo: 1);
        } else if (isLBusSetupApplyCommandActive.value) {
          bleManager.otaProcessState = OtaProcessState.sendLBusSetupApplyCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          lBusSetupApplyCommandStep = 1;
          startRxTimeout();
          await bleManager.sendLBusSetupApplyCmdPkt(lBusNo: 1);
        } else {
          bleManager.otaProcessState = OtaProcessState.sendStopCntrlCmdPkt;
          checkForAccessKeyCmdRsp = 0;
          startRxTimeout();
          await bleManager.sendStopCntrlCmdPkt();
        }
      } else if (rx.payload[13] == 0x0a &&
          String.fromCharCodes(rx.payload.sublist(14, 18)) == accessKey.value) {
        isAccessKeyValid.value = false;
        processDesc.value = "Wrong password. Try again.";
        resetProcessState();
        return;
      } else {
        print("ACCESS KEY not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkDipSetCmdRsp == 1) {
      print("Checking Dip Setting cmd resp");
      if (rx.payload[12] == 0x1C) {
        print("We got dip fetch response");
        bleManager.otaProcessState = OtaProcessState.notInUse;
        checkDipSetCmdRsp == 0;
        print(rx.payload[14]);
        if (rx.payload[14] == 0x00) {
          print("The setup source is solar");
          isExtOutApplyButtonActive.value = true;
        }
      } else {
        print("Dip setting Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
      // checkDipSetCmdRsp = 0;
    }

    if (checkForLBusSetupApplyRes == 1) {
      print(
        "Checking L-Bus Setup Apply CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x02} ",
      );
      if (rx.payload[12] == 0x02) {
        if (lBusSetupApplyCommandStep >= 1 && lBusSetupApplyCommandStep < 31) {
          final nextBusNo = lBusSetupApplyCommandStep + 1;
          print(
            "CMD $lBusSetupApplyCommandStep Validated -> send CMD$nextBusNo, keep polling",
          );
          lBusSetupApplyCommandStep = nextBusNo;
          startRxTimeout();
          await bleManager.sendLBusSetupApplyCmdPkt(lBusNo: nextBusNo);
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          checkForLBusSetupApplyRes = 0;
          isLBusSetupApplyCommandActive.value = false;
          isLBusSetupApplyDone.value = true;
          isAccessKeyValid.value = true;
          print("We got the response for l-bus setup apply");
        }
      } else {
        print("L-Bus Setup Apply Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForLBusSetupFetchRes == 1) {
      print(
        "Checking L-Bus Setup Fetch CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x10} ",
      );
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
          print(
            "CMD $lBusSetupFetchCommandStep Validated -> send CMD$nextBusNo, keep polling",
          );
          lBusSetupFetchCommandStep = nextBusNo;
          startRxTimeout();
          await bleManager.sendLBusSetupFetchCmdPkt(lBusNo: nextBusNo);
        } else {
          bleManager.otaProcessState = OtaProcessState.notInUse;
          checkForLBusSetupFetchRes = 0;
          isLBusSetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
          print("We got the response for l-bus setup fetch");
        }
      } else {
        print("L-Bus Setup Fetch Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForModuleSetupFetchRes == 1) {
      print(
        "Checking Module Setup Fetch CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x01} ",
      );
      if (rx.payload[12] == 0x01) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
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
        // Date: [39][40]=year, [41]=month, [42]=day (adjust byte order if needed)
        final year = (rx.payload[38] << 8) | rx.payload[39]; // big-endian
        // Or: final year = (rx.payload[40] << 8) | rx.payload[39];  // little-endian
        final month = rx.payload[40];
        final day = rx.payload[41];
        moduleDate.value =
            '${day.toString().padLeft(2, '0')}-${month.toString().padLeft(2, '0')}-${year.toString().padLeft(4, '0')}';
        moduleProtocol.value = rx.payload[43];
        isAccessKeyValid.value = true;
        isModuleSetupFetchCommandActive.value = false;
        print("We got the response for module setup fetch");
      } else {
        print("Module Setup Fetch Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRadioSetupFetchRes == 1) {
      print(
        "Checking Radio Setup Fetch CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x1D} ",
      );
      if (rx.payload[12] == 0x1D) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
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
        print(rx.payload[37]);
        isAccessKeyValid.value = true;
        isRadioSetupFetchCommandActive.value = false;
        print("We got the response for radio setup fetch");
      } else {
        print("Radio Setup Fetch Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRadioSetupApplyRes == 1) {
      print(
        "Checking Radio Setup Apply CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x1D} ",
      );
      if (rx.payload[10] == 0x83) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        checkForRadioSetupApplyRes = 0;
        // isRadioSetupApplyCommandActive.value = false;
        isAccessKeyValid.value = true;
        isRadioSetupCommandApplyActive.value = false;
        isRadioSetupApplyDone.value = true;
        print("We got the response for radio setup apply");
      } else {
        print("Radio Setup Apply Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    // __ext out response

    if (checkForExtCmdApplyRes == 1) {
      print(
        "Checking EXT Apply CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x16} ",
      );
      if (rx.payload[10] == 0x83) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        print("Found a control message");
        isAccessKeyValid.value = true;
        checkForExtCmdApplyRes = 0;
        isExtOutCommandApplyActive.value = false;
        isExtOutApplyDone.value = true;
        print("We got the response for ext apply");
      } else {
        print("EXT Apply Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForInputSetupFetchRes == 1) {
      print(
        "Checking Input Setup Fetch CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x06} ",
      );
      if (rx.payload[12] == 0x06) {
        bleManager.otaProcessState = OtaProcessState.notInUse;
        checkForInputSetupFetchRes = 0;
        isInputSetupFetchCommandActive.value = false;
        isAccessKeyValid.value = true;
        print(
          "We got the response for input setup fetch, ${rx.payload[23]}, ${rx.payload[24]}",
        );
        final InputModeConfig config = InputModeCodec.fromHex(
          rx.payload[15].toRadixString(16),
        );
        inputSetupGroup.value = rx.payload[23];
        inputSetupFunction.value = rx.payload[24];
        isInputSetupEnabled.value = config.inputEnable == InputEnable.enabled;
        isInputSetupTest.value = config.inputMode == InputMode.test;
        isInputSetupInverted.value = config.invertMode == InvertMode.inverted;
        inputSetupText.value = extractStringFromPayload(rx.payload);
      } else {
        print("Input Setup Fetch Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForInputSetupApplyRes == 1) {
      print(
        "Checking Input Setup Apply CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x16} ",
      );
      if (rx.payload[10] == 0x83) {
        isAccessKeyValid.value = true;
        bleManager.otaProcessState = OtaProcessState.notInUse;
        print("Found a control message");
        checkForInputSetupApplyRes = 0;
        isInputSetupApplyActive.value = false;
        isInputSetupApplyDone.value = true;
        print("We got the response for ext apply");
      } else {
        print("EXT Apply Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRelaySetupApplyRes == 1) {
      print(
        "Checking Relay Setup Apply CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x16} ",
      );
      if (rx.payload[10] == 0x83) {
        if (relaySetupApplyCommandStep == 1) {
          print("CMD 1 Validated -> send CMD2, keep polling");
          relaySetupApplyCommandStep = 2;
          startRxTimeout();
          await bleManager.sendRelaySetupApplySecondCmdPkt();
        } else if (relaySetupApplyCommandStep == 2) {
          print("CMD 2 Validated -> send CMD3, keep polling");
          relaySetupApplyCommandStep = 3;
          startRxTimeout();
          await bleManager.sendRelaySetupApplyThirdCmdPkt();
        } else if (relaySetupApplyCommandStep == 3) {
          print("CMD3 Validated -> done");
          isAccessKeyValid.value = true;
          bleManager.otaProcessState = OtaProcessState.notInUse;
          checkForRelaySetupApplyRes = 0;
          isRelaySetupCommandApplyActive.value = false;
          isRelaySetupApplyDone.value = true;
          print("We got the response for relay setup apply");
        }
      } else {
        print("Relay Setup Apply Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    //need to add this catch in show password dialog for access code

    if (checkForExtCmdFetchRes == 1) {
      print(
        "Checking EXT Fetch CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x16} ",
      );
      if (rx.payload[12] == 0x16) {
        bleManager.otaProcessState = OtaProcessState.sendDipSettingFetchCmd;
        checkForExtCmdFetchRes = 0;
        isExtOutCommandFetchActive.value = false;
        isAccessKeyValid.value = true;
        print("We got the response for ext fetch");
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
        print("EXT Fetch Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForRelaySetupFetchRes == 1) {
      print(
        "Checking Relay Setup Fetch CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x07} ",
      );
      if (rx.payload[12] == 0x07) {
        if (relaySetupFetchCommandStep == 1) {
          print("CMD 1 Validated -> send CMD2, keep polling");

          final OutputModeConfig config = OutputModeCodec.fromHex(
            rx.payload[15].toRadixString(16),
          );
          final bool outputEnabled =
              config.outputEnable == OutputEnable.enabled;
          final bool outputMode = config.outputMode == OutputMode.test;
          isRelayOneSetupEnabled.value = outputEnabled;
          isRelayOneSetupTest.value = outputMode;
          relayOneSetupOutputText.value = extractStringFromPayload(rx.payload);
          relayOneSetupDynamicText.value = rx.payload[22].toRadixString(16);
          relayOneSetupGroup.value = rx.payload[23];
          relayOneSetupFunction.value = rx.payload[24];

          relaySetupFetchCommandStep = 2;
          startRxTimeout();
          await bleManager.sendRelaySetupFetchSecondCmdPkt();
        } else if (relaySetupFetchCommandStep == 2) {
          print("CMD 2 Validated -> send CMD3, keep polling");

          final OutputModeConfig config = OutputModeCodec.fromHex(
            rx.payload[15].toRadixString(16),
          );
          final bool outputEnabled =
              config.outputEnable == OutputEnable.enabled;
          final bool outputMode = config.outputMode == OutputMode.test;
          isRelayTwoSetupEnabled.value = outputEnabled;
          isRelayTwoSetupTest.value = outputMode;
          relayTwoSetupOutputText.value = extractStringFromPayload(rx.payload);
          relayTwoSetupDynamicText.value = rx.payload[22].toRadixString(16);
          relayTwoSetupGroup.value = rx.payload[23];
          relayTwoSetupFunction.value = rx.payload[24];

          relaySetupFetchCommandStep = 3;
          startRxTimeout();
          await bleManager.sendRelaySetupFetchThirdCmdPkt();
        } else if (relaySetupFetchCommandStep == 3) {
          print("CMD3 Validated -> done");

          final OutputModeConfig config = OutputModeCodec.fromHex(
            rx.payload[15].toRadixString(16),
          );
          final bool outputEnabled =
              config.outputEnable == OutputEnable.enabled;
          final bool outputMode = config.outputMode == OutputMode.test;
          isRelayThreeSetupEnabled.value = outputEnabled;
          isRelayThreeSetupTest.value = outputMode;
          relayThreeSetupOutputText.value = extractStringFromPayload(
            rx.payload,
          );
          relayThreeSetupDynamicText.value = rx.payload[22].toRadixString(16);
          relayThreeSetupGroup.value = rx.payload[23];
          relayThreeSetupFunction.value = rx.payload[24];

          bleManager.otaProcessState = OtaProcessState.notInUse;
          checkForRelaySetupFetchRes = 0;
          isRelaySetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
          print("We got the response for relay setup fetch");
        }
      } else {
        print("Relay Setup Fetch Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForZoneSetupApplyRes == 1) {
      print(
        "Checking Zone Setup Apply CMD RSP Value ${rx.payload[10]}:::::${rx.payload[10] == 0x83} ",
      );
      if (rx.payload[10] == 0x83) {
        if (zoneSetupApplyCommandStep == 1) {
          print("CMD 1 Validated -> send CMD2, keep polling");
          zoneSetupApplyCommandStep = 2;
          startRxTimeout();
          await bleManager.sendZoneSetupApplySecondCmdPkt();
        } else if (zoneSetupApplyCommandStep == 2) {
          print("CMD 2 Validated -> send CMD3, keep polling");
          zoneSetupApplyCommandStep = 3;
          startRxTimeout();
          await bleManager.sendZoneSetupApplyThirdCmdPkt();
        } else if (zoneSetupApplyCommandStep == 3) {
          print("CMD3 Validated -> done");
          bleManager.otaProcessState = OtaProcessState.notInUse;
          checkForZoneSetupApplyRes = 0;
          isZoneSetupCommandApplyActive.value = false;
          isZoneSetupApplyDone.value = true;
          isAccessKeyValid.value = true;
          print("We got the response for zone setup apply");
        }
      } else {
        print("Zone Setup Apply Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    if (checkForZoneSetupFetchRes == 1) {
      print(
        "Checking Zone Setup Fetch CMD RSP Value ${rx.payload[12]}:::::${rx.payload[12] == 0x04} ",
      );
      if (rx.payload[12] == 0x04) {
        print("We got the response for zone setup fetch");
        if (zoneSetupFetchCommandStep == 1) {
          print("CMD 1 Validated -> send CMD2, keep polling");
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
          // zoneOneSetupDetectionMode.value = config.flowDetectionUsed ? 1 : 0;
          startRxTimeout();
          await bleManager.sendZoneSetupFetchSecondCmdPkt();
        } else if (zoneSetupFetchCommandStep == 2) {
          print("CMD 2 Validated -> send CMD3, keep polling");
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
          print("CMD3 Validated -> done");
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
          checkForZoneSetupFetchRes = 0;
          isZoneSetupFetchCommandActive.value = false;
          isAccessKeyValid.value = true;
          print("We got the response for zone setup fetch");
        }
      } else {
        print("Zone Setup Fetch Cmd Response not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    // ----- CONTROL CMD RESPONSE -----
    if (checkForCtrlCmdRsp == 1) {
      print(
        "Checking CONTROL CMD RSP Value ${rx.payload[10]}:::::${rx.payload[10] == 0x83} ",
      );
      if (rx.payload[3] == 0x03 && nackRetryCount < 3) {
        Get.find<BleLogController>().restartNetworkFlow();
      } else if (rx.payload[10] == 0x83) {
        isAccessKeyValid.value = true;
        // nackRetryCount = 0;
        print("CONTROL CMD RESPONSE RECEIVED");
        checkForCtrlCmdRsp = 2;
        logStartingTime = DateTime.now();
        // Continue with normal polling now that we got the response
        startRxTimeout();
        await bleManager.sendPollPacket();
      } else if (nackRetryCount == 3) {
        isOtaCompleted = true;
        processNextOtaFrame = false;

        bleManager.otaProcessState = OtaProcessState.notInUse;
        cancelRxTimeout();
      } else {
        // nackRetryCount = 0;
        // Response not found, send poll again
        print("CONTROL CMD RSP not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    } else if (checkForCtrlCmdRsp == 2) {
      receivedPollCount++;
      print(
        "Total Received logs after control cmd response found: $receivedPollCount",
      );
      int rxLastEvtLogNum =
          rx.payload[19] |
          (rx.payload[18] << 8) |
          (rx.payload[17] << 16) |
          (rx.payload[16] << 24);

      processDesc.value = " ";

      if (rxLastEvtLogNum != 0) {
        validEventLogNum++;
        // Update the ValueNotifier to notify UI listeners
        validEventLogCount.value = validEventLogNum;

        // Parse and store the valid log entry
        try {
          LogModel? parsedLog = _parseEventLogFromPayload(
            rx.payload,
            rxLastEvtLogNum,
          );
          if (parsedLog != null) {
            isValidLogRecieved.value = true;
            final currentLogs = List<LogModel>.from(validEventLogs.value);
            currentLogs.add(parsedLog);
            validEventLogs.value = currentLogs;
          }
        } catch (e) {
          print("Error parsing event log: $e");
        }
      }

      if (rx.payload[12] == 0x02) {
        read1000Logs++;
        read1000LogsCount.value = read1000Logs;
      }

      print(
        "EventLog: 0x${rxLastEvtLogNum.toRadixString(16)} "
        "Valid: $validEventLogNum  "
        "Read1000: $read1000Logs"
        "time: ${DateTime.now().toIso8601String()}",
      );

      if (read1000Logs != 1000) {
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    // ----- READY FOR NEXT FRAME -----
    processNextOtaFrame = true;

    if (read1000Logs >= 1000 && !isOtaCompleted) {
      print("<<<<<< COMPLETED 1000 EVENT LOGS >>>>>>>");

      isOtaCompleted = true;
      processNextOtaFrame = false;

      bleManager.otaProcessState = OtaProcessState.notInUse;
      cancelRxTimeout();

      processDesc.value = "";

      logEndTime = DateTime.now();
      print(
        "Time Taken for 1000 logs ${formatDuration(logEndTime!.difference(logStartingTime!))}",
      );

      await bleManager.sendStopCntrlCmdPkt();
      return;
    }

    print(
      "__________--------------------_________________------------------_________________-----------------_________________--------------_____________----------",
    );
  }

  String extractStringFromPayload(List<int> payload, {int startIndex = 25}) {
    // Length is at index startIndex
    final int length = payload[startIndex];

    print("Length: $length");

    // String starts at index 26
    // final int startIndex = startIndex + 1;
    final int endIndex = startIndex + length + 1;

    final List<int> stringBytes = payload.sublist(startIndex + 1, endIndex);

    return utf8.decode(stringBytes);
  }

  void resetProcessState() {
    // Terminal guards
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
    // Counters
    checkForCtrlCmdRsp = 0;
    checkForAccessKeyCmdRsp = 0;
    validEventLogNum = 0;
    read1000Logs = 0;
    receivedPollCount = 0;

    // Time tracking
    logStartingTime = null;
    logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    validEventLogCount.value = 0;
    read1000LogsCount.value = 0;
    validEventLogs.value = [];
    isValidLogRecieved.value = false;
    panelName.value = "";
  }

  void resetProcessExtOutState() {
    // Terminal guards
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    // Counters
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
    isExtOutApplyButtonActive.value = false;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    // Time tracking
    // logStartingTime = null;
    // logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    // validEventLogCount.value = 0;
    // read1000LogsCount.value = 0;
    // validEventLogs.value = [];
    // isValidLogRecieved.value = false;
    // panelName.value = "";
  }

  void resetProcessInputSetupState() {
    // Terminal guards
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    // Counters
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
    isExtOutApplyButtonActive.value = false;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    // Time tracking
    // logStartingTime = null;
    // logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    // validEventLogCount.value = 0;
    // read1000LogsCount.value = 0;
    // validEventLogs.value = [];
    // isValidLogRecieved.value = false;
    // panelName.value = "";
  }

  void resetProcessRelaySetupState() {
    // Terminal guards
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    // Counters
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
    isExtOutApplyButtonActive.value = false;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    // Time tracking
    // logStartingTime = null;
    // logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    // validEventLogCount.value = 0;
    // read1000LogsCount.value = 0;
    // validEventLogs.value = [];
    // isValidLogRecieved.value = false;
    // panelName.value = "";
  }

  void resetProcessZoneSetupState() {
    // Terminal guards
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    // Counters
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
    isExtOutApplyButtonActive.value = false;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    // Time tracking
    // logStartingTime = null;
    // logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    // validEventLogCount.value = 0;
    // read1000LogsCount.value = 0;
    // validEventLogs.value = [];
    // isValidLogRecieved.value = false;
    // panelName.value = "";
  }

  void resetProcessRadioSetupState() {
    // Terminal guards
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    // Counters
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
    isExtOutApplyButtonActive.value = false;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForModuleSetupFetchRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    // Time tracking
    // logStartingTime = null;
    // logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    // validEventLogCount.value = 0;
    // read1000LogsCount.value = 0;
    // validEventLogs.value = [];
    // isValidLogRecieved.value = false;
    // panelName.value = "";
  }

  void resetProcessModuleSetupState() {
    // Terminal guards
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    // Counters
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
    isExtOutApplyButtonActive.value = false;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    checkForLBusSetupApplyRes = 0;
    // Time tracking
    // logStartingTime = null;
    // logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    // validEventLogCount.value = 0;
    // read1000LogsCount.value = 0;
    // validEventLogs.value = [];
    // isValidLogRecieved.value = false;
    // panelName.value = "";
  }

  void resetProcessLBusSetupState() {
    // Terminal guards
    isOtaCompleted = false;
    processNextOtaFrame = true;
    logRetreivalEnded = false;

    // Counters
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
    isExtOutApplyButtonActive.value = false;
    relaySetupFetchCommandStep = 0;
    checkForRelaySetupFetchRes = 0;
    checkForRadioSetupApplyRes = 0;
    checkForLBusSetupFetchRes = 0;
    lBusSetupFetchCommandStep = 0;
    checkForLBusSetupApplyRes = 0;
    // Time tracking
    // logStartingTime = null;
    // logEndTime = null;

    // OTA state
    bleManager.otaProcessState = OtaProcessState.sendNetworkPacket;

    // RX timeout
    _rxTimeoutTimer?.cancel();
    _rxTimeoutTimer = null;

    _otherPacketsRxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer = null;

    // UI notifiers
    // validEventLogCount.value = 0;
    // read1000LogsCount.value = 0;
    // validEventLogs.value = [];
    // isValidLogRecieved.value = false;
    // panelName.value = "";
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// MAIN BLE STATE MACHINE
  Future<void> bleProcess() async {
    // await Future.delayed(const Duration(milliseconds: 200));
    // print("bleStateMachineState: ${bleManager.bleCurrentState}");
    switch (bleManager.bleStateMachineState) {
      case BleStates.PROCESS_PANEL_EVT_LOG_READ:
        bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
        await handleTsEvtLogRead();
        break;

      case BleStates.PROCESS_WAIT_RSP:
        print("Waiting state");
        // await Future.delayed(const Duration(seconds: 1));
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
    print("Send encry req frame");
    processDesc.value = "Send Encryption Key Request";
    await bleManager.sendAesKeyReq();
    bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
    bleCurrentState = BleStates.REQ_ENCY_KEY;
  }

  sendAuthPacket() async {
    processDesc.value = "Sending Auth Packet";
    await bleManager.sendAuthnMsg();
    bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
    bleCurrentState = BleStates.SEND_AUTHN_MSG;
  }

  sendExtOutApplyPacket() async {
    processDesc.value = "Sending Ext Out Packet";
    await bleManager.sendExtOutSetupApplyCmdPkt();
    bleManager.bleStateMachineState =
        BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
    bleCurrentState = BleStates.SEND_EXT_OUT_SETUP_CMD_FETCH_PACKET;
  }

  // Public method to cancel timer
  void cancelRxTimeout() {
    _rxTimeoutTimer?.cancel();
    _otherPacketsRxTimeoutTimer?.cancel();
    print("RX timeout cancelled from BleManager");
  }

  /// Parse event log data from payload
  LogModel? _parseEventLogFromPayload(List<int> payload, int eventLogNum) {
    try {
      // Check if payload has enough data (should be 216 bytes for full packet)
      if (payload.length < 130) {
        print("Payload too short for event log parsing");
        return null;
      }

      // Extract timestamp (bytes 12-16) - little endian
      List<int> timestamp = payload.sublist(25, 29);
      int timestampDecimal =
          timestamp[3] |
          (timestamp[2] << 8) |
          (timestamp[1] << 16) |
          (timestamp[0] << 24);

      // Use current time if timestamp is invalid
      DateTime eventTime =
          timestampDecimal != 0x00
              ? TimestampConverter.clockTimeFromTimeStamp(timestampDecimal)
              : DateTime.now();

      // Extract Event ID (bytes 126-129) - big endian

      //not using in the protocol document of 110
      // int eventId = 0;
      // if (payload.length >= 130) {
      //   eventId =
      //       (payload[126] << 24) |
      //       (payload[127] << 16) |
      //       (payload[128] << 8) |
      //       (payload[129] << 0);
      // }

      // Extract event text (bytes 42-124)
      String evtTextAscii = "System-Text---------1";
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

      // Extract panel source
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
                  ? "Arcnet No. 0"
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
                  ? "Arcnet No. 0"
                  : "";
        } else {
          panelSource = "Panel No. 1";
        }
      }

      // Create LogModel
      return LogModel(
        panelText: panelSource,
        eventId: eventLogNum.toString(),
        eventDateTime: eventTime,
        panelNo: payload.length > 0 ? payload[13].toString() : null,
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
                )
                : null,
        text: evtTextAscii,
        isValid: timestampDecimal != 0x00,
        retrievedAt: DateTime.now(),
      );
    } catch (e) {
      print("Error parsing event log from payload: $e");
      return null;
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _rxTimeoutTimer?.cancel();
    validEventLogCount.dispose();
    validEventLogs.dispose();
    read1000LogsCount.dispose();
    isValidLogRecieved.dispose();
  }

  // Call this after every TX
  void startRxTimeout() {
    maxOtherPacketsRetriesReached.value = false;
    if (isOtaCompleted) return;

    _rxTimeoutTimer?.cancel();

    _rxTimeoutTimer = Timer(const Duration(seconds: 2), () async {
      if (isOtaCompleted) return;

      rxTimeoutRetryCount++;

      print("RX timeout [$rxTimeoutRetryCount / $maxRxRetries] — no response");

      processDesc.value =
          "No response from device (${rxTimeoutRetryCount}/$maxRxRetries)";

      //Exceeded retry limit → HARD FAIL
      if (rxTimeoutRetryCount >= maxRxRetries) {
        print("RX retry limit reached. Restarting network flow.");

        processDesc.value = "Device not responding. Restarting network flow.";

        // Stop everything
        bleManager.bleProcess.resetProcessState();

        bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
        bleManager.bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
        bleManager.bleStateMachineState = BleStates.PROCESS_PANEL_EVT_LOG_READ;

        // Full BLE shutdown
        // await bleManager.shutdown(deviceId: connectedDeviceId.value);
        restartInitialNetworkFlow();

        // Optional: tell controller/UI explicitly
        // Get.find<BleLogController>().onBleFatalError(
        //   "Device not responding. Please scan again.",
        // );

        return;
      }

      // 🔁 Retry allowed
      bleManager.resetPollInFlight();
      processNextOtaFrame = true;

      await handleTsEvtLogRead();
    });
  }

  void restartInitialNetworkFlow() {
    startOtherPacketsRxTimeout(timeout: const Duration(seconds: 12));
    Get.find<BleLogController>().restartNetworkFlow();
  }

  void startOtherPacketsRxTimeout({Duration? timeout}) {
    cancelRxTimeout();

    print("Other Packets: Starting other packets RX timeout");

    _otherPacketsRxTimeoutTimer = Timer(
      timeout ?? const Duration(seconds: 12),
      () async {
        maxOtherPacketsRetriesReached.value = true;
        print(
          "Other Packets: No response from device, please scan and connect again",
        );
        processDesc.value =
            "No response from device, please scan and connect again";
        restartInitialNetworkFlow();
        // bleManager.shutdown();
      },
    );
  }

  /// HANDLE OTA EVENT LOG
  Future<void> handleTsEvtLogRead() async {
    if (isOtaCompleted ||
        bleManager.otaProcessState == OtaProcessState.notInUse) {
      return;
    }

    if (processNextOtaFrame) {
      startRxTimeout();
      processNextOtaFrame = false;
      // print(
      //   "TS EVT LOG READ STATE: ${bleManager.otaProcessState}, processNextOtaFrame: $processNextOtaFrame",
      // );

      switch (bleManager.otaProcessState) {
        case OtaProcessState.sendNetworkPacket:
          processDesc.value = "Sending Network Packet";
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
          // await Future.delayed(const Duration(milliseconds: 100));
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
      }
      startRxTimeout();
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// RUN STATE MACHINE LOOP
  Future<void> runStateMachine() async {
    if (_isStateMachineRunning) return;

    _isStateMachineRunning = true;

    while (!isOtaCompleted && !_restartRequested) {
      try {
        await bleProcess();
        await Future.delayed(const Duration(milliseconds: 5));
      } catch (e) {
        print("Exception in state machine: $e");
        // await bleManager.shutdown(connectedDeviceId.value);
        break;
      }
    }

    _isStateMachineRunning = false;
    _restartRequested = false;

    print("BLE State Machine exited cleanly");
  }
}
