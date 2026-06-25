library;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
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

class DataHandler {
  // List<List<int>> generateChunksForConfigPayload(List<int> payload) {
  //   List<List<int>> payloadChunkList = <List<int>>[];

  //   int chunkSize =
  //       Get.find<BleNotifyDataHandler>().currentLargePacketModule.value ==
  //               LargePacketModule.devices
  //           ? enBLE_PAYLOAD_SIZE_PER_PACKET_BASED_ON_DEVICE
  //           : Get.find<BleNotifyDataHandler>().currentLargePacketModule.value ==
  //               LargePacketModule.sendingZoneData
  //           ? enBLE_PAYLOAD_SIZE_PER_PACKET_BASED_ON_ZONE
  //           : enBLE_PAYLOAD_SIZE_PER_PACKET;

  //   Logger(
  //     "State : ${Get.find<BleNotifyDataHandler>().currentLargePacketModule.value.name} , Chunk size = $chunkSize , TotalPayload size: ${payload.length}",
  //   );

  //   for (int i = 0; i < payload.length; i += chunkSize) {
  //     List<int> tempSubList = payload.sublist(
  //       i,
  //       i + chunkSize > payload.length ? payload.length : i + chunkSize,
  //     );

  //     payloadChunkList.add(tempSubList);
  //   }

  //   for (int j = 0; j < payloadChunkList.length; j++) {
  //     List<int> sequenceNumber = intToBytesLittleEndian(j + 1);

  //     payloadChunkList[j].insertAll(0, sequenceNumber);
  //   }

  //   return payloadChunkList;
  // }

  // Future<List<List<int>>> generateChunksForFirmwareUpgradePayload(
  //   List<int> payload,
  // ) async {
  //   List<List<int>> payloadChunkList = <List<int>>[];
  //   int chunkSize = 256;

  //   Logger(
  //     'Firmware Upgrade: Using chunk size ${chunkSize} bytes (no sequence number)',
  //   );

  //   for (int i = 0; i < payload.length - 100; i += chunkSize) {
  //     List<int> tempSubList = payload.sublist(
  //       i,
  //       i + chunkSize > payload.length - 100
  //           ? payload.length - 100
  //           : i + chunkSize,
  //     );

  //     if (tempSubList.every((int e) => e == 0xFF)) {
  //       continue;
  //     }

  //     payloadChunkList.add(tempSubList);
  //   }

  //   return payloadChunkList;
  // }

  // Future<List<List<int>>> generateChunksForFirmwareUpgradeWithFullPayload(
  //   List<int> payload,
  // ) async {
  //   List<List<int>> payloadChunkList = <List<int>>[];
  //   int chunkSize = 256;

  //   Logger(
  //     'Firmware Upgrade: Using chunk size $chunkSize bytes (no sequence number)',
  //   );

  //   for (int i = 0; i < payload.length; i += chunkSize) {
  //     List<int> tempSubList = payload.sublist(
  //       i,
  //       i + chunkSize > payload.length ? payload.length : i + chunkSize,
  //     );

  //     if (tempSubList.every((int e) => e == 0xFF)) {
  //       continue;
  //     }

  //     payloadChunkList.add(tempSubList);
  //   }

  //   return payloadChunkList;
  // }

  // Uint8List formatDataToFixedLength({
  //   required String dataValue,
  //   required int lengthOfTheString,
  // }) {
  //   Uint8List? trimmedDataValue;
  //   lengthOfTheString = lengthOfTheString - 1;

  //   if (utf8.encode(dataValue).length > lengthOfTheString) {
  //     trimmedDataValue = utf8.encode(dataValue.padRight(lengthOfTheString));
  //   } else {
  //     trimmedDataValue = Uint8List.fromList(
  //       utf8
  //           .encode(dataValue)
  //           .followedBy(
  //             List<int>.filled(lengthOfTheString - dataValue.length, 0x00),
  //           )
  //           .toList(),
  //     );
  //   }

  //   if (trimmedDataValue.length > lengthOfTheString) {
  //     Uint8List tempDeviceNameList = Uint8List.fromList(
  //       trimmedDataValue.sublist(0, lengthOfTheString),
  //     );

  //     trimmedDataValue = tempDeviceNameList;
  //   }

  //   trimmedDataValue = Uint8List.fromList(
  //     trimmedDataValue
  //         .followedBy(
  //           List<int>.filled(
  //             (lengthOfTheString + 1) - trimmedDataValue.length,
  //             0x00,
  //           ),
  //         )
  //         .toList(),
  //   );

  //   return trimmedDataValue;
  // }

  Future<FrameData?> decryptTheDataPacketWithoutConversion(
    List<int> dataPacket,
  ) async {
    try {
      String hexString = bytesToHex(dataPacket);

      List<int>? decryptedData = await EncryptionUtils().decryptData(hexString);

      final BleNotifyDataHandler handler = Get.find<BleNotifyDataHandler>();
      final BleStateMachine currentState = handler.currentBleState.value;

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

      String rxHex = decryptedData!
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(' ');
      String rxAscii = _bytesToAscii(decryptedData);
      Logger(
        'TX/RX Logs - Non-encrypted RX Data (${decryptedData.length} bytes):',
      );
      Logger('TX/RX Logs - Hex: $rxHex');
      Logger('TX/RX Logs - ASCII: $rxAscii');

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
      return null;
    }
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
        if (!listEquals(data.preambleByte, <String>['AA', '55'])) {
          errorMessage = "Invalid preamble";
          Logger(errorMessage);
          Logger("${data.preambleByte}");
          errorCode!(errorMessage);
          isValid = false;
        } else if (data.frameTypeByte.isEmpty) {
          errorMessage = "Invalid Type of Frame";
          Logger("Invalid Type of Frame");
          errorCode!(errorMessage);
          Logger(data.frameTypeByte);
          isValid = false;
        } else if (data.payloadData.isEmpty) {
          errorMessage = "Invalid payload Data";
          Logger("Invalid payload Data");
          errorCode!(errorMessage);
          Logger("${data.payloadData}");
          isValid = false;
        } else if (data.payloadLength.isEmpty) {
          errorMessage = "Invalid payload length";
          Logger("Invalid payload length");
          errorCode!(errorMessage);
          Logger("${data.payloadLength}");
          isValid = false;
        } else if (!listEquals(data.calculatedCrc, calculatedCrcHexList)) {
          errorMessage = "Invalid CRC";
          Logger("Invalid CRC");
          errorCode!(errorMessage);
          Logger("${data.calculatedCrc}");
          isValid = false;
        } else if (!listEquals(data.endFrame, <String>['EE', 'BB'])) {
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

  // int getExpanderAddress(int index) {
  //   int baseIndex = 200;

  //   int expanderAddress = baseIndex + (index + 1);

  //   return expanderAddress;
  // }
}
