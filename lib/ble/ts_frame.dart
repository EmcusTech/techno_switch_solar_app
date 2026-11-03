import 'dart:typed_data';

import 'package:Technoswitch/utils/constants/ble/ble_constants.dart';

/// Variable-length Techno Switch packet.
///
/// The caller passes 13 header bytes in the old field order (SOT through
/// command). The builder inserts the 2-byte command-data length immediately
/// after the RX packet number, so on the wire:
///
/// bytes 0–5 stay put, bytes 6–7 are the length in little-endian, bytes 8–14 are the old
/// header bytes 6–12 (network through command), and command data starts at
/// byte 15. The length counts network through command (7 bytes) plus the
/// command data. An empty body is sent as one 0x00 byte, so the length is 8.
/// The Fletcher checksum is stored little-endian (chk2, then chk1), then EOT.
class TsFrameView {
  const TsFrameView({
    required this.dataLength,
    required this.data,
    required this.lengthMatches,
    required this.checksumMatches,
    required this.eotMatches,
  });

  final int dataLength;
  final Uint8List data;
  final bool lengthMatches;
  final bool checksumMatches;
  final bool eotMatches;

  bool get isValid => lengthMatches && checksumMatches && eotMatches;
}

abstract final class TsFrame {
  static const int headerLength = 13;
  static const int dataLengthOffset = 6;
  static const int modeOffset = 12;
  static const int commandOffset = 14;
  static const int dataOffset = 15;
  static const int overhead = 18;

  /// Network, three reserved bytes, mode, socket, and command.
  static const int countedHeaderLength = headerLength - dataLengthOffset;

  static int fletcherChecksum(List<int> buffer) {
    if (buffer.isEmpty) return 0;

    int sum1 = 0;
    int sum2 = 0;

    for (final b in buffer) {
      sum1 = (sum1 + b) % 255;
      sum2 = (sum2 + sum1) % 255;
    }

    final int chk1 = (255 - ((sum1 + sum2) % 255)) & BleConstants.base;
    final int chk2 = (255 - ((sum1 + chk1) % 255)) & BleConstants.base;

    return (chk1 << 8) | chk2;
  }

  static Uint8List build(List<int> header, List<int> commandData) {
    if (header.length != headerLength) {
      throw ArgumentError(
        'TS header must be $headerLength bytes, got ${header.length}',
      );
    }

    final int bodyLength = commandData.isEmpty ? 1 : commandData.length;
    final int wireLength = countedHeaderLength + bodyLength;
    if (wireLength > 0xFFFF) {
      throw ArgumentError('TS data length $wireLength exceeds 65535');
    }

    final frame = Uint8List(overhead + bodyLength);
    frame.setRange(0, dataLengthOffset, header);
    frame[dataLengthOffset] = wireLength & BleConstants.base;
    frame[dataLengthOffset + 1] = (wireLength >> 8) & BleConstants.base;
    frame.setRange(
      dataLengthOffset + 2,
      dataOffset,
      header.sublist(dataLengthOffset),
    );
    if (commandData.isEmpty) {
      frame[dataOffset] = 0;
    } else {
      frame.setRange(dataOffset, dataOffset + bodyLength, commandData);
    }

    final int checksum = fletcherChecksum(
      frame.sublist(0, dataOffset + bodyLength),
    );
    final int checksumOffset = dataOffset + bodyLength;
    frame[checksumOffset] = checksum & BleConstants.base;
    frame[checksumOffset + 1] = (checksum >> 8) & BleConstants.base;
    frame[checksumOffset + 2] = BleConstants.eot;
    return frame;
  }

  static TsFrameView parse(List<int> payload) {
    if (payload.length < dataLengthOffset + 2) {
      return TsFrameView(
        dataLength: 0,
        data: Uint8List(0),
        lengthMatches: false,
        checksumMatches: false,
        eotMatches: false,
      );
    }

    final int wireLength =
        payload[dataLengthOffset] | (payload[dataLengthOffset + 1] << 8);
    if (wireLength < countedHeaderLength) {
      return TsFrameView(
        dataLength: 0,
        data: Uint8List(0),
        lengthMatches: false,
        checksumMatches: false,
        eotMatches: false,
      );
    }

    final int bodyLength = wireLength - countedHeaderLength;
    final int expectedLength = overhead + bodyLength;
    final bool lengthMatches = payload.length == expectedLength;
    if (!lengthMatches) {
      return TsFrameView(
        dataLength: bodyLength,
        data: Uint8List(0),
        lengthMatches: false,
        checksumMatches: false,
        eotMatches: false,
      );
    }

    final int checksumOffset = dataOffset + bodyLength;
    final int receivedChecksum =
        payload[checksumOffset] | (payload[checksumOffset + 1] << 8);
    final int calculatedChecksum = fletcherChecksum(
      payload.sublist(0, checksumOffset),
    );

    return TsFrameView(
      dataLength: bodyLength,
      data: Uint8List.fromList(
        payload.sublist(dataOffset, dataOffset + bodyLength),
      ),
      lengthMatches: true,
      checksumMatches: receivedChecksum == calculatedChecksum,
      eotMatches: payload[checksumOffset + 2] == BleConstants.eot,
    );
  }

  /// Rebuilds the pre-length-field layout so existing readers still see
  /// network at byte 6, mode at byte 10, command at byte 12, and data at 13.
  static Uint8List legacyCommandDataPayload(
    List<int> payload,
    TsFrameView parsed,
  ) {
    final view = Uint8List(headerLength + parsed.data.length);
    final int prefixCount =
        payload.length < dataLengthOffset ? payload.length : dataLengthOffset;
    view.setRange(0, prefixCount, payload);
    const int tailStart = dataLengthOffset + 2;
    const int tailLength = headerLength - dataLengthOffset;
    if (payload.length >= tailStart + tailLength) {
      view.setRange(
        dataLengthOffset,
        headerLength,
        payload.sublist(tailStart, tailStart + tailLength),
      );
    }
    if (parsed.data.isNotEmpty) {
      view.setRange(headerLength, view.length, parsed.data);
    }
    return view;
  }
}
