/*
* Project      : gemini_mobile_app
* File         : ble_data_structure_model.dart
* Description  : Data structure representing BLE data with 16-bit, 8-bit integers, a message list, and two 16-bit values, supporting byte array conversion in little and big endian formats
* Author       : SrihariharanT
* Date         : 2024-05-21
* Version      : 1.0
* Ticket       :
*/

/// {@category bluetooth}
library;

import 'dart:typed_data';

/// Represents a data structure for BLE (Bluetooth Low Energy) communication.
class BleDataStructure {
  /// 16-bit unsigned integer member.
  int u16_member;

  /// 8-bit unsigned integer member.
  int u8_member;

  /// List of integers representing a message.
  List<int> au8_msg;

  /// Two 16-bit unsigned integer data.
  int u16_u16_data;

  /// Constructs a [BleDataStructure] instance.
  BleDataStructure(
    this.u16_member,
    this.u8_member,
    this.au8_msg,
    this.u16_u16_data,
  );

  /// Constructs a [BleDataStructure] instance from a byte array using little endian byte order.
  factory BleDataStructure.fromBytes(Uint8List bytes) {
    ByteData byteData = ByteData.sublistView(bytes);

    int u16Member = byteData.getUint16(0, Endian.little);
    int u8Member = byteData.getUint8(2);
    List<int> au8Msg = bytes.sublist(3, 8);
    int u16U16Data = byteData.getUint16(8, Endian.little);

    return BleDataStructure(u16Member, u8Member, au8Msg, u16U16Data);
  }

  /// Constructs a [BleDataStructure] instance from a byte array using big endian byte order.
  factory BleDataStructure.fromBytesBigEndian(Uint8List bytes) {
    ByteData byteData = ByteData.sublistView(bytes);

    int u16Member = byteData.getUint16(0, Endian.big);
    int u8Member = byteData.getUint8(2);
    List<int> au8Msg = bytes.sublist(3, 8);
    int u16U16Data = byteData.getUint16(8, Endian.big);

    return BleDataStructure(u16Member, u8Member, au8Msg, u16U16Data);
  }

  /// Converts the [BleDataStructure] instance to a byte array using little endian byte order.
  Uint8List toBytes() {
    ByteData buffer = ByteData(10);
    buffer.setUint16(0, u16_member, Endian.little);
    buffer.setUint8(2, u8_member);
    for (int i = 0; i < au8_msg.length; i++) {
      buffer.setUint8(3 + i, au8_msg[i]);
    }
    buffer.setUint16(8, u16_u16_data, Endian.little);
    return buffer.buffer.asUint8List();
  }
}
