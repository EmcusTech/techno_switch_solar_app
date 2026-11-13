import 'dart:io';
import 'dart:typed_data';
import 'package:Technoswitch/models/ble/firmware/firmware_bin_format.dart';
import 'package:Technoswitch/models/ble/firmware/firmware_packet_model.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';

class FirmwarePacketService {
  static const int polynomial = 0x04C11DB7;

  /// Reads the whole file and checks the trailing CRC. Pages are cut later,
  /// once the negotiated MTU is known.
  Future<Uint8List> readVerifiedImage(
    File binFile, {
    bool verifyCrc = true,
  }) async {
    final bytes = await binFile.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('BIN file is empty');
    }

    if (verifyCrc) {
      if (bytes.length < FirmwareBinFormat.crcLength) {
        throw Exception('BIN file is too small for a CRC');
      }
      final crcInput = bytes.sublist(
        0,
        bytes.length - FirmwareBinFormat.crcLength,
      );
      final crcFromFile = bytes.sublist(
        bytes.length - FirmwareBinFormat.crcLength,
        bytes.length,
      );
      final expectedCrc = _bytesToUint32BE(crcFromFile);
      final calculatedCrc = _calculateCrc32(crcInput);
      if (expectedCrc != calculatedCrc) {
        throw Exception(
          'CRC mismatch. Expected=0x${expectedCrc.toRadixString(16)}, '
          'Calculated=0x${calculatedCrc.toRadixString(16)}',
        );
      }
    }

    return bytes;
  }

  /// Cuts [data] into pages of [payloadSize] bytes. The last page is shorter.
  /// An all-0xFF page is omitted, and its sequence number is still consumed.
  FirmwarePacketResult buildPackets(
    Uint8List data, {
    required int payloadSize,
  }) {
    if (payloadSize <= 0) {
      throw ArgumentError('Firmware page size must be positive');
    }
    final List<FirmwarePacket> packets = [];
    final List<int> skippedSequences = [];

    int sequence = 1;
    int logicalPacketCount = 0;

    for (int offset = 0; offset < data.length; offset += payloadSize) {
      final end =
          (offset + payloadSize <= data.length)
              ? offset + payloadSize
              : data.length;

      final payload = data.sublist(offset, end);

      final isAllFF = payload.every((b) => b == 0xFF);

      if (!isAllFF) {
        final packetBytes = Uint8List(2 + payload.length);
        final seqBytes = _sequenceTo2BytesLE(sequence);
        packetBytes.setRange(0, 2, seqBytes);
        packetBytes.setRange(2, 2 + payload.length, payload);

        packets.add(FirmwarePacket(sequence: sequence, bytes: packetBytes));

        logicalPacketCount++;
      } else {
        skippedSequences.add(sequence);
      }

      sequence++;
    }

    return FirmwarePacketResult(
      packets: packets,
      totalLogicalPackets: logicalPacketCount,
      skippedSequences: skippedSequences,
    );
  }

  int _calculateCrc32(Uint8List data) {
    int crc = 0xFFFFFFFF;

    for (int i = 0; i < data.length; i += 4) {
      int word = 0;
      for (int b = 0; b < 4 && (i + b) < data.length; b++) {
        word |= data[i + b] << (8 * b);
      }

      crc ^= word;

      for (int bit = 0; bit < 32; bit++) {
        crc =
            (crc & 0x80000000) != 0
                ? ((crc << 1) ^ polynomial) & 0xFFFFFFFF
                : (crc << 1) & 0xFFFFFFFF;
      }
    }

    return _swapUint32(crc);
  }

  int _swapUint32(int v) {
    return ((v >> 24) & 0xFF) |
        ((v >> 16) & 0xFF) << 8 |
        ((v >> 8) & 0xFF) << 16 |
        (v & 0xFF) << 24;
  }

  int _bytesToUint32BE(Uint8List b) {
    if (b.length != 4) {
      throw ArgumentError(StringConstants.crcMustBe4Bytes);
    }
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
  }

  Uint8List _sequenceTo2BytesLE(int seq) {
    return Uint8List.fromList([seq & 0xFF, (seq >> 8) & 0xFF]);
  }
}
