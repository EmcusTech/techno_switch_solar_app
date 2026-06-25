library;

import 'dart:typed_data';

import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

import 'ble_notify_data_handler.dart';
import 'data_helper.dart';

import 'package:get/get.dart';

String _bytesToAscii(List<int> bytes) {
  return bytes.map((b) {
    if (b >= 32 && b <= 126) {
      return String.fromCharCode(b);
    } else {
      return '.';
    }
  }).join();
}

const int PREAMBLE_FIRST_BYTE = 0xAA;
const int PREAMBLE_SECOND_BYTE = 0x55;
const int COMMAND_FIRST_BYTE = 0x10;
const int COMMAND_SECOND_BYTE = 0x01;
const int COMMAND_SECOND_REQUEST_DATA_BYTE = 0x02;
const int CONNECTION_REQUEST_FRAME_TYPE_BYTE = 0x01;
const int DATA_PACKET_FRAME_TYPE_BYTE = 0x02;
const int LARGE_PACKET_FRAME_TYPE_BYTE = 0x03;
const int LARGE_PACKET_START_FRAME_TYPE_BYTE = 0x07;
const int END_OF_FRAME_FIRST_BYTE = 0xEE;
const int END_OF_FRAME_SECOND_BYTE = 0xBB;

Uint8List _buildOriginalTechnoswitchPasskeyFrame(
  String passkey,
  int pktTxCnt,
  int pktRxCnt,
) {
  List<int> frameBuffer = List.filled(216, 0);

  frameBuffer[0] = 0xFE;
  frameBuffer[1] = 0x01;
  frameBuffer[2] = 0x00;
  frameBuffer[3] = 0x01;

  frameBuffer[4] = pktTxCnt & 0xFF;
  frameBuffer[5] = pktRxCnt & 0xFF;

  frameBuffer[6] = 0x00;
  frameBuffer[7] = 0x00;
  frameBuffer[8] = 0x00;
  frameBuffer[9] = 0x00;
  frameBuffer[10] = 0x83;
  frameBuffer[11] = 0x00;
  frameBuffer[12] = 0x04;
  frameBuffer[13] = 0x04;

  List<int> passkeyBytes = passkey.codeUnits;
  int passkeyLength = passkeyBytes.length < 200 ? passkeyBytes.length : 200;
  for (int i = 0; i < passkeyLength; i++) {
    frameBuffer[14 + i] = passkeyBytes[i];
  }

  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));
  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  frameBuffer[215] = 0xFD;

  return Uint8List.fromList(frameBuffer);
}

Uint8List _buildOriginalTechnoswitchPollPacketFrame(
  int pktTxCnt,
  int pktRxCnt,
) {
  List<int> frameBuffer = List.filled(216, 0);

  frameBuffer[0] = 0xFE;
  frameBuffer[1] = 0x01;
  frameBuffer[2] = 0x00;
  frameBuffer[3] = 0x00;

  frameBuffer[4] = (pktTxCnt + 1) & 0xFF;
  frameBuffer[5] = pktRxCnt & 0xFF;

  frameBuffer[6] = 0x00;
  frameBuffer[7] = 0x00;
  frameBuffer[8] = 0x00;
  frameBuffer[9] = 0x00;
  frameBuffer[10] = 0x00;
  frameBuffer[11] = 0x00;

  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));
  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  frameBuffer[215] = 0xFD;

  return Uint8List.fromList(frameBuffer);
}

int _calculateFletcherChecksum(List<int> buffer) {
  int length = buffer.length;
  int checksum = 0;

  if (length > 0) {
    int sum1 = 0;
    int sum2 = 0;

    for (int i = 0; i < length; i++) {
      sum1 = (sum1 + buffer[i]) % 255;
      sum2 = (sum2 + sum1) % 255;
    }

    int chk1 = (255 - ((sum1 + sum2) % 255)) & 0xFF;
    int chk2 = (255 - ((sum1 + chk1) % 255)) & 0xFF;

    checksum = (chk1 << 8) | chk2;
  }

  return checksum;
}

Uint8List _buildOriginalTechnoswitchNetworkPacketFrame(
  int pktTxCnt,
  int pktRxCnt,
) {
  List<int> frameBuffer = List.filled(216, 0);

  frameBuffer[0] = 0xFE;
  frameBuffer[1] = 0x01;
  frameBuffer[2] = 0x00;
  frameBuffer[3] = 0x04;

  frameBuffer[4] = 0x00;
  frameBuffer[5] = 0x00;

  frameBuffer[6] = 0x05;
  frameBuffer[7] = 0x00;
  frameBuffer[8] = 0x00;
  frameBuffer[9] = 0x00;
  frameBuffer[10] = 0x00;
  frameBuffer[11] = 0x02;
  frameBuffer[12] = 0x01;

  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));
  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  frameBuffer[215] = 0xFD;

  return Uint8List.fromList(frameBuffer);
}

Future<Uint8List> networkPacketFrame({
  int pktTxCnt = 0,
  int pktRxCnt = 0,
}) async {
  Uint8List originalFrame = _buildOriginalTechnoswitchNetworkPacketFrame(
    pktTxCnt,
    pktRxCnt,
  );
  String originalFrameHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX ORIGINAL TECHNOSWITCH LOGS [NETWORK] - TX Frame: $originalFrameHex',
    type: LogType.ble,
  );

  int originalFrameLength = originalFrame.length;

  Uint8List newBleFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    (BleCommandsList.BLE_PASSKEY_REQ_CMD.value >> 8) & 0xFF,
    BleCommandsList.BLE_PASSKEY_REQ_CMD.value & 0xFF,
    DATA_PACKET_FRAME_TYPE_BYTE,
    (originalFrameLength >> 8) & 0xFF,
    originalFrameLength & 0xFF,
    ...originalFrame,
  ]);

  int calculatedCRC = convertCrc16(newBleFrame);

  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE);
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE);
  String completeBleFrameHex = completeBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX COMPLETE TECHNOSWITCH LOGS [NETWORK] - TX BLE Frame (unencrypted): $completeBleFrameHex',
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> passKeyFrame(
  String hexPayLoad, {
  int pktTxCnt = 0,
  int pktRxCnt = 0,
}) async {
  Uint8List originalFrame = _buildOriginalTechnoswitchPasskeyFrame(
    hexPayLoad,
    pktTxCnt,
    pktRxCnt,
  );
  String originalFrameHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX ORIGINAL TECHNOSWITCH LOGS [PASSKEY] - TX Frame: $originalFrameHex',
    type: LogType.ble,
  );

  int originalFrameLength = originalFrame.length;

  Uint8List newBleFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    (BleCommandsList.BLE_PASSKEY_REQ_CMD.value >> 8) & 0xFF,
    BleCommandsList.BLE_PASSKEY_REQ_CMD.value & 0xFF,
    DATA_PACKET_FRAME_TYPE_BYTE,
    (originalFrameLength >> 8) & 0xFF,
    originalFrameLength & 0xFF,
    ...originalFrame,
  ]);

  int calculatedCRC = convertCrc16(newBleFrame);

  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE);
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE);
  String completeBleFrameHex = completeBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX COMPLETE TECHNOSWITCH LOGS [PASSKEY] - TX BLE Frame (unencrypted): $completeBleFrameHex',
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> pollPacketFrame({int pktTxCnt = 0, int pktRxCnt = 0}) async {
  Uint8List originalFrame = _buildOriginalTechnoswitchPollPacketFrame(
    pktTxCnt,
    pktRxCnt,
  );
  String originalFrameHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX ORIGINAL TECHNOSWITCH LOGS [POLL] - TX Frame: $originalFrameHex',
    type: LogType.ble,
  );

  int originalFrameLength = originalFrame.length;

  Uint8List newBleFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    (BleCommandsList.BLE_PASSKEY_REQ_CMD.value >> 8) & 0xFF,
    BleCommandsList.BLE_PASSKEY_REQ_CMD.value & 0xFF,
    DATA_PACKET_FRAME_TYPE_BYTE,
    (originalFrameLength >> 8) & 0xFF,
    originalFrameLength & 0xFF,
    ...originalFrame,
  ]);

  int calculatedCRC = convertCrc16(newBleFrame);

  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE);
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE);
  String completeBleFrameHex = completeBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX COMPLETE TECHNOSWITCH LOGS [POLL] - TX BLE Frame (unencrypted): $completeBleFrameHex',
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  return encryptedDataPacket;
}

Uint8List _buildOriginalTechnoswitchControlResEventReportFrame(
  int pktTxCnt,
  int pktRxCnt, {
  int network = 0,
  int node = 0,
  int subnode = 0,
  int module = 0,
  int eventBufferMask = 3,
  int eventBufferMode = 0,
}) {
  const int frameEot = 0xFD;

  List<int> frameBuffer = List.filled(216, 0);

  frameBuffer[0] = 0xFE;
  frameBuffer[1] = 0x01;
  frameBuffer[2] = 0x00;
  frameBuffer[3] = 0x01;
  frameBuffer[4] = pktTxCnt & 0xFF;
  frameBuffer[5] = pktRxCnt & 0xFF;

  frameBuffer[6] = 0x00;
  frameBuffer[7] = 0x00;
  frameBuffer[8] = 0x00;
  frameBuffer[9] = 0x00;
  frameBuffer[10] = 0x83;
  frameBuffer[11] = 0x04;
  frameBuffer[12] = 0x0B;
  frameBuffer[13] = 0x03;
  frameBuffer[14] = eventBufferMode & 0xFF;

  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));

  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;
  frameBuffer[215] = frameEot;

  return Uint8List.fromList(frameBuffer);
}

Future<Uint8List> controlResEventReportFrame({
  int pktTxCnt = 0,
  int pktRxCnt = 0,
  int network = 0,
  int node = 0,
  int subnode = 0,
  int module = 0,
  int eventBufferMask = 3,
  int eventBufferMode = 0,
}) async {
  Uint8List originalFrame =
      _buildOriginalTechnoswitchControlResEventReportFrame(
        pktTxCnt,
        pktRxCnt,
        network: network,
        node: node,
        subnode: subnode,
        module: module,
        eventBufferMask: eventBufferMask,
        eventBufferMode: eventBufferMode,
      );

  String originalFrameHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX ORIGINAL TECHNOSWITCH LOGS [CONTROL_RES_EVENT_REPORT] - TX Frame: $originalFrameHex',
    type: LogType.ble,
  );

  int originalFrameLength = originalFrame.length;

  Uint8List newBleFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    (BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value >> 8) & 0xFF,
    BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value & 0xFF,
    DATA_PACKET_FRAME_TYPE_BYTE,
    (originalFrameLength >> 8) & 0xFF,
    originalFrameLength & 0xFF,
    ...originalFrame,
  ]);

  int calculatedCRC = convertCrc16(newBleFrame);

  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE);
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE);
  String completeBleFrameHex = completeBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(
    'TX/RX COMPLETE TECHNOSWITCH LOGS [CONTROL_RES_EVENT_REPORT] - TX BLE Frame (unencrypted): $completeBleFrameHex',
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> authMsgFrame() async {
  Logger('========================================');
  Logger('TX/RX Logs - STEP 3: SEND AUTHENTICATION MESSAGE (TX)');
  Logger('========================================');

  List<int> payLoadData = convertStringToHex("TECHNOSWITCH-AUTH-APP");
  Logger("Authentication message -  payLoadData: $payLoadData");
  String hexPayLoad = bytesToHex(payLoadData);
  Logger("Authentication message -  hexPayLoad: $hexPayLoad");
  String hexLengthByte = calculateLengthByte(hexPayLoad);
  List<int> lengthByte = hexToBytes(hexLengthByte);

  Uint8List dataFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_REQUEST_DATA_BYTE,
    DATA_PACKET_FRAME_TYPE_BYTE,
    ...lengthByte,
    ...payLoadData,
  ]);

  String txHex = dataFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String txAscii = _bytesToAscii(dataFrame);
  Logger('TX/RX Logs - Non-encrypted TX Data (${dataFrame.length} bytes):');
  Logger('TX/RX Logs - Hex: $txHex');
  Logger('TX/RX Logs - ASCII: $txAscii');
  Logger(
    'TX/RX Logs - Command: 0x${(COMMAND_FIRST_BYTE << 8) | COMMAND_SECOND_REQUEST_DATA_BYTE}',
  );
  Logger('TX/RX Logs - Frame Type: Small Data Frame (0x02)');
  Logger('TX/RX Logs - Payload: TECHNOSWITCH-AUTH-APP');

  int calculatedCRC = convertCrc16(dataFrame);
  Logger(
    "Calculated CRC: $calculatedCRC ; ${calculatedCRC.toRadixString(16).toUpperCase()}",
  );
  List<int> newList = dataFrame.toList();
  newList.addAll(intToBytesBigEndian(calculatedCRC));
  newList.add(END_OF_FRAME_FIRST_BYTE);
  newList.add(END_OF_FRAME_SECOND_BYTE);

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: newList,
  );

  Logger(newList.toString());
  Logger(":::::::::::::::OldList.toString()::::::::::::::::");
  Logger(
    "Authentication message -  encryptedDataPacket: ${encryptedDataPacket.toString()}",
  );

  return encryptedDataPacket;
}

Future<Uint8List> panelAndDeviceConfigDataPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_SEND_PANEL_CONFIG_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> projectDataPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPLOAD_PROJECT_DATA_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> addDeviceToNetworkPacket(List<int> payLoadData) async {
  List<int> data = <int>[0x10, 0x07];
  data.addAll(payLoadData);
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: data,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> changeDeviceAddressCMD(List<int> payLoadData) async {
  List<int> data = <int>[0x10, 0x1B];
  data.addAll(payLoadData);
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: data,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> editDevicePropertiesCMD(List<int> payLoadData) async {
  List<int> data = <int>[0x10, 0x1D];
  data.addAll(payLoadData);
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: data,
  );

  Logger("Sendig Command : $data");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> identifyDeviceByAddressDataPacket({
  required int deviceAddress,
  required bool isEnable,
}) async {
  int enableDiableValue = isEnable ? 0x01 : 0x00;
  List<int> data = <int>[0x10, 0x06, 0x04, enableDiableValue, deviceAddress];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: data,
  );

  Logger("identifyDeviceByAddressDataPacket Command : $data");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> removeDeviceFromNetworkPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_CMD_RMV_DEVIC_FRM_NWK.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> replaceDeviceFromNetworkPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_CMD_REPLACE_DEVICE.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> updateDevicePointDataPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_CMD_UPD_INDEX_DEV_POPTY.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Logger("Update Device Point Data CMD: $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> updateDateTimeDataPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.enCMD_UPD_PANEL_DATE_TIME.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Logger("Update Date Time on the panel: $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> largeDataSyncRequestPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = <int>[];

  frame = frameDataPacket(
    bleCommand: getLargeDataBleCommandByState(
      Get.find<BleNotifyDataHandler>().currentLargePacketModule.value,
    ),
    typeOfFrame: KbleTypeOfFrameDef.enBLE_LARGE_DATA_SYNC_REQ_FRAME.value,
    payLoadData: payLoadData,
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> largeFrameStartPacket(List<int> payLoadData) async {
  List<int> frame = <int>[];

  frame = frameDataPacket(
    bleCommand: getLargeDataBleCommandByState(
      Get.find<BleNotifyDataHandler>().currentLargePacketModule.value,
    ),
    typeOfFrame: KbleTypeOfFrameDef.enLARGE_FRAME_START.value,
    payLoadData: payLoadData,
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> largeDataFrameEndPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = <int>[];

  frame = frameDataPacket(
    bleCommand: getLargeDataBleCommandByState(
      Get.find<BleNotifyDataHandler>().currentLargePacketModule.value,
    ),
    typeOfFrame: KbleTypeOfFrameDef.enLARGE_FRAME_END.value,
    payLoadData: payLoadData,
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

int getLargeDataBleCommandByState(LargePacketModule largePacketModule) {
  switch (largePacketModule) {
    case LargePacketModule.devices:
      return BleCommandsList.BLE_LARGE_DATA_REQ_CMD.value;

    case LargePacketModule.panelNetworkData:
      return BleCommandsList.enCMD_SEND_PANEL_NETWORK_DATA.value;

    case LargePacketModule.firmWareUpgrade:
      return BleCommandsList.BLE_FIRMWARE_UPDATE_CMD.value;

    case LargePacketModule.sendingProjectData:
      return BleCommandsList.BLE_UPLOAD_PROJECT_DATA_CMD.value;

    case LargePacketModule.sendingZoneData:
      return BleCommandsList.BLE_SEND_ZONE_DETAILS_BLE_CMD.value;
  }
}

Future<Uint8List> generateBuildSystemDataPacket() async {
  List<int> payLoadData = <int>[3];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_BUILD_SYSTEM_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Build CMD : $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateStopBuildSystemDataPacket() async {
  List<int> payLoadData = <int>[4];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_BUILD_SYSTEM_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Build CMD : $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateProcedureComandDataPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_PROCEDURE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetSystemOnlineStatusDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x15]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateRfTestCmdDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x20]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetAllDeviceStatusDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x0C]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetSingleDeviceStatusDataPacket(
  int deviceAddress,
) async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x0D, deviceAddress]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetAllDeviceVersionsDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x0A]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateConnectCommandDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x01]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetDeviceVersions(int deviceAddress) async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x0B, deviceAddress]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateResendRequestDataPacket({
  required List<int> payLoad,
  required int bleCommand,
}) async {
  Uint8List data = Uint8List.fromList(payLoad);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: bleCommand,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_RESEND_REQ_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateLinkStatusCommandDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x11]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generatePanelConfigDataPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_PANEL_CONFIG_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateExpanderConfigDataPacket(
  List<int> payLoadData,
) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_EXPANDER_CONFIG_SEND_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateReplaceExpanderConfigDataPacket(
  List<int> payLoadData,
) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_REPLACE_EXPANDER_CONFIG_SEND_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateFirmwaresSelectionDataPacket(
  List<int> payLoadData,
) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_MCU_SELECTION_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );
  return encryptedDataPacket;
}

Future<Uint8List> generateFirmwareFlashEraseDataPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_FLASH_ERASE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );
  return encryptedDataPacket;
}

Future<Uint8List> generateEofImageDataPacket(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_FILE_DATA_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );
  return encryptedDataPacket;
}

Future<Uint8List> updateStatusAsCompletedDataPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_OTA_ALL_MCU_UPDATED_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> sendLocalPanelVersion(List<int> payLoadData) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_PANEL_REL_UPDATE_VER_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateExpanderPasskeyDataPacket(
  List<int> payLoadData,
) async {
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_EXPANDER_PASS_KEY_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetNetworkDataFromPanelPacket(int dataIndex) async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x22, dataIndex]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetExpanderParentPacket(int expanderAddress) async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x27, expanderAddress]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateGetNetworkDataCRCFromPanelPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x24]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateOpenPanelReplacementSessionPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x25]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateClosePanelReplacementSessionPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x26]);
  List<int> payLoadData = data;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_UPDATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadPanelConfigFromPanelCommand() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_PANEL_DOWNLOAD_CONFIG_FROM_BLE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadProjectDataFromPanelCommand() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_DOWNLOAD_PROJECT_DATA_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadExpanderPropsCmd() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_EXPANDER_CONFIG_DOWNLOAD_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadZoneDataCmd() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_DOWNLOAD_ZONE_DETAILS_BLE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> queryMcuVersionFromPanelCommand() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_FIRMWARE_VER_QUERY_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadDeviceConfigFromPanelCommand() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_DEVICE_DOWNLOAD_CONFIG_FROM_BLE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Req Device Config: $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadEventLogsFromPanelCommand() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_CMD_DWNLD_EVT_LOGS.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Req Event Logs: $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadEventLogsFromPanelCommandWithSectionCount({
  required int sectionCount,
}) async {
  List<int> payLoadData = <int>[sectionCount];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_CMD_DWNLD_EVT_LOGS.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDownloadDiagnosticLogsFromPanel() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_CMD_DWNLD_DIAGNOSTIC_LOGS.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );
  return encryptedDataPacket;
}

Future<Uint8List> generateLargeDataSyncResponseCommand() async {
  List<int> payLoadData = <int>[0x01, 0x00, 0x00];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_LARGE_DATA_REQ_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SYNC_RESPONSE_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateDataStartResponseCommand() async {
  List<int> payLoadData = <int>[0x07];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_LARGE_DATA_REQ_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_RESPONSE_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateEndPacketACKCommand({required int bleCommand}) async {
  List<int> payLoadData = <int>[0x02];
  List<int> frame = frameDataPacket(
    bleCommand: bleCommand,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_RESPONSE_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateEventLogACK() async {
  List<int> payLoadData = <int>[0x02];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_CMD_DWNLD_EVT_LOGS.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_RESPONSE_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateRequestForCurrentProjectState() async {
  List<int> payLoadData = <int>[0x00];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_GET_PROJECT_BUILD_STATE_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateRequestForConfigCRC() async {
  List<int> payLoadData = <int>[0x00];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.enCMD_REQ_PANEL_CONFIG_CRC.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateReqEventLogFilterDataPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.enCMD_REQ_EVT_LOGS_FLTR_INFO.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Req Event logs filter: $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateReqPanelStatusDataPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.enCMD_GET_PANEL_STATUS.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Req Panel Status: $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateResetBleTrackDataPacket() async {
  List<int> payLoadData = <int>[0];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_PASSKEY_REQ_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enCMD_RST_BLE_TRACK_STATUS.value,
    payLoadData: payLoadData,
  );

  Logger("Reset Ble Track Data Packet: $frame");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateEnableDisableAnalogValueDataPacket({
  required bool isEnableDisable,
  bool isBuild = false,
  bool isPanelReplace = false,
}) async {
  List<int> payLoadData = <int>[];
  if (isPanelReplace) {
    payLoadData = <int>[
      isEnableDisable
          ? 4
          : isBuild
          ? 2
          : 3,
    ];
  } else {
    payLoadData = <int>[
      isEnableDisable
          ? 1
          : isBuild
          ? 2
          : 0,
    ];
  }
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.enCMD_ANALOG_ENABLE_DISABLE.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generatePayloadByState(
  List<int> payLoadData,
  BleStateMachine bleState,
) async {
  int bleCommand = 0;

  switch (bleState) {
    case BleStateMachine.sendingZoneData:
      bleCommand = BleCommandsList.BLE_SEND_ZONE_DETAILS_BLE_CMD.value;
      break;
    case BleStateMachine.sendingProjectData:
      bleCommand = BleCommandsList.BLE_UPLOAD_PROJECT_DATA_CMD.value;
      break;
    case BleStateMachine.updatingProjectData:
      bleCommand = BleCommandsList.BLE_UPLOAD_PROJECT_DATA_CMD.value;
      break;
    case BleStateMachine.updatingBuildStateData:
      bleCommand = BleCommandsList.BLE_UPLOAD_PROJECT_DATA_CMD.value;
      break;
    default:
  }

  List<int> frame = frameDataPacket(
    bleCommand: bleCommand,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );
  return encryptedDataPacket;
}

Uint8List generateEncryptionKeyDataPacket() {
  Logger('========================================');
  Logger('TX/RX Logs - STEP 1: REQUEST ENCRYPTION KEY (TX)');
  Logger('========================================');

  Uint8List frameBuffer = Uint8List(1 + BLE_FRAME_FILED_SIZE);
  Uint8List responseData = hexStringToUint8List("00");

  bleFrameTheTxPkt(
    BleCommandsList.BLE_ENCRY_REQ_KEY_CMD.value,
    KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    0x01,
    responseData,
    frameBuffer,
  );

  String txHex = frameBuffer
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String txAscii = _bytesToAscii(frameBuffer);
  Logger('TX/RX Logs - Non-encrypted TX Data (${frameBuffer.length} bytes):');
  Logger('TX/RX Logs - Hex: $txHex');
  Logger('TX/RX Logs - ASCII: $txAscii');
  Logger(
    'TX/RX Logs - Command: 0x${BleCommandsList.BLE_ENCRY_REQ_KEY_CMD.value.toRadixString(16).padLeft(4, '0')}',
  );
  Logger('TX/RX Logs - Frame Type: Request Frame (0x01)');
  Logger('TX/RX Logs - ========================================\n');

  return frameBuffer;
}

List<int> ledToggleFrame() {
  Uint8List dataFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_REQUEST_DATA_BYTE,
    CONNECTION_REQUEST_FRAME_TYPE_BYTE,
    0x00,
    0x01,
    0x00,
    0x12,
    0x34,
    END_OF_FRAME_FIRST_BYTE,
    END_OF_FRAME_SECOND_BYTE,
  ]);
  return dataFrame;
}
