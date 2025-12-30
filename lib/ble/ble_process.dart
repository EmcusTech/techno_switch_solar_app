import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'ble_manager.dart';
import 'ble_frame.dart';
import '../models/log_model.dart';
import '../utils/event_constants.dart';
import '../utils/timestamp_converter.dart';

class BleProcess {
  final BleManager bleManager;
  Timer? _rxTimeoutTimer;

  int checkForCtrlCmdRsp = 0;
  int checkForAccessKeyCmdRsp = 0;
  int validEventLogNum = 0;
  int read1000Logs = 0;
  bool logRetreivalEnded = false;

  DateTime? logStartingTime;
  DateTime? logEndTime;

  // ValueNotifier to expose valid event log count to UI
  final ValueNotifier<int> validEventLogCount = ValueNotifier<int>(0);

  // ValueNotifier to expose read1000Logs count to UI for progress tracking
  final ValueNotifier<int> read1000LogsCount = ValueNotifier<int>(0);

  // ValueNotifier to expose list of valid event logs to UI
  final ValueNotifier<List<LogModel>> validEventLogs =
      ValueNotifier<List<LogModel>>([]);

  final ValueNotifier<bool> isValidLogRecieved = ValueNotifier<bool>(false);

  // BleStates bleStateMachineState = BleStates.IDLE;
  BleStates bleCurrentState = BleStates.IDLE;
  DeviceConnectState deviceConnectState = DeviceConnectState.notConnected;

  bool processNextOtaFrame = true;
  int txData = 1;

  int pollWaitRspTimeoutCnt = 0;

  int receivedPollCount = 0;

  BleProcess(this.bleManager);

  Future<void> bleRxFrameProcess(BleRxFrame rx) async {
    pollWaitRspTimeoutCnt = 0;

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

      default:
        break;
    }

    // ----- ACCESS KEY RESPONSE -----
    if (checkForAccessKeyCmdRsp == 1) {
      print("Checking ACCESS KEY CMD RSP...");

      if (String.fromCharCodes(rx.payload.sublist(14, 18)) == "1974") {
        print("ACCESS KEY RECEIVED → NEXT CONTROL CMD");
        bleManager.otaProcessState = OtaProcessState.sendStopCntrlCmdPkt;
        checkForAccessKeyCmdRsp = 0;
        startRxTimeout();
        await bleManager.sendStopCntrlCmdPkt();
      } else {
        print("ACCESS KEY not found, polling again");
        startRxTimeout();
        await bleManager.sendPollPacket();
      }
    }

    // ----- CONTROL CMD RESPONSE -----
    if (checkForCtrlCmdRsp == 1) {
      print(
        "Checking CONTROL CMD RSP Value ${rx.payload[10]}:::::${rx.payload[10] == 0x83} ",
      );
      if (rx.payload[3] == 0x03) {
        Get.find<BleLogController>().restartNetworkFlow();
      } else if (rx.payload[10] == 0x83) {
        print("CONTROL CMD RESPONSE RECEIVED");
        checkForCtrlCmdRsp = 2;
        logStartingTime = DateTime.now();
        // Continue with normal polling now that we got the response
        startRxTimeout();
        await bleManager.sendPollPacket();
      } else {
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

    if (read1000Logs == 1000) {
      print("<<<<<< COMPLETED 1000 EVENT LOGS >>>>>>>");
      logEndTime = DateTime.now();
      print(
        "Time Taken for 1000 logs ${formatDuration(logEndTime!.difference(logStartingTime!))}",
      );
      processNextOtaFrame = false;
      // startRxTimeout();
      await bleManager.sendStopCntrlCmdPkt();
    }
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
      await bleManager.disconnectHandler();
    }
  }

  requestENCKey() async {
    print("Send encry req frame");
    await bleManager.sendAesKeyReq();
    bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
    bleCurrentState = BleStates.REQ_ENCY_KEY;
  }

  sendAuthPacket() async {
    await bleManager.sendAuthnMsg();
    bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
    bleCurrentState = BleStates.SEND_AUTHN_MSG;
  }

  // Public method to cancel timer
  void cancelRxTimeout() {
    _rxTimeoutTimer?.cancel();
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
                  ? "RADIO"
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
                  ? "RADIO"
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
                ? EventConstants.getEventDescription(payload[22], payload[24])
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
    // Cancel any existing timer
    _rxTimeoutTimer?.cancel();

    // Start a new 10-second timer
    _rxTimeoutTimer = Timer(const Duration(seconds: 5), () async {
      print("RX timeout: no response received. Sending next packet anyway.");
      // Allow next poll in case in-flight guard is set
      bleManager.resetPollInFlight();
      processNextOtaFrame = true;
      await handleTsEvtLogRead(); // trigger next TX
    });
  }

  /// HANDLE OTA EVENT LOG
  Future<void> handleTsEvtLogRead() async {
    if (processNextOtaFrame) {
      startRxTimeout();
      processNextOtaFrame = false;
      // print(
      //   "TS EVT LOG READ STATE: ${bleManager.otaProcessState}, processNextOtaFrame: $processNextOtaFrame",
      // );

      switch (bleManager.otaProcessState) {
        case OtaProcessState.sendNetworkPacket:
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
      }
      startRxTimeout();
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// RUN STATE MACHINE LOOP
  Future<void> runStateMachine() async {
    while (true) {
      try {
        await bleProcess();
      } catch (e) {
        print("Exception in state machine: $e");
        await bleManager.shutdown();
        break;
      }
    }
  }
}
