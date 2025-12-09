import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart' hide Response;
import 'package:dio/dio.dart' as dio show Response;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:techno_switch_solar_app/models/mcu_info.dart';
import 'package:techno_switch_solar_app/services/firmware_upgrade_service.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_packet_generator.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_transfer_manager.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';

/// Controller for managing firmware update operations
class UpdatesController extends GetxController {
  final FirmwareUpgradeService _firmwareService = FirmwareUpgradeService();
  final DataTransferManager dataTransferManager = DataTransferManager();

  // Observable state variables
  final Rx<DownloadStatus> downloadingStatus = DownloadStatus.downloading.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloaded = false.obs;
  final RxBool isFileCrcMatched = false.obs;
  final RxInt progressbarIndex = 0.obs;
  final RxInt tempCurrentIndex = 0.obs;
  final RxDouble progressbarCount = 0.0.obs;
  final RxInt totalPacketLength = 0.obs;

  // Firmware file and version data
  PlatformFile? selectedFirmwareFile;
  Uint8List versionByte = Uint8List(0);

  // Firmware type (for single MCU file handling)
  // 0 = Main Panel, 1 = BLE Chip
  int? selectedFirmwareType; // 0 = mainPanel, 1 = bleChip

  // MCU data storage
  List<int> mainMCUBytes = [];
  List<int> rfMCUBytes = [];
  List<int> netMCUBytes = [];
  List<int> mainMcuLast100Byte = [];
  List<int> rfMcuLast100Byte = [];
  List<int> netMcuLast100Byte = [];

  List<MCUInfo> mcuInfoList = [];
  List<MCUInfo> mismatchedMcuInfos = [];

  // MCU type data
  List<int> typeData = [];
  List<int> mainMcu = [];
  List<int> rfMcu = [];
  List<int> netMcu = [];

  /// Downloads firmware file from the given URL
  Future<PlatformFile?> downloadFile(
    String fileLink,
    String fileName,
    String fileVersion,
  ) async {
    if (!await _isConnected()) {
      // Handle no internet connection
      Logger('No internet connection');
      return null;
    }

    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';

      downloadProgress.value = 0.1;

      final dio.Response<dynamic> response = await Dio().download(
        fileLink,
        filePath,
        onReceiveProgress: (int received, int total) async {
          if (total != -1) {
            double tempProgressValue = (received / total) * 100;
            if (tempProgressValue > downloadProgress.value) {
              downloadProgress.value = tempProgressValue;
            }
          }
        },
      );

      final File downloadedFile = File(filePath);
      if (await downloadedFile.exists()) {
        final int fileSize = await downloadedFile.length();
        Logger('Downloaded file size: ${fileSize / (1024 * 1024)} MB');
      }

      isDownloaded.value = true;
      return _firmwareService.handleDownloadResponse(
        response,
        filePath,
        fileName,
        fileVersion,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        Logger('DioException: 403 Forbidden: ${e.message}');
      } else {
        Logger('DioException: ${e.message}');
      }
      isDownloaded.value = false;
      downloadProgress.value = 0.0;
    } catch (e) {
      Logger('Unexpected error: $e');
    }
    return null;
  }

  /// Selects a firmware file and stores it
  void selectFirmwareFile(PlatformFile file) {
    selectedFirmwareFile = file;
    update();
  }

  /// Reads and processes the binary file as a single MCU firmware
  /// Both Main Panel and BLE Chip firmware are single MCU files
  Future<void> readAndSplitBinFile(String filePath) async {
    Logger('=== FILE READING (readAndSplitBinFile) ===');
    Logger('File path: $filePath');
    Logger(
      'Firmware type: ${selectedFirmwareType == 1 ? "BLE Chip" : "Main Panel"}',
    );

    // Clear previous MCU info list to avoid duplicates
    mcuInfoList.clear();
    Logger('Cleared previous MCU info list');

    final File file = File(filePath);
    List<int> byteData = await file.readAsBytes();

    Logger(
      'Total file size: ${byteData.length} bytes (${(byteData.length / 1024).toStringAsFixed(2)} KB)',
    );

    // Log complete file hex dump for verification
    _logCompleteHexDump('ORIGINAL FILE DATA', byteData);

    // === DETAILED FILE DATA LOGGING ===
    Logger('=== FILE DATA ANALYSIS ===');
    Logger(
      'First 32 bytes (header): ${byteData.take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );
    Logger(
      'Last 17 bytes (version info): ${byteData.skip(byteData.length - 17).take(17).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );

    // Log middle section sample (around 25% of file)
    if (byteData.length > 100) {
      int middleOffset = (byteData.length * 0.25).round();
      Logger(
        'Middle section (offset $middleOffset, 32 bytes): ${byteData.skip(middleOffset).take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
      );
    }

    // Log bytes before version info (last 17 bytes)
    if (byteData.length > 50) {
      Logger(
        'Bytes before version info (32 bytes before end): ${byteData.skip(byteData.length - 49).take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
      );
    }

    // Log firmware data start
    Logger(
      'Firmware data start (first 32 bytes): ${byteData.take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );
    Logger('=== FILE DATA ANALYSIS COMPLETE ===');

    Get.find<BleNotifyDataHandler>().currentLargePacketModule.value =
        LargePacketModule.firmWareUpgrade;

    // Both firmware types are single MCU files
    // Extract firmware data (excluding last 17 bytes which contain version info)
    const int versionInfoSize = 17;
    if (byteData.length < versionInfoSize) {
      throw Exception(
        'File too small: ${byteData.length} bytes (minimum ${versionInfoSize} bytes required)',
      );
    }

    final int firmwareSize = byteData.length - versionInfoSize;

    Logger('=== SINGLE MCU FIRMWARE PROCESSING ===');
    Logger(
      'Firmware data size: $firmwareSize bytes (excluding ${versionInfoSize} bytes version info)',
    );
    Logger('MCU Type: ${selectedFirmwareType == 1 ? "BleChipMCU" : "MainMCU"}');

    // Store firmware bytes in mainMCUBytes (used for single MCU)
    mainMCUBytes = byteData.sublist(0, firmwareSize);
    rfMCUBytes = [];
    netMCUBytes = [];

    // Extract last 100 bytes for EOF image data
    mainMcuLast100Byte =
        mainMCUBytes.length > 100
            ? mainMCUBytes.sublist(mainMCUBytes.length - 100)
            : List<int>.from(mainMCUBytes);

    rfMcuLast100Byte = [];
    netMcuLast100Byte = [];

    Logger('Firmware bytes extracted: ${mainMCUBytes.length} bytes');
    Logger('Last 100 bytes extracted: ${mainMcuLast100Byte.length} bytes');

    // Log complete firmware bytes hex dump
    _logCompleteHexDump(
      'FIRMWARE BYTES (after removing version info)',
      mainMCUBytes,
    );

    // Log complete last 100 bytes hex dump
    _logCompleteHexDump('LAST 100 BYTES (EOF image data)', mainMcuLast100Byte);

    // === DETAILED FIRMWARE BYTES LOGGING ===
    Logger('=== FIRMWARE BYTES DETAILS ===');
    Logger(
      'Firmware start (first 32 bytes hex): ${mainMCUBytes.take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );
    Logger(
      'Firmware end - last 100 bytes (hex): ${mainMcuLast100Byte.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );

    // Log middle section of firmware
    if (mainMCUBytes.length > 200) {
      int firmwareMiddle = (mainMCUBytes.length * 0.5).round();
      Logger(
        'Firmware middle (offset $firmwareMiddle, 32 bytes hex): ${mainMCUBytes.skip(firmwareMiddle).take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
      );
    }

    // Log byte statistics
    int zeroBytes = mainMCUBytes.where((b) => b == 0x00).length;
    int ffBytes = mainMCUBytes.where((b) => b == 0xFF).length;
    Logger('Firmware byte statistics:');
    Logger('  - Total bytes: ${mainMCUBytes.length}');
    Logger(
      '  - Zero bytes (0x00): $zeroBytes (${(zeroBytes / mainMCUBytes.length * 100).toStringAsFixed(2)}%)',
    );
    Logger(
      '  - FF bytes (0xFF): $ffBytes (${(ffBytes / mainMCUBytes.length * 100).toStringAsFixed(2)}%)',
    );
    Logger('=== FIRMWARE BYTES DETAILS COMPLETE ===');

    Logger('=== VERSION EXTRACTION ===');
    final String mcuTypeName =
        selectedFirmwareType == 1 ? 'BleChipMCU' : 'MainMCU';
    await processMCUBytes(mainMCUBytes, mcuTypeName);

    Logger('=== MCU INFO LIST CREATION ===');
    await processAllMCUs();

    Logger('=== FILE READING COMPLETE ===');
  }

  /// Processes MCU bytes to extract version information
  Future<void> processMCUBytes(List<int> bytes, String mcuType) async {
    Logger('Processing $mcuType - Extracting version information');

    // Extract version string from MCU bytes
    // This is a simplified version - adjust based on your actual firmware format
    String version = 'Unknown';

    // Look for version pattern in the bytes
    // Adjust this logic based on your firmware format
    try {
      // Example: Look for version string starting at a specific offset
      // This is placeholder logic - replace with actual version extraction
      if (bytes.length > 100) {
        // Extract version from bytes (adjust offset as needed)
        List<int> versionBytes = bytes.sublist(
          bytes.length - 100,
          bytes.length,
        );
        version = _extractVersionString(versionBytes);
        Logger('$mcuType version extracted: $version');
        Logger(
          '$mcuType version bytes (last 100): ${versionBytes.length} bytes',
        );
      } else {
        Logger('$mcuType: File too small for version extraction (< 100 bytes)');
      }
    } catch (e) {
      Logger('Error extracting version for $mcuType: $e');
    }

    List<int> last100Bytes =
        bytes.length > 100
            ? bytes.sublist(bytes.length - 100)
            : List<int>.from(bytes);

    final mcuInfo = MCUInfo(
      mcuType: mcuType,
      version: version,
      byteData: bytes,
      last100Bytes: last100Bytes,
    );

    mcuInfoList.add(mcuInfo);

    Logger('$mcuType MCUInfo created:');
    Logger('  - Type: ${mcuInfo.mcuType}');
    Logger('  - Version: ${mcuInfo.version}');
    Logger('  - Byte data size: ${mcuInfo.byteData.length} bytes');
    Logger('  - Last 100 bytes size: ${mcuInfo.last100Bytes.length} bytes');
  }

  /// Extracts version string from bytes
  String _extractVersionString(List<int> bytes) {
    // This is a placeholder - implement actual version extraction logic
    // based on your firmware format
    try {
      String version = '';
      for (int i = 0; i < bytes.length && i < 20; i++) {
        if (bytes[i] >= 32 && bytes[i] <= 126) {
          version += String.fromCharCode(bytes[i]);
        }
      }
      return version.isNotEmpty ? version : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Processes all MCUs and prepares for comparison
  Future<void> processAllMCUs() async {
    // This method can be used to compare versions with device versions
    // and determine which MCUs need updating
    Logger('=== MCU INFO LIST CREATION ===');
    Logger('Total MCUs processed: ${mcuInfoList.length}');
    for (int i = 0; i < mcuInfoList.length; i++) {
      final mcu = mcuInfoList[i];
      Logger(
        'MCU[$i]: ${mcu.mcuType} - Version: ${mcu.version} - Size: ${mcu.byteData.length} bytes',
      );
    }
    Logger('MCU Info List creation complete');
  }

  /// Processes mismatched MCUs and starts the upgrade process
  Future<int> processMismatchedMCUs(List<int> mismatchedIndexes) async {
    if (mismatchedIndexes.isEmpty) {
      Logger("No mismatched MCUs to process.");
      return 0;
    }

    totalPacketLength.value = 0;
    mismatchedMcuInfos.clear();

    for (int index in mismatchedIndexes) {
      if (index < mcuInfoList.length) {
        final MCUInfo mcuInfo = mcuInfoList[index];
        mismatchedMcuInfos.add(mcuInfo);
        typeData = getTypeDataForMcu(mcuInfo.mcuType);

        Logger('=== PROCESSING MCU[$index]: ${mcuInfo.mcuType} ===');

        List<int> payLoadData = generatePayLoadFromFirmwareList(
          mcuInfo: mcuInfo,
        );

        try {
          Logger('=== PACKET LIST GENERATION ===');
          Logger('MCU Type: ${mcuInfo.mcuType}');
          Logger(
            'Using ${typeData == mainMcu ? "generateListOfWithOutFFLargePacketsFromPayload" : "generateListOfWithoutSkippingFFLargePacketsFromPayload"}',
          );
          Logger('Payload size: ${payLoadData.length} bytes');

          List<Uint8List> largePacketsList =
              (typeData == mainMcu)
                  ? await generateListOfWithOutFFLargePacketsFromPayload(
                    payLoadData,
                  )
                  : await generateListOfWithoutSkippingFFLargePacketsFromPayload(
                    payLoadData,
                  );

          Logger('Packet list generated for ${mcuInfo.mcuType}:');
          Logger('  - Total packets: ${largePacketsList.length}');
          Logger(
            '  - First packet size: ${largePacketsList.isNotEmpty ? largePacketsList[0].length : 0} bytes',
          );
          Logger(
            '  - Last packet size: ${largePacketsList.isNotEmpty ? largePacketsList[largePacketsList.length - 1].length : 0} bytes',
          );

          if (largePacketsList.isNotEmpty) {
            Logger(
              '  - First packet (first 16 bytes hex): ${largePacketsList[0].take(16).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
            );

            // Log first 3 packets completely for verification
            Logger(
              '[Uploaded File Hex values] === FIRST 3 PACKETS HEX DUMP ===',
            );
            for (int i = 0; i < largePacketsList.length && i < 3; i++) {
              Logger(
                '[Uploaded File Hex values] Packet $i (${largePacketsList[i].length} bytes):',
              );
              final packetHexDump = _formatHexDump(
                largePacketsList[i].toList(),
              );
              packetHexDump.split('\n').forEach((line) {
                if (line.isNotEmpty) {
                  Logger('[Uploaded File Hex values] $line');
                }
              });
            }
            Logger('[Uploaded File Hex values] === END FIRST 3 PACKETS ===');
          }

          totalPacketLength.value += largePacketsList.length;
          Logger('Total packet length updated: ${totalPacketLength.value}');
          Logger('=== PACKET LIST GENERATION COMPLETE ===');
        } catch (e) {
          Logger("Error generating packets: $e");
          return totalPacketLength.value;
        }
      }
    }

    if (mismatchedMcuInfos.isNotEmpty) {
      downloadingStatus.value = DownloadStatus.upgrading;
      tempCurrentIndex.value = 0;
      try {
        await readBinFile(mismatchedMcuInfos[0].byteData);
        selectedMcu(mismatchedMcuInfos[0].mcuType);
        mismatchedMcuInfos.removeAt(0);
        update();
      } catch (e) {
        Logger("Error in processing first mismatched MCU: $e");
      }
    }

    return totalPacketLength.value;
  }

  /// Generates payload from firmware list
  List<int> generatePayLoadFromFirmwareList({required MCUInfo mcuInfo}) {
    Logger('=== PAYLOAD GENERATION ===');
    Logger('Generating payload for ${mcuInfo.mcuType}');
    Logger('MCU byte data size: ${mcuInfo.byteData.length} bytes');

    final payload = List<int>.from(mcuInfo.byteData);

    Logger('Payload generated: ${payload.length} bytes');

    // Log complete payload hex dump
    _logCompleteHexDump('PAYLOAD DATA', payload);

    Logger(
      'Payload first 16 bytes (hex): ${payload.take(16).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );
    Logger(
      'Payload last 16 bytes (hex): ${payload.skip(payload.length - 16).take(16).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );

    // === DETAILED PAYLOAD LOGGING ===
    Logger('=== PAYLOAD DETAILS ===');
    Logger(
      'Payload first 32 bytes (hex): ${payload.take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );
    Logger(
      'Payload last 32 bytes (hex): ${payload.skip(payload.length - 32).take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
    );

    // Log payload middle section
    if (payload.length > 100) {
      int payloadMiddle = (payload.length * 0.5).round();
      Logger(
        'Payload middle (offset $payloadMiddle, 32 bytes hex): ${payload.skip(payloadMiddle).take(32).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}',
      );
    }

    // Payload byte statistics
    int payloadZeroBytes = payload.where((b) => b == 0x00).length;
    int payloadFfBytes = payload.where((b) => b == 0xFF).length;
    Logger('Payload byte statistics:');
    Logger('  - Total bytes: ${payload.length}');
    Logger(
      '  - Zero bytes (0x00): $payloadZeroBytes (${(payloadZeroBytes / payload.length * 100).toStringAsFixed(2)}%)',
    );
    Logger(
      '  - FF bytes (0xFF): $payloadFfBytes (${(payloadFfBytes / payload.length * 100).toStringAsFixed(2)}%)',
    );
    Logger('=== PAYLOAD DETAILS COMPLETE ===');

    Logger('=== PAYLOAD GENERATION COMPLETE ===');

    return payload;
  }

  /// Generates payload from device list (for resending)
  List<int> generatePayLoadFromDeviceList() {
    if (mismatchedMcuInfos.isNotEmpty) {
      return List<int>.from(mismatchedMcuInfos[0].byteData);
    }
    return [];
  }

  /// Gets type data for MCU
  List<int> getTypeDataForMcu(String mcuType) {
    switch (mcuType) {
      case 'MainMCU':
        return mainMcu;
      case 'RfMCU':
        return rfMcu;
      case 'NetMCU':
        return netMcu;
      default:
        return [];
    }
  }

  /// Reads binary file data
  Future<void> readBinFile(List<int> byteData) async {
    // Store the byte data for sending
    // This is used when sending firmware data
  }

  /// Sends firmware update data over BLE
  Future<void> sendFirmwareUpdateData({
    int sequenceNumber = 1,
    bool isResending = false,
  }) async {
    List<int> payLoadData = generatePayLoadFromDeviceList();
    List<Uint8List> largePacketsList =
        (typeData == mainMcu)
            ? await generateListOfWithOutFFLargePacketsFromPayload(
              payLoadData,
              sequenceNumber: sequenceNumber,
              isResending: isResending,
            )
            : await generateListOfWithoutSkippingFFLargePacketsFromPayload(
              payLoadData,
              sequenceNumber: sequenceNumber,
              isResending: isResending,
            );

    Get.find<BleNotifyDataHandler>().currentBleState(
      BleStateMachine.sendingLargePacketOnGoing,
    );

    await Future<dynamic>.delayed(const Duration(milliseconds: 50));

    if (dataTransferManager.loopGoingON) {
      dataTransferManager.stopSendingData = true;
    }

    await Future<dynamic>.delayed(const Duration(milliseconds: 100));

    dataTransferManager.sendLargeDataPacketsOverBle(
      isResending: isResending,
      largePacketsList: largePacketsList,
      sequenceNumber:
          sequenceNumber == -1 ? largePacketsList.length : sequenceNumber,
    );
  }

  /// Selects MCU and sends selection command
  void selectedMcu(String mcuType) {
    typeData = getTypeDataForMcu(mcuType);
    if (typeData.isEmpty) {
      return;
    }

    DataTransferManager().sendFirmwareUpgradeDataToBle(
      typeData,
      dataWritten: (bool isWritten) {
        Get.find<BleNotifyDataHandler>().currentBleState(
          BleStateMachine.mcuSelection,
        );
        update();
      },
    );
  }

  /// Checks if device is connected
  Future<bool> _isConnected() async {
    // Implement connection check logic
    // This should check if BLE device is connected
    return true; // Placeholder
  }

  /// Formats bytes as hex dump similar to Notepad++ hex view
  /// Format: OFFSET: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX
  String _formatHexDump(List<int> bytes, {int bytesPerLine = 16}) {
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += bytesPerLine) {
      final offset = i.toRadixString(16).padLeft(8, '0').toUpperCase();
      final lineBytes = bytes.skip(i).take(bytesPerLine).toList();
      final hexString = lineBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      buffer.writeln('$offset: $hexString');
    }
    return buffer.toString();
  }

  /// Logs complete hex dump of data for verification with filterable tag
  /// For large files (>10KB), only logs first 1KB, last 1KB, and a middle section
  void _logCompleteHexDump(String label, List<int> data) {
    const int maxFullDumpSize = 10 * 1024; // 10KB - log full dump if smaller
    const int sampleSize = 1024; // 1KB samples for large files

    Logger('[Uploaded File Hex values] === $label - HEX DUMP ===');
    Logger('[Uploaded File Hex values] Total bytes: ${data.length}');

    if (data.length <= maxFullDumpSize) {
      // Small files: log complete dump
      Logger(
        '[Uploaded File Hex values] Hex dump (Notepad++ format - COMPLETE):',
      );
      final hexDump = _formatHexDump(data);
      hexDump.split('\n').forEach((line) {
        if (line.isNotEmpty) {
          Logger('[Uploaded File Hex values] $line');
        }
      });
    } else {
      // Large files: log samples (first 1KB, middle 1KB, last 1KB)
      Logger(
        '[Uploaded File Hex values] Hex dump (Notepad++ format - SAMPLES for large file):',
      );

      // First 1KB
      Logger('[Uploaded File Hex values] --- FIRST ${sampleSize} BYTES ---');
      final firstSample = data.take(sampleSize).toList();
      final firstHexDump = _formatHexDump(firstSample);
      firstHexDump.split('\n').forEach((line) {
        if (line.isNotEmpty) {
          Logger('[Uploaded File Hex values] $line');
        }
      });

      // Middle 1KB (if file is large enough)
      if (data.length > sampleSize * 2) {
        final middleStart = (data.length / 2 - sampleSize / 2).round();
        Logger(
          '[Uploaded File Hex values] --- MIDDLE SECTION (offset: 0x${middleStart.toRadixString(16).toUpperCase()}, ${sampleSize} bytes) ---',
        );
        final middleSample = data.skip(middleStart).take(sampleSize).toList();
        final middleHexDump = _formatHexDump(middleSample);
        middleHexDump.split('\n').forEach((line) {
          if (line.isNotEmpty) {
            Logger('[Uploaded File Hex values] $line');
          }
        });
      }

      // Last 1KB
      Logger('[Uploaded File Hex values] --- LAST ${sampleSize} BYTES ---');
      final lastSample =
          data.skip(data.length - sampleSize).take(sampleSize).toList();
      final lastHexDump = _formatHexDump(lastSample);
      lastHexDump.split('\n').forEach((line) {
        if (line.isNotEmpty) {
          Logger('[Uploaded File Hex values] $line');
        }
      });
    }

    Logger('[Uploaded File Hex values] === END $label HEX DUMP ===');
  }

  /// Simulates BLE responses in test mode to show progress
  /// This method simulates the entire firmware upgrade flow without actual BLE communication
  Future<void> simulateBleFirmwareUpgrade() async {
    Logger('=== TEST MODE: Simulating BLE firmware upgrade flow ===');

    try {
      // Ensure MCU data is loaded for simulation
      if (mismatchedMcuInfos.isNotEmpty && mainMCUBytes.isEmpty) {
        Logger('TEST MODE: Loading MCU data for simulation');
        final firstMcu = mismatchedMcuInfos[0];
        await readBinFile(firstMcu.byteData);
        typeData = getTypeDataForMcu(firstMcu.mcuType);
      }

      // Ensure totalPacketLength is set - use the value from processMismatchedMCUs
      if (totalPacketLength.value == 0) {
        Logger('TEST MODE: totalPacketLength is 0, calculating from MCU data');
        // Calculate packet count from the first MCU
        if (mismatchedMcuInfos.isNotEmpty) {
          final firstMcu = mismatchedMcuInfos[0];
          List<int> payLoadData = List<int>.from(firstMcu.byteData);
          List<Uint8List> testPackets =
              (typeData == mainMcu)
                  ? await generateListOfWithOutFFLargePacketsFromPayload(
                    payLoadData,
                  )
                  : await generateListOfWithoutSkippingFFLargePacketsFromPayload(
                    payLoadData,
                  );
          totalPacketLength.value = testPackets.length;
          Logger(
            'TEST MODE: Calculated totalPacketLength: ${totalPacketLength.value}',
          );
        }
      }

      // Initialize progress
      tempCurrentIndex.value = 0;
      progressbarIndex.value = 0;
      progressbarCount.value = 0.0;
      update(); // Trigger GetX reactivity

      // Step 1: Simulate MCU Selection ACK
      Logger('TEST MODE: Simulating MCU Selection ACK');
      await Future.delayed(const Duration(milliseconds: 500));

      if (Get.isRegistered<BleNotifyDataHandler>()) {
        final bleHandler = Get.find<BleNotifyDataHandler>();
        bleHandler.currentBleState(BleStateMachine.mcuSelection);
      }

      // Step 2: Simulate EOF Image Data ACK
      Logger('TEST MODE: Simulating EOF Image Data ACK');
      await Future.delayed(const Duration(milliseconds: 500));

      if (Get.isRegistered<BleNotifyDataHandler>()) {
        final bleHandler = Get.find<BleNotifyDataHandler>();
        bleHandler.currentBleState(BleStateMachine.eofImageData);
      }

      // Step 3: Simulate Data Sync Request ACK
      Logger('TEST MODE: Simulating Data Sync Request ACK');
      await Future.delayed(const Duration(milliseconds: 500));

      if (Get.isRegistered<BleNotifyDataHandler>()) {
        final bleHandler = Get.find<BleNotifyDataHandler>();
        bleHandler.currentBleState(BleStateMachine.respondedDataSyncRequest);
      }

      // Step 4: Simulate sending firmware chunks with progress updates
      Logger('TEST MODE: Simulating firmware chunk transmission');

      // Get the packet list for progress simulation
      List<Uint8List> largePacketsList;
      int packetCount = 0;

      try {
        List<int> payLoadData = generatePayLoadFromDeviceList();
        if (payLoadData.isEmpty && mismatchedMcuInfos.isNotEmpty) {
          payLoadData = List<int>.from(mismatchedMcuInfos[0].byteData);
        }

        largePacketsList =
            (typeData == mainMcu)
                ? await generateListOfWithOutFFLargePacketsFromPayload(
                  payLoadData,
                )
                : await generateListOfWithoutSkippingFFLargePacketsFromPayload(
                  payLoadData,
                );
        packetCount = largePacketsList.length;

        // Update totalPacketLength if it's still 0
        if (totalPacketLength.value == 0) {
          totalPacketLength.value = packetCount;
        }

        Logger('TEST MODE: Generated ${packetCount} packets for simulation');
        Logger('TEST MODE: totalPacketLength: ${totalPacketLength.value}');
      } catch (e) {
        Logger('TEST MODE: Error generating packet list: $e');
        // Fallback: use totalPacketLength if available
        packetCount =
            totalPacketLength.value > 0 ? totalPacketLength.value : 10;
        largePacketsList = List.generate(
          packetCount,
          (index) => Uint8List(256),
        );
        Logger('TEST MODE: Using fallback packet count: $packetCount');
      }

      if (Get.isRegistered<BleNotifyDataHandler>()) {
        final bleHandler = Get.find<BleNotifyDataHandler>();
        bleHandler.currentBleState(BleStateMachine.sendingLargePacketOnGoing);
        bleHandler.currentLargePacketModule.value =
            LargePacketModule.firmWareUpgrade;
      }

      // Simulate progress for each packet
      Logger('TEST MODE: Starting packet transmission simulation...');

      final int totalPackets =
          totalPacketLength.value > 0 ? totalPacketLength.value : packetCount;

      for (int i = 0; i < totalPackets; i++) {
        // Simulate packet transmission delay (longer delay for visibility)
        await Future.delayed(const Duration(milliseconds: 100));

        // Update progress observables
        tempCurrentIndex.value = i;
        progressbarIndex.value = i + 1;

        // Calculate progress percentage
        if (totalPackets > 0) {
          progressbarCount.value =
              (progressbarIndex.value.toDouble() / totalPackets.toDouble());
        } else {
          progressbarCount.value =
              ((i + 1).toDouble() / totalPackets.toDouble());
        }

        // Trigger GetX reactivity update
        update();

        // Log progress every 10 packets or at milestones
        if ((i + 1) % 10 == 0 || (i + 1) == totalPackets || (i + 1) == 1) {
          Logger(
            'TEST MODE: Progress: ${(progressbarCount.value * 100).toStringAsFixed(1)}% (${i + 1}/$totalPackets packets)',
          );
        }
      }

      // Ensure progress is at 100% after all packets
      progressbarIndex.value = totalPackets;
      progressbarCount.value = 1.0;
      update();
      Logger('TEST MODE: All packets simulated. Progress: 100%');

      // Step 5: Simulate Data End Request ACK
      Logger('TEST MODE: Simulating Data End Request ACK');
      await Future.delayed(const Duration(milliseconds: 500));

      if (Get.isRegistered<BleNotifyDataHandler>()) {
        final bleHandler = Get.find<BleNotifyDataHandler>();
        bleHandler.currentBleState(BleStateMachine.respondToEndPacket);
      }

      // Step 6: Complete the upgrade
      Logger('TEST MODE: Firmware upgrade simulation completed');
      await Future.delayed(const Duration(milliseconds: 500));

      downloadingStatus.value = DownloadStatus.completed;
      progressbarCount.value = 1.0;
      update();

      Logger('=== TEST MODE: BLE firmware upgrade simulation complete ===');
    } catch (e, stackTrace) {
      Logger('TEST MODE: Error during simulation: $e');
      Logger('TEST MODE: Stack trace: $stackTrace');
      downloadingStatus.value = DownloadStatus.failed;
      update();
    }
  }
}
