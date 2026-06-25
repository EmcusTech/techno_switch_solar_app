library;

import 'dart:typed_data';

import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

import 'data_helper.dart';

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
