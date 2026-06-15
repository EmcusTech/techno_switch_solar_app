library;

import 'dart:async';
import 'dart:typed_data';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
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

  void requestingPassKeyToBle({dynamic Function(bool)? dataWritten}) async {
    logger.Logger("<<===========Requesting pass Key===========>>");
    List<int> passKeyPacket = await passKeyRequestFrame();
    sendDataToBle(passKeyPacket, dataWritten: dataWritten);
  }

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

  void sendingNetworkPacketToBle({
    Function(bool)? dataWritten,
    int pktTxCnt = 0,
    int pktRxCnt = 0,
  }) async {
    List<int> networkPacket = await networkPacketFrame(
      pktTxCnt: pktTxCnt,
      pktRxCnt: pktRxCnt,
    );
    logger.Logger(
      'network packet frame <<===========NetworkPacket: $networkPacket===========>>',
    );
    sendDataToBle(networkPacket, dataWritten: dataWritten);
  }

  void sendingPollPacketToBle({
    Function(bool)? dataWritten,
    int pktTxCnt = 0,
    int pktRxCnt = 0,
  }) async {
    List<int> pollPacket = await pollPacketFrame(
      pktTxCnt: pktTxCnt,
      pktRxCnt: pktRxCnt,
    );
    logger.Logger(
      'poll packet frame <<===========PollPacket: $pollPacket===========>>',
    );
    sendDataToBle(pollPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.sendingPollPacket, pollPacket);
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
    logger.Logger(
      'dummy packet frame <<===========DummyPacket: $dummyPacket===========>>',
    );
    sendDataToBle(dummyPacket, dataWritten: dataWritten);
  }

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
    logger.Logger(
      'control res event report frame <<===========ControlResEventReportPacket: $controlResEventReportPacket===========>>',
    );
    sendDataToBle(controlResEventReportPacket, dataWritten: dataWritten);
  }

  void toggleLedButton() {}

  void sendAuthPacket({Function(bool)? dataWritten}) async {
    List<int> data = await authMsgFrame();
    logger.Logger("Authentication message -  data: $data");
    logger.Logger("%%%%%%%%%%%%% AUTH MESSAGE SENT %%%%%%%%%%%%");
    sendDataToBle(data, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.sendingAuthMessage, data);
  }

  void requestEncryptionKey({Function(bool)? dataWritten}) {
    Uint8List frameBuffer = generateEncryptionKeyDataPacket();
    logger.Logger("Sending encryption Key :$frameBuffer");
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
  }

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
    logger.Logger("<<--<<--<<--Written Expander Data-->>-->>-->>");
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
    logger.Logger("---------Sended-------------");
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

  Future<void> sendAddDevicePacketToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await addDeviceToNetworkPacket(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.addDeviceState, generatedPacket);
  }

  Future<void> sendChangeDeviceAddress(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await changeDeviceAddressCMD(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.changeDeviceAddress, generatedPacket);
  }

  Future<void> sendEditProperties(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await editDevicePropertiesCMD(payLoadData);
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.editDeviceProperties, generatedPacket);
  }

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

  Future<void> sendReplaceDevicePacketToBle(
    List<int> payLoadData, {
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> generatedPacket = await replaceDeviceFromNetworkPacket(
      payLoadData,
    );
    sendDataToBle(generatedPacket, dataWritten: dataWritten);
  }

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

  Future<void> sendDataPacketBasedOnSize({
    required List<int> dataPacket,
    required BleStateMachine currentState,
  }) async {
    if (dataPacket.length > enBLE_PAYLOAD_SIZE_PER_PACKET) {
      DataTransferManager().sendDataSyncRequestPacket(
        dataWritten: (bool isWritten) async {
          if (isWritten) {
            logger.Logger("::>>Data Sync Request sended:::>>>");
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

  Future<void> sendLargeDataPacketLength() async {}

  Future<void> generateAndSendLargePacketData({
    int sequenceNumber = 1,
    bool isResending = false,
  }) async {
    Get.find<BleNotifyDataHandler>().currentBleState(
      BleStateMachine.sendingLargePacketOnGoing,
    );
    await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    if (loopGoingON == true) {
      stopSendingData = true;
    }
    await Future<dynamic>.delayed(const Duration(milliseconds: 100));
  }

  Future<void> sendDataSyncRequestPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataSyncRequestPacket = await largeDataSyncRequestPacket();
    sendDataToBle(dataSyncRequestPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.dataSyncRequest, dataSyncRequestPacket);
  }

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

  Future<void> sendLargeFrameEndDataPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> dataLargeFrameEndPacket = await largeDataFrameEndPacket();
    sendDataToBle(dataLargeFrameEndPacket, dataWritten: dataWritten);
    startResponseTimer(BleStateMachine.dataEndRequest, dataLargeFrameEndPacket);
  }

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

  Future<void> sendLargeDataStartResponsePacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> largeDataStartResponsePacket =
        await generateDataStartResponseCommand();
    sendDataToBle(largeDataStartResponsePacket, dataWritten: dataWritten);
  }

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
  }

  Future<void> sendEndPacketACKPacket({
    dynamic Function(bool)? dataWritten,
    required int command,
  }) async {
    List<int> endPacketAckPacket = await generateEndPacketACKCommand(
      bleCommand: command,
    );
    sendDataToBle(endPacketAckPacket, dataWritten: dataWritten);
  }

  Future<void> sendEEventLogsSmallPacketACKPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> endPacketAckPacket = await generateEventLogACK();
    sendDataToBle(endPacketAckPacket, dataWritten: dataWritten);
  }

  Future<void> sendRfTestCommandPacket({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> endPacketAckPacket = await generateRfTestCmdDataPacket();
    sendDataToBle(endPacketAckPacket, dataWritten: dataWritten);
  }

  Future<void> sendGetCurrentProjectStateCmd({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> requestForCurrentProjectStatePacket =
        await generateRequestForCurrentProjectState();
    sendDataToBle(
      requestForCurrentProjectStatePacket,
      dataWritten: dataWritten,
    );
  }

  Future<void> sendReqEventLogFilterData({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> reqEventLogFilterData =
        await generateReqEventLogFilterDataPacket();
    sendDataToBle(reqEventLogFilterData, dataWritten: dataWritten);
  }

  Future<void> sendReqPanelStatusData({
    dynamic Function(bool)? dataWritten,
  }) async {
    List<int> reqEventLogFilterData = await generateReqPanelStatusDataPacket();
    sendDataToBle(reqEventLogFilterData, dataWritten: dataWritten);
  }

  Future<void> sendResetBleTrack({dynamic Function(bool)? dataWritten}) async {
    List<int> dataPacket = await generateResetBleTrackDataPacket();
    sendDataToBle(dataPacket, dataWritten: dataWritten);
  }

  void sendDataToBle(List<int> data, {Function(bool)? dataWritten}) async {
    DiscoveredDevice? connectedDevice = await BtUtils().getConnectedDevice();
    if (connectedDevice != null) {
      BtUtils().writeData(connectedDevice, data, dataWritten: dataWritten);
    } else {}
  }

  Future<void> sendDataToBleWithResponse(
    List<int> data, {
    Function(bool)? dataWritten,
  }) async {
    DiscoveredDevice? connectedDevice = await BtUtils().getConnectedDevice();
    if (connectedDevice != null) {
      await BtUtils().writeData(
        connectedDevice,
        data,
        dataWritten: dataWritten,
        withoutResponse: false,
      );
    } else {}
  }

  Future<void> handleBluetoothCommunicationErrors(
    String payLoad,
    List<int> data,
    void Function(bool) callback,
  ) async {
    if (payLoad == "01") {
      debugPrint("<:::CRC Mismatch:::>$retryCount");
      bleWriteError = BluetoothWriteError.crcMissMatchError;
      callback(true);
    } else if (payLoad == "03") {
      bleWriteError = BluetoothWriteError.nackUnSuccess;
      debugPrint("<:::COMM Nack unsuccessful ERROR:::>$retryCount");
      callback(true);
    } else if (payLoad == "04") {
      bleWriteError = BluetoothWriteError.invalidFrame;
      debugPrint("<:::COMM Invalid frame ERROR:::>$retryCount");
      callback(true);
    } else if (payLoad == "05") {
      debugPrint("<:::COMM Authentication required ERROR:::>$retryCount");
      bleWriteError = BluetoothWriteError.authenticationRequired;
      callback(true);
    } else if (payLoad == "06") {
      debugPrint("<:::Busy on process ERROR:::>$retryCount");
      bleWriteError = BluetoothWriteError.busyOnProcess;
      callback(true);
      Future<Null>.delayed(const Duration(seconds: 10), () {});
    } else {
      debugPrint("<:::ACK:::>$retryCount");
      bleWriteError = BluetoothWriteError.ackSuccess;
      callback(false);
    }
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

  void handleError(
    BluetoothWriteError error,
    String debugMessage,
    String snackBarMessage,
  ) {}

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
        logger.Logger(
          "Timer Tick: Current BLE State = $currentState, Expected State = $currentBleState",
        );
        if (currentState == currentBleState) {
          retryBleCommandsWithoutDisconnect(currentBleState, dataSent);
        } else {
          stopResponseTimer();
        }
      } catch (e, stackTrace) {
        logger.Logger("Error in timer callback: $e\n$stackTrace");
        stopResponseTimer();
      }
    });
  }

  void startResponseTimerWithoutRetry(
    BleStateMachine currentBleState,
    List<int>? dataSent,
  ) {
    _waitingTimer = Timer.periodic(const Duration(seconds: 10), (Timer time) {
      logger.Logger(
        "Timer IS Here WITHOUT RETRY ----------->> ${Get.find<BleNotifyDataHandler>().currentBleState.value == currentBleState} ",
      );
      if (Get.find<BleNotifyDataHandler>().currentBleState.value ==
          currentBleState) {
        logger.Logger("Disconnected due to no response from the panel");
        stopResponseTimer();
        BtUtils().disconnect();
      } else {
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

  void retryBleCommandsWithoutDisconnect(
    BleStateMachine currentBleState,
    List<int>? dataSent,
  ) {
    retryCount = retryCount + 1;
    logger.Logger(
      "<====================$retryCount======================ON Retry CMD WITHOUT DISCONNECT==========================$retryCount=================>",
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
      stopResponseTimer();
    }
  }

  bool stopSendingData = false;
  bool loopGoingON = false;

  Future<void> sendStatusAsUpdated() async {
    List<int> sendUpdatedStatus = await updateStatusAsCompletedDataPacket();
    sendDataToBle(sendUpdatedStatus);
    Get.find<BleNotifyDataHandler>().currentBleState(
      BleStateMachine.firmwareUploadStatus,
    );
  }
}
