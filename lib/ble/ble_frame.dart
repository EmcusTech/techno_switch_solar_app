import 'dart:typed_data';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

import 'ble_manager.dart';

class BleRxFrame {
  int sof = 0;
  int cmd = 0;
  int tof = 0;
  int payloadLen = 0;
  List<int> payload = [];
  int crc = 0;
  int eof = 0;
  int calculatedCrc = 0;
}

BleRxFrame bleRxFrame = BleRxFrame();

BleRxFrame bleParseAndUpdateRxFrame(Uint8List frame, int frameLen) {
  final int frameLen = frame.length;

  if (frameLen < 12) {
    Logger(StringConstants.invalidFrameLen);
    return bleRxFrame;
  }

  int count = 0;

  Logger(
    "TX/RX: RECEIVED: time: ${DateTime.now().toIso8601String()}, frame: ${frame.sublist(7, frameLen - 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ")}",
  );

  int sof = (frame[count] << 8) | frame[count + 1];
  count += 2;

  int cmd = (frame[count] << 8) | frame[count + 1];
  count += 2;

  int tof = frame[count++];

  int payloadLen = (frame[count] << 8) | frame[count + 1];

  count += 2;

  if (frameLen < count + payloadLen + 4) {
    Logger(StringConstants.mismatchFrameLen);
    return bleRxFrame;
  }

  List<int> payload = frame.sublist(count, count + payloadLen);
  count += payloadLen;

  int crc = (frame[count] << 8) | frame[count + 1];
  count += 2;

  int eof = (frame[count] << 8) | frame[count + 1];

  int calculatedCrc = BleManager.crcCcittFalse(frame.sublist(0, frameLen - 4));

  bleRxFrame.sof = sof;
  bleRxFrame.cmd = cmd;
  bleRxFrame.tof = tof;
  bleRxFrame.payloadLen = payloadLen;
  bleRxFrame.payload = payload;
  bleRxFrame.crc = crc;
  bleRxFrame.eof = eof;
  bleRxFrame.calculatedCrc = calculatedCrc;

  return bleRxFrame;
}

bool bleValidateRxFrame(BleRxFrame rx) {
  Logger("the input dats is : $rx");
  if (rx.sof != 0xAA55) {
    Logger(StringConstants.sofValidationFail);
    return false;
  }

  if (rx.cmd <= 0) {
    Logger(StringConstants.cmdValidationFail);
    return false;
  }

  if (rx.tof <= 0) {
    Logger(StringConstants.tofValidationFail);
    return false;
  }

  if (rx.payloadLen <= 0) {
    Logger(StringConstants.payloadLenValidationFail);
    return false;
  }

  if (rx.crc != rx.calculatedCrc) {
    Logger(StringConstants.crcValidationFail);
    return false;
  }

  if (rx.eof != 0xEEBB) {
    Logger(StringConstants.eofValidationFail);
    return false;
  }

  return true;
}
