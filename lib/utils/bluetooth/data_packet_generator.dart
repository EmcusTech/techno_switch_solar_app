/*
* Project      : gemini_mobile_app
* File         : data_packet_generator.dart
* Description  : Constants and functions for constructing various communication frames including CRC-16 calculation, payload handling, and frame composition for a BLE communication protocol
* Author       : SrihariharanT
* Date         : 2024-05-20
* Version      : 1.0
* Ticket       :
*/

/// {@category bluetooth}
library;

import 'dart:typed_data';

import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

import 'ble_notify_data_handler.dart';
import 'data_helper.dart';

import 'package:get/get.dart';

/// Converts bytes to ASCII representation (printable chars or dots)
String _bytesToAscii(List<int> bytes) {
  return bytes.map((b) {
    if (b >= 32 && b <= 126) {
      // Printable ASCII characters
      return String.fromCharCode(b);
    } else {
      // Non-printable characters shown as dots
      return '.';
    }
  }).join();
}

///bytes
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

/// Generates a complete data packet frame for a passkey request.
///
/// This function constructs a complete data packet frame for a passkey request,
/// including the preamble bytes, command bytes, frame type byte, payload length,
/// payload (if any), CRC (Cyclic Redundancy Check), and end-of-frame bytes.
///
/// Returns:
///   A list of integers representing the complete data packet frame.
///
Future<Uint8List> passKeyRequestFrame() async {
  Uint8List dataFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_BYTE,
    CONNECTION_REQUEST_FRAME_TYPE_BYTE,
    0x00, 0x01, //PAYLOAD LENGTH
    0x00, // PAYLOAD
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

/// Builds the original Technoswitch frame structure for passkey.
///
/// This creates a 216-byte frame following the original protocol:
/// SOT (0xFE) + dest + origin + pktTyp + txp + rxp + payload header (7 bytes) +
/// payload data (200 bytes) + CRC (2 bytes Fletcher) + EOT (0xFD)
///
/// Parameters:
///   - passkey: The passkey string to embed in the frame
///   - pktTxCnt: Packet transmit counter
///   - pktRxCnt: Packet receive counter
///
/// Returns:
///   A Uint8List representing the complete original Technoswitch frame (216 bytes)
Uint8List _buildOriginalTechnoswitchPasskeyFrame(
  String passkey,
  int pktTxCnt,
  int pktRxCnt,
) {
  // Original frame constants from serial_communication_service.dart
  const int frameSot = 0xFE;
  const int frameEot = 0xFD;
  const int scriptOrig = 0;
  const int scriptDest = 1;
  const int packetTypeNrm = 1; // NRM packet type

  // Payload header values (similar to access key request)
  const int logNw = 0;
  const int logNd = 0;
  const int logSnd = 0;
  const int logMo = 0;
  const int logMd = 0x83; // Mode 0 (reverted from 2)
  const int logSk = 0;
  const int logCmd = 0x04; // Command for passkey/access key

  // Build 216-byte frame buffer
  List<int> frameBuffer = List.filled(216, 0);

  // SOT
  frameBuffer[0] = frameSot;
  // dest
  frameBuffer[1] = scriptDest;
  // origin
  frameBuffer[2] = scriptOrig;
  // pktTyp (NRM = 1)
  frameBuffer[3] = packetTypeNrm;
  // txp
  frameBuffer[4] = pktTxCnt & 0xFF;
  // rxp
  frameBuffer[5] = pktRxCnt & 0xFF;

  // Payload header (7 bytes)
  frameBuffer[6] = logNw; // nwk
  frameBuffer[7] = logNd; // nod
  frameBuffer[8] = logSnd; // subnod
  frameBuffer[9] = logMo; // module
  frameBuffer[10] = logMd; // mode
  frameBuffer[11] = logSk; // sck
  frameBuffer[12] = logCmd;
  frameBuffer[13] = 0x04; // cmd

  // Convert passkey string to bytes and place in payload (starting at offset 13)
  List<int> passkeyBytes = passkey.codeUnits;
  int passkeyLength = passkeyBytes.length < 200 ? passkeyBytes.length : 200;
  for (int i = 0; i < passkeyLength; i++) {
    frameBuffer[14 + i] = passkeyBytes[i];
  }

  // Calculate Fletcher checksum (from SOF to end of payload data, before CRC)
  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));
  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  // EOT
  frameBuffer[215] = frameEot;

  return Uint8List.fromList(frameBuffer);
}

/// Calculates Fletcher checksum for the original Technoswitch frame.
///
/// This matches the _toolsFletcherChecksum implementation from serial_communication_service.dart
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

/// Builds the original Technoswitch frame structure for network packet request.
///
/// This creates a 216-byte frame following the original protocol:
/// SOT (0xFE) + dest + origin + pktTyp (NWK=0x04) + txp + rxp + payload header (7 bytes) +
/// payload data (200 bytes, all zeros) + CRC (2 bytes Fletcher) + EOT (0xFD)
///
/// Parameters:
///   - pktTxCnt: Packet transmit counter
///   - pktRxCnt: Packet receive counter
///
/// Returns:
///   A Uint8List representing the complete original Technoswitch frame (216 bytes)
Uint8List _buildOriginalTechnoswitchNetworkPacketFrame(
  int pktTxCnt,
  int pktRxCnt,
) {
  // Original frame constants from serial_communication_service.dart
  const int frameSot = 0xFE;
  const int frameEot = 0xFD;
  const int scriptOrig = 0;
  const int scriptDest = 1;
  const int packetTypeNwk = 4; // NWK packet type

  // Build 216-byte frame buffer
  List<int> frameBuffer = List.filled(216, 0);

  // SOT
  frameBuffer[0] = frameSot;
  // dest
  frameBuffer[1] = scriptDest;
  // origin
  frameBuffer[2] = scriptOrig;
  // pktTyp (NWK = 4)
  frameBuffer[3] = packetTypeNwk;
  // txp
  frameBuffer[4] = pktTxCnt & 0xFF;
  // rxp
  frameBuffer[5] = pktRxCnt & 0xFF;

  // Payload header (7 bytes) - all zeros for network packet
  frameBuffer[6] = 5; // nwk
  frameBuffer[7] = 0; // nod
  frameBuffer[8] = 0; // subnod
  frameBuffer[9] = 0; // module
  frameBuffer[10] = 0; // mode
  frameBuffer[11] = 5; // sck
  frameBuffer[12] = 0; // cmd

  // Payload data (200 bytes) - all zeros for network packet request
  // Already filled with zeros by List.filled(216, 0)

  // Calculate Fletcher checksum (from SOF to end of payload data, before CRC)
  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));
  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  // EOT
  frameBuffer[215] = frameEot;

  return Uint8List.fromList(frameBuffer);
}

/// Builds the original Technoswitch frame structure for dummy packet.
///
/// This creates a 216-byte frame following the original protocol:
/// SOT (0xFE) + dest + origin + pktTyp (NRM=0x01) + txp + rxp + payload header (7 bytes) +
/// payload data (200 bytes, with event log search data) + CRC (2 bytes Fletcher) + EOT (0xFD)
///
/// Parameters:
///   - pktTxCnt: Packet transmit counter
///   - pktRxCnt: Packet receive counter
///   - logEvtSearchNumber: Event log search number (default: 999)
///
/// Returns:
///   A Uint8List representing the complete original Technoswitch frame (216 bytes)
Uint8List _buildOriginalTechnoswitchDummyPacketFrame(
  int pktTxCnt,
  int pktRxCnt,
  int logEvtSearchNumber,
) {
  // Original frame constants from serial_communication_service.dart
  const int frameSot = 0xFE;
  const int frameEot = 0xFD;
  const int scriptOrig = 0;
  const int scriptDest = 1;
  const int packetTypeNrm = 1; // NRM packet type

  // Payload header values (from old way: logNw=0, logNd=0, logSnd=0, logMo=0, logMd=2, logSk=0, logCmd=2)
  const int logNw = 5; // Changed to 5 to match other frames
  const int logNd = 0;
  const int logSnd = 0;
  const int logMo = 0;
  const int logMd = 2; // Mode 2 for event log
  const int logSk = 5; // Changed to 5 to match other frames
  const int logCmd = 2; // Command 2 for event log
  const int logEvtSearchMethod = 0x04;

  // Build 216-byte frame buffer
  List<int> frameBuffer = List.filled(216, 0);

  // SOT
  frameBuffer[0] = frameSot;
  // dest
  frameBuffer[1] = scriptDest;
  // origin
  frameBuffer[2] = scriptOrig;
  // pktTyp (NRM = 1)
  frameBuffer[3] = packetTypeNrm;
  // txp
  frameBuffer[4] = pktTxCnt & 0xFF;
  // rxp
  frameBuffer[5] = pktRxCnt & 0xFF;

  // Payload header (7 bytes)
  frameBuffer[6] = logNw; // nwk
  frameBuffer[7] = logNd; // nod
  frameBuffer[8] = logSnd; // subnod
  frameBuffer[9] = logMo; // module
  frameBuffer[10] = logMd; // mode
  frameBuffer[11] = logSk; // sck
  frameBuffer[12] = logCmd; // cmd

  // Payload data: event log search method + search number (5 bytes total)
  frameBuffer[13] = logEvtSearchMethod;
  frameBuffer[14] = (logEvtSearchNumber >> 24) & 0xFF;
  frameBuffer[15] = (logEvtSearchNumber >> 16) & 0xFF;
  frameBuffer[16] = (logEvtSearchNumber >> 8) & 0xFF;
  frameBuffer[17] = logEvtSearchNumber & 0xFF;

  // Rest of payload (200 bytes) remains zeros

  // Calculate Fletcher checksum (from SOF to end of payload data, before CRC)
  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));
  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  // EOT
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

/// Constructs a frame for sending a network packet request to a BLE device.
///
/// This function uses a nested frame structure:
/// 1. Builds the original Technoswitch frame (216 bytes) for network packet request
/// 2. Wraps it in the new BLE format (SOF, CMD, TOF, PAYLOAD LEN, PAYLOAD (original frame), CRC, EOF)
/// 3. Encrypts the entire new BLE frame
///
/// Parameters:
///   - pktTxCnt: Packet transmit counter
///   - pktRxCnt: Packet receive counter
///
/// Returns:
///   A Uint8List representing the encrypted BLE frame ready for transmission
Future<Uint8List> networkPacketFrame({
  int pktTxCnt = 0,
  int pktRxCnt = 0,
}) async {
  Logger('========================================');
  Logger('TX/RX Logs - STEP 5: SEND NETWORK PACKET (TX)');
  Logger('========================================');
  Logger(
    'network packet frame <<===========Building nested frame for network packet request===========>>',
  );

  // Step 1: Build the original Technoswitch frame (216 bytes)
  Uint8List originalFrame = _buildOriginalTechnoswitchNetworkPacketFrame(
    pktTxCnt,
    pktRxCnt,
  );

  Logger(
    'network packet frame <<===========Original Technoswitch Frame (${originalFrame.length} bytes) built===========>>',
  );

  // Log original Technoswitch frame
  String originalFrameHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String originalFrameAscii = _bytesToAscii(originalFrame);
  Logger(
    'TX/RX Logs - Original Technoswitch Frame (${originalFrame.length} bytes):',
  );
  Logger('TX/RX Logs - Hex: $originalFrameHex');
  Logger('TX/RX Logs - ASCII: $originalFrameAscii');
  Logger('TX/RX Logs - Packet Type: NWK (0x04)');
  Logger('TX/RX Logs - TX Counter: $pktTxCnt, RX Counter: $pktRxCnt');

  // Step 2: Wrap the original frame in the new BLE format
  // New BLE Format: SOF (2) + CMD (2) + TOF (1) + PAYLOAD LEN (2) + PAYLOAD (216) + CRC (2) + EOF (2)
  // Using BLE_PASSKEY_REQ_CMD as placeholder - may need to be changed to a specific network packet command
  int originalFrameLength = originalFrame.length; // 216 bytes

  // Build new BLE frame header
  Uint8List newBleFrame = Uint8List.fromList(<int>[
    // SOF
    PREAMBLE_FIRST_BYTE, // 0xAA
    PREAMBLE_SECOND_BYTE, // 0x55
    // CMD (using passkey command as placeholder - TODO: verify correct command)
    (BleCommandsList.BLE_PASSKEY_REQ_CMD.value >> 8) & 0xFF, // MSB
    BleCommandsList.BLE_PASSKEY_REQ_CMD.value & 0xFF, // LSB
    // TOF (Small Data Frame: 0x02)
    DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
    // PAYLOAD LEN (2 bytes, big-endian)
    (originalFrameLength >> 8) & 0xFF, // MSB
    originalFrameLength & 0xFF, // LSB
    // PAYLOAD (original Technoswitch frame)
    ...originalFrame,
  ]);

  Logger(
    'network packet frame <<===========New BLE Frame header + payload (${newBleFrame.length} bytes)===========>>',
  );

  // Step 3: Calculate CRC-16 for new BLE frame (from SOF to end of PAYLOAD)
  int calculatedCRC = convertCrc16(newBleFrame);
  Logger(
    "network packet frame <<===========Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})===========>>",
  );

  // Step 4: Add CRC and EOF to new BLE frame
  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

  Logger(
    'network packet frame <<===========Complete New BLE Frame (${completeBleFrame.length} bytes) before encryption===========>>',
  );

  // Log complete non-encrypted BLE frame (before encryption)
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

  // Step 5: Encrypt the entire new BLE frame
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  Logger(
    'network packet frame <<===========Encrypted BLE Frame (${encryptedDataPacket.length} bytes) ready for transmission===========>>',
  );

  return encryptedDataPacket;
}

/// Constructs a frame for sending a passkey to a BLE device.
///
/// This function now uses a nested frame structure:
/// 1. Builds the original Technoswitch frame (216 bytes) containing the passkey
/// 2. Wraps it in the new BLE format (SOF, CMD, TOF, PAYLOAD LEN, PAYLOAD (original frame), CRC, EOF)
/// 3. Encrypts the entire new BLE frame
///
/// Parameters:
///   - hexPayLoad: The passkey string to send
///
/// Returns:
///   A Uint8List representing the encrypted BLE frame ready for transmission
Future<Uint8List> passKeyFrame(String hexPayLoad) async {
  Logger('========================================');
  Logger('TX/RX Logs - STEP 7: SEND PASSKEY (TX)');
  Logger('========================================');
  Logger(
    'passkey frame <<===========Building nested frame for passkey: $hexPayLoad===========>>',
  );

  // Step 1: Build the original Technoswitch frame (216 bytes)
  // Using default packet counters (can be adjusted if needed)
  int pktTxCnt = 0;
  int pktRxCnt = 0;
  Uint8List originalFrame = _buildOriginalTechnoswitchPasskeyFrame(
    hexPayLoad,
    pktTxCnt,
    pktRxCnt,
  );

  Logger(
    'passkey frame <<===========Original Technoswitch Frame (${originalFrame.length} bytes) built===========>>',
  );

  // Log original Technoswitch frame
  String originalFrameHex = originalFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String originalFrameAscii = _bytesToAscii(originalFrame);
  Logger(
    'TX/RX Logs - Original Technoswitch Frame (${originalFrame.length} bytes):',
  );
  Logger('TX/RX Logs - Hex: $originalFrameHex');
  Logger('TX/RX Logs - ASCII: $originalFrameAscii');
  Logger('TX/RX Logs - Passkey Value: "$hexPayLoad"');
  Logger('TX/RX Logs - Packet Type: NRM (0x01)');
  Logger('TX/RX Logs - TX Counter: $pktTxCnt, RX Counter: $pktRxCnt');

  // Step 2: Wrap the original frame in the new BLE format
  // New BLE Format: SOF (2) + CMD (2) + TOF (1) + PAYLOAD LEN (2) + PAYLOAD (216) + CRC (2) + EOF (2)
  int originalFrameLength = originalFrame.length; // 216 bytes

  // Build new BLE frame header
  Uint8List newBleFrame = Uint8List.fromList(<int>[
    // SOF
    PREAMBLE_FIRST_BYTE, // 0xAA
    PREAMBLE_SECOND_BYTE, // 0x55
    // CMD (passkey command: 0x1001)
    (BleCommandsList.BLE_PASSKEY_REQ_CMD.value >> 8) & 0xFF, // MSB
    BleCommandsList.BLE_PASSKEY_REQ_CMD.value & 0xFF, // LSB
    // TOF (Small Data Frame: 0x02)
    DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
    // PAYLOAD LEN (2 bytes, big-endian)
    (originalFrameLength >> 8) & 0xFF, // MSB
    originalFrameLength & 0xFF, // LSB
    // PAYLOAD (original Technoswitch frame)
    ...originalFrame,
  ]);

  Logger(
    'passkey frame <<===========New BLE Frame header + payload (${newBleFrame.length} bytes)===========>>',
  );

  // Step 3: Calculate CRC-16 for new BLE frame (from SOF to end of PAYLOAD)
  int calculatedCRC = convertCrc16(newBleFrame);
  Logger(
    "passkey frame <<===========Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})===========>>",
  );

  // Step 4: Add CRC and EOF to new BLE frame
  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

  Logger(
    'passkey frame <<===========Complete New BLE Frame (${completeBleFrame.length} bytes) before encryption===========>>',
  );

  // Log complete non-encrypted BLE frame (before encryption)
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

  // Step 5: Encrypt the entire new BLE frame
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  Logger(
    'passkey frame <<===========Encrypted BLE Frame (${encryptedDataPacket.length} bytes) ready for transmission===========>>',
  );

  return encryptedDataPacket;
}

/// Request for dummy packet using nested frame structure.
///
/// This function builds a dummy packet following the old Technoswitch protocol,
/// wraps it in the new BLE format, and encrypts it.
///
/// Parameters:
///   - pktTxCnt: Packet transmit counter
///   - pktRxCnt: Packet receive counter
///   - logEvtSearchNumber: Event log search number (default: 999)
///
/// Returns:
///   A Uint8List representing the encrypted BLE frame ready for transmission
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

  // Step 1: Build the original Technoswitch frame (216 bytes)
  Uint8List originalFrame = _buildOriginalTechnoswitchDummyPacketFrame(
    pktTxCnt,
    pktRxCnt,
    logEvtSearchNumber,
  );

  Logger(
    'dummy packet frame <<===========Original Technoswitch Frame (${originalFrame.length} bytes) built===========>>',
  );

  // Log original Technoswitch frame
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

  // Step 2: Wrap the original frame in the new BLE format
  int originalFrameLength = originalFrame.length; // 216 bytes

  // Build new BLE frame header
  Uint8List newBleFrame = Uint8List.fromList(<int>[
    // SOF
    PREAMBLE_FIRST_BYTE, // 0xAA
    PREAMBLE_SECOND_BYTE, // 0x55
    // CMD (using passkey command as placeholder - may need specific command)
    (BleCommandsList.BLE_PASSKEY_REQ_CMD.value >> 8) & 0xFF, // MSB
    BleCommandsList.BLE_PASSKEY_REQ_CMD.value & 0xFF, // LSB
    // TOF (Small Data Frame: 0x02)
    DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
    // PAYLOAD LEN (2 bytes, big-endian)
    (originalFrameLength >> 8) & 0xFF, // MSB
    originalFrameLength & 0xFF, // LSB
    // PAYLOAD (original Technoswitch frame)
    ...originalFrame,
  ]);

  Logger(
    'dummy packet frame <<===========New BLE Frame header + payload (${newBleFrame.length} bytes)===========>>',
  );

  // Log non-encrypted TX data (before encryption)
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

  // Step 3: Calculate CRC-16 for new BLE frame (from SOF to end of PAYLOAD)
  int calculatedCRC = convertCrc16(newBleFrame);
  Logger(
    "dummy packet frame <<===========Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})===========>>",
  );

  // Step 4: Add CRC and EOF to new BLE frame
  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

  Logger(
    'dummy packet frame <<===========Complete New BLE Frame (${completeBleFrame.length} bytes) before encryption===========>>',
  );

  // Log complete non-encrypted BLE frame (before encryption)
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

  // Step 5: Encrypt the entire new BLE frame
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  Logger(
    'dummy packet frame <<===========Encrypted BLE Frame (${encryptedDataPacket.length} bytes) ready for transmission===========>>',
  );

  return encryptedDataPacket;
}

/// Builds the original Technoswitch frame structure for CONTROL_RES_EVENT_REPORT command.
///
/// This creates a 216-byte frame following the original protocol:
/// SOT (0xFE) + dest + origin + pktTyp (NRM=0x01) + txp + rxp + payload header (7 bytes) +
/// payload data (EVENT_BUFFER_MASK, EVENT_BUFFER_MODE) + CRC (2 bytes Fletcher) + EOT (0xFD)
///
/// Parameters:
///   - pktTxCnt: Packet transmit counter
///   - pktRxCnt: Packet receive counter
///   - network: Network value (default: 0)
///   - node: Node value (default: 0)
///   - subnode: Sub-node value (default: 0)
///   - module: Module value (default: 0)
///   - eventBufferMask: Event buffer mask (default: 3 for Radio event printer)
///   - eventBufferMode: Event buffer mode (default: 0 for Start)
///
/// Returns:
///   A Uint8List representing the complete original Technoswitch frame (216 bytes)
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
  // Original frame constants
  const int frameSot = 0xFE;
  const int frameEot = 0xFD;
  const int scriptOrig = 0;
  const int scriptDest = 1;
  const int packetTypeNrm = 1; // NRM packet type

  // Payload header values according to CONTROL_RES_EVENT_REPORT specification
  const int mode = 0x83; // MODE = 0x83
  const int socket = 0; // SOCKET = Reserved (0)
  const int controlResEventReport = 0x0B; // CONTROL_RES_EVENT_REPORT = 0x0B

  // Build 216-byte frame buffer
  List<int> frameBuffer = List.filled(216, 0);

  // Frame header
  frameBuffer[0] = frameSot; // SOT
  frameBuffer[1] = scriptDest; // dest
  frameBuffer[2] = scriptOrig; // origin
  frameBuffer[3] = packetTypeNrm; // pktTyp (NRM = 1)
  frameBuffer[4] = pktTxCnt & 0xFF; // txp
  frameBuffer[5] = pktRxCnt & 0xFF; // rxp

  // Payload header (7 bytes)
  frameBuffer[6] = network & 0xFF; // NETWORK
  frameBuffer[7] = node & 0xFF; // NODE
  frameBuffer[8] = subnode & 0xFF; // SUBNODE
  frameBuffer[9] = module & 0xFF; // MODULE
  frameBuffer[10] = mode; // MODE (0x83)
  frameBuffer[11] = socket; // SOCKET (Reserved, 0)
  frameBuffer[12] = controlResEventReport; // CONTROL_RES_EVENT_REPORT (0x0B)

  // Data payload
  frameBuffer[13] = eventBufferMask & 0xFF; // EVENT_BUFFER_MASK (3)
  frameBuffer[14] = eventBufferMode & 0xFF; // EVENT_BUFFER_MODE (0)

  // Rest of payload (200 bytes) remains zeros (already filled by List.filled(216, 0))

  // Calculate Fletcher checksum (from SOF to end of payload data, before CRC)
  int crc = _calculateFletcherChecksum(frameBuffer.sublist(0, 213));
  frameBuffer[213] = (crc >> 8) & 0xFF;
  frameBuffer[214] = crc & 0xFF;

  // EOT
  frameBuffer[215] = frameEot;

  return Uint8List.fromList(frameBuffer);
}

/// Constructs a frame for sending CONTROL_RES_EVENT_REPORT command to a BLE device.
///
/// This function uses a nested frame structure:
/// 1. Builds the original Technoswitch frame (216 bytes) for CONTROL_RES_EVENT_REPORT
/// 2. Wraps it in the new BLE format (SOF, CMD, TOF, PAYLOAD LEN, PAYLOAD (original frame), CRC, EOF)
/// 3. Encrypts the entire new BLE frame
///
/// Parameters:
///   - pktTxCnt: Packet transmit counter
///   - pktRxCnt: Packet receive counter
///   - network: Network value (default: 0)
///   - node: Node value (default: 0)
///   - subnode: Sub-node value (default: 0)
///   - module: Module value (default: 0)
///   - eventBufferMask: Event buffer mask (default: 3 for Radio event printer)
///   - eventBufferMode: Event buffer mode (default: 0 for Start)
///
/// Returns:
///   A Uint8List representing the encrypted BLE frame ready for transmission
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
  Logger('========================================');
  Logger('TX/RX Logs - CONTROL_RES_EVENT_REPORT: SEND COMMAND (TX)');
  Logger('========================================');
  Logger(
    'control res event report frame <<===========Building nested frame for CONTROL_RES_EVENT_REPORT===========>>',
  );

  // Step 1: Build the original Technoswitch frame (216 bytes)
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

  Logger(
    'control res event report frame <<===========Original Technoswitch Frame (${originalFrame.length} bytes) built===========>>',
  );

  // Log original Technoswitch frame
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
  Logger('TX/RX Logs - Mode: 0x83, Command: 0x0B (CONTROL_RES_EVENT_REPORT)');
  Logger(
    'TX/RX Logs - EVENT_BUFFER_MASK: $eventBufferMask, EVENT_BUFFER_MODE: $eventBufferMode',
  );
  Logger('TX/RX Logs - TX Counter: $pktTxCnt, RX Counter: $pktRxCnt');

  // Step 2: Wrap the original frame in the new BLE format
  int originalFrameLength = originalFrame.length; // 216 bytes

  // Build new BLE frame header
  Uint8List newBleFrame = Uint8List.fromList(<int>[
    // SOF
    PREAMBLE_FIRST_BYTE, // 0xAA
    PREAMBLE_SECOND_BYTE, // 0x55
    // CMD
    (BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value >> 8) & 0xFF, // MSB
    BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value & 0xFF, // LSB
    // TOF (Small Data Frame: 0x02)
    DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
    // PAYLOAD LEN (2 bytes, big-endian)
    (originalFrameLength >> 8) & 0xFF, // MSB
    originalFrameLength & 0xFF, // LSB
    // PAYLOAD (original Technoswitch frame)
    ...originalFrame,
  ]);

  Logger(
    'control res event report frame <<===========New BLE Frame header + payload (${newBleFrame.length} bytes)===========>>',
  );

  // Log non-encrypted TX data (before encryption)
  String txHex = newBleFrame
      .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
      .join(' ');
  String txAscii = _bytesToAscii(newBleFrame);
  Logger('TX/RX Logs - Non-encrypted TX Data (${newBleFrame.length} bytes):');
  Logger('TX/RX Logs - Hex: $txHex');
  Logger('TX/RX Logs - ASCII: $txAscii');
  Logger(
    'TX/RX Logs - Command: 0x${BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value.toRadixString(16).padLeft(4, '0')}',
  );
  Logger('TX/RX Logs - Frame Type: Small Data Frame (0x02)');
  Logger('TX/RX Logs - Payload Length: $originalFrameLength bytes');

  // Step 3: Calculate CRC-16 for new BLE frame (from SOF to end of PAYLOAD)
  int calculatedCRC = convertCrc16(newBleFrame);
  Logger(
    "control res event report frame <<===========Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})===========>>",
  );

  // Step 4: Add CRC and EOF to new BLE frame
  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

  Logger(
    'control res event report frame <<===========Complete New BLE Frame (${completeBleFrame.length} bytes) before encryption===========>>',
  );

  // Log complete non-encrypted BLE frame (before encryption)
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
    'TX/RX Logs - Command: 0x${BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value.toRadixString(16).padLeft(4, '0')}',
  );
  Logger('TX/RX Logs - Frame Type: Small Data Frame (0x02)');
  Logger(
    'TX/RX Logs - Payload Length: 216 bytes (Original Technoswitch Frame)',
  );
  Logger('TX/RX Logs - ========================================\n');

  // Step 5: Encrypt the entire new BLE frame
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: completeBleFrame,
  );

  Logger(
    'control res event report frame <<===========Encrypted BLE Frame (${encryptedDataPacket.length} bytes) ready for transmission===========>>',
  );

  return encryptedDataPacket;
}

/// Test function to visualize CONTROL_RES_EVENT_REPORT frame generation at each stage.
///
/// This function generates the CONTROL_RES_EVENT_REPORT frame and prints detailed output
/// at each stage of the nested frame construction process.
///
/// Parameters:
///   - pktTxCnt: Packet transmit counter (default: 1)
///   - pktRxCnt: Packet receive counter (default: 0)
///   - eventBufferMask: Event buffer mask (default: 3 for Radio event printer)
///   - eventBufferMode: Event buffer mode (default: 0 for Start)
///
/// Returns:
///   A map containing all intermediate frames for inspection
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

  // Step 1: Build original Technoswitch frame
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

  // Step 2: Build BLE frame wrapper
  Logger('\n--- STAGE 2: BLE Frame Wrapper (before encryption) ---');
  int originalFrameLength = originalFrame.length; // 216 bytes

  Uint8List newBleFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE, // 0xAA
    PREAMBLE_SECOND_BYTE, // 0x55
    // CMD
    (BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value >> 8) & 0xFF, // MSB
    BleCommandsList.BLE_CONTROL_RES_EVENT_REPORT_CMD.value & 0xFF, // LSB
    // TOF (Small Data Frame: 0x02)
    DATA_PACKET_FRAME_TYPE_BYTE, // 0x02
    // PAYLOAD LEN (2 bytes, big-endian)
    (originalFrameLength >> 8) & 0xFF, // MSB
    originalFrameLength & 0xFF, // LSB
    // PAYLOAD (original Technoswitch frame)
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
    '  [5-6] PAYLOAD LEN: 0x${newBleFrame[5].toRadixString(16).toUpperCase().padLeft(2, '0')}${newBleFrame[6].toRadixString(16).toUpperCase().padLeft(2, '0')} (${originalFrameLength} bytes)',
  );
  Logger('  [7-222] PAYLOAD: Original Technoswitch Frame (216 bytes)');

  // Step 3: Calculate CRC
  Logger('\n--- STAGE 3: CRC Calculation ---');
  int calculatedCRC = convertCrc16(newBleFrame);
  Logger(
    'Calculated CRC: $calculatedCRC (0x${calculatedCRC.toRadixString(16).toUpperCase().padLeft(4, '0')})',
  );

  // Step 4: Add CRC and EOF
  Logger('\n--- STAGE 4: Complete BLE Frame (before encryption) ---');
  List<int> completeBleFrame = newBleFrame.toList();
  completeBleFrame.addAll(intToBytesBigEndian(calculatedCRC));
  completeBleFrame.add(END_OF_FRAME_FIRST_BYTE); // 0xEE
  completeBleFrame.add(END_OF_FRAME_SECOND_BYTE); // 0xBB

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

  // Step 5: Encrypt
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

/// Test function to visualize passkey frame generation at each stage.
///
/// This function generates the passkey frame and prints detailed output
/// at each stage of the nested frame construction process.
///
/// Parameters:
///   - passkey: The passkey string to test (e.g., "1974")
///
/// Returns:
///   A map containing all intermediate frames for inspection
Future<Map<String, dynamic>> testPasskeyFrameGeneration(String passkey) async {
  Logger('========================================');
  Logger('TESTING PASSKEY FRAME GENERATION');
  Logger('Input Passkey: "$passkey"');
  Logger('========================================\n');

  // Step 1: Build original Technoswitch frame
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

  // Step 2: Wrap in new BLE format
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

  // Step 3: Calculate CRC-16
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

  // Step 4: Add CRC and EOF
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
  Logger('  PAYLOAD: ${originalFrameLength} bytes');
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

  // Step 5: Encrypt
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

  // Return all stages for further inspection
  return {
    'passkey': passkey,
    'originalFrame': originalFrame,
    'newBleFrame': newBleFrame,
    'calculatedCRC': calculatedCRC,
    'completeBleFrame': Uint8List.fromList(completeBleFrame),
    'encryptedFrame': encryptedDataPacket,
  };
}

/// Generates a complete data packet from the payload represented by a hexadecimal string.
///
/// This function constructs a complete data packet frame from the provided payload,
/// including the preamble, command bytes, length byte, payload data, CRC (Cyclic Redundancy Check),
/// and end-of-frame bytes.
///
/// Parameters:
///   - hexPayLoad: The hexadecimal string representing the payload data.
///
/// Returns:
///   A list of integers representing the complete data packet frame.
///
List<int> generateDataPacketFromPayload(String hexPayLoad) {
  /// Convert the payload hexadecimal string to a byte array
  List<int> payLoadData = hexToBytes(hexPayLoad);

  /// Calculate the length byte for the payload data
  String hexLengthByte = calculateLengthByte(hexPayLoad);
  List<int> lengthByte = hexToBytes(hexLengthByte);

  /// Construct the data packet frame
  Uint8List dataPacketFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_BYTE,
    DATA_PACKET_FRAME_TYPE_BYTE,
    ...lengthByte,
    ...payLoadData,
  ]);

  /// Calculate CRC for the data packet frame
  int calculatedCRC = convertCrc16(dataPacketFrame);
  // Logger(
  //     "Calculated CRC: $calculatedCRC ; ${calculatedCRC.toRadixString(16).toUpperCase()}");

  /// Add CRC and end-of-frame bytes to the data packet frame
  List<int> newList = dataPacketFrame.toList();
  newList.addAll(intToBytesBigEndian(calculatedCRC));
  newList.add(END_OF_FRAME_FIRST_BYTE);
  newList.add(END_OF_FRAME_SECOND_BYTE);

  return newList;
}

/// Generates an authentication message frame for sending over a communication channel.
///
/// This function constructs an authentication message frame from the provided text payload,
/// including the preamble, command bytes, length byte, payload data (converted to hexadecimal),
/// CRC (Cyclic Redundancy Check), and end-of-frame bytes. The entire frame is then encrypted
/// before transmission.
///
/// Parameters:
///   - text: The plaintext string payload to be converted and sent as hexadecimal.
///
/// Returns:
///   A Uint8List representing the encrypted authentication message frame.
///
Future<Uint8List> authMsgFrame() async {
  Logger('========================================');
  Logger('TX/RX Logs - STEP 3: SEND AUTHENTICATION MESSAGE (TX)');
  Logger('========================================');

  // String text = AppUtilConstants.geminiAuthKey;

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

  // Log non-encrypted TX data (before encryption)
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

/// This method is used to send the Device, Panel Datas to the Ble
///
///
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

///////////////////Maintanace Packets/////////////////////////

/// Adding a New device to the network
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

/// Change Device Address (Change loop address)
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

/// Edit Device Properties
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

/// Remove Device From Network
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

/// Replace Device From Network
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

/// Update Device Point Data
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

/// Update Date Time on the panel
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

///////////////////////////LARGE PACKET SENDING PACKET STRUCTURES//////////////////////////////////
///
/// Large Data sync request packet structure
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

/// Large Frame Start packet
///
/// Sendig the Total packet length
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

///Send Large Data Packet
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

/// Large Data Frame End Packet Structure
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

/// Get Large Data BleCommand By Current State
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

    default:
      return BleCommandsList.BLE_LARGE_DATA_REQ_CMD.value;
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
  List<Uint8List> largePacketsList = <Uint8List>[];
  List<List<int>> payLoadChunks = await DataHandler()
      .generateChunksForFirmwareUpgradePayload(payload);
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
  }
  Logger(largePacketsList.length.toString());
  Logger("largePacketsList.length.toString()");
  return largePacketsList;
}

Future<List<Uint8List>> generateListOfWithoutSkippingFFLargePacketsFromPayload(
  List<int> payload, {
  int sequenceNumber = 1,
  bool isResending = false,
}) async {
  List<Uint8List> largePacketsList = <Uint8List>[];
  List<List<int>> payLoadChunks = await DataHandler()
      .generateChunksForFirmwareUpgradeWithFullPayload(payload);

  for (int i = 0; i < payLoadChunks.length; i++) {
    Logger("Packet $i : ${payLoadChunks[i]}");
    Uint8List tempLargeDataPacket;

    // Always generate the packet without skipping any FF chunks
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
  }

  return largePacketsList;
}

////////////////////////////////////////////////////////////////////////////////////////////

/// Put device to link mode cmd
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

/// Put device to link mode cmd
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

/// Update ble process command
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

/// Update Panel Network process command
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

///Build system Data Packet
Future<Uint8List> generateBuildSystemDataPacket() async {
  List<int> payLoadData = <int>[3];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_BUILD_SYSTEM_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Build CMD : ${frame}");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

///Build system Data Packet
Future<Uint8List> generateStopBuildSystemDataPacket() async {
  List<int> payLoadData = <int>[4];
  List<int> frame = frameDataPacket(
    bleCommand: BleCommandsList.BLE_BUILD_SYSTEM_CMD.value,
    typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
    payLoadData: payLoadData,
  );

  Logger("Build CMD : ${frame}");
  Uint8List encryptedDataPacket = await EncryptionUtils().encryptData(
    data: frame,
  );

  return encryptedDataPacket;
}

///Get Procedure Status From Panel Command
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

/// Get Online Status Command From Panel
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

/// Test
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

/// Get All Device Status From Panel
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

/// Get Single Device Status From Panel
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

/// Get All Device Firmware and Production Lot From Panel
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

/// Get All Device Status From Panel
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

/// Get Device Firmware version and Production lot
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

///Resend Request Data packet
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

// LINK STATUS COMMAND FOR ALL DEVICE STATUS
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

/// Sending Panel Config Data Packet
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

/// Data Packet to send Expander Data
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

// Future<Uint8List> upgradeCompletedDataPacket() async {
//   List<int> payLoadData = <int>[0];
//   List<int> frame = frameDataPacket(
//       bleCommand: BleCommandsList.BLE_FIRMWARE_UPDATE_END_CMD.value,
//       typeOfFrame: KbleTypeOfFrameDef.enBLE_SMALL_DATA_FRAME.value,
//       payLoadData: payLoadData);
//   Uint8List encryptedDataPacket =
//       await EncryptionUtils().encryptData(data: frame);
//
//   return encryptedDataPacket;
// }

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

/// Data Packet For Sendig Expander Key
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

/// To Get Network Data From Panel
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

/// To Get Expander Parent Address from panel after build completion
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

/// To Get Network Data From Panel
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

/// Open Panel Replacement Session
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

/// Close Panel Replacement Session
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

///////////////////-Download data from panel-///////////////////

///Request for Panel Config (Download Panel config from panel)
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

// To Download Project Data From Panel
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

///Request for Device Config (Download Device config from panel)
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

/// Request for Event Logs (Download  Event Logs from panel)
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

/// Request for Event Logs with packet section count (Download  Event Logs from panel)
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

/// Download Diagnostic Logs from panel
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

///Respond to Data Sync Request From BLE
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

///Respond to Data Start Request From BLE (Master is Ready to Receive the packets)
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

///Respond to Data Start Request From BLE (Master is Ready to Receive the packets)
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

///Request for current project State (For robustnes)
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

///Request for current project State (For robustnes)
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

///Request for Event long Filter data
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

///Request for Event long Filter data
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

///
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

/// Enable Disable Analog Value
Future<Uint8List> generateEnableDisableAnalogValueDataPacket({
  required bool isEnableDisable,
  bool isBuild = false,
  bool isPanelReplace = false,
}) async {
  List<int> payLoadData = <int>[];
  if (isPanelReplace) {
    // for disable use 3 while panel replace (4 for enable)
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

///////////////////////// --- Common Payload --- //////////////////////////
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

////////////////////////////////////////////////////////////////

///Send Large Data Packet
Uint8List generateEncryptionKeyDataPacket() {
  Logger('========================================');
  Logger('TX/RX Logs - STEP 1: REQUEST ENCRYPTION KEY (TX)');
  Logger('========================================');

  Uint8List frameBuffer = Uint8List(1 + BLE_FRAME_FILED_SIZE);
  Uint8List response_data = hexStringToUint8List("00");

  bleFrameTheTxPkt(
    BleCommandsList.BLE_ENCRY_REQ_KEY_CMD.value,
    KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    0x01,
    response_data,
    frameBuffer,
  );

  // Log non-encrypted TX data
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

/// Generates a frame for toggling an LED.
///
/// This function constructs a frame used for toggling an LED, including preamble,
/// command bytes, frame type byte, payload length, payload (if any), CRC (Cyclic Redundancy Check),
/// and end-of-frame bytes.
///
/// Returns:
///   A Uint8List representing the LED toggle frame.
///
List<int> ledToggleFrame() {
  Uint8List dataFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_REQUEST_DATA_BYTE,
    CONNECTION_REQUEST_FRAME_TYPE_BYTE,
    0x00, 0x01, //PAYLOAD LENGTH
    0x00, // PAYLOAD
    0x12, 0x34, //CRC
    END_OF_FRAME_FIRST_BYTE,
    END_OF_FRAME_SECOND_BYTE,
  ]);
  return dataFrame;
}

////
