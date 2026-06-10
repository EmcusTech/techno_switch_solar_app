import 'dart:typed_data';

import 'data_helper.dart';

enum BleCommandsList {
  BLE_PASSKEY_REQ_CMD(0x1001),
  BLE_ENCRY_REQ_KEY_CMD(0x1000),
  BLE_LARGE_DATA_REQ_CMD(0x1002),
  BLE_SEND_AUTH_CMD(0x1000),
  BLE_SEND_PANEL_CONFIG_CMD(0x1002),
  BLE_BUILD_SYSTEM_CMD(0x1004),
  BLE_PANEL_CONFIG_CMD(0x1005),
  BLE_PANEL_DOWNLOAD_CONFIG_FROM_BLE_CMD(0x1006),
  BLE_DEVICE_DOWNLOAD_CONFIG_FROM_BLE_CMD(0x1007),
  BLE_SEND_ZONE_DETAILS_BLE_CMD(0x1008),
  BLE_DOWNLOAD_ZONE_DETAILS_BLE_CMD(0x1009),
  BLE_PROCEDURE_CMD(0x100E),
  BLE_UPDATE_CMD(0x1029),
  BLE_LINK_STATUS_CMD(0x1011),
  BLE_MCU_SELECTION_CMD(0x1022),
  BLE_FLASH_ERASE_CMD(0x1025),
  BLE_FILE_DATA_CMD(0x1026),
  BLE_FIRMWARE_UPDATE_CMD(0x1027),
  BLE_GET_SYSTEM_ONLINE_STATUS_CMD(0x1015),
  BLE_EXPANDER_PASS_KEY_CMD(0x101E),
  BLE_EXPANDER_CONFIG_SEND_CMD(0x102A),
  BLE_REPLACE_EXPANDER_CONFIG_SEND_CMD(0x103A),
  BLE_EXPANDER_CONFIG_DOWNLOAD_CMD(0x1031),
  BLE_UPLOAD_PROJECT_DATA_CMD(0x102C),
  BLE_DOWNLOAD_PROJECT_DATA_CMD(0x102D),
  BLE_GET_ALL_DEVICE_STATUS_CMD(0x100C),
  BLE_GET_PROJECT_BUILD_STATE_CMD(0x102E),
  BLE_PANEL_REL_UPDATE_VER_CMD(0x1030),
  BLE_CMD_REPLACE_DEVICE(0x1010),
  BLE_CMD_RMV_DEVIC_FRM_NWK(0x100F),
  BLE_CMD_ADD_DEVICE_TO_NWK(0x102B),
  BLE_OTA_ALL_MCU_UPDATED_CMD(0x1028),
  BLE_EDIT_DEVICE_PROPERTIES_CMD(0x101C),
  BLE_CMD_UPD_INDEX_DEV_POPTY(0x1032),
  BLE_CMD_DWNLD_EVT_LOGS(0x1033),
  BLE_CMD_DWNLD_DIAGNOSTIC_LOGS(0x103B),
  enCMD_REQ_EVT_LOGS_FLTR_INFO(0x1034),
  enCMD_REQ_DIAGNOSTIC_LOGS_FLTR_INFO(0x103C),
  enCMD_GET_PANEL_STATUS(0x1035),
  enCMD_UPD_PANEL_DATE_TIME(0x1036),
  enCMD_REQ_PANEL_CONFIG_CRC(0x1037),
  enCMD_ANALOG_ENABLE_DISABLE(0x1038),
  enCMD_RF_GET_ALL_DEVICE_INFO(0x100A),
  enCMD_GET_NETWORK_DATA(0x1022),
  enCMD_SEND_PANEL_NETWORK_DATA(0x1039),
  enCMD_UPLD_EVT_LOGS_CHK2(0x1039),
  BLE_FIRMWARE_VER_QUERY_CMD(0x102F),
  BLE_CONTROL_RES_EVENT_REPORT_CMD(0x103D);

  final int value;
  const BleCommandsList(this.value);
}

enum FrameFieldersDef {
  enBLE_SOF_MSB(0xAA),
  enBLE_SOF_LSB(0x55),
  enBLE_EOF_MSB(0xEE),
  enBLE_EOF_LSB(0xBB);

  final int value;
  const FrameFieldersDef(this.value);
}

enum FrameHeaderFieldPosDef {
  enBLE_SOF_MSB_POS(0X00),
  enBLE_SOF_LSB_POS(0X01),
  enBLE_CMD_MSB_POS(0X02),
  enBLE_CMD_LSB_POS(0X03),
  enBLE_TOF_POS(0X04),
  enBLE_DATA_LEN_MSB_POS(0X05),
  enBLE_DATA_LEN_LSB_POS(0X06),
  enBLE_DATA_POS(0X07);

  final int value;
  const FrameHeaderFieldPosDef(this.value);
}

enum TxFrameFooterFieldPos {
  enBLE_TXPKT_CRC_MSB_POS(0x07),
  enBLE_TXPKT_CRC_LSB_POS(0x08),
  enBLE_TXPKT_EOF_MSB_POS(0x09),
  enBLE_TXPKT_EOF_LSB_POS(0x0A);

  final int value;
  const TxFrameFooterFieldPos(this.value);
}

enum KbleTypeOfFrameDef {
  enBLE_REQUEST_FRAME(0x01),
  enBLE_SMALL_DATA_FRAME(0x02),
  enBLE_LARGE_DATA_FRAME(0x03),
  enOTA_SEQNUM_AFTER_FF_SKIP(0x0B),
  enCMD_RST_BLE_TRACK_STATUS(0x0C),
  enBLE_RESPONSE_FRAME(0x04),
  enBLE_SYNC_RESPONSE_FRAME(0x0A),
  enBLE_RESEND_REQ_FRAME(0x05),
  enBLE_RESEND_RSP_FRAME(0x06),
  enLARGE_FRAME_START(0x07),
  enLARGE_FRAME_END(0x08),
  enBLE_LARGE_DATA_SYNC_REQ_FRAME(0x09);

  final int value;
  const KbleTypeOfFrameDef(this.value);
}

const int BLE_FRAME_FILED_SIZE = 0x0B;
const int enBLE_PROCESS_FAILED = 0;
const int enBLE_PROCESS_SUCCESS = 1;
const int enBLE_PAYLOAD_SIZE_PER_PACKET = 482;
const int enBLE_PAYLOAD_SIZE_PER_PACKET_BASED_ON_DEVICE = 441;
const int enBLE_PAYLOAD_SIZE_PER_PACKET_BASED_ON_ZONE = 368;

const int enPanel_ADDRESS = 200;

int calculateCrc(Uint8List data, int length) {
  return 0xEA9A;
}

int bleFrameTheTxPkt(
  int u16Cmd,
  int u8TypeofFrame,
  int u16DataLen,
  Uint8List pu8Data,
  Uint8List pu8FrameBuff,
) {
  if ((u16Cmd > 0) &&
      (u8TypeofFrame > 0) &&
      (u16DataLen > 0) &&
      (pu8Data.isNotEmpty) &&
      (pu8FrameBuff.isNotEmpty)) {
    pu8FrameBuff[FrameHeaderFieldPosDef.enBLE_SOF_MSB_POS.index] =
        FrameFieldersDef.enBLE_SOF_MSB.value;
    pu8FrameBuff[FrameHeaderFieldPosDef.enBLE_SOF_LSB_POS.index] =
        FrameFieldersDef.enBLE_SOF_LSB.value;
    pu8FrameBuff[FrameHeaderFieldPosDef.enBLE_CMD_MSB_POS.index] =
        (u16Cmd >> 8) & 0xFF;
    pu8FrameBuff[FrameHeaderFieldPosDef.enBLE_CMD_LSB_POS.index] =
        u16Cmd & 0xFF;
    pu8FrameBuff[FrameHeaderFieldPosDef.enBLE_TOF_POS.index] = u8TypeofFrame;
    pu8FrameBuff[FrameHeaderFieldPosDef.enBLE_DATA_LEN_MSB_POS.index] =
        (u16DataLen >> 8) & 0xFF;
    pu8FrameBuff[FrameHeaderFieldPosDef.enBLE_DATA_LEN_LSB_POS.index] =
        u16DataLen & 0xFF;

    Uint8List crcData = Uint8List.fromList(
      pu8FrameBuff.sublist(
        0,
        FrameHeaderFieldPosDef.enBLE_DATA_POS.index + u16DataLen,
      ),
    );

    int crc = convertCrc16(crcData);

    pu8FrameBuff[TxFrameFooterFieldPos.enBLE_TXPKT_CRC_MSB_POS.value +
            u16DataLen] =
        (crc >> 8) & 0xFF;

    pu8FrameBuff[TxFrameFooterFieldPos.enBLE_TXPKT_CRC_LSB_POS.value +
            u16DataLen] =
        crc & 0xFF;

    pu8FrameBuff[TxFrameFooterFieldPos.enBLE_TXPKT_EOF_MSB_POS.value +
            u16DataLen] =
        FrameFieldersDef.enBLE_EOF_MSB.value;
    pu8FrameBuff[TxFrameFooterFieldPos.enBLE_TXPKT_EOF_LSB_POS.value +
            u16DataLen] =
        FrameFieldersDef.enBLE_EOF_LSB.value;

    return (BLE_FRAME_FILED_SIZE + u16DataLen);
  } else {
    return enBLE_PROCESS_FAILED;
  }
}

List<int> frameDataPacket({
  required int bleCommand,
  required int typeOfFrame,
  required List<int> payLoadData,
}) {
  String hexLengthByte = calculateLengthByteByBytes(payLoadData);
  List<int> lengthByte = hexToBytes(hexLengthByte);

  Uint8List dataFrame = Uint8List.fromList(<int>[
    FrameFieldersDef.enBLE_SOF_MSB.value,
    FrameFieldersDef.enBLE_SOF_LSB.value,

    (bleCommand >> 8) & 0xFF,
    bleCommand & 0xFF,

    typeOfFrame,

    ...lengthByte,

    ...payLoadData,
  ]);

  int calculatedCRC = convertCrc16(dataFrame);
  List<int> newList = dataFrame.toList();

  newList.addAll(intToBytesBigEndian(calculatedCRC));

  newList.add(FrameFieldersDef.enBLE_EOF_MSB.value);
  newList.add(FrameFieldersDef.enBLE_EOF_LSB.value);

  return newList;
}
