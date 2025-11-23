/*
* Project      : gemini_mobile_app
* File         : frame_data.dart
* Description  : Models a data frame structure for byte-level communication, allowing conversion to a Uint8List and providing a string representation. It encapsulates preamble, command, frame type, payload length, payload data, CRC, and end frame components using hexadecimal string lists for byte conversion and manipulation
* Author       : SrihariharanT
* Date         : 2024-06-17
* Version      : 1.0
* Ticket       : 
*/

import 'dart:typed_data';

class FrameData {
  List<String> preambleByte;
  List<String> commandByte;
  final String frameTypeByte;
  List<String> payloadLength;
  List<String> payloadData;
  List<String> calculatedCrc;
  List<String> endFrame;

  FrameData({
    required this.preambleByte,
    required this.commandByte,
    required this.frameTypeByte,
    required this.payloadLength,
    required this.payloadData,
    required this.calculatedCrc,
    required this.endFrame,
  });

  @override
  String toString() {
    return '[$preambleByte,$commandByte,$frameTypeByte,$payloadLength,$payloadData $calculatedCrc,$endFrame]';
  }

  Uint8List toUint8List() {
    List<int> bytes = <int>[];

    // Convert each list of strings to bytes

    bytes.addAll(convertHexListToBytes(preambleByte));

    bytes.addAll(convertHexListToBytes(commandByte));

    bytes.add(int.parse(frameTypeByte, radix: 16));

    bytes.addAll(convertHexListToBytes(payloadLength));

    bytes.addAll(convertHexListToBytes(payloadData));

    return Uint8List.fromList(bytes);
  }

  List<int> convertHexListToBytes(List<String> hexList) {
    return hexList.map((String hex) => int.parse(hex, radix: 16)).toList();
  }
}
