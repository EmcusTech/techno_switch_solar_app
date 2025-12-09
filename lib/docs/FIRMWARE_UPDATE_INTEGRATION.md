# Firmware Update Integration Guide

This document explains how the firmware update functionality has been integrated into the project.

## Overview

The firmware update system allows downloading firmware files, validating them via CRC checks, splitting them into MCU segments (MainMCU, RfMCU, NetMCU), and uploading them to the device via BLE.

## Components

### 1. Models

#### `MCUInfo` (`lib/models/mcu_info.dart`)
Stores information about each MCU:
- `mcuType`: Type of MCU ('MainMCU', 'RfMCU', 'NetMCU')
- `version`: Version string extracted from firmware
- `byteData`: Complete firmware bytes for this MCU
- `last100Bytes`: Last 100 bytes needed for EOF frame

### 2. Services

#### `FirmwareUpgradeService` (`lib/services/firmware_upgrade_service.dart`)
Handles firmware file validation:
- **`handleDownloadResponse()`**: Validates CRC32 (file) and CRC16 (version) checksums
- Extracts version information from the last 17 bytes of the firmware file
- Verifies file integrity before allowing upgrade

### 3. Controllers

#### `UpdatesController` (`lib/controllers/updates_controller.dart`)
Main controller for firmware update operations:

**Key Methods:**
- `downloadFile()`: Downloads firmware from URL
- `readAndSplitBinFile()`: Splits binary into MCU segments
- `processMCUBytes()`: Extracts version info from MCU bytes
- `processMismatchedMCUs()`: Processes MCUs that need updating
- `sendFirmwareUpdateData()`: Sends firmware chunks over BLE
- `selectedMcu()`: Sends MCU selection command

**Observable State:**
- `downloadingStatus`: Current status (downloading, ready, upgrading, completed, failed)
- `downloadProgress`: Download progress (0-100)
- `isDownloaded`: Whether file is downloaded
- `isFileCrcMatched`: Whether CRC validation passed
- `progressbarIndex`: Current packet index
- `progressbarCount`: Progress percentage (0.0-1.0)
- `totalPacketLength`: Total number of packets to send

### 4. BLE Integration

#### `BleNotifyDataHandler` (`lib/utils/bluetooth/ble_notify_data_handler.dart`)
Handles firmware update responses:

**New Handlers:**
- `_handleMcuSelectionProcess()`: Handles MCU selection ACK/NACK
- `_handleEofImageDataProcess()`: Handles EOF image data response
- `_handleDataSyncRequestProcess()`: Handles data sync request
- `_handleDataStartRequestProcess()`: Handles data start request
- `_handleLargePacketProcess()`: Handles large packet responses
- `_handleDataEndRequestProcess()`: Handles data end request

#### `DataTransferManager` (`lib/utils/bluetooth/data_transfer_manager.dart`)
Sends firmware data:
- `sendFirmwareUpgradeDataToBle()`: Sends MCU selection command
- `sendEofImageDataToBle()`: Sends EOF image data (last 100 bytes)
- `sendLargeDataPacketsOverBle()`: Sends firmware chunks with progress tracking

## Usage Flow

### 1. Download Firmware

```dart
final UpdatesController controller = Get.put(UpdatesController());

// Download firmware file
PlatformFile? file = await controller.downloadFile(
  'https://example.com/firmware.bin',
  'firmware.bin',
  '1.0.0',
);

if (file != null && controller.isFileCrcMatched.value) {
  // CRC validation passed, proceed with upgrade
}
```

### 2. Process Firmware File

```dart
if (controller.selectedFirmwareFile != null) {
  await controller.readAndSplitBinFile(
    controller.selectedFirmwareFile!.path!,
  );
  
  // MCUs are now split and versions extracted
  // Compare with device versions to determine which need updating
}
```

### 3. Start Firmware Upgrade

```dart
// Determine which MCUs need updating (example)
List<int> mismatchedIndexes = [0, 1, 2]; // MainMCU, RfMCU, NetMCU

// Process mismatched MCUs
int totalPackets = await controller.processMismatchedMCUs(mismatchedIndexes);

// The upgrade will start automatically
// Monitor progress via observables:
controller.downloadingStatus.listen((status) {
  print('Status: $status');
});

controller.progressbarCount.listen((progress) {
  print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
});
```

## Firmware File Format

The firmware binary file structure:
- **MainMCU**: Offset 0x00000000, Size 0x001E8000 (1,920 KB)
- **RfMCU**: Offset 0x001E8000, Size 0x00080000 (512 KB)
- **NetMCU**: Offset 0x00268000, Size 0x00020000 (128 KB)
- **Version Info**: Last 17 bytes contain:
  - Bytes 0-3: File CRC32 (big-endian)
  - Bytes 4-14: OEM ID and Version (11 bytes)
  - Bytes 15-16: Version CRC16 (big-endian)

## BLE Protocol Flow

1. **MCU Selection**: Send MCU type data → Wait for ACK
2. **EOF Image Data**: Send last 100 bytes → Wait for ACK
3. **Data Sync Request**: Request data sync → Wait for ACK
4. **Send Firmware Chunks**: Send chunks sequentially with progress tracking
5. **Data End Request**: Send end packet → Wait for ACK
6. **Next MCU**: If more MCUs, repeat from step 1

## Error Handling

- **NACK Response**: Upgrade fails, status set to `DownloadStatus.failed`
- **CRC Mismatch**: File rejected before upgrade starts
- **Connection Loss**: Handle reconnection and resume if needed
- **Timeout**: Retry mechanism can be implemented

## Dependencies Added

- `dio`: ^5.4.0 - HTTP client for downloading firmware
- `path_provider`: ^2.1.1 - File system paths
- `file_picker`: ^6.1.1 - File selection (if needed)

## Notes

- The UI layer is not included - implement your own UI to display progress and status
- Version extraction logic may need adjustment based on your firmware format
- MCU type data (`mainMcu`, `rfMcu`, `netMcu`) needs to be set based on your protocol
- Connection check (`_isConnected()`) should verify BLE device connection
- The system supports resending packets on failure (handled by `DataTransferManager`)

## Example UI Integration

```dart
class FirmwareUpdateScreen extends StatelessWidget {
  final UpdatesController controller = Get.find<UpdatesController>();
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          // Download progress
          if (controller.downloadingStatus.value == DownloadStatus.downloading)
            LinearProgressIndicator(
              value: controller.downloadProgress.value / 100,
            ),
          
          // Upgrade progress
          if (controller.downloadingStatus.value == DownloadStatus.upgrading)
            LinearProgressIndicator(
              value: controller.progressbarCount.value,
            ),
          
          // Status text
          Text('Status: ${controller.downloadingStatus.value.name}'),
          
          // Progress percentage
          if (controller.downloadingStatus.value == DownloadStatus.upgrading)
            Text(
              '${(controller.progressbarCount.value * 100).toStringAsFixed(1)}%',
            ),
        ],
      );
    });
  }
}
```

