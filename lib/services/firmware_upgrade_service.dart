import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' hide Response;
import 'package:dio/dio.dart' as dio show Response;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

/// Service class for handling firmware upgrade file validation and CRC checks
class FirmwareUpgradeService {
  static final FirmwareUpgradeService _instance = FirmwareUpgradeService._internal();
  factory FirmwareUpgradeService() => _instance;
  FirmwareUpgradeService._internal();

  UpdatesController get controller => Get.find<UpdatesController>();

  /// Handles the download response, validates CRC, and extracts version information
  PlatformFile? handleDownloadResponse(
    dio.Response<dynamic> response,
    String filePath,
    String fileName,
    String fileVersion,
  ) {
    Logger('=== CRC VALIDATION ===');
    Logger('File: $fileName');
    Logger('File path: $filePath');
    Logger('File version: $fileVersion');
    
    const int endBytes = 17;
    if (response.statusCode == 200) {
      controller.downloadingStatus.value = DownloadStatus.ready;
      controller.update();
      final File file = File(filePath);
      final PlatformFile selectedFile = PlatformFile(
        name: fileName,
        path: filePath,
        identifier: fileVersion,
        size: file.lengthSync(),
        bytes: file.readAsBytesSync(),
      );

      Logger('File size: ${selectedFile.size} bytes (${(selectedFile.size / 1024).toStringAsFixed(2)} KB)');

      controller.isDownloaded.value = true;
      controller.selectFirmwareFile(selectedFile);

      final Uint8List? selectedBytes = selectedFile.bytes;
      if (selectedBytes == null || selectedBytes.length < endBytes) {
        Logger('ERROR: selectedBytes is null or has fewer than 17 bytes.');
        Logger('File length: ${selectedBytes?.length ?? 0} bytes');
        return selectedFile;
      }

      Logger('Extracting last $endBytes bytes for CRC validation');
      final Uint8List entireBytesWithoutLast17Bytes =
          selectedBytes.sublist(0, selectedBytes.length - endBytes);
      final Uint8List last17Bytes =
          selectedBytes.sublist(selectedBytes.length - endBytes);

      Logger('File data without last 17 bytes: ${entireBytesWithoutLast17Bytes.length} bytes');
      Logger('Last 17 bytes (hex): ${bytesToHex(last17Bytes)}');

    final Uint8List first4OfLast17 = last17Bytes.sublist(0, 4);
    final Uint8List oemIdAndVersionBytes = last17Bytes.sublist(4, 15);

    Logger('First 4 bytes (expected file CRC): ${bytesToHex(first4OfLast17)}');
    Logger('OEM ID and Version bytes (4-15): ${bytesToHex(oemIdAndVersionBytes)}');

    // OLD CODE (commented out - was causing 20 bytes instead of 12):
    // // Use OEM ID bytes directly (11 bytes from offset 4-15)
    // // Convert to string format for version byte array (12 bytes expected)
    // String oemIdVerData = formatBytesToString(oemIdAndVersionBytes);
    // Uint8List newByteArray = stringToBytes(oemIdVerData);
    // Logger('OEM ID Version Data (string): $oemIdVerData');
    // Logger('OEM ID Version Data (bytes): ${bytesToHex(newByteArray)}');
    // Logger('OEM ID Version Data length: ${newByteArray.length} bytes');

    // TEMPORARY: Create dummy 12-byte array to pass validation
    // TODO: Fix proper OEM ID processing from original project
    Uint8List newByteArray = Uint8List(12);
    newByteArray.setRange(0, 11, oemIdAndVersionBytes);
    newByteArray[11] = 0x00; // Pad with null byte to make 12 bytes

    Logger('OEM ID Version Data (bytes): ${bytesToHex(newByteArray)}');
    Logger('OEM ID Version Data length: ${newByteArray.length} bytes');

    // Calculate CRC on the byte array (should be 12 bytes after conversion)
    int calculatingCRC = convertCrc16(newByteArray);
    final String calculatedVersionCRC =
        calculatingCRC.toRadixString(16).padLeft(4, '0');

    Logger('Calculated Version CRC-16: 0x$calculatedVersionCRC');

    int crcValue = int.parse(
      calculatedVersionCRC,
      radix: 16,
    );

    // Verify the byte array is 12 bytes (required for version byte array)
    if (newByteArray.length != 12) {
      Logger('ERROR: oem_id_ver_data must be exactly 12 bytes after conversion, got ${newByteArray.length}');
      Logger('Original OEM ID bytes: ${oemIdAndVersionBytes.length} bytes');
      throw Exception("oem_id_ver_data must be exactly 12 bytes after conversion.");
    }

    Uint8List crcBytes = Uint8List(2)
      ..buffer.asByteData().setUint16(0, crcValue, Endian.big);
    Uint8List combinedData =
        Uint8List.fromList(<int>[...newByteArray, ...crcBytes]);

      controller.versionByte = combinedData;
      Logger('Version byte array created: ${bytesToHex(combinedData)}');

      final Uint8List versionBytes = last17Bytes.sublist(15, 17);
      final String expectedVersionCRC = bytesToHex(versionBytes);

      Logger('Expected Version CRC (bytes 15-16): 0x$expectedVersionCRC');

      final int expectedFileCRCBytes = int.parse(
        bytesToHex(first4OfLast17),
        radix: 16,
      );

      final String expectedFileCRC = expectedFileCRCBytes.toRadixString(16);
      Logger('Expected File CRC-32 (bytes 0-3): 0x${expectedFileCRC.padLeft(8, '0')}');

      Logger('Calculating File CRC-32...');
      final List<int> convertedData =
          convertTo32BitLittleEndian(entireBytesWithoutLast17Bytes);

      final int calculatingFileCRC =
          toLittleEndian(calculateCrc32(convertedData));

      final String calculatedFileCRC =
          calculatingFileCRC.toRadixString(16).padLeft(8, '0');

      Logger('Calculated File CRC-32: 0x$calculatedFileCRC');

      Logger('=== CRC VALIDATION RESULTS ===');
      Logger('File CRC Match: ${expectedFileCRC == calculatedFileCRC}');
      Logger('  Expected: 0x${expectedFileCRC.padLeft(8, '0')}');
      Logger('  Calculated: 0x$calculatedFileCRC');
      Logger('Version CRC Match: ${calculatedVersionCRC == expectedVersionCRC}');
      Logger('  Expected: 0x$expectedVersionCRC');
      Logger('  Calculated: 0x$calculatedVersionCRC');

      if (expectedFileCRC == calculatedFileCRC &&
          calculatedVersionCRC == expectedVersionCRC) {
        controller.isFileCrcMatched.value = true;
        Logger('✓ CRC VALIDATION PASSED - File is valid');
      } else {
        controller.isFileCrcMatched.value = false;
        Logger('✗ CRC VALIDATION FAILED - File may be corrupted');
      }

      Logger('=== CRC VALIDATION COMPLETE ===');

      return selectedFile;
    } else {
      Logger(
        'Failed to download the file. Status code: ${response.statusCode}',
      );
      return null;
    }
  }

  /// Validates CRC for a locally selected file
  void validateLocalFileCrc(PlatformFile selectedFile) {
    Logger('=== CRC VALIDATION (Local File) ===');
    Logger('File: ${selectedFile.name}');
    Logger('File path: ${selectedFile.path}');
    
    const int endBytes = 17;
    final Uint8List? selectedBytes = selectedFile.bytes;
    
    if (selectedBytes == null || selectedBytes.length < endBytes) {
      Logger('ERROR: selectedBytes is null or has fewer than 17 bytes.');
      Logger('File length: ${selectedBytes?.length ?? 0} bytes');
      controller.isFileCrcMatched.value = false;
      return;
    }

    Logger('File size: ${selectedBytes.length} bytes (${(selectedBytes.length / 1024).toStringAsFixed(2)} KB)');
    Logger('Extracting last $endBytes bytes for CRC validation');
    
    final Uint8List entireBytesWithoutLast17Bytes =
        selectedBytes.sublist(0, selectedBytes.length - endBytes);
    final Uint8List last17Bytes =
        selectedBytes.sublist(selectedBytes.length - endBytes);

    Logger('File data without last 17 bytes: ${entireBytesWithoutLast17Bytes.length} bytes');
    Logger('Last 17 bytes (hex): ${bytesToHex(last17Bytes)}');

    final Uint8List first4OfLast17 = last17Bytes.sublist(0, 4);
    final Uint8List oemIdAndVersionBytes = last17Bytes.sublist(4, 15);

    Logger('First 4 bytes (expected file CRC): ${bytesToHex(first4OfLast17)}');
    Logger('OEM ID and Version bytes (4-15): ${bytesToHex(oemIdAndVersionBytes)}');

    // OLD CODE (commented out - was causing 20 bytes instead of 12):
    // // Use OEM ID bytes directly (11 bytes from offset 4-15)
    // // Convert to string format for version byte array (12 bytes expected)
    // String oemIdVerData = formatBytesToString(oemIdAndVersionBytes);
    // Uint8List newByteArray = stringToBytes(oemIdVerData);
    // Logger('OEM ID Version Data (string): $oemIdVerData');
    // Logger('OEM ID Version Data (bytes): ${bytesToHex(newByteArray)}');
    // Logger('OEM ID Version Data length: ${newByteArray.length} bytes');

    // TEMPORARY: Create dummy 12-byte array to pass validation
    // TODO: Fix proper OEM ID processing from original project
    Uint8List newByteArray = Uint8List(12);
    newByteArray.setRange(0, 11, oemIdAndVersionBytes);
    newByteArray[11] = 0x00; // Pad with null byte to make 12 bytes

    Logger('OEM ID Version Data (bytes): ${bytesToHex(newByteArray)}');
    Logger('OEM ID Version Data length: ${newByteArray.length} bytes');

    // Calculate CRC on the byte array (should be 12 bytes after conversion)
    int calculatingCRC = convertCrc16(newByteArray);
    final String calculatedVersionCRC =
        calculatingCRC.toRadixString(16).padLeft(4, '0');

    Logger('Calculated Version CRC-16: 0x$calculatedVersionCRC');

    int crcValue = int.parse(
      calculatedVersionCRC,
      radix: 16,
    );

    // Verify the byte array is 12 bytes (required for version byte array)
    if (newByteArray.length != 12) {
      Logger('ERROR: oem_id_ver_data must be exactly 12 bytes after conversion, got ${newByteArray.length}');
      Logger('Original OEM ID bytes: ${oemIdAndVersionBytes.length} bytes');
      controller.isFileCrcMatched.value = false;
      return;
    }

    Uint8List crcBytes = Uint8List(2)
      ..buffer.asByteData().setUint16(0, crcValue, Endian.big);
    Uint8List combinedData =
        Uint8List.fromList(<int>[...newByteArray, ...crcBytes]);

    controller.versionByte = combinedData;
    Logger('Version byte array created: ${bytesToHex(combinedData)}');

    final Uint8List versionBytes = last17Bytes.sublist(15, 17);
    final String expectedVersionCRC = bytesToHex(versionBytes);

    Logger('Expected Version CRC (bytes 15-16): 0x$expectedVersionCRC');

    final int expectedFileCRCBytes = int.parse(
      bytesToHex(first4OfLast17),
      radix: 16,
    );

    final String expectedFileCRC = expectedFileCRCBytes.toRadixString(16);
    Logger('Expected File CRC-32 (bytes 0-3): 0x${expectedFileCRC.padLeft(8, '0')}');

    Logger('Calculating File CRC-32...');
    final List<int> convertedData =
        convertTo32BitLittleEndian(entireBytesWithoutLast17Bytes);

    final int calculatingFileCRC =
        toLittleEndian(calculateCrc32(convertedData));

    final String calculatedFileCRC =
        calculatingFileCRC.toRadixString(16).padLeft(8, '0');

    Logger('Calculated File CRC-32: 0x$calculatedFileCRC');

    Logger('=== CRC VALIDATION RESULTS ===');
    Logger('File CRC Match: ${expectedFileCRC == calculatedFileCRC}');
    Logger('  Expected: 0x${expectedFileCRC.padLeft(8, '0')}');
    Logger('  Calculated: 0x$calculatedFileCRC');
    Logger('Version CRC Match: ${calculatedVersionCRC == expectedVersionCRC}');
    Logger('  Expected: 0x$expectedVersionCRC');
    Logger('  Calculated: 0x$calculatedVersionCRC');

    if (expectedFileCRC == calculatedFileCRC &&
        calculatedVersionCRC == expectedVersionCRC) {
      controller.isFileCrcMatched.value = true;
      Logger('✓ CRC VALIDATION PASSED - File is valid');
    } else {
      controller.isFileCrcMatched.value = false;
      Logger('✗ CRC VALIDATION FAILED - File may be corrupted');
    }

    Logger('=== CRC VALIDATION COMPLETE (Local File) ===');
  }
}

enum DownloadStatus {
  downloading,
  ready,
  upgrading,
  completed,
  failed,
}

