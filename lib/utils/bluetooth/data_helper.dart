/*
* Project      : gemini_mobile_app
* File         : data_helper.dart
* Description  : Utility functions for CRC-16 checksum calculation, byte manipulation (big-endian), and hexadecimal data conversion.
* Author       : SrihariharanT
* Date         : 2024-05-20
* Version      : 1.0
* Ticket       :
*/

/// {@category bluetooth}
library;

import 'dart:convert';
import 'dart:typed_data';

/// Calculates the CRC-16 checksum for the provided data.
///
/// This function calculates the CRC-16 checksum for the given data using the
/// CRC-16-CCITT polynomial (0x1021) with an initial seed value of 0xFFFF.
///  Ensure that the provided data is valid and not empty.
int convertCrc16(Uint8List data, {bool isDefaultPolynomial = true}) {
  int crc = 0xFFFF; // Initial seed value

  int polynomial = isDefaultPolynomial ? 0x1021 : 0x8408; // Polynomial value

  for (int byte in data) {
    crc ^= (byte << 8); // XOR byte into the high byte of crc

    for (int i = 0; i < 8; i++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ polynomial) & 0xFFFF; // Ensure crc remains 16-bit
      } else {
        crc = (crc << 1) & 0xFFFF; // Ensure crc remains 16-bit
      }
    }
  }

  crc =
      crc ^
      0x0000; // Final XOR value (no effect in this case, could be omitted)

  return crc;
}

int crc16ForLogs(List<int> data, [int? size]) {
  // Initialize CRC value
  int crc = 0xFFFF;
  size ??= data.length;

  // Calculate CRC for each byte in the data buffer
  for (int i = 0; i < size; i++) {
    int byte = data[i];
    for (int j = 0; j < 8; j++) {
      if ((crc ^ byte) & 0x0001 != 0) {
        crc = (crc >> 1) ^ 0x8408;
      } else {
        crc = crc >> 1;
      }
      byte = byte >> 1;
    }
  }

  // Invert CRC and return
  return ~crc & 0xFFFF;
}

// int crcCcittFalse(List<int> data, {int poly = 0x1021, int initVal = 0xFFFF}) {
//   int crc = initVal;
//   for (var byte in data) {
//     crc ^= byte << 8;
//     for (int i = 0; i < 8; i++) {
//       if (crc & 0x8000 != 0) {
//         crc = (crc << 1) ^ poly;
//       } else {
//         crc <<= 1;
//       }
//       crc &= 0xFFFF;  // Keep crc within 16 bits
//     }
//   }
//   return crc;
// }
//
// int calculateCrc16(List<int> pu8Data, int u16DataLen) {
//   // Initialize the frame buffer
//   List<int> pu8FrameBuff = List.filled(u16DataLen, 0);
//
//   // Fill the frame buffer with the data
//   for (int i = 0; i < u16DataLen; i++) {
//     pu8FrameBuff[i] = pu8Data[i];
//   }
//
//   // Calculate the CRC
//   int u16CalculatedCrc = crcCcittFalse(pu8FrameBuff);
//
//   return u16CalculatedCrc;
// }

// Function to convert list of 8-bit values to 32-bit little-endian values
List<int> convertTo32BitLittleEndian(Uint8List data) {
  List<int> littleEndianData = <int>[];
  for (int i = 0; i < data.length; i += 4) {
    int value = 0;
    if (i + 3 < data.length) {
      value =
          (data[i] & 0xFF) |
          ((data[i + 1] & 0xFF) << 8) |
          ((data[i + 2] & 0xFF) << 16) |
          ((data[i + 3] & 0xFF) << 24);
    }
    littleEndianData.add(value);
  }
  return littleEndianData;
}

int calculateCrc32(
  List<int> data, {
  int polynomial = 0x04C11DB7,
  int initValue = 0xFFFFFFFF,
}) {
  int crc = initValue;

  for (int word in data) {
    crc ^= word;
    for (int i = 0; i < 32; i++) {
      if ((crc & 0x80000000) != 0) {
        crc = ((crc << 1) ^ polynomial) & 0xFFFFFFFF;
      } else {
        crc = (crc << 1) & 0xFFFFFFFF;
      }
    }
  }

  return crc & 0xFFFFFFFF;
}

// Helper function to reverse the byte order to little-endian format
int toLittleEndian(int value) {
  return ((value >> 24) & 0xFF) |
      ((value >> 16) & 0xFF) << 8 |
      ((value >> 8) & 0xFF) << 16 |
      (value & 0xFF) << 24;
}

/// Converts a 16-bit integer value to a Uint8List representing the bytes in big-endian order.
///
/// This function takes a 16-bit integer value and converts it to a Uint8List containing
/// the bytes representing the value in big-endian (network byte order).
///
/// Ensure that the provided value is within the range of a 16-bit integer.
Uint8List intToBytesBigEndian(int value) {
  // Create a ByteData instance with a buffer of length 2
  ByteData buffer = ByteData(2);

  // Set the 16-bit integer value in big-endian order
  buffer.setUint16(0, value, Endian.big);

  // Create a Uint8List from the ByteData buffer
  return Uint8List.view(buffer.buffer);
}

Uint8List intToBytesLittleEndian(int value) {
  // Create a ByteData instance with a buffer of length 2
  ByteData buffer = ByteData(2);

  // Set the 16-bit integer value in big-endian order
  buffer.setUint16(0, value, Endian.little);

  // Create a Uint8List from the ByteData buffer
  return Uint8List.view(buffer.buffer);
}

int bytesToIntLittleEndian(Uint8List bytes) {
  // Create a ByteData instance from the byte list
  ByteData buffer = ByteData.sublistView(bytes);

  // Read the 16-bit integer value in little-endian order
  return buffer.getUint16(0, Endian.little);
}

/// Converts a list of bytes to a hexadecimal string.
String bytesToHex(List<int> bytes) {
  return bytes
      .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join('');
}

List<String> bytesToHexList(List<int> bytes) {
  return bytes
      .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
      .toList();
}

int hexToInt(String hexString) {
  int decimalValue = int.parse(hexString, radix: 16);

  return decimalValue;
}

/// Converts a hexadecimal string to a list of bytes.
List<int> hexToBytes(String hexString) {
  List<int> bytes = <int>[];

  for (int i = 0; i < hexString.length; i += 2) {
    String hex = hexString.substring(i, i + 2);
    int byte = int.parse(hex, radix: 16);
    bytes.add(byte);
  }

  return bytes;
}

/// Converts a given [text] string into a list of integers representing
/// the hexadecimal values of its characters.
List<int> convertStringToHex(String text) {
  List<int> hexValues = <int>[];
  for (int i = 0; i < text.length; i++) {
    hexValues.add(text.codeUnitAt(i));
  }
  return hexValues;
}

/// Converts a list of hexadecimal strings to a list of integers.
List<int> convertStringListToHex(List<String> stringList) {
  return stringList.map((String str) => int.parse(str, radix: 16)).toList();
}

List<int> convertPassword(String password) {
  List<String> data = password.split("");
  return convertStringListToHex(data);
}

/// Converts a list of hexadecimal strings to a list of integers.
List<String> convertIntListToHex(List<int> stringList) {
  return stringList.map((int str) => str.toRadixString(16)).toList();
}

Uint8List hexStringToUint8List(String hexString) {
  List<int> intList =
      hexString.split('').map((String e) => int.parse(e, radix: 16)).toList();
  return Uint8List.fromList(intList);
}

List<String> intToHexList(int value) {
  String hexStr =
      value
          .toRadixString(16)
          .padLeft(4, '0')
          .toUpperCase(); // Ensure it is 4 characters long
  return <String>[hexStr.substring(0, 2), hexStr.substring(2, 4)];
}

/// Calculates the length byte for a given hexadecimal string.
///
/// This function calculates the length byte for the provided hexadecimal string,
/// which represents the length of the data in bytes. The length byte is formatted
/// as a 16-bit hexadecimal value (2 bytes).
String calculateLengthByte(String hexString) {
  List<int> byteArray = hexToBytes(hexString);
  String lengthInHex = byteArray.length.toRadixString(16).padLeft(2, '0');
  lengthInHex = lengthInHex.padLeft(4, '0');
  // Logger(
  //     "Hex bytes: ${byteArray.map((e) => e.toRadixString(16).padLeft(2, '0')).join('')}");
  // Logger("Length (hex, 2 bytes): $lengthInHex");
  return lengthInHex;
}

String calculateLengthByteByBytes(List<int> byteArray) {
  String lengthInHex = byteArray.length.toRadixString(16).padLeft(2, '0');
  lengthInHex = lengthInHex.padLeft(4, '0');
  // Logger(
  //     "Hex bytes: ${byteArray.map((e) => e.toRadixString(16).padLeft(2, '0')).join('')}");
  // Logger("Length (hex, 2 bytes): $lengthInHex");
  return lengthInHex;
}

///Convert bit value to hex
String convertBitToHex(String binaryStr) {
  int decimalValue = int.parse(binaryStr, radix: 2);

  // Convert the decimal value to a hexadecimal string
  String hexValue = decimalValue.toRadixString(16);

  return hexValue;
}

///Convert bit value to hex
int convertBitToDecimal(String binaryStr) {
  int decimalValue = int.parse(binaryStr, radix: 2);
  return decimalValue;
}

Uint8List convertZoneBytesToLittleEndian(int value) {
  // Create a ByteData instance with a buffer of length 4
  ByteData buffer = ByteData(8);

  // Set the 32-bit integer value in big-endian order
  buffer.setUint64(0, value, Endian.little);

  return Uint8List.view(buffer.buffer);
}

int convertLittleEndianToZoneBytes(Uint8List bytes) {
  ByteData buffer = ByteData.sublistView(bytes);
  return buffer.getUint64(0, Endian.little);
}

int convertStringListToInt(List<String> data) {
  List<int> bytes = convertStringListToHex(data).reversed.toList();

  // Combine the two bytes to form an integer
  int value = (bytes[0] << 8) | bytes[1];

  return value;
}

Uint8List removeExtraFillingBytes(Uint8List data) {
  List<int> result = data.toList();

  while (result.isNotEmpty && result.last == 0) {
    result.removeLast();
  }

  return Uint8List.fromList(result);
}

String formatBytesToString(List<int> bytes) {
  return bytes
      .map(
        (int byte) =>
            (byte < 32 || byte > 126)
                ? byte.toRadixString(16).padLeft(2, '0')
                : String.fromCharCode(byte),
      )
      .join();
}

Uint8List stringToBytes(String result) {
  List<int> byteList = <int>[];
  for (int i = 0; i < result.length; i++) {
    String char = result[i];
    if (char.codeUnitAt(0) < 32 || char.codeUnitAt(0) > 126) {
      byteList.add(int.parse(result.substring(i, i + 2), radix: 16));
      i++;
    } else {
      byteList.add(char.codeUnitAt(0));
    }
  }
  return Uint8List.fromList(byteList);
}

String convertDecimalToBit(int decimalValue) {
  String binaryStr = decimalValue.toRadixString(2);

  return binaryStr;
}

String convertDecimalToHex(int decimalValue) {
  String hexString = decimalValue.toRadixString(16).padLeft(2, '0');

  return hexString;
}

List<int> removeSpace(List<int> data) {
  for (int i = data.length - 1; i >= 0; i--) {
    if (data[i] != 0) {
      break;
    } else {
      data.removeAt(i);
    }
  }
  return data;
}

bool checkForFormat(String? qrData) {
  bool isFormatValid = false;
  List<String> tempQrDataList = qrData!.split(" ");
  isFormatValid = tempQrDataList.length == 3;
  return isFormatValid;
}

int uint8ListToIntUsingByteData(Uint8List uint8List) {
  ByteData byteData = ByteData.sublistView(uint8List);
  return byteData.getUint32(0, Endian.big); // Adjust size if needed
}

String handleEmptyString(String value) {
  if (value.isEmpty) {
    return "-";
  } else {
    return value;
  }
}

Uint8List convertToFixedLengthUint8List(String inputText) {
  String textToProcess = inputText;
  Uint8List processedData;

  if (utf8.encode(textToProcess).length > 20) {
    processedData = utf8.encode(textToProcess.padRight(20));
  } else {
    processedData = Uint8List.fromList(
      utf8
          .encode(textToProcess)
          .followedBy(List<int>.filled(20 - textToProcess.length, 0x00))
          .toList(),
    );
  }

  if (processedData.length > 20) {
    Uint8List tempDeviceNameList = Uint8List.fromList(
      processedData.sublist(0, 20),
    );

    processedData = tempDeviceNameList;
  }

  processedData = Uint8List.fromList(
    processedData
        .followedBy(List<int>.filled(21 - processedData.length, 0x00))
        .toList(),
  );

  return processedData;
}

int hexBytesToUint32LE(List<String> hexBytes) {
  if (hexBytes.length != 4) {
    throw ArgumentError('Exactly 4 hex bytes required');
  }

  ByteData byteData = ByteData(4);
  for (int i = 0; i < 4; i++) {
    int byteValue = int.parse(hexBytes[i], radix: 16);
    byteData.setUint8(i, byteValue);
  }

  return byteData.getUint32(0, Endian.little);
}
