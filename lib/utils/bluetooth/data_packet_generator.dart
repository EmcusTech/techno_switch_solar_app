library;

import 'dart:typed_data';

import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
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

Future<Uint8List> passKeyRequestFrame() async {
  Uint8List dataFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_BYTE,
    CONNECTION_REQUEST_FRAME_TYPE_BYTE,
    0x00,
    0x01,
    0x00,
  ]);

  int calculatedCRC = convertCrc16(dataFrame);
  Logger(
    "Calculated CRC: $calculatedCRC ; ${calculatedCRC.toRadixString(16).toUpperCase()}",
  );
  Logger("::::::Requesting connection ::::::::::::");
  List<int> newList = dataFrame.toList();
  newList.addAll(intToBytesBigEndian(calculatedCRC));
  newList.add(END_OF_FRAME_FIRST_BYTE);
  newList.add(END_OF_FRAME_SECOND_BYTE);
  Logger(newList.toString());
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: newList,
  );
  return encryptedDataPacket;
}

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

Uint8List _buildOriginalTechnoswitchDummyPacketFrame(
  int pktTxCnt,
  int pktRxCnt,
  int logEvtSearchNumber,
) {
  const int frameSot = 0xFE;
  const int frameEot = 0xFD;
  const int scriptOrig = 0;
  const int scriptDest = 1;
  const int packetTypeNrm = 1;

  const int logNw = 5;
  const int logNd = 0;
  const int logSnd = 0;
  const int logMo = 0;
  const int logMd = 2;
  const int logSk = 5;
  const int logCmd = 2;
  const int logEvtSearchMethod = 0x04;

  List<int> frameBuffer = List.filled(216, 0);

  frameBuffer[0] = frameSot;
  frameBuffer[1] = scriptDest;
  frameBuffer[2] = scriptOrig;
  frameBuffer[3] = packetTypeNrm;
  frameBuffer[4] = pktTxCnt & 0xFF;
  frameBuffer[5] = pktRxCnt & 0xFF;
  frameBuffer[6] = logNw;
  frameBuffer[7] = logNd;
  frameBuffer[8] = logSnd;
  frameBuffer[9] = logMo;
  frameBuffer[10] = logMd;
  frameBuffer[11] = logSk;
  frameBuffer[12] = logCmd;
  frameBuffer[13] = logEvtSearchMethod;
  frameBuffer[14] = (logEvtSearchNumber >> 24) & 0xFF;
  frameBuffer[15] = (logEvtSearchNumber >> 16) & 0xFF;
  frameBuffer[16] = (logEvtSearchNumber >> 8) & 0xFF;
  frameBuffer[17] = logEvtSearchNumber & 0xFF;

  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));

  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  frameBuffer[215] = frameEot;

  return Uint8List.fromList([
    0xfe,
    0x01,
    0x00,
    0x01,
    0x02,
    0x01,
    0x00,
    0x00,
    0x00,
    0x00,
    0x02,
    0x00,
    0x02,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x04,
    0x00,
    0x00,
    0x03,
    0xe7,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xc8,
    0x40,
    0xfd,
  ]);
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

Future<Uint8List> dummyPacketFrame({
  int pktTxCnt = 0,
  int pktRxCnt = 0,
  int logEvtSearchNumber = 999,
}) async {
  Logger('========================================');
  Logger('TX/RX Logs - STEP 9: SEND DUMMY PACKET (TX)');
  Logger('========================================');
  Logger(
    'dummy packet frame <<===========Building nested frame for dummy packet===========>>',
  );

  Uint8List originalFrame = _buildOriginalTechnoswitchDummyPacketFrame(
    pktTxCnt,
    pktRxCnt,
    logEvtSearchNumber,
  );

  Logger(
    'dummy packet frame <<===========Original Technoswitch Frame (${originalFrame.length} bytes) built===========>>',
  );

  String originalFrameHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String originalFrameAscii = _bytesToAscii(originalFrame);
  Logger(
    'TX/RX Logs - Original Technoswitch Frame (${originalFrame.length} bytes):',
  );
  Logger('TX/RX Logs - Hex: $originalFrameHex');
  Logger('TX/RX Logs - ASCII: $originalFrameAscii');
  Logger('TX/RX Logs - Packet Type: NRM (0x01)');
  Logger('TX/RX Logs - Mode: 2, Command: 2 (Event Log)');
  Logger('TX/RX Logs - Event Log Search Number: $logEvtSearchNumber');
  Logger('TX/RX Logs - TX Counter: $pktTxCnt, RX Counter: $pktRxCnt');

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

  Logger(
    'dummy packet frame <<===========New BLE Frame header + payload (${newBleFrame.length} bytes)===========>>',
  );

  String txHex = newBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String txAscii = _bytesToAscii(newBleFrame);
  Logger('TX/RX Logs - Non-encrypted TX Data (${newBleFrame.length} bytes):');
  Logger('TX/RX Logs - Hex: $txHex');
  Logger('TX/RX Logs - ASCII: $txAscii');
  Logger(
    'TX/RX Logs - Command: 0x${BleCommandsList.BLE_PASSKEY_REQ_CMD.value.toRadixString(16).padLeft(4, '0')}',
  );
  Logger('TX/RX Logs - Frame Type: Small Data Frame (0x02)');
  Logger(
    'TX/RX Logs - Payload Length: 216 bytes (Original Technoswitch Frame)',
  );

  int calculatedCRC = convertCrc16(newBleFrame);
  Logger(
    "dummy packet frame <<===========Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})===========>>",
  );

  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE);
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE);

  Logger(
    'dummy packet frame <<===========Complete New BLE Frame (${completeBleFrame.length} bytes) before encryption===========>>',
  );

  String completeBleFrameHex = completeBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String completeBleFrameAscii = _bytesToAscii(completeBleFrame);
  Logger(
    'TX/RX Logs - Complete Non-encrypted BLE Frame (${completeBleFrame.length} bytes):',
  );
  Logger('TX/RX Logs - Hex: $completeBleFrameHex');
  Logger('TX/RX Logs - ASCII: $completeBleFrameAscii');
  Logger(
    'TX/RX Logs - Command: 0x${BleCommandsList.BLE_PASSKEY_REQ_CMD.value.toRadixString(16).padLeft(4, '0')}',
  );
  Logger('TX/RX Logs - Frame Type: Small Data Frame (0x02)');
  Logger(
    'TX/RX Logs - Payload Length: 216 bytes (Original Technoswitch Frame)',
  );
  Logger('TX/RX Logs - ========================================\n');

  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  Logger(
    'dummy packet frame <<===========Encrypted BLE Frame (${encryptedDataPacket.length} bytes) ready for transmission===========>>',
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

Future<Map<String, dynamic>> testControlResEventReportFrameGeneration({
  int pktTxCnt = 1,
  int pktRxCnt = 0,
  int network = 5,
  int node = 0,
  int subnode = 0,
  int module = 0,
  int eventBufferMask = 3,
  int eventBufferMode = 0,
}) async {
  Logger('========================================');
  Logger('TESTING CONTROL_RES_EVENT_REPORT FRAME GENERATION');
  Logger('Parameters:');
  Logger('  pktTxCnt: $pktTxCnt');
  Logger('  pktRxCnt: $pktRxCnt');
  Logger('  network: $network');
  Logger('  node: $node');
  Logger('  subnode: $subnode');
  Logger('  module: $module');
  Logger('  eventBufferMask: $eventBufferMask');
  Logger('  eventBufferMode: $eventBufferMode');
  Logger('========================================\n');
  Logger('--- STAGE 1: Original Technoswitch Frame (216 bytes) ---');
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

  Logger('Original Frame Length: ${originalFrame.length} bytes');
  Logger('Original Frame (Hex):');
  String originalHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(originalHex);
  Logger('\nOriginal Frame Breakdown:');
  Logger(
    '  [0] SOT: 0x${originalFrame[0].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [1] dest: 0x${originalFrame[1].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [2] origin: 0x${originalFrame[2].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [3] pktTyp: 0x${originalFrame[3].toRadixString(16).toUpperCase().padLeft(2, '0')} (NRM=1)',
  );
  Logger(
    '  [4] txp: 0x${originalFrame[4].toRadixString(16).toUpperCase().padLeft(2, '0')} ($pktTxCnt)',
  );
  Logger(
    '  [5] rxp: 0x${originalFrame[5].toRadixString(16).toUpperCase().padLeft(2, '0')} ($pktRxCnt)',
  );
  Logger(
    '  [6] network: 0x${originalFrame[6].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [7] node: 0x${originalFrame[7].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [8] subnode: 0x${originalFrame[8].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [9] module: 0x${originalFrame[9].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [10] mode: 0x${originalFrame[10].toRadixString(16).toUpperCase().padLeft(2, '0')} (0x83)',
  );
  Logger(
    '  [11] socket: 0x${originalFrame[11].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [12] command: 0x${originalFrame[12].toRadixString(16).toUpperCase().padLeft(2, '0')} (0x0B = CONTROL_RES_EVENT_REPORT)',
  );
  Logger(
    '  [13] eventBufferMask: 0x${originalFrame[13].toRadixString(16).toUpperCase().padLeft(2, '0')} ($eventBufferMask)',
  );
  Logger(
    '  [14] eventBufferMode: 0x${originalFrame[14].toRadixString(16).toUpperCase().padLeft(2, '0')} ($eventBufferMode)',
  );
  Logger(
    '  [213-214] CRC: 0x${originalFrame[213].toRadixString(16).toUpperCase().padLeft(2, '0')}${originalFrame[214].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [215] EOT: 0x${originalFrame[215].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );

  Logger('\n--- STAGE 2: BLE Frame Wrapper (before encryption) ---');
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

  Logger('BLE Frame Length (before CRC/EOF): ${newBleFrame.length} bytes');
  Logger('BLE Frame (Hex):');
  String bleFrameHex = newBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(bleFrameHex);
  Logger('\nBLE Frame Breakdown:');
  Logger(
    '  [0-1] SOF: 0x${newBleFrame[0].toRadixString(16).toUpperCase().padLeft(2, '0')}${newBleFrame[1].toRadixString(16).toUpperCase().padLeft(2, '0')} (0xAA55)',
  );
  Logger(
    '  [2-3] CMD: 0x${newBleFrame[2].toRadixString(16).toUpperCase().padLeft(2, '0')}${newBleFrame[3].toRadixString(16).toUpperCase().padLeft(2, '0')} (0x${BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value.toRadixString(16).padLeft(4, '0').toUpperCase()})',
  );
  Logger(
    '  [4] TOF: 0x${newBleFrame[4].toRadixString(16).toUpperCase().padLeft(2, '0')} (0x02 = Small Data Frame)',
  );
  Logger(
    '  [5-6] PAYLOAD LEN: 0x${newBleFrame[5].toRadixString(16).toUpperCase().padLeft(2, '0')}${newBleFrame[6].toRadixString(16).toUpperCase().padLeft(2, '0')} ($originalFrameLength bytes)',
  );
  Logger('  [7-222] PAYLOAD: Original Technoswitch Frame (216 bytes)');

  Logger('\n--- STAGE 3: CRC Calculation ---');
  int calculatedCRC = convertCrc16(newBleFrame);
  Logger(
    'Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})',
  );

  Logger('\n--- STAGE 4: Complete BLE Frame (before encryption) ---');
  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE);
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE);

  Logger('Complete BLE Frame Length: ${completeBleFrame.length} bytes');
  Logger('Complete BLE Frame (Hex):');
  String completeHex = completeBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(completeHex);
  Logger('\nComplete BLE Frame Breakdown:');
  Logger('  [0-1] SOF: 0xAA55');
  Logger(
    '  [2-3] CMD: 0x${BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value.toRadixString(16).padLeft(4, '0').toUpperCase()}',
  );
  Logger('  [4] TOF: 0x02');
  Logger('  [5-6] PAYLOAD LEN: 216 bytes');
  Logger('  [7-222] PAYLOAD: Original Technoswitch Frame');
  Logger(
    '  [223-224] CRC: 0x${completeBleFrame[223].toRadixString(16).toUpperCase().padLeft(2, '0')}${completeBleFrame[224].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [225-226] EOF: 0x${completeBleFrame[225].toRadixString(16).toUpperCase().padLeft(2, '0')}${completeBleFrame[226].toRadixString(16).toUpperCase().padLeft(2, '0')} (0xEEBB)',
  );

  Logger('\n--- STAGE 5: Encrypted Frame (final, ready for transmission) ---');
  Uint8List encryptedFrame = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  Logger('Encrypted Frame Length: ${encryptedFrame.length} bytes');
  Logger('Encrypted Frame (Hex):');
  String encryptedHex = encryptedFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(encryptedHex);
  Logger('\nEncrypted Frame (Hex, no spaces):');
  Logger(
    encryptedFrame
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join(''),
  );

  Logger('\n========================================');
  Logger('FRAME GENERATION COMPLETE');
  Logger('========================================\n');

  return {
    'originalFrame': originalFrame,
    'bleFrame': newBleFrame,
    'completeBleFrame': completeBleFrame,
    'encryptedFrame': encryptedFrame,
    'crc': calculatedCRC,
  };
}

Future<Map<String, dynamic>> testPasskeyFrameGeneration(String passkey) async {
  Logger('========================================');
  Logger('TESTING PASSKEY FRAME GENERATION');
  Logger('Input Passkey: "$passkey"');
  Logger('========================================\n');
  Logger('--- STAGE 1: Original Technoswitch Frame ---');
  int pktTxCnt = 0;
  int pktRxCnt = 0;
  Uint8List originalFrame = _buildOriginalTechnoswitchPasskeyFrame(
    passkey,
    pktTxCnt,
    pktRxCnt,
  );

  Logger('Original Frame Length: ${originalFrame.length} bytes');
  Logger('Original Frame (Hex):');
  String originalHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(originalHex);
  Logger('\nOriginal Frame Breakdown:');
  Logger(
    '  [0] SOT: 0x${originalFrame[0].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [1] dest: 0x${originalFrame[1].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [2] origin: 0x${originalFrame[2].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [3] pktTyp: 0x${originalFrame[3].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [4] txp: 0x${originalFrame[4].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '  [5] rxp: 0x${originalFrame[5].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger('  [6-12] Payload Header:');
  for (int i = 6; i <= 12; i++) {
    Logger(
      '    [$i] 0x${originalFrame[i].toRadixString(16).toUpperCase().padLeft(2, '0')}',
    );
  }
  Logger('  [13-212] Payload Data (first 20 bytes):');
  String payloadPreview = originalFrame
      .sublist(13, 13 + (passkey.length < 20 ? passkey.length : 20))
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger('    $payloadPreview');
  Logger('  [213-214] CRC (Fletcher):');
  Logger(
    '    [213] MSB: 0x${originalFrame[213].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger(
    '    [214] LSB: 0x${originalFrame[214].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  int fletcherCrc = (originalFrame[213] << 8) | originalFrame[214];
  Logger(
    '    CRC Value: 0x${fletcherCrc.toRadixString(16).toUpperCase().padLeft(4, '0')}',
  );
  Logger(
    '  [215] EOT: 0x${originalFrame[215].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger('');

  Logger('--- STAGE 2: New BLE Frame (Header + Payload) ---');
  int originalFrameLength = originalFrame.length;
  Uint8List newBleFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE, // 0xAA
    PREAMBLE_SECOND_BYTE, // 0x55
    (BleCommandsList.BLE_PASSKEY_REQ_CMD.value >> 8) & 0xFF,
    BleCommandsList.BLE_PASSKEY_REQ_CMD.value & 0xFF,
    DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
    (originalFrameLength >> 8) & 0xFF,
    originalFrameLength & 0xFF,
    ...originalFrame,
  ]);

  Logger('New BLE Frame Length: ${newBleFrame.length} bytes');
  Logger('New BLE Frame (Hex - first 50 bytes):');
  String newBleHex = newBleFrame
      .sublist(0, newBleFrame.length > 50 ? 50 : newBleFrame.length)
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(newBleHex + (newBleFrame.length > 50 ? '...' : ''));
  Logger('\nNew BLE Frame Breakdown:');
  Logger(
    '  [0-1] SOF: 0x${newBleFrame[0].toRadixString(16).toUpperCase().padLeft(2, '0')} 0x${newBleFrame[1].toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  int cmdValue = (newBleFrame[2] << 8) | newBleFrame[3];
  Logger(
    '  [2-3] CMD: 0x${cmdValue.toRadixString(16).toUpperCase().padLeft(4, '0')}',
  );
  Logger(
    '  [4] TOF: 0x${newBleFrame[4].toRadixString(16).toUpperCase().padLeft(2, '0')} (Small Data Frame)',
  );
  int payloadLen = (newBleFrame[5] << 8) | newBleFrame[6];
  Logger(
    '  [5-6] PAYLOAD LEN: 0x${payloadLen.toRadixString(16).toUpperCase().padLeft(4, '0')} ($payloadLen bytes)',
  );
  Logger('  [7-222] PAYLOAD (Original Frame): [216 bytes - see Stage 1]');
  Logger('');

  Logger('--- STAGE 3: CRC-16 Calculation ---');
  int calculatedCRC = convertCrc16(newBleFrame);
  Logger('CRC-16 Input: SOF to end of PAYLOAD (${newBleFrame.length} bytes)');
  Logger(
    'CRC-16 Value: 0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')} ($calculatedCRC)',
  );
  Logger(
    'CRC-16 Bytes: MSB=0x${(calculatedCRC >> 8).toRadixString(16).toUpperCase().padLeft(2, '0')}, LSB=0x${(calculatedCRC & 0xFF).toRadixString(16).toUpperCase().padLeft(2, '0')}',
  );
  Logger('');

  Logger('--- STAGE 4: Complete BLE Frame (Before Encryption) ---');
  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

  Logger('Complete Frame Length: ${completeBleFrame.length} bytes');
  Logger('Complete Frame Structure:');
  Logger('  SOF: 2 bytes');
  Logger('  CMD: 2 bytes');
  Logger('  TOF: 1 byte');
  Logger('  PAYLOAD LEN: 2 bytes');
  Logger('  PAYLOAD: $originalFrameLength bytes');
  Logger('  CRC: 2 bytes');
  Logger('  EOF: 2 bytes');
  Logger('  Total: ${completeBleFrame.length} bytes');
  Logger('\nComplete Frame (Hex - first 30 and last 10 bytes):');
  String completeHexStart = completeBleFrame
      .sublist(0, 30)
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String completeHexEnd = completeBleFrame
      .sublist(completeBleFrame.length - 10)
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger('  Start: $completeHexStart...');
  Logger('  End: ...$completeHexEnd');
  Logger('');

  Logger('--- STAGE 5: Encrypted Frame ---');
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  Logger('Encrypted Frame Length: ${encryptedDataPacket.length} bytes');
  Logger('Encrypted Frame (Hex - first 30 bytes):');
  String encryptedHex = encryptedDataPacket
      .sublist(0, encryptedDataPacket.length)
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  Logger(encryptedHex);
  Logger('');

  Logger('========================================');
  Logger('FRAME GENERATION COMPLETE');
  Logger('========================================\n');

  return {
    'passkey': passkey,
    'originalFrame': originalFrame,
    'newBleFrame': newBleFrame,
    'calculatedCRC': calculatedCRC,
    'completeBleFrame': Uint8List.fromList(completeBleFrame),
    'encryptedFrame': encryptedDataPacket,
  };
}

List<int> generateDataPacketFromPayload(String hexPayLoad) {
  List<int> payLoadData = hexToBytes(hexPayLoad);

  String hexLengthByte = calculateLengthByte(hexPayLoad);
  List<int> lengthByte = hexToBytes(hexLengthByte);

  Uint8List dataPacketFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_BYTE,
    DATA_PACKET_FRAME_TYPE_BYTE,
    ...lengthByte,
    ...payLoadData,
  ]);

  int calculatedCRC = convertCrc16(dataPacketFrame);
  List<int> newList = dataPacketFrame.toList();
  newList.addAll(intToBytesBigEndian(calculatedCRC));
  newList.add(END_OF_FRAME_FIRST_BYTE);
  newList.add(END_OF_FRAME_SECOND_BYTE);

  return newList;
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

Future<Uint8List> generateLargeDataPacket(
  List<int> payLoadData, {
  bool isResnding = false,
}) async {
  List<int> frame = <int>[];

  frame = frameDataPacket(
    bleCommand: getLargeDataBleCommandByState(
      Get.find<BleNotifyDataHandler>().currentLargePacketModule.value,
    ),
    typeOfFrame:
        isResnding
            ? KbleTypeOfFrameDef.enBLE_RESEND_RSP_FRAME.value
            : payLoadData.length == 4
            ? KbleTypeOfFrameDef.enOTA_SEQNUM_AFTER_FF_SKIP.value
            : KbleTypeOfFrameDef.enBLE_LARGE_DATA_FRAME.value,
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

Future<List<Uint8List>> generateListOfLargePacketsFromPayload(
  List<int> payload, {
  int sequenceNumber = 1,
  bool isResnding = false,
}) async {
  List<Uint8List> largePacketsList = <Uint8List>[];

  List<List<int>> payLoadChunks = DataHandler().generateChunksForConfigPayload(
    payload,
  );

  Logger("Large Packet Generated :${payLoadChunks.length}");
  for (int i = 0; i < payLoadChunks.length; i++) {
    Logger("Large Packet Generated On ${i + 1} :${payLoadChunks[i].length}");
  }

  for (int i = 0; i < payLoadChunks.length; i++) {
    Uint8List? tempLargeDataPacket;
    if (isResnding && i == sequenceNumber - 1) {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: isResnding,
      );
    } else if (sequenceNumber == 1) {
      tempLargeDataPacket = await generateLargeDataPacket(payLoadChunks[i]);
    } else if (sequenceNumber == -1) {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: i == payLoadChunks.length - 1,
      );
    } else {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: i == sequenceNumber - 1,
      );
    }

    largePacketsList.add(tempLargeDataPacket);
  }
  return largePacketsList;
}

Future<List<Uint8List>> generateListOfWithOutFFLargePacketsFromPayload(
  List<int> payload, {
  int sequenceNumber = 1,
  bool isResending = false,
}) async {
  Logger('=== PACKET LIST GENERATION (Without FF Skipping) ===');
  Logger('Input payload size: ${payload.length} bytes');
  Logger('Sequence number: $sequenceNumber');
  Logger('Is resending: $isResending');

  List<Uint8List> largePacketsList = <Uint8List>[];
  List<List<int>> payLoadChunks = await DataHandler()
      .generateChunksForFirmwareUpgradePayload(payload);

  Logger('Payload chunks created: ${payLoadChunks.length} chunks');
  Logger(
    'Chunk sizes: ${payLoadChunks.map((chunk) => chunk.length).join(', ')} bytes',
  );

  for (int i = 0; i < payLoadChunks.length; i++) {
    Uint8List? tempLargeDataPacket;
    if (isResending && i == sequenceNumber - 1) {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: isResending,
      );
    } else if (sequenceNumber == 1) {
      tempLargeDataPacket = await generateLargeDataPacket(payLoadChunks[i]);
    } else if (sequenceNumber == -1) {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: i == payLoadChunks.length - 1,
      );
    } else {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: i == sequenceNumber - 1,
      );
    }
    largePacketsList.add(tempLargeDataPacket);

    if (i < 3 || i == payLoadChunks.length - 1) {
      Logger('Packet[$i]: ${tempLargeDataPacket.length} bytes');
    }
  }

  Logger('Total packets generated: ${largePacketsList.length}');
  Logger(
    'Total packet data size: ${largePacketsList.fold<int>(0, (sum, packet) => sum + packet.length)} bytes',
  );
  Logger('=== PACKET LIST GENERATION COMPLETE (Without FF Skipping) ===');

  return largePacketsList;
}

Future<List<Uint8List>> generateListOfWithoutSkippingFFLargePacketsFromPayload(
  List<int> payload, {
  int sequenceNumber = 1,
  bool isResending = false,
}) async {
  Logger('=== PACKET LIST GENERATION (Without Skipping FF) ===');
  Logger('Input payload size: ${payload.length} bytes');
  Logger('Sequence number: $sequenceNumber');
  Logger('Is resending: $isResending');

  List<Uint8List> largePacketsList = <Uint8List>[];
  List<List<int>> payLoadChunks = await DataHandler()
      .generateChunksForFirmwareUpgradeWithFullPayload(payload);

  Logger('Payload chunks created: ${payLoadChunks.length} chunks');
  Logger(
    'Chunk sizes: ${payLoadChunks.map((chunk) => chunk.length).join(', ')} bytes',
  );

  for (int i = 0; i < payLoadChunks.length; i++) {
    Logger("Processing chunk $i: ${payLoadChunks[i].length} bytes");
    Uint8List tempLargeDataPacket;

    if (isResending && i == sequenceNumber - 1) {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: true,
      );
    } else if (sequenceNumber == 1) {
      tempLargeDataPacket = await generateLargeDataPacket(payLoadChunks[i]);
    } else if (sequenceNumber == -1) {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: i == payLoadChunks.length - 1,
      );
    } else {
      tempLargeDataPacket = await generateLargeDataPacket(
        payLoadChunks[i],
        isResnding: i == sequenceNumber - 1,
      );
    }

    largePacketsList.add(tempLargeDataPacket);

    if (i < 3 || i == payLoadChunks.length - 1) {
      Logger('Packet[$i] generated: ${tempLargeDataPacket.length} bytes');
    }
  }

  Logger('Total packets generated: ${largePacketsList.length}');
  Logger(
    'Total packet data size: ${largePacketsList.fold<int>(0, (sum, packet) => sum + packet.length)} bytes',
  );
  Logger('=== PACKET LIST GENERATION COMPLETE (Without Skipping FF) ===');

  return largePacketsList;
}

Future<Uint8List> generatePutDeviceToLinkModeDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x04, 6]);
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

Future<Uint8List> generateEmptyDeviceDataPacket(List<int> payLoad) async {
  List<int> payLoadData = payLoad;
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_LARGE_DATA_REQ_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

Future<Uint8List> generateUpdateBleProcessDataPacket() async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x02]);
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

Future<Uint8List> generateUpdatePanelNetworkProcessDataPacket(int index) async {
  Uint8List data = Uint8List.fromList(<int>[0x10, 0x23, index]);
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
