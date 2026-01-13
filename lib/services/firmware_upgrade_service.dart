import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio show Response;
import 'package:file_picker/file_picker.dart';

/// Result of validating a firmware BIN file.
class FirmwareValidationResult {
  final bool isValid;
  final int expectedCrc;
  final int calculatedCrc;
  final Uint8List firmwareData;
  final String? error;

  FirmwareValidationResult({
    required this.isValid,
    required this.expectedCrc,
    required this.calculatedCrc,
    required this.firmwareData,
    this.error,
  });

  String get expectedHex =>
      expectedCrc.toRadixString(16).padLeft(8, '0').toUpperCase();

  String get calculatedHex =>
      calculatedCrc.toRadixString(16).padLeft(8, '0').toUpperCase();
}

/// Service class for firmware file validation and packetization.
class FirmwareUpgradeService {
  static final FirmwareUpgradeService _instance =
      FirmwareUpgradeService._internal();
  factory FirmwareUpgradeService() => _instance;
  FirmwareUpgradeService._internal();

  /// Validate a BIN file:
  /// - Last 4 bytes = CRC32 (big endian) from file.
  /// - CRC calculated on all preceding bytes.
  FirmwareValidationResult validateFirmwareFile(PlatformFile file) {
    final Uint8List? bytes = file.bytes ??
        (file.path != null ? File(file.path!).readAsBytesSync() : null);

    if (bytes == null || bytes.length < 4) {
      return FirmwareValidationResult(
        isValid: false,
        expectedCrc: 0,
        calculatedCrc: 0,
        firmwareData: Uint8List(0),
        error: 'Invalid BIN file (too small or unreadable)',
      );
    }

    final Uint8List firmwareData = bytes.sublist(0, bytes.length - 4);
    final Uint8List crcBytes = bytes.sublist(bytes.length - 4);

    final int expectedCrc = _bytesToUint32BE(crcBytes);
    final int calculatedCrc = _calculateCrc32(firmwareData);

    final bool isValid = expectedCrc == calculatedCrc;

    return FirmwareValidationResult(
      isValid: isValid,
      expectedCrc: expectedCrc,
      calculatedCrc: calculatedCrc,
      firmwareData: firmwareData,
      error: isValid ? null : 'CRC mismatch. BIN file may be corrupted.',
    );
  }

  /// Optional helper used for debugging/printing hex.
  String formatHex(Uint8List bytes, {int bytesPerLine = 16}) {
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += bytesPerLine) {
      final offset = i.toRadixString(16).padLeft(8, '0').toUpperCase();
      final lineBytes = bytes.skip(i).take(bytesPerLine);
      final hex = lineBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      buffer.writeln('$offset: $hex');
    }
    return buffer.toString();
  }

  // ===== CRC + helpers (from provided reference snippet) =====

  int _calculateCrc32(Uint8List data) {
    const int polynomial = 0x04C11DB7;
    int crc = 0xFFFFFFFF;

    for (int i = 0; i < data.length; i += 4) {
      int word = 0;
      for (int b = 0; b < 4 && (i + b) < data.length; b++) {
        word |= data[i + b] << (8 * b);
      }
      crc ^= word;
      for (int bit = 0; bit < 32; bit++) {
        if ((crc & 0x80000000) != 0) {
          crc = ((crc << 1) ^ polynomial) & 0xFFFFFFFF;
        } else {
          crc = (crc << 1) & 0xFFFFFFFF;
        }
      }
    }

    return _swapUint32(crc);
  }

  int _swapUint32(int value) {
    return ((value >> 24) & 0xFF) |
        ((value >> 16) & 0xFF) << 8 |
        ((value >> 8) & 0xFF) << 16 |
        (value & 0xFF) << 24;
  }

  int _bytesToUint32BE(Uint8List bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  Uint8List _sequenceTo2BytesBE(int seq) {
    return Uint8List.fromList([(seq >> 8) & 0xFF, seq & 0xFF]);
  }

  /// Convenience method for downloaded files (kept for compatibility).
  PlatformFile? handleDownloadResponse(
    dio.Response<dynamic> response,
    String filePath,
    String fileName,
    String fileVersion,
  ) {
    if (response.statusCode != 200) {
      return null;
    }
    final File file = File(filePath);
    if (!file.existsSync()) return null;

    return PlatformFile(
      name: fileName,
      path: filePath,
      identifier: fileVersion,
      size: file.lengthSync(),
      bytes: file.readAsBytesSync(),
    );
  }
}

enum DownloadStatus {
  downloading,
  ready,
  upgrading,
  completed,
  failed,
}

