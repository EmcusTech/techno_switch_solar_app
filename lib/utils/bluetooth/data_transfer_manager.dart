library;

import 'dart:async';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;
import 'bt_utils.dart';
import 'data_packet_generator.dart';

class DataTransferManager {
  static final DataTransferManager _instance = DataTransferManager._internal();

  factory DataTransferManager() {
    return _instance;
  }

  DataTransferManager._internal();

  int retryCount = 0;

  int maxRetries = 40;

  BluetoothWriteError bleWriteError = BluetoothWriteError.none;

  List<int> currentLargeDataPacket = <int>[];

  void sendingPasskeyToBle(
    String password, {
    Function(bool)? dataWritten,
    int pktTxCnt = 0,
    int pktRxCnt = 0,
  }) async {
    List<int> passKeyValuePacket = await passKeyFrame(
      password,
      pktTxCnt: pktTxCnt,
      pktRxCnt: pktRxCnt,
    );
    logger.Logger(
      'passkey frame <<===========PasskeyValuePacket: $passKeyValuePacket===========>>',
    );
    sendDataToBle(passKeyValuePacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.sendingPasskeyPacket,
      passKeyValuePacket,
    );
  }

  void sendAuthPacket({Function(bool)? dataWritten}) async {
    List<int> data = await authMsgFrame();
    logger.Logger("Authentication message -  data: $data");
    logger.Logger("%%%%%%%%%%%%% AUTH MESSAGE SENT %%%%%%%%%%%%");
    sendDataToBle(data, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.sendingAuthMessage, data);
  }

  void sendDataToBle(List<int> data, {Function(bool)? dataWritten}) async {
    DiscoveredDevice? connectedDevice = await BtUtils().getConnectedDevice();
    if (connectedDevice != null) {
      BtUtils().writeData(connectedDevice, data, dataWritten: dataWritten);
    } else {}
  }

  FrameData parseRxFrame(List<int> rxData) {
    List<String> hexValues =
        rxData
            .map(
              (int byte) =>
                  byte.toRadixString(16).toUpperCase().padLeft(2, '0'),
            )
            .toList();
    logger.Logger("From list ::::>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    logger.Logger(hexValues.sublist(7, hexValues.length - 4).toString());
    return FrameData(
      preambleByte: hexValues.sublist(0, 2),
      commandByte: hexValues.sublist(2, 4),
      frameTypeByte: hexValues[4],
      payloadLength: hexValues.sublist(5, 7),
      payloadData: hexValues.sublist(7, hexValues.length - 4),
      calculatedCrc: hexValues.sublist(
        hexValues.length - 4,
        hexValues.length - 2,
      ),
      endFrame: hexValues.sublist(hexValues.length - 2),
    );
  }

  Timer? _waitingTimer;

  void startResponseTimer(
    BleStateMachine currentBleState,
    List<int>? dataSent,
  ) {
    if (_waitingTimer != null) {
      _waitingTimer!.cancel();
      _waitingTimer = null;
    }
    _waitingTimer = Timer.periodic(const Duration(seconds: 5), (Timer time) {
      try {
        final BleStateMachine currentState =
            Get.find<BleNotifyDataHandler>().currentBleState.value;
        logger.Logger(
          "Timer Tick: Current BLE State = $currentState, Expected State = $currentBleState",
        );
        if (currentState == currentBleState) {
          retryBleCommands(currentBleState, dataSent);
        } else {
          stopResponseTimer();
        }
      } catch (e, stackTrace) {
        logger.Logger("Error in timer callback: $e\n$stackTrace");
        stopResponseTimer();
      }
    });
  }

  void stopResponseTimer() {
    logger.Logger("<<---------<<Timer stopped>>---------->>");
    if (_waitingTimer != null) {
      retryCount = 0;
      _waitingTimer!.cancel();
      _waitingTimer = null;
    }
  }

  void retryBleCommands(BleStateMachine currentBleState, List<int>? dataSent) {
    retryCount = retryCount + 1;
    logger.Logger(
      "<====================$retryCount======================ON Retry CMD==========================$retryCount=================>",
    );

    if (retryCount < maxRetries) {
      sendDataToBle(
        dataSent!,
        dataWritten: (bool isWritten) {
          Get.find<BleNotifyDataHandler>().currentBleState(currentBleState);
          Get.find<BleNotifyDataHandler>().update();
        },
      );
    } else {
      logger.Logger("Disconnected due to no response from the panel");
      stopResponseTimer();
      BtUtils().disconnect();
    }
  }

  bool stopSendingData = false;
  bool loopGoingON = false;
}
