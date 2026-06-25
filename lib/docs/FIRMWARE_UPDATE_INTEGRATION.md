# Firmware Update Integration Guide

This document explains how firmware update works in the app.

## Overview

The firmware update system downloads firmware files, validates CRC checksums, splits them into MCU segments, and uploads them to the device over BLE via `BleManager`.

## Components

### Services

#### `FirmwareUpgradeService` (`lib/services/firmware_upgrade_service.dart`)

Validates downloaded firmware:

- CRC32 (file) and CRC16 (version) checks
- Version extraction from the last 17 bytes of the firmware file

#### `FirmwarePacketService` (`lib/services/firmware_packet_service.dart`)

Builds logical packets for OTA transfer.

### Controllers

#### `UpdatesController` (`lib/controllers/updates_controller.dart`)

Main controller for firmware operations:

- `downloadFile()` — download from URL
- Packet preparation and progress tracking
- Observable `downloadingStatus`, `downloadProgress`, etc.

### BLE integration

#### `BleManager` / `BleProcess` (`lib/ble/`)

Handles the full OTA state machine: MCU selection, EOF image, sync, large packets, and end-of-transfer.

#### `FirmwareUpgradeBottomSheet` (`lib/widgets/firmware_upgrade_bottom_sheet.dart`)

UI flow for file pick, validation, progress, and reconnect-after-jump logic. Uses `BleLogController` and `BleManager` directly for packet send and status.

## Usage flow

1. User opens firmware upgrade from the updates UI.
2. File is downloaded or picked locally; `FirmwareUpgradeService` validates CRC.
3. `UpdatesController` splits the binary into MCU segments and builds packets.
4. `FirmwareUpgradeBottomSheet` sends packets through `BleManager` OTA APIs.
5. On BLE chip jump, the sheet rescans and reconnects using `BluetoothService`.

## Related files

- `lib/ble/ble_manager.dart` — OTA send/receive
- `lib/ble/ble_process.dart` — OTA process state
- `lib/utils/bluetooth_service.dart` — scan/reconnect helper
