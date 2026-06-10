import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio show Response;
import 'package:file_picker/file_picker.dart';
import 'package:techno_switch_solar_app/models/ble/firmware/firmware_bin_format.dart';

class FirmwareValidationResult {
  final bool isValid;
  final int expectedCrc;
  final int calculatedCrc;
  final Uint8List firmwareData;
  final String firmwareVersion;
  final String hardwareVersion;
  final String date;
  final String productId;
  final String? error;

  FirmwareValidationResult({
    required this.isValid,
    required this.expectedCrc,
    required this.calculatedCrc,
    required this.firmwareData,
    this.firmwareVersion = '',
    this.hardwareVersion = '',
    this.date = '',
    this.productId = '',
    this.error,
  });

  String get expectedHex =>
      expectedCrc.toRadixString(16).padLeft(8, '0').toUpperCase();

  String get calculatedHex =>
      calculatedCrc.toRadixString(16).padLeft(8, '0').toUpperCase();
}

class FirmwareUpgradeService {
  static final FirmwareUpgradeService _instance =
      FirmwareUpgradeService._internal();
  factory FirmwareUpgradeService() => _instance;
  FirmwareUpgradeService._internal();

  static const String expectedProductId = 'BLUENRGM2SP';

  FirmwareValidationResult validateFirmwareFile(
    PlatformFile file, {
    String? requiredProductId,
  }) {
    final Uint8List? bytes =
        file.bytes ??
        (file.path != null ? File(file.path!).readAsBytesSync() : null);

    if (bytes == null || bytes.length < FirmwareBinFormat.minFileLength) {
      return FirmwareValidationResult(
        isValid: false,
        expectedCrc: 0,
        calculatedCrc: 0,
        firmwareData: Uint8List(0),
        error:
            'Invalid BIN file (too small, need at least '
            '${FirmwareBinFormat.minFileLength} bytes, or unreadable)',
      );
    }

    final Uint8List trailer = bytes.sublist(
      bytes.length - FirmwareBinFormat.trailerLength,
    );
    final fields = FirmwareBinTrailer.fromLast40Bytes(trailer);

    final Uint8List crcInput = bytes.sublist(
      0,
      bytes.length - FirmwareBinFormat.crcLength,
    );
    final Uint8List crcBytes = bytes.sublist(
      bytes.length - FirmwareBinFormat.crcLength,
      bytes.length,
    );

    final int expectedCrc = _bytesToUint32BE(crcBytes);
    final int calculatedCrc = _calculateCrc32(crcInput);

    final bool crcOk = expectedCrc == calculatedCrc;

    final Uint8List firmwareData = FirmwareBinFormat.applicationImageFromFile(
      bytes,
    );

    if (!crcOk) {
      return FirmwareValidationResult(
        isValid: false,
        expectedCrc: expectedCrc,
        calculatedCrc: calculatedCrc,
        firmwareData: firmwareData,
        firmwareVersion: fields.firmwareVersion,
        hardwareVersion: fields.hardwareVersion,
        date: fields.date,
        productId: fields.productId,
        error: 'CRC mismatch. BIN file may be corrupted.',
      );
    }

    if (requiredProductId != null) {
      final String fileProductId = fields.productId.trim();
      if (fileProductId != requiredProductId) {
        return FirmwareValidationResult(
          isValid: false,
          expectedCrc: expectedCrc,
          calculatedCrc: calculatedCrc,
          firmwareData: firmwareData,
          firmwareVersion: fields.firmwareVersion,
          hardwareVersion: fields.hardwareVersion,
          date: fields.date,
          productId: fields.productId,
          error:
              'This firmware is not for this product. '
              'Expected product ID $requiredProductId, '
              'but file has ${fileProductId.isEmpty ? '(empty)' : fileProductId}.',
        );
      }
    }

    return FirmwareValidationResult(
      isValid: true,
      expectedCrc: expectedCrc,
      calculatedCrc: calculatedCrc,
      firmwareData: firmwareData,
      firmwareVersion: fields.firmwareVersion,
      hardwareVersion: fields.hardwareVersion,
      date: fields.date,
      productId: fields.productId,
      error: null,
    );
  }

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

enum DownloadStatus { downloading, ready, upgrading, completed, failed }
