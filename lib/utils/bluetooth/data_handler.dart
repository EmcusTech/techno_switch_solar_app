/*
* Project      : gemini_mobile_app
* File         : data_handler.dart
* Description  : Facilitates operations on Bluetooth data packets, including extracting payload data, converting payloads to big-endian and little-endian byte orders, decrypting data packets, validating frame integrity, and generating data packets. It also handles error checking and logging throughout these processes.
* Author       : SrihariharanT
* Date         : 2024-05-20
* Version      : 1.0
* Ticket       :
*/

/// {@category bluetooth}
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/models/ble/ble_data_structure_model.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_frame_utils.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/encryption_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'data_helper.dart';
import 'data_packet_generator.dart';

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

/// A utility class for handling data related operations, such as extracting firmware versions and verifying CRC.
class DataHandler {
  /// Extracts the payload data from a given packet.
  ///
  /// This function takes a packet represented as a string and extracts the payload
  /// data from it. It skips the preamble, command, CRC, and end byte sections of
  /// the packet to retrieve the payload. The extracted payload data is returned as a string.
  String getPayloadFromPacket(String packet) {
    String payload = "";

    int crcAndEndByteLength = 8;
    int preambleAndCommandLength = 14;

    for (
      int i = preambleAndCommandLength;
      i < packet.length - crcAndEndByteLength;
      i++
    ) {
      payload = payload + packet[i];
    }
    Logger("::::::Key Value $payload");
    return payload;
  }

  /// Creating chunks of large data packet for sending to the ble
  List<List<int>> generateChunksForConfigPayload(List<int> payload) {
    List<List<int>> payloadChunkList = <List<int>>[];

    int chunkSize =
        Get.find<BleNotifyDataHandler>().currentLargePacketModule.value ==
                LargePacketModule.devices
            ? enBLE_PAYLOAD_SIZE_PER_PACKET_BASED_ON_DEVICE
            : Get.find<BleNotifyDataHandler>().currentLargePacketModule.value ==
                LargePacketModule.sendingZoneData
            ? enBLE_PAYLOAD_SIZE_PER_PACKET_BASED_ON_ZONE
            : enBLE_PAYLOAD_SIZE_PER_PACKET;

    Logger(
      "State : ${Get.find<BleNotifyDataHandler>().currentLargePacketModule.value.name} , Chunk size = $chunkSize , TotalPayload size: ${payload.length}",
    );

    for (int i = 0; i < payload.length; i += chunkSize) {
      List<int> tempSubList = payload.sublist(
        i,
        i + chunkSize > payload.length ? payload.length : i + chunkSize,
      );

      payloadChunkList.add(tempSubList);
    }

    // Adding sequence number to the payload chunks
    for (int j = 0; j < payloadChunkList.length; j++) {
      List<int> sequenceNumber = intToBytesLittleEndian(j + 1);

      payloadChunkList[j].insertAll(0, sequenceNumber);
    }

    return payloadChunkList;
  }

  /// Creating chunks of large data packet for Upgrading Firmware to the ble
  Future<List<List<int>>> generateChunksForFirmwareUpgradePayload(
    List<int> payload,
  ) async {
    List<List<int>> payloadChunkList = <List<int>>[];
    // Firmware upgrade uses 256-byte chunks (no sequence number)
    int chunkSize =
        256; // Changed from 484 (482 + 2 sequence) to 256 bytes without sequence number

    Logger(
      'Firmware Upgrade: Using chunk size ${chunkSize} bytes (no sequence number)',
    );

    // Step 1: Generate chunks from payload
    for (int i = 0; i < payload.length - 100; i += chunkSize) {
      List<int> tempSubList = payload.sublist(
        i,
        i + chunkSize > payload.length - 100
            ? payload.length - 100
            : i + chunkSize,
      );

      // Step 2: Check if the chunk is full of 0xFF and skip if it is
      if (tempSubList.every((int e) => e == 0xFF)) {
        continue; // Skip this chunk
      }

      // Add the non-skipped chunk to the list (no sequence number added)
      payloadChunkList.add(tempSubList);
    }

    // OLD CODE (commented out - sequence number removed):
    // // Step 3: Adding sequence numbers to the payload chunks
    // for (int j = 0; j < payloadChunkList.length; j++) {
    //   List<int> sequenceNumber = intToBytesLittleEndian(j + 1);
    //   payloadChunkList[j].insertAll(0, sequenceNumber);
    // }

    return payloadChunkList;
  }

  Future<List<List<int>>> generateChunksForFirmwareUpgradeWithFullPayload(
    List<int> payload,
  ) async {
    List<List<int>> payloadChunkList = <List<int>>[];
    // Firmware upgrade uses 256-byte chunks (no sequence number)
    int chunkSize =
        256; // Changed from 484 (482 + 2 sequence) to 256 bytes without sequence number

    Logger(
      'Firmware Upgrade: Using chunk size ${chunkSize} bytes (no sequence number)',
    );

    // Step 1: Generate chunks from the complete payload
    for (int i = 0; i < payload.length; i += chunkSize) {
      List<int> tempSubList = payload.sublist(
        i,
        i + chunkSize > payload.length ? payload.length : i + chunkSize,
      );

      // Step 2: Check if the chunk is full of 0xFF and skip if it is
      if (tempSubList.every((int e) => e == 0xFF)) {
        continue; // Skip this chunk
      }

      // OLD CODE (commented out - sequence number removed):
      // bool isGoneThroughFF = false;
      // if (isGoneThroughFF) {
      //   List<int> sequenceNumber = intToBytesLittleEndian(
      //     tempSequenceNumber - 1,
      //   );
      //   List<int> chunkSizeByes = intToBytesLittleEndian(chunkSize);
      //   payloadChunkList.add(<int>[...sequenceNumber, ...chunkSizeByes]);
      //   isGoneThroughFF = false;
      // }
      // List<int> sequenceNumber = intToBytesLittleEndian(tempSequenceNumber);
      // tempSubList.insertAll(0, sequenceNumber);

      // Add the chunk to the list (no sequence number added)
      payloadChunkList.add(tempSubList);
    }

    // // Step 2: Add sequence numbers to the payload chunks
    // for (int j = 0; j < payloadChunkList.length; j++) {
    //   List<int> sequenceNumber = intToBytesLittleEndian(j + 1);
    //   payloadChunkList[j].insertAll(0, sequenceNumber);
    // }

    return payloadChunkList;
  }

  // Future<List<List<int>>> generateChunksForFirmwareUpgradeWithFullPayload(
  //     List<int> payload) async {
  //   List<List<int>> payloadChunkList = [];
  //   int chunkSize = enBLE_PAYLOAD_SIZE_PER_PACKET;

  //   // Step 1: Generate chunks from the complete payload
  //   for (int i = 0; i < payload.length; i += chunkSize) {
  //     var tempSubList = payload.sublist(
  //       i,
  //       i + chunkSize > payload.length ? payload.length : i + chunkSize,
  //     );

  //     // Add the chunk to the list (no skipping logic)
  //     payloadChunkList.add(tempSubList);
  //   }

  //   // Step 2: Add sequence numbers to the payload chunks
  //   for (int j = 0; j < payloadChunkList.length; j++) {
  //     List<int> sequenceNumber = intToBytesLittleEndian(j + 1);
  //     payloadChunkList[j].insertAll(0, sequenceNumber);
  //   }

  //   return payloadChunkList;
  // }

  /// This function formats a given string to a fixed length.
  /// It trims the string if it exceeds the specified length, or pads it with
  /// null bytes (0x00) if it's shorter than the specified length.
  /// Returns a Uint8List of the fixed length.
  Uint8List formatDataToFixedLength({
    required String dataValue,
    required int lengthOfTheString,
  }) {
    Uint8List? trimmedDataValue;
    lengthOfTheString = lengthOfTheString - 1;

    if (utf8.encode(dataValue).length > lengthOfTheString) {
      trimmedDataValue = utf8.encode(dataValue.padRight(lengthOfTheString));
    } else {
      trimmedDataValue = Uint8List.fromList(
        utf8
            .encode(dataValue)
            .followedBy(
              List<int>.filled(lengthOfTheString - dataValue.length, 0x00),
            )
            .toList(),
      );
    }

    if (trimmedDataValue.length > lengthOfTheString) {
      Uint8List tempDeviceNameList = Uint8List.fromList(
        trimmedDataValue.sublist(0, lengthOfTheString),
      );

      trimmedDataValue = tempDeviceNameList;
    }

    trimmedDataValue = Uint8List.fromList(
      trimmedDataValue
          .followedBy(
            List<int>.filled(
              (lengthOfTheString + 1) - trimmedDataValue.length,
              0x00,
            ),
          )
          .toList(),
    );

    return trimmedDataValue;
  }

  /// Converts a payload represented as a hexadecimal string to big-endian byte order.
  ///
  /// This function takes a hexadecimal string representing the payload data,
  /// converts it to a list of bytes, then to a `Uint8List`, and finally converts
  /// it to big-endian byte order using a `BleDataStructure`. The resulting
  /// big-endian payload is returned as a hexadecimal string.
  String convertPayloadToBigEndian({required String payLoadHexString}) {
    List<int> payLoadDataBytes = hexToBytes(payLoadHexString);
    Uint8List unit8Data = Uint8List.fromList(payLoadDataBytes);
    BleDataStructure bleStruct = BleDataStructure.fromBytes(unit8Data);

    /// Convert each value to hexadecimal and concatenate them
    String result =
        bleStruct.u16_member.toRadixString(16).padLeft(4, '0') +
        bleStruct.u8_member.toRadixString(16).padLeft(2, '0') +
        bleStruct.au8_msg
            .map((int e) => e.toRadixString(16).padLeft(2, '0'))
            .join('') +
        bleStruct.u16_u16_data.toRadixString(16).padLeft(4, '0');

    return result;
  }

  /// Decrypts the received data packet and parses it into a `FrameData` object.
  Future<FrameData?> decryptTheDataPacket(List<int> dataPacket) async {
    try {
      String hexString = bytesToHex(dataPacket);

      /// Decrypt received data
      List<int>? decryptedData = await EncryptionUtils().decryptData(hexString);
      FrameData parsedFrame = DataTransferManager().parseRxFrame(
        decryptedData!,
      );

      /// Convert decrypted data to big-endian format
      if (parsedFrame.payloadData.length > 4) {
        String bigEndianFormatedData = DataHandler().convertPayloadToBigEndian(
          payLoadHexString: parsedFrame.payloadData.join(),
        );
        Logger(":::::::::::::::Payload Got Here::::::::::::");
        Logger(bigEndianFormatedData);

        parsedFrame.payloadData = <String>[bigEndianFormatedData];
      }

      return parsedFrame;
    } catch (e) {
      // TODO(username): message.
      return null;
    }
  }

  /// Decrypts the received data packet and parses it into a `FrameData` object.
  Future<FrameData?> decryptTheDataPacketWithoutConversion(
    List<int> dataPacket,
  ) async {
    try {
      String hexString = bytesToHex(dataPacket);

      /// Decrypt received data
      List<int>? decryptedData = await EncryptionUtils().decryptData(hexString);

      // Get current state to determine step name
      final BleNotifyDataHandler handler = Get.find<BleNotifyDataHandler>();
      final BleStateMachine currentState = handler.currentBleState.value;

      // Determine step name based on current state
      String stepName = 'UNKNOWN';
      int stepNumber = 0;
      switch (currentState) {
        case BleStateMachine.reqEncryptionKey:
          stepName = 'RECEIVE ENCRYPTION KEY';
          stepNumber = 2;
          break;
        case BleStateMachine.sendingAuthMessage:
          stepName = 'RECEIVE AUTHENTICATION RESPONSE';
          stepNumber = 4;
          break;
        case BleStateMachine.requestingNetworkPacket:
          stepName = 'RECEIVE NETWORK PACKET RESPONSE';
          stepNumber = 6;
          break;
        case BleStateMachine.sendingPollPacket:
          stepName = 'RECEIVE POLL PACKET RESPONSE';
          stepNumber = 7;
          break;
        case BleStateMachine.sendingPasskeyPacket:
          stepName = 'PASSKEY PACKET SENT (response in poll packet)';
          stepNumber = 8;
          break;
        case BleStateMachine.sendingControlResEventReport:
          stepName = 'CONTROL_RES_EVENT_REPORT SENT (response in poll packet)';
          stepNumber = 9;
          break;
        case BleStateMachine.receivingEventLogs:
          stepName = 'RECEIVE EVENT LOG DATA';
          stepNumber = 10;
          break;
        case BleStateMachine.sendingDummyPacket:
          stepName = 'RECEIVE DUMMY PACKET RESPONSE';
          stepNumber = 10;
          break;
        default:
          stepName = 'RECEIVE DATA';
          stepNumber = 0;
      }

      Logger('========================================');
      Logger('TX/RX Logs - STEP $stepNumber: $stepName (RX)');
      Logger('========================================');
      Logger("TX/RX Logs - Current State: ${currentState.name}");

      // Log non-encrypted RX data (after decryption)
      String rxHex = decryptedData!
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(' ');
      String rxAscii = _bytesToAscii(decryptedData);
      Logger(
        'TX/RX Logs - Non-encrypted RX Data (${decryptedData.length} bytes):',
      );
      Logger('TX/RX Logs - Hex: $rxHex');
      Logger('TX/RX Logs - ASCII: $rxAscii');

      // Parse frame to get command and frame type
      FrameData parsedFrame = DataTransferManager().parseRxFrame(decryptedData);

      if (parsedFrame.commandByte.isNotEmpty &&
          parsedFrame.commandByte.length >= 2) {
        int cmdValue =
            (int.parse(parsedFrame.commandByte[0], radix: 16) << 8) |
            int.parse(parsedFrame.commandByte[1], radix: 16);
        Logger(
          'TX/RX Logs - Command: 0x${cmdValue.toRadixString(16).padLeft(4, '0')}',
        );
      }
      Logger('TX/RX Logs - Frame Type: ${parsedFrame.frameTypeByte}');
      Logger(
        'TX/RX Logs - Payload Length: ${parsedFrame.payloadData.length} bytes',
      );
      Logger('TX/RX Logs - ========================================\n');

      return parsedFrame;
    } catch (e) {
      Logger('TX/RX Logs - ERROR: Failed to decrypt/parse frame: $e');
      // TODO(username): message.
      return null;
    }
  }

  /// Converts a payload represented as a hexadecimal string to little-endian byte order.
  ///
  /// This function takes a hexadecimal string representing the payload data,
  /// converts it to a list of bytes, then to a `Uint8List`, and finally converts
  /// it to little-endian byte order using a `BleDataStructure`. The resulting
  /// little-endian payload is returned as a `Uint8List`.
  Uint8List convertPayloadToLittleEndian({required String payLoadHexString}) {
    List<int> payLoadDataBytes = hexToBytes(payLoadHexString);
    Uint8List unit8Data = Uint8List.fromList(payLoadDataBytes);
    BleDataStructure bleStruct = BleDataStructure.fromBytesBigEndian(unit8Data);
    Uint8List littleEndianPayLoad = bleStruct.toBytes();

    return littleEndianPayLoad;
  }

  /// Converts a hexadecimal string to little-endian byte order.
  ///
  /// This function first extracts payload data from the provided hexadecimal string
  /// using a `DataHandler`. It then converts the payload data to little-endian byte order
  /// and generates a data packet from the converted payload. The resulting data packet
  /// is returned as a list of integers.
  ///
  /// Parameters:
  ///   - hexString: The hexadecimal string to be converted to little-endian byte order.
  ///
  /// Returns:
  ///   A list of integers representing the data packet in little-endian byte order.
  ///
  /// Ensure that the provided hexadecimal string represents valid data
  /// that can be converted to little-endian byte order.

  List<int> convertItToLittleEndian(String hexString) {
    String payLoadData = DataHandler().getPayloadFromPacket(hexString);
    Logger("BEFORE CONVERTING:::::>$payLoadData");
    Uint8List convertedPayLoad = DataHandler().convertPayloadToLittleEndian(
      payLoadHexString: payLoadData,
    );
    Logger("AFTER CONVERTING:::::>$convertedPayLoad");

    String payLoadDataFrame = bytesToHex(convertedPayLoad);

    List<int> dataPacket = generateDataPacketFromPayload(payLoadDataFrame);
    Logger("::::::::::::<Data Packet Generated After Little ENDIAN>::::::::::");
    Logger(dataPacket.toString());
    String dataPacketInHex = bytesToHex(dataPacket);
    Logger(dataPacketInHex);

    return dataPacket;
  }

  bool frameValidation(FrameData? data, {Function(String)? errorCode}) {
    bool isValid = true;

    if (data != null) {
      try {
        Uint8List uint8ListData = data.toUint8List();
        int expectedCrc = convertCrc16(uint8ListData);
        List<String> calculatedCrcHexList = intToHexList(expectedCrc);
        Logger('Data used to generate CRC: $uint8ListData');
        Logger('Calculated CRC from the frame: $calculatedCrcHexList ');
        Logger('Expected CRC from the frame: ${data.calculatedCrc}');
        String errorMessage = "";
        // Check preamble byte
        if (!listEquals(data.preambleByte, <String>['AA', '55'])) {
          errorMessage = "Invalid preamble";
          Logger(errorMessage);
          Logger("${data.preambleByte}");
          errorCode!(errorMessage);
          isValid = false;
        } else
        // Check Frame type is greater than zero
        if (data.frameTypeByte.isEmpty) {
          errorMessage = "Invalid Type of Frame";
          Logger("Invalid Type of Frame");
          errorCode!(errorMessage);
          Logger(data.frameTypeByte);
          isValid = false;
        } else
        // Check payload data is greater than zero
        if (data.payloadData.isEmpty) {
          errorMessage = "Invalid payload Data";
          Logger("Invalid payload Data");
          errorCode!(errorMessage);
          Logger("${data.payloadData}");
          isValid = false;
        } else
        // Check payload length is greater than zero
        if (data.payloadLength.isEmpty) {
          errorMessage = "Invalid payload length";
          Logger("Invalid payload length");
          errorCode!(errorMessage);
          Logger("${data.payloadLength}");
          isValid = false;
        } else
        // Check Calculated CRC byte
        if (!listEquals(data.calculatedCrc, calculatedCrcHexList)) {
          errorMessage = "Invalid CRC";
          Logger("Invalid CRC");
          errorCode!(errorMessage);
          Logger("${data.calculatedCrc}");
          isValid = false;
        } else
        // Check end frame
        if (!listEquals(data.endFrame, <String>['EE', 'BB'])) {
          errorMessage = "Invalid end frame";
          Logger("Invalid end frame");
          errorCode!(errorMessage);
          Logger("${data.endFrame}");
          isValid = false;
        }
      } catch (e) {
        isValid = false;
        Logger("Invalid Packet: ${e.toString()} Packet: ${data.payloadData}");
      }
    } else {
      String errorMessage = "Invalid or corrupted Data";
      Logger("Invalid or corrupted Data");
      errorCode!(errorMessage);
      isValid = false;
    }
    return isValid;
  }

  /// For getting Expander Address
  /// that is starting from 201
  int getExpanderAddress(int index) {
    int baseIndex = 200;

    int expanderAddress = baseIndex + (index + 1);

    return expanderAddress;
  }
}
