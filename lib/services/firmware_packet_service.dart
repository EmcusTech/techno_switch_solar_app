import 'dart:io';
import 'dart:typed_data';
import 'package:techno_switch_solar_app/models/ble/firmware/firmware_bin_format.dart';
import 'package:techno_switch_solar_app/models/ble/firmware/firmware_packet_model.dart';

class FirmwarePacketService {
  static const int payloadSize = 240;
  static const int polynomial = 0x04C11DB7;
  Future<FirmwarePacketResult> processBinFile(
    File binFile, {
    void Function(int current, int total)? onProgress,
  }) async {
    final bytes = await binFile.readAsBytes();

    if (bytes.length < FirmwareBinFormat.minFileLength) {
      throw Exception(
        'BIN file too small (need at least ${FirmwareBinFormat.minFileLength} bytes)',
      );
    }
    final crcInput = bytes.sublist(
      0,
      bytes.length - FirmwareBinFormat.crcLength,
    );
    final crcFromFile = bytes.sublist(
      bytes.length - FirmwareBinFormat.crcLength,
      bytes.length,
    );
    final imageForDevice = FirmwareBinFormat.applicationImageFromFile(bytes);

    final expectedCrc = _bytesToUint32BE(crcFromFile);
    final calculatedCrc = _calculateCrc32(crcInput);

    if (expectedCrc != calculatedCrc) {
      throw Exception(
        'CRC mismatch. Expected=0x${expectedCrc.toRadixString(16)}, '
        'Calculated=0x${calculatedCrc.toRadixString(16)}',
      );
    }

    return _buildPackets(imageForDevice, onProgress: onProgress);
  }

  FirmwarePacketResult _buildPackets(
    Uint8List data, {
    void Function(int current, int total)? onProgress,
  }) {
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

      onProgress?.call(logicalPacketCount, logicalPacketCount);
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
      throw ArgumentError('CRC must be 4 bytes');
    }
    return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
  }

  Uint8List _sequenceTo2BytesLE(int seq) {
    return Uint8List.fromList([seq & 0xFF, (seq >> 8) & 0xFF]);
  }
}
