import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ble_manager.dart';
import 'ble_frame.dart';

class BleProcess {
  final BleManager bleManager;
  Timer? _rxTimeoutTimer;

  int checkForCtrlCmdRsp = 0;
  int checkForAccessKeyCmdRsp = 0;
  int validEventLogNum = 0;
  int read1000Logs = 0;

  // ValueNotifier to expose valid event log count to UI
  final ValueNotifier<int> validEventLogCount = ValueNotifier<int>(0);

  // BleStates bleStateMachineState = BleStates.IDLE;
  BleStates bleCurrentState = BleStates.IDLE;
  DeviceConnectState deviceConnectState = DeviceConnectState.notConnected;

  bool processNextOtaFrame = true;
  int txData = 1;

  int pollWaitRspTimeoutCnt = 0;

  BleProcess(this.bleManager);

  Future<void> bleRxFrameProcess(BleRxFrame rx) async {
    pollWaitRspTimeoutCnt = 0;

    bleManager.u8RxPktCnt = rx.payload[4];

    print("Rx pkt count: $bleManager.u8RxPktCnt");

    // ----- OTA STATE MACHINE -----
    switch (bleManager.otaProcessState) {
      case OtaProcessState.sendNetworkPacket:
        print("NEXT: POLL PACKET");
        // await Future.delayed(Duration(seconds: 1));
        bleManager.otaProcessState = OtaProcessState.sendPollPacket;
        // await Future.delayed(Duration(seconds: 1));
        break;

      case OtaProcessState.sendPollPacket:
        print("NEXT: ACCESS PACKET");
        // await Future.delayed(Duration(seconds: 1));
        bleManager.otaProcessState = OtaProcessState.sendAccessKeyPacket;
        // await Future.delayed(Duration(seconds: 1));
        break;

      case OtaProcessState.sendAccessKeyPacket:
        print("NEXT: CONTINUOUS POLL PACKET");
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        checkForAccessKeyCmdRsp = 1;
        // await Future.delayed(Duration(milliseconds: 100));
        break;

      case OtaProcessState.sendContinuousPollPacket:
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        break;

      case OtaProcessState.sendControlCmdPacket:
        print("Control cmd received → Next continuous poll");
        bleManager.otaProcessState = OtaProcessState.sendContinuousPollPacket;
        checkForCtrlCmdRsp = 1;
        // await Future.delayed(Duration(milliseconds: 100));
        break;

      default:
        break;
    }

    // ----- ACCESS KEY RESPONSE -----
    if (checkForAccessKeyCmdRsp == 1) {
      print("Checking ACCESS KEY CMD RSP...");

      if (String.fromCharCodes(rx.payload.sublist(14, 18)) == "1974") {
        print("ACCESS KEY RECEIVED → NEXT CONTROL CMD");
        bleManager.otaProcessState = OtaProcessState.sendControlCmdPacket;
        checkForAccessKeyCmdRsp = 0;
        // await Future.delayed(Duration(milliseconds: 100));
      }
    }

    // ----- CONTROL CMD RESPONSE -----
    if (checkForCtrlCmdRsp == 1) {
      if (rx.payload[10] == 0x83) {
        print("CONTROL CMD RESPONSE RECEIVED");
        checkForCtrlCmdRsp = 2;
      }
    } else if (checkForCtrlCmdRsp == 2) {
      int rxLastEvtLogNum =
          rx.payload[19] |
          (rx.payload[18] << 8) |
          (rx.payload[17] << 16) |
          (rx.payload[16] << 24);

      if (rxLastEvtLogNum != 0) {
        validEventLogNum++;
        // Update the ValueNotifier to notify UI listeners
        validEventLogCount.value = validEventLogNum;
      }

      if (rx.payload[12] == 0x02) read1000Logs++;

      print(
        "EventLog: 0x${rxLastEvtLogNum.toRadixString(16)} "
        "Valid: $validEventLogNum  "
        "Read1000: $read1000Logs",
      );
    }

    // ----- READY FOR NEXT FRAME -----
    processNextOtaFrame = true;

    if (read1000Logs == 1030) {
      print("<<<<<< COMPLETED 1000 EVENT LOGS >>>>>>>");
      processNextOtaFrame = false;
    }
  }

  /// MAIN BLE STATE MACHINE
  Future<void> bleProcess() async {
    await Future.delayed(const Duration(milliseconds: 200));
    print("bleStateMachineState: ${bleManager.bleCurrentState}");
    switch (bleManager.bleStateMachineState) {
      case BleStates.REQ_ENCY_KEY:
        print("Send encry req frame");
        await bleManager.sendAesKeyReq();
        bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
        bleCurrentState = BleStates.REQ_ENCY_KEY;
        break;

      case BleStates.SEND_AUTHN_MSG:
        print("Send authn msg frame");
        await bleManager.sendAuthnMsg();
        bleManager.bleStateMachineState = BleStates.PROCESS_WAIT_RSP;
        bleCurrentState = BleStates.SEND_AUTHN_MSG;
        break;

      case BleStates.PROCESS_PANEL_EVT_LOG_READ:
        bleCurrentState = BleStates.PROCESS_PANEL_EVT_LOG_READ;
        await handleTsEvtLogRead();
        break;

      case BleStates.PROCESS_WAIT_RSP:
        print("Waiting state");
        await Future.delayed(const Duration(seconds: 1));
        break;

      case BleStates.IDLE:
        break;
    }

    if (!bleManager.isConnected) {
      await bleManager.disconnectHandler();
    }
  }

  // Public method to cancel timer
  void cancelRxTimeout() {
    _rxTimeoutTimer?.cancel();
    print("RX timeout cancelled from BleManager");
  }

  // Dispose method to clean up resources
  void dispose() {
    _rxTimeoutTimer?.cancel();
    validEventLogCount.dispose();
  }

  // Call this after every TX
  void startRxTimeout() {
    // Cancel any existing timer
    _rxTimeoutTimer?.cancel();

    // Start a new 10-second timer
    _rxTimeoutTimer = Timer(const Duration(seconds: 5), () {
      print("RX timeout: no response received. Sending next packet anyway.");
      processNextOtaFrame = true;
      handleTsEvtLogRead(); // trigger next TX
    });
  }

  /// HANDLE OTA EVENT LOG
  Future<void> handleTsEvtLogRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (processNextOtaFrame) {
      startRxTimeout();
      processNextOtaFrame = false;
      print(
        "TS EVT LOG READ STATE: ${bleManager.otaProcessState}, processNextOtaFrame: $processNextOtaFrame",
      );

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
          await bleManager.sendCntrlCmdPkt();
          break;
        case OtaProcessState.sendContinuousPollPacket:
          await bleManager.sendPollPacket();
          break;
        case OtaProcessState.otaWaitRsp:
          await Future.delayed(const Duration(milliseconds: 100));
          break;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// RUN STATE MACHINE LOOP
  Future<void> runStateMachine() async {
    while (true) {
      await Future.delayed(Duration(milliseconds: 200));
      try {
        switch (deviceConnectState) {
          case DeviceConnectState.notConnected:
            print("Start connect");
            await bleManager.scanAndConnect();
            deviceConnectState = DeviceConnectState.registerNotifyHandler;
            break;
          case DeviceConnectState.registerNotifyHandler:
            print("Start register handler");
            await bleManager.registerNotifyHandler();
            break;
          case DeviceConnectState.running:
            print("<<<<<<<<<<<<<<  BLE PROCESS RUNNING >>>>>>>>>>>>>>>>>>>>");
            await bleProcess();
            break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print("Exception in state machine: $e");
        await bleManager.shutdown();
        break;
      }
    }
  }
}
