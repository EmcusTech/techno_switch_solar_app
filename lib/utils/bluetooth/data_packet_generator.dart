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

/// Constructs a frame for sending a payload to a BLE device.
///
/// This function generates a frame used to transmit a payload to a Bluetooth Low Energy (BLE) device,
/// including preamble bytes, command identifiers, frame type, payload length, payload data,
/// CRC (Cyclic Redundancy Check), and end-of-frame bytes.
///
/// Parameters:
///   - hexPayLoad: The hexadecimal string representing the payload data.
///
/// Returns:
///   A list of integers representing the complete frame for transmitting the payload to BLE.
///
Future<Uint8List> passKeyFrame(String hexPayLoad) async {
  /// Step 1: Convert the string to hexadecimal representation
  List<int> payLoadData = convertStringToHex(hexPayLoad);
  String hexPayloadStr = bytesToHex(payLoadData);

  /// Convert the byte length to hexadecimal and get it as a list of bytes
  String hexLengthByte = calculateLengthByte(hexPayloadStr);
  List<int> lengthByte = hexToBytes(hexLengthByte);

  Logger("$lengthByte");
  Logger("$payLoadData");
  Logger("lengthByte");

  Uint8List dataFrame = Uint8List.fromList(<int>[
    PREAMBLE_FIRST_BYTE,
    PREAMBLE_SECOND_BYTE,
    COMMAND_FIRST_BYTE,
    COMMAND_SECOND_BYTE,
    CONNECTION_REQUEST_FRAME_TYPE_BYTE,
    ...lengthByte,
    ...payLoadData,
  ]);

  int calculatedCRC = convertCrc16(dataFrame);
  Logger(
    "Calculated CRC: $calculatedCRC ; ${calculatedCRC.toRadixString(16).toUpperCase()}",
  );
  Logger("::::::Sending Password  to BLE ::::::::::::");
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
  // String text = AppUtilConstants.geminiAuthKey;

  List<int> payLoadData = convertStringToHex("TECHNOSWITCH-AUTH-APP");
  String hexPayLoad = bytesToHex(payLoadData);
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
  Logger(encryptedDataPacket.toString());

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
  Uint8List frameBuffer = Uint8List(1 + BLE_FRAME_FILED_SIZE);
  Uint8List response_data = hexStringToUint8List("00");

  bleFrameTheTxPkt(
    BleCommandsList.BLE_ENCRY_REQ_KEY_CMD.value,
    KbleTypeOfFrameDef.enBLE_REQUEST_FRAME.value,
    0x01,
    response_data,
    frameBuffer,
  );

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
