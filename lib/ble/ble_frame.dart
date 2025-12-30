import 'dart:typed_data';
// import 'crc.dart'; // your CRC function file
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
    print("Invalid frame length");
    return bleRxFrame;
  }

  int count = 0;

  print(
    "TX/RX: RECEIVED: time: ${DateTime.now().toIso8601String()}, frame: ${frame.sublist(7, frameLen - 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ")}",
  );

  // SOF
  int sof = (frame[count] << 8) | frame[count + 1];
  count += 2;

  // CMD
  int cmd = (frame[count] << 8) | frame[count + 1];
  count += 2;

  // TOF
  int tof = frame[count++];

  // Payload length
  int payloadLen = (frame[count] << 8) | frame[count + 1];
  print(
    "frame desc: payload bytes:${frame[count + 1]}, ${frame[count]} frame length: $frameLen, count: $count, payloadLength: $payloadLen}",
  );
  count += 2;

  if (frameLen < count + payloadLen + 4) {
    print("Frame length does not match payload length");
    return bleRxFrame;
  }

  // Payload
  List<int> payload = frame.sublist(count, count + payloadLen);
  count += payloadLen;

  // CRC
  int crc = (frame[count] << 8) | frame[count + 1];
  count += 2;

  // EOF
  int eof = (frame[count] << 8) | frame[count + 1];

  int calculatedCrc = BleManager.crcCcittFalse(frame.sublist(0, frameLen - 4));

  // Update structure
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
  if (rx.sof != 0xAA55) return false;
  if (rx.cmd <= 0) return false;
  if (rx.tof <= 0) return false;
  if (rx.payloadLen <= 0) return false;
  if (rx.crc != rx.calculatedCrc) return false;
  if (rx.eof != 0xEEBB) return false;

  return true;
}
