/*
* Project      : gemini_mobile_app
* File         : data_transfer_manager.dart
* Description  : Manages the data transfer operations, particularly over Bluetooth Low Energy (BLE)
* Author       : SrihariharanT
* Date         : 2024-05-21
* Version      : 1.0
* Ticket       :
*/

/// {@category bluetooth}
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'bt_utils.dart';
import 'data_packet_generator.dart';

/// A manager class responsible for handling data transfer operations.
class DataTransferManager {
  static final DataTransferManager _instance = DataTransferManager._internal();

  factory DataTransferManager() {
    return _instance;
  }

  DataTransferManager._internal();

  /// Number of retries after CRC mismatch.
  int retryCount = 0;

  /// Maximum number of retries allowed after CRC mismatch.
  int maxRetries = 3;

  // final controller = Get.find<UpdatesController>();

  /// [bleWriteError] this variable is used to store the type of error we are getting from BLE
  /// and show respected error messages
  BluetoothWriteError bleWriteError = BluetoothWriteError.none;

  /// Current Large Data That is going to send over Ble
  List<int> currentLargeDataPacket = <int>[];
  // CurrentLargeDataAndState? currentLargeDataAndState;

  /// Sending the data packets to the BLE device to read the firmware version.
  void requestingPassKeyToBle({dynamic Function(bool)? dataWritten}) async {
    Logger("<<===========Requesting pass Key===========>>");
    List<int> passKeyPacket = await passKeyRequestFrame();
    sendDataToBle(passKeyPacket, dataWritten: dataWritten);
  }

  void sendingPasskeyToBle(
    String password, {
    Function(bool)? dataWritten,
  }) async {
    List<int> passKeyValuePacket = await passKeyFrame(password);
    Logger(
      'passkey frame <<===========PasskeyValuePacket: $passKeyValuePacket===========>>',
    );
    sendDataToBle(passKeyValuePacket, dataWritten: dataWritten);
  }

  void sendingNetworkPacketToBle({
    Function(bool)? dataWritten,
    int pktTxCnt = 0,
    int pktRxCnt = 0,
  }) async {
    List<int> networkPacket = await networkPacketFrame(
      pktTxCnt: pktTxCnt,
      pktRxCnt: pktRxCnt,
    );
    Logger(
      'network packet frame <<===========NetworkPacket: $networkPacket===========>>',
    );
    sendDataToBle(networkPacket, dataWritten: dataWritten);
  }

  void sendingPollingPacket1ToBle({Function(bool)? dataWritten}) async {
    List<int> pollingPacket1 = await pollingPacket1Frame();
    Logger(
      'polling packet 1 frame <<===========PollingPacket1: $pollingPacket1===========>>',
    );
    sendDataToBle(pollingPacket1, dataWritten: dataWritten);
  }

  void sendingPollingPacket2ToBle({Function(bool)? dataWritten}) async {
    List<int> pollingPacket2 = await pollingPacket2Frame();
    Logger(
      'polling packet 2 frame <<===========PollingPacket2: $pollingPacket2===========>>',
    );
    sendDataToBle(pollingPacket2, dataWritten: dataWritten);
  }

  void sendingDummyPacketToBle({
    Function(bool)? dataWritten,
    int pktTxCnt = 0,
    int pktRxCnt = 0,
    int logEvtSearchNumber = 999,
  }) async {
    List<int> dummyPacket = await dummyPacketFrame(
      pktTxCnt: pktTxCnt,
      pktRxCnt: pktRxCnt,
      logEvtSearchNumber: logEvtSearchNumber,
    );
    Logger(
      'dummy packet frame <<===========DummyPacket: $dummyPacket===========>>',
    );
    sendDataToBle(dummyPacket, dataWritten: dataWritten);
  }

  /// Sends CONTROL_RES_EVENT_REPORT command to BLE device.
  ///
  /// This command controls event reporting for different event printers.
  /// The panel will respond with a CONTROL_MESSAGE message.
  ///
  /// Parameters:
  ///   - dataWritten: Callback function called when data is written (optional)
  ///   - pktTxCnt: Packet transmit counter (default: 0)
  ///   - pktRxCnt: Packet receive counter (default: 0)
  ///   - network: Network value (default: 0)
  ///   - node: Node value (default: 0)
  ///   - subnode: Sub-node value (default: 0)
  ///   - module: Module value (default: 0)
  ///   - eventBufferMask: Event buffer mask (default: 3 for Radio event printer)
  ///   - eventBufferMode: Event buffer mode (default: 0 for Start)
  void sendingControlResEventReportToBle({
    Function(bool)? dataWritten,
    int pktTxCnt = 0,
    int pktRxCnt = 0,
    int network = 0,
    int node = 0,
    int subnode = 0,
    int module = 0,
    int eventBufferMask = 3,
    int eventBufferMode = 0,
  }) async {
    List<int> controlResEventReportPacket = await controlResEventReportFrame(
      pktTxCnt: pktTxCnt,
      pktRxCnt: pktRxCnt,
      network: network,
      node: node,
      subnode: subnode,
      module: module,
      eventBufferMask: eventBufferMask,
      eventBufferMode: eventBufferMode,
    );
    Logger(
      'control res event report frame <<===========ControlResEventReportPacket: $controlResEventReportPacket===========>>',
    );
    sendDataToBle(controlResEventReportPacket, dataWritten: dataWritten);
  }

  void toggleLedButton() {
    // sendDataToBle(ledToggleFrame());
  }

  /// Sends a Gemini packet over Bluetooth Low Energy (BLE).
  ///
  /// This function asynchronously creates a Gemini packet and sends it over BLE.
  ///
  void sendAuthPacket({Function(bool)? dataWritten}) async {
    /// Create a Gemini packet
    List<int> data = await authMsgFrame();
    Logger("Authentication message -  data: $data");
    Logger("%%%%%%%%%%%%% AUTH MESSAGE SENT %%%%%%%%%%%%");

    /// Send the BLE data packet
    sendDataToBle(data, dataWritten: dataWritten);
  }

  void requestEncryptionKey({Function(bool)? dataWritten}) {
    Uint8List frameBuffer = generateEncryptionKeyDataPacket();
    Logger("Sending encryption Key :$frameBuffer");
    sendDataToBle(frameBuffer, dataWritten: dataWritten);
  }

  Future<void> sendUpdateBleProcessDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> updateBleProcessDataPacket =
        await generateUpdateBleProcessDataPacket();
    sendDataToBle(updateBleProcessDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.updateBleProcess,
      updateBleProcessDataPacket,
    );
  }

  Future<void> sendUpdatePanelNetworkDataProcessDataPacketToBle({
    dynamic Function(bool)? dataWritten,
    required int index,
  }) async {
    List<int> updateBleProcessDataPacket =
        await generateUpdatePanelNetworkProcessDataPacket(index);
    sendDataToBle(updateBleProcessDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.updatePanelNetworkDataProcess,
      updateBleProcessDataPacket,
    );
  }

  Future<void> sendPutDevicesToLinkModeDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataPcket = await generatePutDeviceToLinkModeDataPacket();
    sendDataToBle(dataPcket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.putDeviceToLinkMode, dataPcket);
  }

  Future<void> sendBuildSystemDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> buildSystemDataPacket = await generateBuildSystemDataPacket();
    sendDataToBle(buildSystemDataPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.buildSystem, buildSystemDataPacket);
  }

  Future<void> sendStopBuildSystemDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> buildSystemDataPacket = await generateStopBuildSystemDataPacket();
    sendDataToBle(buildSystemDataPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.stopBuildSystem, buildSystemDataPacket);
  }

  Future<void> sendProcedureCommandDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> procedureCommandDataPacket =
        await generateProcedureComandDataPacket();
    sendDataToBle(procedureCommandDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.procedureCommandSent,
      procedureCommandDataPacket,
    );
  }

  Future<void> sendGetSystemOnlineStatusDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> getSystemOnlineStatusDataPacket =
        await generateGetSystemOnlineStatusDataPacket();
    sendDataToBle(getSystemOnlineStatusDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.getSystemOnlineStatus,
      getSystemOnlineStatusDataPacket,
    );
  }

  Future<void> sendGetAllDeviceStatusDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> getAllDeviceStatus = await generateGetAllDeviceStatusDataPacket();
    sendDataToBle(getAllDeviceStatus, dataWritten: dataWritten);
    // startResponseTimer(
    //     BleStateMachine.getSystemOnlineStatus, getAllDeviceStatus);
  }

  Future<void> sendGetSingleDeviceStatusDataPacketToBle({
    dynamic Function(bool)? dataWritten,
    required int deviceAddress,
  }) async {
    List<int> getSingleDeviceStatusPacket =
        await generateGetSingleDeviceStatusDataPacket(deviceAddress);
    sendDataToBle(getSingleDeviceStatusPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.getSingleDeviceStatusState,
      getSingleDeviceStatusPacket,
    );
  }

  Future<void> sendGetSinglePendingBitDeviceStatusDataPacketToBle({
    dynamic Function(bool)? dataWritten,
    required int deviceAddress,
  }) async {
    List<int> getSingleDeviceStatusPacket =
        await generateGetSingleDeviceStatusDataPacket(deviceAddress);
    sendDataToBle(getSingleDeviceStatusPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.getSingleDeviceStatusStateForPendingBit,
      getSingleDeviceStatusPacket,
    );
  }

  Future<void> sendGetAllDeviceVersionDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> getAllDeviceVersions =
        await generateGetAllDeviceVersionsDataPacket();
    sendDataToBle(getAllDeviceVersions, dataWritten: dataWritten);
    // startResponseTimer(
    //     BleStateMachine.getSystemOnlineStatus, getAllDeviceStatus);
  }

  // Sending network data request to panel
  Future<void> sendGetNetworkDataFromPanelPacketToBle({
    dynamic Function(bool)? dataWritten,
    required int dataIndex,
  }) async {
    List<int> dataPacket = await generateGetNetworkDataFromPanelPacket(
      dataIndex,
    );
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.requestedForNetworkData, dataPacket);
  }

  // Sending Expander Parent Data Request
  Future<void> sendRequestForExpanderParentPacketToBle({
    dynamic Function(bool)? dataWritten,
    required int expanderAddress,
  }) async {
    List<int> dataPacket = await generateGetExpanderParentPacket(
      expanderAddress,
    );
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForExpanderParentAddress,
      dataPacket,
    );
  }

  Future<void> sendGetNetworkDataCRCFromPanelPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataPacket = await generateGetNetworkDataCRCFromPanelPacket();
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.requestedForNetworkDataCRC, dataPacket);
  }

  Future<void> sendStartPanelReplaceSessionPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataPacket = await generateOpenPanelReplacementSessionPacket();
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.startPanelReplacementSession,
      dataPacket,
    );
  }

  Future<void> sendClosePanelReplaceSessionPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataPacket = await generateClosePanelReplacementSessionPacket();
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.closePanelReplacementSession,
      dataPacket,
    );
  }

  Future<void> sendCloseOldPanelReplaceSessionPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataPacket = await generateClosePanelReplacementSessionPacket();
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.closeOldPanelReplacementSession,
      dataPacket,
    );
  }

  Future<void> sendConnectCommandDataPacketToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> connectCmdPacket = await generateConnectCommandDataPacket();
    sendDataToBle(connectCmdPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.connectCommandSend, connectCmdPacket);
  }

  Future<void> sendLinkStatsCommandToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> linkStatusCMD = await generateLinkStatusCommandDataPacket();
    sendDataToBle(linkStatusCMD, dataWritten: dataWritten);
    startResponseTimerWithoutDisconnect(
      BleStateMachine.linkStatusCommand,
      linkStatusCMD,
    );
  }

  Future<void> sendPanelConfigDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> panelConfigDataPacket = await generatePanelConfigDataPacket(
      payLoadData,
    );
    sendDataToBle(panelConfigDataPacket, dataWritten: dataWritten);
  }

  Future<void> sendProjectDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> projectDataPackets = await projectDataPacket(payLoadData);
    sendDataToBle(projectDataPackets, dataWritten: dataWritten);
  }

  Future<void> sendExpanderConfigDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> expanderConfigDataPacket =
        await generateReplaceExpanderConfigDataPacket(payLoadData);
    Logger("<<--<<--<<--Written Expander Data-->>-->>-->>");
    sendDataToBle(expanderConfigDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.sendingExpanderConfig,
      expanderConfigDataPacket,
    );
  }

  Future<void> sendFirmwareUpgradeDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> panelConfigDataPacket =
        await generateFirmwaresSelectionDataPacket(payLoadData);
    sendDataToBle(panelConfigDataPacket, dataWritten: dataWritten);
    Logger("---------Sended-------------");
    startResponseTimer(BleStateMachine.mcuSelection, panelConfigDataPacket);
  }

  Future<void> sendFirmwareFlashDataToBle({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> panelConfigDataPacket =
        await generateFirmwareFlashEraseDataPacket();
    sendDataToBle(panelConfigDataPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.eraseFirmware, panelConfigDataPacket);
  }

  Future<void> sendEofImageDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> panelConfigDataPacket = await generateEofImageDataPacket(
      payLoadData,
    );
    sendDataToBle(panelConfigDataPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.eofImageData, panelConfigDataPacket);
  }

  Future<void> sendPanelVersionDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> panelVersionPacket = await sendLocalPanelVersion(payLoadData);
    sendDataToBle(panelVersionPacket, dataWritten: dataWritten);
  }

  // sending expander pass key
  Future<void> sendExpanderPasskeyToBLE(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> encryptedPayload = await generateExpanderPasskeyDataPacket(
      payLoadData,
    );
    sendDataToBle(encryptedPayload, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.expanderPassKeySent, encryptedPayload);
  }

  /// Add Device ///
  Future<void> sendAddDevicePacketToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await addDeviceToNetworkPacket(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.addDeviceState, generatedPacket);
  }

  /// Change Device ///
  Future<void> sendChangeDeviceAddress(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await changeDeviceAddressCMD(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.changeDeviceAddress, generatedPacket);
  }

  /// Edit Properties
  Future<void> sendEditProperties(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await editDevicePropertiesCMD(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.editDeviceProperties, generatedPacket);
  }

  /// Identify Devices
  Future<void> sendIdentifyDevice({
    required int deviceAddress,
    required bool isEnable,
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await identifyDeviceByAddressDataPacket(
      deviceAddress: deviceAddress,
      isEnable: isEnable,
    );
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.identifyDevices, generatedPacket);
  }

  /// Remove Device
  Future<void> sendRemoveDevicePacketToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await removeDeviceFromNetworkPacket(
      payLoadData,
    );
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.skipRemoveDeviceState, generatedPacket);
  }

  /// Replace Device
  Future<void> sendReplaceDevicePacketToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await replaceDeviceFromNetworkPacket(
      payLoadData,
    );
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
  }

  /// Send Single Device Data To Ble
  Future<void> sendUpdateDevicePointDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await updateDevicePointDataPacket(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
  }

  Future<void> sendEmptyDeviceDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await generateEmptyDeviceDataPacket(
      payLoadData,
    );
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
  }

  Future<void> sendDateTimeDataToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await updateDateTimeDataPacket(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
  }

  Future<void> sendConfigCRCRequest({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> configCrcRequestPacket = await generateRequestForConfigCRC();
    sendDataToBle(configCrcRequestPacket, dataWritten: dataWritten);
  }

  Future<void> sendDeviceVersionsRequest(
    int deviceAddress, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> deviceVersionRequestPacket = await generateGetDeviceVersions(
      deviceAddress,
    );
    sendDataToBle(deviceVersionRequestPacket, dataWritten: dataWritten);
  }

  //////////////////////////////////Large Data Functions/////////////////////////////////////

  /// Send Data based on length
  /// if the payLoad length is > [enBLE_PAYLOAD_SIZE_PER_PACKET] it should send on the Large packet
  /// otherwise it should send on the small packet
  Future<void> sendDataPacketBasedOnSize({
    required List<int> dataPacket,
    required BleStateMachine currentState,
  }) async {
    if (dataPacket.length > enBLE_PAYLOAD_SIZE_PER_PACKET) {
      /// Sending Data Over Large Packet
      // currentLargeDataAndState = CurrentLargeDataAndState(
      //   largeDataPacket: dataPacket,
      //   state: currentState,
      // );
      DataTransferManager().sendDataSyncRequestPacket(
        dataWritten: (bool isWritten) async {
          if (isWritten) {
            Logger("::>>Data Sync Request sended:::>>>");
            if (currentState == BleStateMachine.sendingZoneData) {
              Get.find<BleNotifyDataHandler>().currentLargePacketModule(
                LargePacketModule.sendingZoneData,
              );
            }
            Get.find<BleNotifyDataHandler>().currentBleState(
              BleStateMachine.dataSyncRequest,
            );
          }
        },
      );
    } else {
      Uint8List smallDataPacket = await generatePayloadByState(
        dataPacket,
        currentState,
      );

      /// Sending Data Over Small Packet
      sendDataToBle(
        smallDataPacket,
        dataWritten: (bool isWritten) async {
          if (isWritten) {
            Get.find<BleNotifyDataHandler>().currentBleState(currentState);
          }
        },
      );
      startResponseTimer(currentState, dataPacket);
    }
  }

  Future<void> sendLargeDataPacketLength() async {
    // List<Uint8List> largePacketsList =
    //     await generateListOfLargePacketsFromPayload(
    //       currentLargeDataAndState!.largeDataPacket,
    //     );

    // Logger("Sending Length packet::>>");
    // Logger(largePacketsList.length.toString());

    // List<int> totalPacketLengthData = intToBytesLittleEndian(
    //   largePacketsList.length,
    // );

    // DataTransferManager().sendLargeFrameStartDataPacket(
    //   totalPacketLengthData,
    //   dataWritten: (bool isWritten) {
    //     if (isWritten) {
    //       Get.find<BleNotifyDataHandler>().currentBleState(
    //         BleStateMachine.dataStartRequest,
    //       );
    //     }
    //   },
    // );
  }

  Future<void> generateAndSendLargePacketData({
    int sequenceNumber = 1,
    bool isResending = false,
  }) async {
    // List<Uint8List> largePacketsList =
    //     await generateListOfLargePacketsFromPayload(
    //       currentLargeDataAndState!.largeDataPacket,
    //       sequenceNumber: sequenceNumber,
    //       isResnding: isResending,
    //     );

    Get.find<BleNotifyDataHandler>().currentBleState(
      BleStateMachine.sendingLargePacketOnGoing,
    );
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    if (loopGoingON == true) {
      stopSendingData = true;
    }
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
    // sendLargeDataPacketsOverBle(
    //   largePacketsList: largePacketsList,
    //   isResending: isResending,
    //   sequenceNumber:
    //       sequenceNumber == -1 ? largePacketsList.length : sequenceNumber,
    // );
  }

  ///Sending Data Sync Request Packet to the Ble
  Future<void> sendDataSyncRequestPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataSyncRequestPacket = await largeDataSyncRequestPacket();
    sendDataToBle(dataSyncRequestPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.dataSyncRequest, dataSyncRequestPacket);
  }

  /// Sending large frame start packet to the ble
  Future<void> sendLargeFrameStartDataPacket(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataLargeFrameStartPacket = await largeFrameStartPacket(
      payLoadData,
    );
    sendDataToBle(dataLargeFrameStartPacket, dataWritten: dataWritten);

    startResponseTimer(
      BleStateMachine.dataStartRequest,
      dataLargeFrameStartPacket,
    );
  }

  /// Send Large Data Packet to BLE
  // sendLargeDataPacketToBle(List<int> payLoadData,
  //     {dynamic Function(bool)? dataWritten}) async {
  //   sendDataToBleWithResponse(payLoadData, dataWritten: dataWritten);
  // }

  /// Sending large frame start packet to the ble
  Future<void> sendLargeFrameEndDataPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataLargeFrameEndPacket = await largeDataFrameEndPacket();
    sendDataToBle(dataLargeFrameEndPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.dataEndRequest, dataLargeFrameEndPacket);
  }

  //////////////////////////////////////////////////////////////
  ///                                                     ///
  //////////////////-Download data From BLE-///////////////////

  ///Sending Download Panel Config Command Packet Request From BLE
  Future<void> sendDownloadPanelConfigPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> downloadPanelConfigPacket =
        await generateDownloadPanelConfigFromPanelCommand();
    sendDataToBle(downloadPanelConfigPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForPanelConfig,
      downloadPanelConfigPacket,
    );
  }

  ///Sending Download Panel Config Command Packet Request From BLE
  Future<void> sendDownloadProjectDataPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> downloadProjectDataPacket =
        await generateDownloadProjectDataFromPanelCommand();
    sendDataToBle(downloadProjectDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForProjectData,
      downloadProjectDataPacket,
    );
  }

  Future<void> sendDownloadExpanderDataPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> downloadProjectDataPacket =
        await generateDownloadExpanderPropsCmd();
    sendDataToBle(downloadProjectDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForExpanderData,
      downloadProjectDataPacket,
    );
  }

  Future<void> sendDownloadZoneDataPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> downloadProjectDataPacket = await generateDownloadZoneDataCmd();
    sendDataToBle(downloadProjectDataPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForZoneData,
      downloadProjectDataPacket,
    );
  }

  Future<void> sendingRequestToGetMcuVersionDataPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> localMcuVersions = await queryMcuVersionFromPanelCommand();
    sendDataToBle(localMcuVersions, dataWritten: dataWritten);
    startResponseTimerWithoutRetry(
      BleStateMachine.requestedForMcuVersions,
      localMcuVersions,
    );
  }

  Future<void> sendingEnableDisableAnalogValueDataPacket({
    dynamic Function(bool)? dataWritten,
    required bool isEnableDisable,
    bool isBuild = false,
    bool isPanelReplace = false,
  }) async {
    List<int> generateEnableDisablePacket =
        await generateEnableDisableAnalogValueDataPacket(
          isEnableDisable: isEnableDisable,
          isBuild: isBuild,
          isPanelReplace: isPanelReplace,
        );
    sendDataToBle(generateEnableDisablePacket, dataWritten: dataWritten);
    startResponseTimer(
      Get.find<BleNotifyDataHandler>().currentBleState.value,
      generateEnableDisablePacket,
    );
  }

  ///Sending Download Panel Config Command Packet Request From BLE
  Future<void> sendDownloadDeviceConfigPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> downloadDeviceConfigPacket =
        await generateDownloadDeviceConfigFromPanelCommand();
    sendDataToBle(downloadDeviceConfigPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForDeviceConfig,
      downloadDeviceConfigPacket,
    );
  }

  ///Sending Download Panel Config Command Packet Request From BLE
  Future<void> sendDownloadEventLogsPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> downloadEventLogsPacket =
        await generateDownloadEventLogsFromPanelCommand();
    sendDataToBle(downloadEventLogsPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForEventLogs,
      downloadEventLogsPacket,
    );
  }

  Future<void> sendDownloadEventLogsPacketWithSectionCount({
    dynamic Function(bool)? dataWritten,
    required int sectionCount,
  }) async {
    List<int> downloadEventLogsPacket =
        await generateDownloadEventLogsFromPanelCommandWithSectionCount(
          sectionCount: sectionCount,
        );
    sendDataToBle(downloadEventLogsPacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.requestedForEventLogs,
      downloadEventLogsPacket,
    );
  }

  Future<void> sendDownloadDiagnosticLogsPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataPacket = await generateDownloadDiagnosticLogsFromPanel();
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.requestedForDiagnosticLogs, dataPacket);
  }

  ///Sending Large packet sync response Packet To BLE
  Future<void> sendLargeDataSyncResponsePacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> largeDataSyncResponsePacket =
        await generateLargeDataSyncResponseCommand();
    sendDataToBle(largeDataSyncResponsePacket, dataWritten: dataWritten);
    startResponseTimer(
      BleStateMachine.respondedDataSyncRequest,
      largeDataSyncResponsePacket,
    );
  }

  ///Sending Large packet Start response Packet To BLE
  Future<void> sendLargeDataStartResponsePacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> largeDataStartResponsePacket =
        await generateDataStartResponseCommand();
    sendDataToBle(largeDataStartResponsePacket, dataWritten: dataWritten);
    // startResponseTimer(
    //     BleStateMachine.respondedToDataStart, largeDataStartResponsePacket);
  }

  ///Sending Large packet Start response Packet To BLE
  Future<void> sendLargeDataResendRequestPacket({
    required List<int> payLoad,
    required int bleCommand,
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> largeDataStartResendRequestPacket =
        await generateResendRequestDataPacket(
          bleCommand: bleCommand,
          payLoad: payLoad,
        );
    sendDataToBle(largeDataStartResendRequestPacket, dataWritten: dataWritten);
    // startResponseTimer(
    //     BleStateMachine.respondedToDataStart, largeDataStartResponsePacket);
  }

  ///Sending End Packet response Packet To BLE
  Future<void> sendEndPacketACKPacket({
    dynamic Function(bool)? dataWritten,
    required int command,
  }) async {
    List<int> endPacketAckPacket = await generateEndPacketACKCommand(
      bleCommand: command,
    );
    sendDataToBle(endPacketAckPacket, dataWritten: dataWritten);
    // startResponseTimer(BleStateMachine.respondToEndPacket, endPacketAckPacket);
  }

  ///Sending End Packet response Packet To BLE
  Future<void> sendEEventLogsSmallPacketACKPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> endPacketAckPacket = await generateEventLogACK();
    sendDataToBle(endPacketAckPacket, dataWritten: dataWritten);
    // startResponseTimer(BleStateMachine.respondToEndPacket, endPacketAckPacket);
  }

  ///Test
  Future<void> sendRfTestCommandPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> endPacketAckPacket = await generateRfTestCmdDataPacket();
    sendDataToBle(endPacketAckPacket, dataWritten: dataWritten);
    // startResponseTimer(BleStateMachine.respondToEndPacket, endPacketAckPacket);
  }

  //////////////////////////////////////////////////////////////

  /// get current project state from BLE ///
  Future<void> sendGetCurrentProjectStateCmd({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> requestForCurrentProjectStatePacket =
        await generateRequestForCurrentProjectState();
    sendDataToBle(
      requestForCurrentProjectStatePacket,
      dataWritten: dataWritten,
    );
    // startResponseTimer(
    //     BleStateMachine.respondedToDataStart, largeDataStartResponsePacket);
  }

  /// get current project state from BLE ///
  Future<void> sendReqEventLogFilterData({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> reqEventLogFilterData =
        await generateReqEventLogFilterDataPacket();
    sendDataToBle(reqEventLogFilterData, dataWritten: dataWritten);
    // startResponseTimer(
    //     BleStateMachine.respondedToDataStart, largeDataStartResponsePacket);
  }

  /// get current project state from BLE ///
  Future<void> sendReqPanelStatusData({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> reqEventLogFilterData = await generateReqPanelStatusDataPacket();
    sendDataToBle(reqEventLogFilterData, dataWritten: dataWritten);
    // startResponseTimer(
    //     BleStateMachine.respondedToDataStart, largeDataStartResponsePacket);
  }

  /// get current project state from BLE ///
  Future<void> sendResetBleTrack({dynamic Function(bool)? dataWritten}) async {
    List<int> dataPacket = await generateResetBleTrackDataPacket();
    sendDataToBle(dataPacket, dataWritten: dataWritten);
    // startResponseTimer(
    //     BleStateMachine.respondedToDataStart, largeDataStartResponsePacket);
  }

  /////////////////////////////////////////

  /// Sends BLE (Bluetooth Low Energy) data to the connected device.
  ///
  /// This will write the [data] to the connected BLE Device.
  /// [data]: The BLE data packet to send.
  void sendDataToBle(List<int> data, {Function(bool)? dataWritten}) async {
    BluetoothDevice? connectedDevice = await BtUtils().getConnectedDevices();
    if (connectedDevice != null) {
      BtUtils().writeData(connectedDevice, data, dataWritten: dataWritten);
    } else {
      // AppAlert.alertSnackBar(
      //   Get.context!,
      //   'Oops!!!.Your device is not connected',
      // );
    }
  }

  /// Sends BLE (Bluetooth Low Energy) data to the connected device.
  ///
  /// This will write the [data] to the connected BLE Device.
  /// [data]: The BLE data packet to send.
  Future<void> sendDataToBleWithResponse(
    List<int> data, {
    Function(bool)? dataWritten,
  }) async {
    BluetoothDevice? connectedDevice = await BtUtils().getConnectedDevices();
    if (connectedDevice != null) {
      await BtUtils().writeData(
        connectedDevice,
        data,
        dataWritten: dataWritten,
        withoutResponse: false,
      );
    } else {
      // AppAlert.alertSnackBar(
      //   Get.context!,
      //   'Oops!!!.Your device is not connected',
      // );
    }
  }

  // void sendConfigurationData() async {
  //   List<int> data = await requestConfigurationData();
  //   sendDataToBle(data);
  // }

  /// This function is used to handle Bluetooth communication errors.
  ///
  /// Handles potential CRC mismatch errors,No data errors, COMM Hardware and software errors by retrying the write request up to a maximum number
  /// of retries defined by [maxRetries].
  Future<void> handleBluetoothCommunicationErrors(
    String payLoad,
    List<int> data,
    void Function(bool) callback,
  ) async {
    //Checking if CRC Mismatching (NACK) if its true retrying the write request for 3 time
    if (payLoad == "01") {
      debugPrint("<:::CRC Mismatch:::>$retryCount");
      bleWriteError = BluetoothWriteError.crcMissMatchError;
      callback(true);
      // sendDataToBle(data);
    } else if (payLoad == "03") {
      bleWriteError = BluetoothWriteError.nackUnSuccess;
      debugPrint("<:::COMM Nack unsuccessful ERROR:::>$retryCount");
      callback(true);
      // sendDataToBle(data);
    }
    // Checking if COMM Hardware Error if its true retrying the write request for 3 time
    else if (payLoad == "04") {
      bleWriteError = BluetoothWriteError.invalidFrame;
      debugPrint("<:::COMM Invalid frame ERROR:::>$retryCount");
      callback(true);
      // sendDataToBle(data);
    }
    // Checking if COMM Software Error if its true retrying the write request for 3 time
    else if (payLoad == "05") {
      debugPrint("<:::COMM Authentication required ERROR:::>$retryCount");
      bleWriteError = BluetoothWriteError.authenticationRequired;
      callback(true);
      // sendDataToBle(data);
    }
    // Checking if Data's like [0] we are receiving from BLE if its [0] retrying the write request for 3 time
    else if (payLoad == "06") {
      debugPrint("<:::Busy on process ERROR:::>$retryCount");
      bleWriteError = BluetoothWriteError.busyOnProcess;
      callback(true);

      // Adding a 10-second delay before sending the BLE data
      Future<Null>.delayed(const Duration(seconds: 10), () {
        // sendDataToBle(data);
      });
    } else {
      debugPrint("<:::ACK:::>$retryCount");
      bleWriteError = BluetoothWriteError.ackSuccess;
      callback(false);
    }

    // After reaching [maxRetries] we will show respected error messages to the user.
  }

  String getActualData(String hexString) {
    String dataPacketInHex = "";

    /// Get the payload data from the packet
    String payLoadData = DataHandler().getPayloadFromPacket(hexString);
    debugPrint("BEFORE CONVERTING:::::>$payLoadData");

    if (payLoadData.length > 4) {
      /// Convert the payload data to big-endian format
      String convertedPayLoad = DataHandler().convertPayloadToBigEndian(
        payLoadHexString: payLoadData,
      );
      debugPrint("AFTER CONVERTING:::::>$convertedPayLoad");

      /// Generate a data packet from the converted payload
      List<int> dataPacket = generateDataPacketFromPayload(convertedPayLoad);
      debugPrint(
        "::::::::::::<Data Packet Generated After BIG ENDIAN>::::::::::",
      );
      debugPrint(dataPacket.toString());

      /// Convert the generated data packet to hexadecimal
      dataPacketInHex = bytesToHex(dataPacket);
      debugPrint(dataPacketInHex);
    } else {
      dataPacketInHex = payLoadData;
    }

    return dataPacketInHex;
  }

  FrameData parseRxFrame(List<int> rxData) {
    // Add logic to parse rxData into FrameData
    List<String> hexValues =
        rxData
            .map(
              (int byte) =>
                  byte.toRadixString(16).toUpperCase().padLeft(2, '0'),
            )
            .toList();
    Logger("From list ::::>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    Logger(hexValues.sublist(7, hexValues.length - 4).toString());
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

  void handleError(
    BluetoothWriteError error,
    String debugMessage,
    String snackBarMessage,
  ) {
    // AppAlert.errorSnackBar(Get.context!, snackBarMessage);
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
    _waitingTimer = Timer.periodic(const Duration(seconds: 10), (Timer time) {
      try {
        final BleStateMachine currentState =
            Get.find<BleNotifyDataHandler>().currentBleState.value;
        Logger(
          "Timer Tick: Current BLE State = $currentState, Expected State = $currentBleState",
        );
        if (currentState == currentBleState) {
          retryBleCommands(currentBleState, dataSent);
        } else {
          stopResponseTimer();
        }
      } catch (e, stackTrace) {
        Logger("Error in timer callback: $e\n$stackTrace");
        stopResponseTimer();
      }
    });
  }

  void startResponseTimerWithoutDisconnect(
    BleStateMachine currentBleState,
    List<int>? dataSent,
  ) {
    if (_waitingTimer != null) {
      _waitingTimer!.cancel();
      _waitingTimer = null;
    }
    _waitingTimer = Timer.periodic(const Duration(seconds: 10), (Timer time) {
      try {
        final BleStateMachine currentState =
            Get.find<BleNotifyDataHandler>().currentBleState.value;
        Logger(
          "Timer Tick: Current BLE State = $currentState, Expected State = $currentBleState",
        );
        if (currentState == currentBleState) {
          retryBleCommandsWithoutDisconnect(currentBleState, dataSent);
        } else {
          stopResponseTimer();
        }
      } catch (e, stackTrace) {
        Logger("Error in timer callback: $e\n$stackTrace");
        stopResponseTimer();
      }
    });
  }

  void startResponseTimerWithoutRetry(
    BleStateMachine currentBleState,
    List<int>? dataSent,
  ) {
    _waitingTimer = Timer.periodic(const Duration(seconds: 10), (Timer time) {
      Logger(
        "Timer IS Here WITHOUT RETRY ----------->> ${Get.find<BleNotifyDataHandler>().currentBleState.value == currentBleState} ",
      );
      if (Get.find<BleNotifyDataHandler>().currentBleState.value ==
          currentBleState) {
        // Get.find<InstallationController>().isBuildingSystem(false);
        // Get.find<InstallationController>().update();
        Logger("Disconnected due to no response from the panel");
        // AppAlert.alertSnackBar(
        //   Get.context!,
        //   "Disconnected due to no response from panel.",
        // );
        stopResponseTimer();
        BtUtils().disconnect();
      } else {
        stopResponseTimer();
      }
    });
  }

  void stopResponseTimer() {
    Logger("<<---------<<Timer stopped>>---------->>");
    if (_waitingTimer != null) {
      retryCount = 0;
      _waitingTimer!.cancel();
      _waitingTimer = null;
    }
  }

  void retryBleCommands(BleStateMachine currentBleState, List<int>? dataSent) {
    retryCount = retryCount + 1;
    Logger(
      "<====================$retryCount======================ON Retry CMD==========================$retryCount=================>",
    );

    if (retryCount < maxRetries) {
      // send the command again
      sendDataToBle(
        dataSent!,
        dataWritten: (bool isWritten) {
          Get.find<BleNotifyDataHandler>().currentBleState(currentBleState);
          Get.find<BleNotifyDataHandler>().update();
        },
      );
    } else {
      // Get.find<InstallationController>().isBuildingSystem(false);
      // Get.find<InstallationController>().update();
      Logger("Disconnected due to no response from the panel");
      // AppAlert.alertSnackBar(
      //   Get.context!,
      //   "Disconnected due to no response from panel.",
      // );
      stopResponseTimer();
      BtUtils().disconnect();
    }
  }

  void retryBleCommandsWithoutDisconnect(
    BleStateMachine currentBleState,
    List<int>? dataSent,
  ) {
    retryCount = retryCount + 1;
    Logger(
      "<====================$retryCount======================ON Retry CMD WITHOUT DISCONNECT==========================$retryCount=================>",
    );

    if (retryCount < maxRetries) {
      // send the command again
      sendDataToBle(
        dataSent!,
        dataWritten: (bool isWritten) {
          Get.find<BleNotifyDataHandler>().currentBleState(currentBleState);
          Get.find<BleNotifyDataHandler>().update();
        },
      );
    } else {
      ///
      // Get.context!.loaderOverlay.hide();
      // if (currentBleState == BleStateMachine.linkStatusCommand) {
      //   if (Get.find<InstallationController>().stopFetchingStatus.isFalse) {
      //     if (Get.find<HomeController>().isBleConnected.isTrue) {
      //       Get.find<InstallationController>().sendRequestForConfigCRC();
      //     }
      //     Get.find<InstallationController>().startSystemStatusTimerTask();
      //   }
      // }
      stopResponseTimer();
    }
  }

  /////////////////// Large Data Functions ////////////////////

  bool stopSendingData = false;
  bool loopGoingON = false;

  Future<void> sendLargeDataPacketsOverBle({
    required List<Uint8List> largePacketsList,
    required int sequenceNumber,
    required bool isResending,
  }) async {
    int packetsSentCount = 0;
    Logger("Sequence Number");
    Logger(sequenceNumber.toString());
    // Get.lazyPut(() => UpdatesController());
    // final UpdatesController forUpdateController = Get.find<UpdatesController>();
    // InstallationController installerController =
    //     Get.find<InstallationController>();
    // Calculate the initial progress value

    ///if the sequenceNumber != 1 then we will send the packet 3 times to the ble with few delay
    if (isResending) {
      await sendDataToBleWithResponse(
        largePacketsList[sequenceNumber - 1],
        dataWritten: (bool isWritten) {
          if (isWritten) {
            Logger(
              "||||||||||||||||||||||||||||||||||Large Data Written resend (${sequenceNumber - 1})($isWritten)||||||||||||||||||||||||||||||||||",
            );
            Get.find<BleNotifyDataHandler>().currentBleState(
              BleStateMachine.largeDataResended,
            );
          }
        },
      );

      Get.find<BleNotifyDataHandler>().lOngoingsequenceNumber =
          sequenceNumber + 1;
      Get.find<BleNotifyDataHandler>().lOnGoinglargePacketsList =
          largePacketsList;
      Get.find<BleNotifyDataHandler>().update();
      return;
    }

    Logger("-- Going to start the loop From  ${sequenceNumber - 1} --");

    for (int i = sequenceNumber - 1; i < largePacketsList.length; i++) {
      await Future<dynamic>.delayed(const Duration(milliseconds: 1));
      await sendDataToBleWithResponse(
        largePacketsList[i],
        dataWritten: (bool isWritten) {
          // double value = forUpdateController.progressbarIndex.value;
          // if ((forUpdateController.tempCurrentIndex.value + 1) == i) {
          //   forUpdateController.tempCurrentIndex(i);
          //   value = forUpdateController.progressbarIndex.value + 1;
          //   Logger("value.toString()");
          //   Logger(value.toString());
          //   Logger(forUpdateController.totalPacketLength.toString());
          //   forUpdateController.progressbarIndex(value);
          //   forUpdateController.progressbarCount(
          //     forUpdateController.progressbarIndex.value /
          //         forUpdateController.totalPacketLength,
          //   );
          // } else {
          //   Logger("Difference came on $sequenceNumber");
          //   Logger(
          //     "Current index ${forUpdateController.tempCurrentIndex.value}",
          //   );
          //   Logger("Ongoing index $i");
          // }

          // if (Get.find<BleNotifyDataHandler>().currentLargePacketModule.value !=
          //     LargePacketModule.sendingProjectData) {
          //   installerController.progressBarValues(
          //     (i + 1) / largePacketsList.length,
          //   );
          // }

          // if (Get.find<BleNotifyDataHandler>().currentLargePacketModule.value ==
          //     LargePacketModule.panelNetworkData) {
          //   int totalPacketsToSend = largePacketsList.length * 21;
          //   installerController.progressBarForNetworkDataValues(
          //     (installerController.currentSendingNetworkIndex *
          //             largePacketsList.length) /
          //         totalPacketsToSend,
          //   );
          // }
          // Logger(
          //   "||||||||||||||||||||||||||||||||||Large Data Written ($i)($isWritten)||Progress : ${(installerController.progressBarValues.value * 100).toStringAsFixed(1)}%||||Length: ${largePacketsList.length}||||||||||||||||||||||||||||",
          // );
          // Logger(largePacketsList[i].toString());
          // if (isWritten) {}
        },
      );
      await Future<dynamic>.delayed(const Duration(milliseconds: 1));
      if (stopSendingData) {
        Logger("--Breaking the loop--");
        stopSendingData = false;
        i = 0;
        break;
      }
      packetsSentCount = i;
      loopGoingON = true;
    }
    loopGoingON = false;
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    if (packetsSentCount == largePacketsList.length - 1) {
      await Future<dynamic>.delayed(const Duration(milliseconds: 1000));
      if (Get.find<BleNotifyDataHandler>().currentBleState.value !=
          BleStateMachine.dataEndRequest) {
        sendLargeFrameEndDataPacket(
          dataWritten: (bool isWritten) async {
            Logger("-- Sending End Packet --");
            Get.find<BleNotifyDataHandler>().currentBleState(
              BleStateMachine.dataEndRequest,
            );
          },
        );
      }
    }
  }

  // void sendUpgradeFirmwareDataPacketToBle(
  //     {dynamic Function(bool)? dataWritten}) async {
  //   List<int> updateFirmwareDataPacket = await upgradeCompletedDataPacket();
  //   sendDataToBle(updateFirmwareDataPacket, dataWritten: dataWritten);
  //   startResponseTimer(
  //       BleStateMachine.firmwareUpdated, updateFirmwareDataPacket);
  // }
  Future<void> sendStatusAsUpdated() async {
    List<int> sendUpdatedStatus = await updateStatusAsCompletedDataPacket();
    sendDataToBle(sendUpdatedStatus);
    Get.find<BleNotifyDataHandler>().currentBleState(
      BleStateMachine.firmwareUploadStatus,
    );
  }
}
