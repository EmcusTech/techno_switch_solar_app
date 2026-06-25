import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:techno_switch_solar_app/ble/ble_session_idle_policy.dart';
import 'package:techno_switch_solar_app/models/ble/firmware/firmware_packet_model.dart';
import 'package:techno_switch_solar_app/widgets/common/common_cta_button.dart';
import '../ble/ble_manager.dart';
import '../ble/controller/ble_log_controller.dart';
import '../controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/services/firmware_upgrade_service.dart'
    as fw;
import 'package:techno_switch_solar_app/utils/bluetooth_service.dart'
    as app_bluetooth;
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/ble_msd_utils.dart';
import 'package:techno_switch_solar_app/utils/logger.dart' as logger;

final BleManager ble = Get.find<BleManager>();

enum FirmwareType { mainPanel, bleChip }

enum FirmwareUpgradeStep {
  essentialSteps,
  connectDevice,
  chooseType,
  fileUpload,
  fileDetails,
  progress,
  result,
}

class FirmwareUpgradeBottomSheet extends StatefulWidget {
  final DiscoveredDevice? connectedDevice;

  const FirmwareUpgradeBottomSheet({super.key, this.connectedDevice});

  @override
  State<FirmwareUpgradeBottomSheet> createState() =>
      _FirmwareUpgradeBottomSheetState();
}

class _FirmwareUpgradeBottomSheetState extends State<FirmwareUpgradeBottomSheet>
    with SingleTickerProviderStateMixin {
  final UpdatesController _controller = Get.find<UpdatesController>();
  FirmwareUpgradeStep _currentStep = FirmwareUpgradeStep.essentialSteps;
  FirmwareType? _selectedFirmwareType;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isUpgrading = false;
  bool _isValidating = false;
  bool _isValidatingSuccess = false;
  bool _testMode = false;
  String? _errorMessage;
  String? _currentBleStateMessage;
  fw.FirmwareValidationResult? _validationResult;

  // BLE connection state
  DiscoveredDevice? _selectedDevice;

  // Internal reconnect state for firmware upgrade
  bool _isWaitingForJumpReconnect = false;
  bool _isWaitingForEndReconnect = false;
  String? _originalDeviceName; // Store device name for reconnection
  String?
  _originalStableDeviceId; // Last 8 chars - stable across name changes (P_87654321 vs TECHNOSWITCH_87654321)
  int? _originalManufacturerData; // Store manufacturer data before jump command
  StreamSubscription<ConnectionStateUpdate>? _internalReconnectSub;
  bool _bootloaderNotifyReady = false;

  // Bluetooth service for internal reconnect (only used for reconnecting after jump/end commands)
  final app_bluetooth.BluetoothService _bluetoothService =
      app_bluetooth.BluetoothService();
  StreamSubscription? _bleResultsSub;

  // Tuning knobs to reduce reconnect latency while keeping BLE stable.
  static const Duration _bleShortDelay = Duration(milliseconds: 800);
  static const Duration _bleConnectSettleDelay = Duration(milliseconds: 600);
  static const Duration _jumpReconnectInitialDelay = Duration(seconds: 2);
  static const Duration _endReconnectInitialDelay = Duration(seconds: 1);
  static const Duration _jumpScanGlobalTimeout = Duration(seconds: 6);
  static const Duration _endScanGlobalTimeout = Duration(seconds: 10);
  static const Duration _scanRetryDelay = Duration(milliseconds: 800);

  void _beginFirmwareSession() {
    BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value = true;
    BleSessionIdlePolicy.suppressIdleDisconnect.value = true;
  }

  void _endFirmwareSession() {
    BleSessionIdlePolicy.suppressFirmwareDisconnectUi.value = false;
    BleSessionIdlePolicy.suppressIdleDisconnect.value = false;
  }

  @override
  void initState() {
    super.initState();

    // Get connected device from widget parameter or from BleManager
    if (widget.connectedDevice != null) {
      _selectedDevice = widget.connectedDevice;
      print(
        'DEBUG INIT: Device from widget - Name: ${_selectedDevice!.name}, Manufacturer data: ${_selectedDevice!.manufacturerData}, Length: ${_selectedDevice!.manufacturerData.length}',
      );
    } else {
      // Try to get connected device from BleManager
      try {
        final bleController = Get.find<BleLogController>();
        final bleManager = bleController.bleManager;
        if (bleManager.isConnected && bleManager.selectedDevice != null) {
          _selectedDevice = bleManager.selectedDevice;
          print(
            'DEBUG INIT: Device from BleManager - Name: ${_selectedDevice!.name}, Manufacturer data: ${_selectedDevice!.manufacturerData}, Length: ${_selectedDevice!.manufacturerData.length}',
          );
        }
      } catch (e) {
        logger.Logger('Error getting connected device: $e');
      }
    }

    // If device is available and connected, skip to chooseType step
    // if (_selectedDevice != null) {
    //   final bleController = Get.find<BleLogController>();
    //   if (bleController.isConnected) {
    //     _currentStep = FirmwareUpgradeStep.chooseType;
    //   }
    // }

    // Listen to download status changes
    _controller.downloadingStatus.listen((status) {
      if (mounted) {
        if (status == fw.DownloadStatus.upgrading) {
          setState(() {
            if (_currentStep == FirmwareUpgradeStep.fileDetails ||
                _currentStep == FirmwareUpgradeStep.progress) {
              _currentStep = FirmwareUpgradeStep.progress;
              _isUpgrading = true;
            }
          });
        } else if (status == fw.DownloadStatus.completed) {
          setState(() {
            _currentStep = FirmwareUpgradeStep.result;
            _isUpgrading = false;
            _errorMessage = null;
          });
        } else if (status == fw.DownloadStatus.failed) {
          setState(() {
            _currentStep = FirmwareUpgradeStep.result;
            _isUpgrading = false;
            _errorMessage = _errorMessage ?? 'Firmware upgrade failed';
          });
        }
      }
    });

  }

  Future<void> _sendPacketsOverBle({bool? isChipInBootLoader = false}) async {
    if (_controller.packetResult == null ||
        _controller.packetResult!.packets.isEmpty) {
      throw Exception('No packets prepared');
    }

    _beginFirmwareSession();
    try {
      await _sendPacketsOverBleImpl(isChipInBootLoader: isChipInBootLoader);
    } finally {
      _endFirmwareSession();
    }
  }

  Future<void> _sendPacketsOverBleImpl({
    bool? isChipInBootLoader = false,
  }) async {
    // if (_bleHandler.currentBleState.value != BleStateMachine.connected) {
    //   throw Exception('Device not connected. Complete BLE handshake first.');
    // }

    // Try to get BleManager via BleLogController if registered
    BleManager? manager;
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }

    final packets = _controller.packetResult!.packets;
    final logicalTotal = _controller.packetResult!.totalLogicalPackets;

    int logicalIndex = 0;

    if (manager != null) {
      manager.resetFirmwareState();
      _bootloaderNotifyReady = false;
      print("isChipInBootLoader: $isChipInBootLoader");

      // Store original device name, stable ID, and manufacturer data before jump command
      if (isChipInBootLoader != true && _selectedDevice != null) {
        _originalDeviceName = _selectedDevice!.name;
        _originalStableDeviceId = BleNameUtils.getDisplayIdFromBleName(
          _selectedDevice!.name,
        );
        // Store manufacturer data before jump command
        final md = _selectedDevice!.manufacturerData;
        _originalManufacturerData = BleMsdUtils.statusByte(md);
        logger.Logger(
          'Stored device info before jump - name: $_originalDeviceName, manufacturer data array: $md, status byte: $_originalManufacturerData',
        );
        print(
          'DEBUG: Before jump - Full manufacturer data: $md, Length: ${md.length}, Status byte: $_originalManufacturerData',
        );
      }

      if (isChipInBootLoader != true) {
        if (!manager.isConnected) {
          throw Exception('Device not connected. Cannot send jump command.');
        }
        if (!manager.handshakeCompleteNotifier.value) {
          throw Exception(
            'BLE handshake not complete. Cannot start firmware upgrade.',
          );
        }

        // Jump uses plaintext framing on the existing session; no enc-key re-request.
        manager.setFirmwareState(BleStates.SEND_JUMP_FIRMWARE_PACKET);

        try {
          await manager.sendJumpFirmwarePacket(withoutResponse: true);
        } catch (e) {
          // Expected: device disconnects after jump packet, causing write to fail
          logger.Logger('Jump packet sent, device disconnected (expected): $e');
        }

        await Future.delayed(const Duration(milliseconds: 300));

        // Start internal reconnect after jump command
        setState(() {
          _isWaitingForJumpReconnect = true;
          _currentBleStateMessage = 'Checking device status...';
        });
        await _reconnectAndCheckStatus(isJumpCommand: true);

        // After reconnect, wait a bit before continuing
        // Device needs time to stabilize in bootloader mode
        await Future.delayed(_bleShortDelay);
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (!_bootloaderNotifyReady) {
        await manager.registerNotifyHandlerForFirmwareUpgrade(
          isChipInBootLoader: true,
        );
        await Future.delayed(_bleShortDelay);
      }
      manager.setFirmwareState(BleStates.SEND_START_FIRMWARE_PACKET);

      // Send start firmware packet - might fail if device disconnects
      try {
        await manager.sendStartFirmwarePacket();
      } catch (e) {
        // If device disconnects, wait and reconnect again
        logger.Logger(
          'Start firmware packet failed, device may have disconnected: $e',
        );
        // Wait for device to reconnect
        await Future.delayed(const Duration(seconds: 2));
        // Try to reconnect if needed
        if (!manager.isConnected && _originalDeviceName != null) {
          setState(() {
            _isWaitingForJumpReconnect = true;
            _currentBleStateMessage = 'Checking device status...';
          });
          await _reconnectAndCheckStatus(isJumpCommand: true);
          await Future.delayed(const Duration(seconds: 2));
          // Retry start packet after reconnect
          try {
            await manager.sendStartFirmwarePacket();
          } catch (e2) {
            logger.Logger('Start firmware packet retry failed: $e2');
            throw Exception(
              'Failed to send start firmware packet after reconnect: $e2',
            );
          }
        } else {
          throw Exception('Failed to send start firmware packet: $e');
        }
      }

      print("Sending firmware packets...");

      await Future.delayed(const Duration(milliseconds: 300));
      manager.setFirmwareState(BleStates.SEND_FIRMWARE_PACKET);
      // Replace the existing print
      int seqFromField = 0;

      for (FirmwarePacket packet in packets) {
        final int currentSeqFromField = packet.sequence;
        print("currentSeqFromField: $currentSeqFromField");
        await manager.sendFirmwarePacket(
          Uint8List.fromList(packet.bytes),
          isFirstPacketAfterSkip: currentSeqFromField != (seqFromField + 1),
        );
        await Future.delayed(const Duration(milliseconds: 8));
        seqFromField = currentSeqFromField;
        logicalIndex++;
        _controller.progressbarIndex.value = logicalIndex;
        _controller.progressbarCount.value =
            logicalTotal == 0 ? 0 : logicalIndex / logicalTotal;
      }

      await Future.delayed(const Duration(milliseconds: 300));
      manager.setFirmwareState(BleStates.SEND_END_FIRMWARE_PACKET);

      // Store device name before sending end packet (device will disconnect)
      if (_selectedDevice != null) {
        _originalDeviceName = _selectedDevice!.name;
      }

      setState(() {
        _isWaitingForEndReconnect = true;
        _currentBleStateMessage = 'Fetching Firmware Upgrade status...';
      });

      // Send end packet - expect it to fail when device disconnects
      try {
        await manager.sendEndFirmwarePacket();
      } catch (e) {
        // Expected: device disconnects after end packet, causing write to fail
        logger.Logger('End packet sent, device disconnected (expected): $e');
      }

      // Start internal reconnect after end command

      // Short grace period to allow disconnect/reboot to begin before scanning
      await Future.delayed(_bleShortDelay);
      await _reconnectAndCheckStatus(isJumpCommand: false);
    } else {
      // Fallback: just simulate progress if manager unavailable
      // for (final _ in packets) {
      //   logicalIndex++;
      //   _controller.progressbarIndex.value = logicalIndex;
      //   _controller.progressbarCount.value =
      //       logicalTotal == 0 ? 0 : logicalIndex / logicalTotal;
      //   await Future.delayed(const Duration(milliseconds: 20));
      // }
      throw Exception('BLE manager not found');
    }

    _controller.downloadingStatus.value = fw.DownloadStatus.completed;
  }

  /// Internal method to reconnect and check firmware upgrade status
  Future<void> _reconnectAndCheckStatus({required bool isJumpCommand}) async {
    if (_originalDeviceName == null || _originalDeviceName!.isEmpty) {
      logger.Logger('No device name stored for reconnection');
      setState(() {
        _isWaitingForJumpReconnect = false;
        _isWaitingForEndReconnect = false;
        _errorMessage = 'Unable to reconnect: Device name not found';
      });
      return;
    }

    try {
      // Wait longer for device to disconnect and restart (especially for jump command)
      // Jump command causes device reboot, so it needs more time
      await Future.delayed(
        isJumpCommand ? _jumpReconnectInitialDelay : _endReconnectInitialDelay,
      );

      // Start scanning internally
      await _bluetoothService.requestPermissions();
      final poweredOn = await _bluetoothService.ensurePoweredOn();

      if (!poweredOn) {
        setState(() {
          _isWaitingForJumpReconnect = false;
          _isWaitingForEndReconnect = false;
          _errorMessage = 'Bluetooth is not enabled';
        });
        return;
      }

      // Single continuous scan with a global timeout (faster than attempt loops)
      DiscoveredDevice? device;
      int? scanLastByte;
      int? manufacturerDataFromScan;
      final Completer<void> scanDoneCompleter = Completer<void>();
      StreamSubscription? internalScanSub;
      Timer? scanTimeoutTimer;

      logger.Logger(
        'Starting reconnect scan (${isJumpCommand ? "jump" : "end"} command) with global timeout',
      );

      internalScanSub = _bluetoothService.scanResultsStream.listen((results) {
        for (var result in results) {
          // Log all scanned devices for debugging
          print(
            'DEBUG SCAN: Device found - Name: ${result.name}, ID: ${result.id}, Manufacturer data: ${result.manufacturerData}, Length: ${result.manufacturerData.length}',
          );

          final manufacturerData = result.manufacturerData;
          final statusByte = BleMsdUtils.statusByte(manufacturerData);
          final stableId = BleNameUtils.getDisplayIdFromBleName(result.name);

          if (isJumpCommand) {
            // For jump: prioritize device with bootloader status and matching stable ID
            // Handles name change: P_87654321 -> TECHNOSWITCH_87654321 (both have "87654321")
            final matchesStableId =
                _originalStableDeviceId != null &&
                stableId.isNotEmpty &&
                stableId == _originalStableDeviceId;
            final isBootloader = BleMsdUtils.isBootloader(manufacturerData);

            if (matchesStableId && isBootloader) {
              device = result;
              scanLastByte = statusByte;
              manufacturerDataFromScan = statusByte;
              logger.Logger(
                'Found bootloader device ${result.name} (stable ID match) with manufacturer data: $manufacturerData',
              );
              if (!scanDoneCompleter.isCompleted) {
                scanDoneCompleter.complete();
              }
              return;
            }
            // Fallback: exact name match with bootloader (old firmware where name doesn't change)
            if (result.name == _originalDeviceName && isBootloader) {
              device = result;
              scanLastByte = statusByte;
              manufacturerDataFromScan = statusByte;
              logger.Logger(
                'Found bootloader device ${result.name} (name match) with manufacturer data: $manufacturerData',
              );
              if (!scanDoneCompleter.isCompleted) {
                scanDoneCompleter.complete();
              }
              return;
            }
          } else {
            // End command: match by name as before
            if (result.name == _originalDeviceName) {
              device = result;
              if (manufacturerData.isNotEmpty) {
                manufacturerDataFromScan = statusByte;
                scanLastByte = manufacturerDataFromScan;
              }
              logger.Logger(
                'Found device ${result.name} with manufacturer data array: $manufacturerData (status byte: $scanLastByte)',
              );
              if (scanLastByte == BleMsdUtils.statusUpgradeSuccess) {
                if (!scanDoneCompleter.isCompleted) {
                  scanDoneCompleter.complete();
                }
              }
            }
          }
        }
      });

      // Start scanning
      await _bluetoothService.startScanning(
        disconnectIfConnected: true,
        postDisconnectDelay: _scanRetryDelay,
      );

      // Global timeout for scan
      scanTimeoutTimer = Timer(
        isJumpCommand ? _jumpScanGlobalTimeout : _endScanGlobalTimeout,
        () {
          if (!scanDoneCompleter.isCompleted) {
            scanDoneCompleter.complete();
          }
        },
      );

      await scanDoneCompleter.future;

      await internalScanSub.cancel();
      await _bluetoothService.stopScanning();
      scanTimeoutTimer.cancel();

      if (device == null) {
        setState(() {
          _isWaitingForJumpReconnect = false;
          _isWaitingForEndReconnect = false;
          _errorMessage =
              'Device not found. Please ensure device is powered on.';
        });
        return;
      }

      // Check manufacturer data from scan first
      // scanLastByte may already be set from scan results, but ensure it's set
      final scanManufacturerData = device!.manufacturerData;
      if (scanLastByte == null && scanManufacturerData.isNotEmpty) {
        scanLastByte = BleMsdUtils.statusByte(scanManufacturerData);
      }

      print(
        'DEBUG: After scan complete - Device: ${device!.name}, Full manufacturer data array: $scanManufacturerData, Length: ${scanManufacturerData.length}, Status byte: $scanLastByte',
      );
      logger.Logger(
        'Device found: ${device!.name}, Manufacturer data from scan (full array): $scanManufacturerData (status byte: $scanLastByte)',
      );

      // If we have manufacturer data from scan, check it first
      // For jump command: expect [0,1]
      // For end command: expect [0,2] for success
      if (scanLastByte != null) {
        if (isJumpCommand) {
          // Jump command: expect bootloader status byte
          if (scanLastByte == BleMsdUtils.statusBootloader) {
            // Success - device is in bootloader mode
            setState(() {
              _isWaitingForJumpReconnect = false;
              _selectedDevice = device;
              _currentBleStateMessage = 'Device ready. Continuing upgrade...';
            });
            // Still need to connect for continuing the upgrade
            // Fall through to connection logic
          } else {
            logger.Logger(
              'Unexpected manufacturer data for jump command: $scanLastByte (expected 1)',
            );
            // Still try to connect
          }
        } else {
          // End command: expect [0,2] for success, [0,1] for failed
          // Update message to show we're validating
          setState(() {
            _isValidatingSuccess = true;
            _currentBleStateMessage = 'Validating firmware upgrade success...';
          });

          if (scanLastByte == BleMsdUtils.statusUpgradeSuccess) {
            // Success - upgrade completed
            setState(() {
              _isWaitingForEndReconnect = false;
              _selectedDevice = device;
              _currentBleStateMessage =
                  'Firmware upgrade completed successfully!';
            });
            _controller.downloadingStatus.value = fw.DownloadStatus.completed;
            logger.Logger('Firmware upgrade SUCCESS confirmed from MSD [0,2]');
            return; // No need to connect, we have the status
          } else if (scanLastByte == BleMsdUtils.statusBootloader) {
            // Failed - device still in bootloader mode
            setState(() {
              _isWaitingForEndReconnect = false;
              _errorMessage = 'Firmware upgrade failed';
            });
            _controller.downloadingStatus.value = fw.DownloadStatus.failed;
            logger.Logger('Firmware upgrade FAILED confirmed from MSD [0,1]');
            return; // No need to connect, we have the status
          } else {
            logger.Logger(
              'Unknown manufacturer data for end command: $scanLastByte (expected 1 or 2). Device may still be processing, will check after connection.',
            );
            // Device might still be processing, continue to connect and check
          }
        }
      }

      // If manufacturer data is not available from scan, or we need to connect for jump command
      // Connect to get manufacturer data

      // Connect to the device using BleLogController
      final bleController = Get.find<BleLogController>();
      final bleManager = bleController.bleManager;
      final bool fastReconnect = true; // Opt-in for firmware upgrade flow

      // Check if already connected to avoid duplicate connections
      if (bleManager.isConnected &&
          bleManager.connectedDeviceId.value == device!.id) {
        logger.Logger('Device already connected, skipping reconnect');
      } else {
        // Disconnect first if connected to a different device
        if (bleManager.isConnected) {
          logger.Logger('Disconnecting from current device before reconnect');
          await bleManager.shutdown();
          await Future.delayed(const Duration(seconds: 1));
        }

        // Use BleLogController's connectToDevice which handles initialization properly
        // IMPORTANT: Use scan value (current device state) instead of old stored value
        // For jump command: device is now in bootloader mode with MSD [0,1]
        // For end command: device shows upgrade status with MSD [0,2] or [0,1]
        final manufacturerDataToUse = scanLastByte ?? _originalManufacturerData;

        // Update selectedDevice in bleManager with the new device that has correct MSD
        // This ensures subsequent connection attempts use the correct manufacturer data
        bleManager.selectedDevice = device;

        try {
          await bleController.connectToDevice(
            device: device!,
            manufacturerDataOverride: manufacturerDataToUse,
            fastReconnect: fastReconnect,
            skipConnectionHandshake:
                true, // Bootloader reconnect - auth done via registerNotifyHandlerForFirmwareUpgrade
          );

          // Wait for connection to be fully established
          int waitCount = 0;
          final int maxWaitCycles = fastReconnect ? 15 : 30;
          final Duration waitStep =
              fastReconnect
                  ? const Duration(milliseconds: 150)
                  : const Duration(milliseconds: 200);
          while (!bleManager.isConnected && waitCount < maxWaitCycles) {
            await Future.delayed(waitStep);
            waitCount++;
          }

          if (!bleManager.isConnected) {
            throw Exception('Connection not established after reconnect');
          }

          // After connection, ensure bleManufacturerData reflects the current scan value
          // This is critical - use the scan value (current device state) not old stored value
          if (scanLastByte != null) {
            // Use the scan value (current device state) instead of old stored value
            bleManager.bleManufacturerData.value = scanLastByte!;
            logger.Logger(
              'Using scan manufacturer data after reconnect: $scanLastByte (from MSD: $scanManufacturerData)',
            );
            print(
              'DEBUG RECONNECT: Set bleManufacturerData.value = $scanLastByte (from scan MSD: $scanManufacturerData)',
            );
          } else if (_originalManufacturerData != null) {
            // Fallback to stored value only if scan data is not available
            bleManager.bleManufacturerData.value = _originalManufacturerData!;
            logger.Logger(
              'Using stored manufacturer data after reconnect (fallback): $_originalManufacturerData',
            );
          }
        } catch (e) {
          logger.Logger('Error connecting during reconnect: $e');
          setState(() {
            _isWaitingForJumpReconnect = false;
            _isWaitingForEndReconnect = false;
            _errorMessage = 'Failed to reconnect to device: $e';
          });
          return;
        }
      }

      // Wait for connection to be fully established
      await Future.delayed(_bleConnectSettleDelay);

      // For jump command, we need to register notify handler in bootloader mode
      // BUT we should NOT trigger auth flow - device is already in bootloader mode
      if (isJumpCommand) {
        // The device is already in bootloader mode after jump command
        // We just need to ensure notifications are registered, but skip auth
        // The registerNotifyHandler will check if already registered
        await bleManager.registerNotifyHandlerForFirmwareUpgrade(
          isChipInBootLoader: true,
        );
        _bootloaderNotifyReady = true;
        // Give device more time to stabilize after reboot
        await Future.delayed(_bleConnectSettleDelay);
      }

      // Wait a bit for manufacturer data to be available
      await Future.delayed(_bleConnectSettleDelay);

      // Check manufacturer data from the reconnected device
      // Get the latest manufacturer data from BleManager after connection
      final manufacturerDataValue = bleManager.bleManufacturerData.value;

      setState(() {
        _isWaitingForJumpReconnect = false;
        _isWaitingForEndReconnect = false;
      });

      if (isJumpCommand) {
        // For jump command: expect [0,1] - device should be in bootloader mode
        if (manufacturerDataValue == BleMsdUtils.statusBootloader) {
          setState(() {
            _selectedDevice = device;
            _currentBleStateMessage = 'Device ready. Continuing upgrade...';
          });
        } else {
          logger.Logger(
            'Unexpected manufacturer data for jump command: $manufacturerDataValue (expected 1)',
          );
          setState(() {
            _selectedDevice = device;
            _currentBleStateMessage =
                'Device reconnected. Continuing upgrade...';
          });
        }
      } else {
        // For end command, check upgrade status
        // manufacturerDataValue is the MSD status byte (index 1)
        // [0,2] = success, [0,1] = failed

        // Update message to show we're validating
        setState(() {
          _isValidatingSuccess = true;
          _currentBleStateMessage = 'Validating firmware upgrade success...';
        });

        if (manufacturerDataValue == BleMsdUtils.statusUpgradeSuccess) {
          // Success
          setState(() {
            _selectedDevice = device;
            _currentBleStateMessage =
                'Firmware upgrade completed successfully!';
          });
          _controller.downloadingStatus.value = fw.DownloadStatus.completed;
        } else if (manufacturerDataValue == BleMsdUtils.statusBootloader) {
          // Failed
          setState(() {
            _errorMessage = 'Firmware upgrade failed';
          });
          _controller.downloadingStatus.value = fw.DownloadStatus.failed;
        } else {
          // Unknown status - fallback to scan data if available
          if (scanLastByte == BleMsdUtils.statusUpgradeSuccess) {
            // Success (from scan data)
            setState(() {
              _selectedDevice = device;
              _currentBleStateMessage =
                  'Firmware upgrade completed successfully!';
            });
            _controller.downloadingStatus.value = fw.DownloadStatus.completed;
          } else if (scanLastByte == BleMsdUtils.statusBootloader) {
            // Failed (from scan data)
            setState(() {
              _errorMessage = 'Firmware upgrade failed';
            });
            _controller.downloadingStatus.value = fw.DownloadStatus.failed;
          } else {
            // Unknown status
            logger.Logger(
              'Unknown manufacturer data value: $manufacturerDataValue, scan: $scanLastByte',
            );
            setState(() {
              _errorMessage = 'Unable to determine upgrade status';
            });
            _controller.downloadingStatus.value = fw.DownloadStatus.failed;
          }
        }
      }
    } catch (e) {
      logger.Logger('Error during reconnect: $e');
      setState(() {
        _isWaitingForJumpReconnect = false;
        _isWaitingForEndReconnect = false;
        _errorMessage = 'Reconnection error: $e';
      });
      _controller.downloadingStatus.value = fw.DownloadStatus.failed;
    }
  }

  @override
  void dispose() {
    _endFirmwareSession();
    _bleResultsSub?.cancel();
    _internalReconnectSub?.cancel();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Block back navigation while firmware upgrade is in progress
        if (_currentStep == FirmwareUpgradeStep.progress ||
            _isUpgrading ||
            _isWaitingForEndReconnect ||
            _isWaitingForJumpReconnect) {
          return false;
        }

        // Allow back in all other cases
        return true;
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE31C23),
          borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
            ),
            child: SingleChildScrollView(
              // controller: scrollController,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    // SizedBox(height: 24),
                    // _buildStepIndicator(),
                    SizedBox(height: 24),
                    _buildStepContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Firmware Upgrade',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
            Visibility(
              visible: _currentStep != FirmwareUpgradeStep.progress,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
        // Test Mode Toggle
        // Container(
        //   margin: EdgeInsets.only(top: 8),
        //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //   decoration: BoxDecoration(
        //     color:
        //         _testMode
        //             ? Color(0xFFEC1D24).withOpacity(0.1)
        //             : Color(0xFFD9D9D9).withOpacity(0.3),
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(
        //         Icons.bug_report,
        //         size: 16,
        //         color: _testMode ? Color(0xFFEC1D24) : Color(0xFF979797),
        //       ),
        //       SizedBox(width: 8),
        //       Text(
        //         'Test Mode',
        //         style: GoogleFonts.inter(
        //           fontSize: 12,
        //           fontWeight: FontWeight.w500,
        //           color: _testMode ? Color(0xFFEC1D24) : Color(0xFF979797),
        //         ),
        //       ),
        //       SizedBox(width: 8),
        //       Switch(
        //         value: _testMode,
        //         onChanged: (value) {
        //           setState(() {
        //             _testMode = value;
        //           });
        //         },
        //         activeColor: Color(0xFFEC1D24),
        //         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      'Steps',
      'Connect',
      'Type',
      'Upload',
      'Details',
      'Progress',
      'Result',
    ];
    final currentIndex = FirmwareUpgradeStep.values.indexOf(_currentStep);

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentIndex;
        final isCurrent = index == currentIndex;
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isActive
                          ? (isCurrent ? Color(0xFFEC1D24) : Color(0xFF00A706))
                          : Color(0xFFD9D9D9),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Color(0xFF979797),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                steps[index],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Color(0xFF1B1F26) : Color(0xFF979797),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case FirmwareUpgradeStep.essentialSteps:
        return _buildEssentialSteps();
      case FirmwareUpgradeStep.chooseType:
        return _buildChooseType();
      case FirmwareUpgradeStep.fileUpload:
        return _buildFileUpload();
      case FirmwareUpgradeStep.fileDetails:
        return _buildFileDetails();
      case FirmwareUpgradeStep.progress:
        return _buildProgress();
      case FirmwareUpgradeStep.result:
        return _buildResult();
      case FirmwareUpgradeStep.connectDevice:
        // This step is no longer used - device is already connected
        return _buildChooseType();
    }
  }

  Widget _buildEssentialSteps() {
    final steps = [
      'Ensure the device is connected via Bluetooth',
      'Keep the device powered on throughout the upgrade',
      'Do not disconnect or turn off the device during upgrade',
      'Close other apps that might interfere with Bluetooth',
    ];

    return FutureBuilder<bool>(
      future: _checkBleConnection(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Essential Steps Before Firmware Upgrade',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),

            ...steps.map(
              (step) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFEC1D24).withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFFEC1D24),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1B1F26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            CommonCtaButton(
              onTap: () {
                setState(() {
                  // Skip connectDevice step - device is already connected
                  _currentStep = FirmwareUpgradeStep.chooseType;
                });
              },
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            // ElevatedButton(
            //   onPressed: () {
            // setState(() {
            //   _currentStep =
            //       _testMode
            //           ? FirmwareUpgradeStep.chooseType
            //           : FirmwareUpgradeStep.connectDevice;
            // });
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Color(0xFFEC1D24),
            //     padding: EdgeInsets.symmetric(vertical: 16),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(8),
            //     ),
            //   ),
            //   child: Text(
            //     'Continue',
            //     style: GoogleFonts.inter(
            //       fontSize: 16,
            //       fontWeight: FontWeight.w600,
            //       color: Colors.white,
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  Future<bool> _checkBleConnection() async {
    try {
      final bleManager = Get.find<BleManager>();
      return bleManager.isConnected;
    } catch (e) {
      logger.Logger('Error checking BLE connection: $e');
      return false;
    }
  }

  void _showBluetoothOffDialog({
    // kept for signature compatibility
    required BuildContext context,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bluetooth_disabled,
                      size: 32,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Turn on Bluetooth',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bluetooth is off. Please enable Bluetooth to continue scanning.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC1D24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.5),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Removed _buildConnectDevice and all scanning UI methods - device is already connected
  // All scanning-related methods have been removed since we use the existing BLE connection

  Widget _buildChooseType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose Firmware Type',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 24),
        _buildFirmwareTypeOption(
          title: 'Main Panel Firmware',
          description: 'Upgrade the main panel firmware',
          type: FirmwareType.mainPanel,
          enabled: false,
        ),
        SizedBox(height: 16),
        _buildFirmwareTypeOption(
          title: 'BLE Chip Firmware',
          description: 'Upgrade the Bluetooth chip firmware',
          type: FirmwareType.bleChip,
        ),
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: CommonCtaButton(
                onTap: () {
                  setState(() {
                    _currentStep = FirmwareUpgradeStep.essentialSteps;
                  });
                },
                color: Color(0xFFEFEEEE),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF49454F),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: CommonCtaButton(
                onTap:
                    _selectedFirmwareType == null
                        ? null
                        : () {
                          setState(() {
                            _currentStep = FirmwareUpgradeStep.fileUpload;
                          });
                        },
                isDisabled: _selectedFirmwareType == null,
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFirmwareTypeOption({
    required String title,
    required String description,
    required FirmwareType type,
    bool enabled = true,
  }) {
    final isSelected = _selectedFirmwareType == type;
    return GestureDetector(
      onTap:
          enabled
              ? () {
                setState(() {
                  _selectedFirmwareType = type;
                });
              }
              : null,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              !enabled
                  ? Colors.grey.shade200
                  : (isSelected
                      ? Color(0xFFEC1D24).withOpacity(0.1)
                      : Colors.white),
          border: Border.all(
            color: isSelected ? Color(0xFFEC1D24) : Color(0xFFD9D9D9),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xFFEC1D24) : Color(0xFFD9D9D9),
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEC1D24),
                          ),
                        ),
                      )
                      : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1F26),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF979797),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Upload Firmware File',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 24),
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: DottedBorder(
            // childOnTop: false,
            options: RoundedRectDottedBorderOptions(
              color: Color(0xFFEC1D24).withOpacity(0.3),
              radius: Radius.circular(12),
              dashPattern: [5, 5],
              strokeWidth: 2,
              padding: EdgeInsets.all(0),
              stackFit: StackFit.passthrough,
            ),
            child: Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Color(0xFFF6EBEB),
                // border: Border.all(
                //   color: Color(0xFFEC1D24).withOpacity(0.3),
                //   width: 2,
                //   style: BorderStyle.solid,
                // ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/svgs/upload_icon.svg',
                    width: 32,
                    height: 32,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _selectedFile == null
                        ? 'Tap to select firmware file'
                        : _selectedFile!.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1F26),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    SizedBox(height: 8),
                    Text(
                      '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF979797),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (_isUploading) ...[
          SizedBox(height: 16),
          LinearProgressIndicator(
            backgroundColor: Color(0xFFD9D9D9),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1D24)),
          ),
        ],
        SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: CommonCtaButton(
                onTap: () {
                  setState(() {
                    _currentStep = FirmwareUpgradeStep.chooseType;
                  });
                },
                color: Color(0xFFEFEEEE),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF49454F),
                  ),
                ),
              ),
            ),
            // Expanded(
            //   child: OutlinedButton(
            //     onPressed: () {
            //       setState(() {
            //         _currentStep = FirmwareUpgradeStep.chooseType;
            //       });
            //     },
            //     style: OutlinedButton.styleFrom(
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       side: BorderSide(color: Color(0xFFEC1D24)),
            //     ),
            //     child: Text(
            //       'Back',
            //       style: GoogleFonts.inter(
            //         fontSize: 16,
            //         fontWeight: FontWeight.w600,
            //         color: Color(0xFFEC1D24),
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(width: 16),
            Expanded(
              child: CommonCtaButton(
                onTap:
                    _selectedFile == null || _isUploading
                        ? null
                        : _goToFileDetails,
                isDisabled: _selectedFile == null || _isUploading,
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Expanded(
            //   child: ElevatedButton(
            //     onPressed:
            //         _selectedFile == null || _isUploading
            //             ? null
            //             : _goToFileDetails,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Color(0xFFEC1D24),
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       disabledBackgroundColor: Color(0xFFD9D9D9),
            //     ),
            //     child: Text(
            //       'Continue',
            //       style: GoogleFonts.inter(
            //         fontSize: 16,
            //         fontWeight: FontWeight.w600,
            //         color: Colors.white,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileDetails() {
    if (_selectedFile == null) return SizedBox();

    final result = _validationResult;
    final isCrcMatched = _controller.isFileCrcMatched.value;
    final expectedCrc = result?.expectedHex ?? '-';
    final calculatedCrc = result?.calculatedHex ?? '-';

    print('expectedCrc: $expectedCrc');
    print('calculatedCrc: $calculatedCrc');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'File Details',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 24),
        _buildDetailRow('File Name', _selectedFile!.name),
        SizedBox(height: 12),
        _buildDetailRow(
          'File Size',
          '${(_selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
        ),
        SizedBox(height: 12),
        _buildDetailRow(
          'Firmware Type',
          _selectedFirmwareType == FirmwareType.mainPanel
              ? 'Main Panel Firmware'
              : 'BLE Chip Firmware',
        ),
        if (result != null) ...[
          SizedBox(height: 12),
          _buildDetailRow(
            'Firmware version',
            _emptyToDash(result.firmwareVersion),
          ),
          SizedBox(height: 12),
          _buildDetailRow(
            'Hardware version',
            _emptyToDash(result.hardwareVersion),
          ),
          SizedBox(height: 12),
          _buildDetailRow('Build date', _emptyToDash(result.date)),
          SizedBox(height: 12),
          _buildDetailRow('Product ID', _emptyToDash(result.productId)),
        ],
        Visibility(
          visible: !isCrcMatched,
          child: Column(
            children: [
              SizedBox(height: 12),
              _buildDetailRow('Expected CRC', expectedCrc),
              SizedBox(height: 12),
              _buildDetailRow('Calculated CRC', calculatedCrc),
            ],
          ),
        ),
        SizedBox(height: 12),
        _buildDetailRow(
          'Status',
          _isValidating
              ? 'Validating...'
              : isCrcMatched
              ? 'Valid'
              : 'Invalid',
          valueColor:
              _isValidating
                  ? Color(0xFF979797)
                  : isCrcMatched
                  ? Color(0xFF00A706)
                  : Color(0xFFEC1D24),
        ),
        if (_isValidating) ...[
          SizedBox(height: 16),
          Center(child: CircularProgressIndicator()),
        ],
        if (!_isValidating && !isCrcMatched)
          Container(
            margin: EdgeInsets.only(top: 24),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFEC1D24).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Color(0xFFEC1D24)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _validationResult?.error ??
                        'File CRC validation failed. Please select a valid firmware file.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CommonCtaButton(
                color: Color(0xFFEFEEEE),
                onTap:
                    _isValidating
                        ? null
                        : () {
                          setState(() {
                            _currentStep = FirmwareUpgradeStep.fileUpload;
                          });
                        },
                isDisabled: _isValidating,
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF49454F),
                  ),
                ),
              ),
            ),
            // Expanded(
            //   child: OutlinedButton(
            //     onPressed:
            //         _isValidating
            //             ? null
            //             : () {
            //               setState(() {
            //                 _currentStep = FirmwareUpgradeStep.fileUpload;
            //               });
            //             },
            //     style: OutlinedButton.styleFrom(
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       side: BorderSide(color: Color(0xFFEC1D24)),
            //     ),
            //     child: Text(
            //       'Back',
            //       style: GoogleFonts.inter(
            //         fontSize: 16,
            //         fontWeight: FontWeight.w600,
            //         color: Color(0xFFEC1D24),
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(width: 16),
            Expanded(
              child: CommonCtaButton(
                onTap:
                    (_isValidating || !isCrcMatched)
                        ? null
                        : () async {
                          await _onValidationContinuePressed();
                        },
                isDisabled: _isValidating || !isCrcMatched,
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Expanded(
            //   flex: 2,
            //   child: ElevatedButton(
            //     onPressed:
            //         (_isValidating || !isCrcMatched)
            //             ? null
            //             : () {
            //               _startUpgrade(
            //                 isChipInBootLoader:
            //                     _selectedDevice?.manufacturerData.last == 1,
            //               );
            //             },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Color(0xFFEC1D24),
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       disabledBackgroundColor: Color(0xFFD9D9D9),
            //     ),
            //     child: Text(
            //       'Continue',
            //       style: GoogleFonts.inter(
            //         fontSize: 16,
            //         fontWeight: FontWeight.w600,
            //         color: Colors.white,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  String _emptyToDash(String s) => s.isEmpty ? '-' : s;

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF979797),
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Color(0xFF1B1F26),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Obx(() {
      final progress = _controller.progressbarCount.value;
      final status = _controller.downloadingStatus.value;

      // Always show the normal progress UI, even during reconnection phases
      // This hides the reconnection/status fetching messages and shows only the upload progress
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text(
          //   'Firmware Upgrade in Progress',
          //   style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          // ),
          // SizedBox(height: 32),
          Center(
            child:
                _isWaitingForEndReconnect
                    ? Lottie.asset('assets/jsons/ble_connecting.json')
                    : (progress * 100).toStringAsFixed(1) == '0.0'
                    ? Lottie.asset('assets/jsons/ble_connecting.json')
                    : CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 8,
                      percent: progress.clamp(0.0, 1.0),
                      center: Lottie.asset(
                        'assets/jsons/firmware_upgrade.json',
                      ),
                      progressColor: Color(0xFFEC1D24),
                      backgroundColor: Color(0xFFD9D9D9),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
          ),
          SizedBox(height: 12),
          Visibility(
            visible:
                !((progress * 100).toStringAsFixed(1) == '0.0') &&
                !_isWaitingForEndReconnect,
            child: Center(
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  // color: Color(0xFFEC1D24),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          // if (totalPackets > 0)
          //   Text(
          //     'Packet $currentIndex of $totalPackets',
          //     style: GoogleFonts.inter(
          //       fontSize: 14,
          //       fontWeight: FontWeight.w400,
          //       color: Color(0xFF979797),
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // SizedBox(height: 8),
          // LinearPercentIndicator(
          //   lineHeight: 8,
          //   percent: progress.clamp(0.0, 1.0),
          //   backgroundColor: Color(0xFFD9D9D9),
          //   progressColor: Color(0xFFEC1D24),
          //   barRadius: Radius.circular(4),
          // ),
          SizedBox(height: 12),
          Text(
            _currentBleStateMessage ??
                (status == fw.DownloadStatus.upgrading
                    ? 'Please wait while the firmware is being upgraded. Do not disconnect the device.'
                    : 'Processing...'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF979797),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    });
  }

  Widget _buildResult() {
    final isSuccess =
        _controller.downloadingStatus.value == fw.DownloadStatus.completed;
    final message =
        _errorMessage ??
        (isSuccess
            ? 'Firmware upgrade completed successfully!'
            : 'Firmware upgrade failed');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Lottie.asset(
          height: 180,
          width: 180,
          isSuccess
              ? 'assets/jsons/firmware_upgrade_success.json'
              : 'assets/jsons/firmware_upgrade_failed.json',
          repeat: false,
        ),
        SizedBox(height: 24),
        Text(
          isSuccess ? 'Success!' : 'Failed',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isSuccess ? Color(0xFF00A706) : Color(0xFFEC1D24),
          ),
          textAlign: TextAlign.center,
        ),
        // SizedBox(height: 16),
        // Text(
        //   message,
        //   style: GoogleFonts.inter(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w400,
        //     color: Color(0xFF1B1F26),
        //   ),
        //   textAlign: TextAlign.center,
        // ),
        SizedBox(height: 32),
        CommonCtaButton(
          onTap: () {
            Navigator.of(context).pop(isSuccess);
            // Reset state
            _controller.downloadingStatus.value = fw.DownloadStatus.downloading;
            _controller.isFileCrcMatched.value = false;
            _controller.selectedFirmwareFile = null;
            _controller.progressbarIndex.value = 0;
            _controller.progressbarCount.value = 0.0;
            _controller.totalPacketLength.value = 0;
          },
          child: Text(
            'Done',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        // ElevatedButton(
        //   onPressed: () {
        //     Navigator.of(context).pop();
        //     // Reset state
        //     _controller.downloadingStatus.value = fw.DownloadStatus.downloading;
        //     _controller.isFileCrcMatched.value = false;
        //     _controller.selectedFirmwareFile = null;
        //     _controller.progressbarIndex.value = 0;
        //     _controller.progressbarCount.value = 0.0;
        //     _controller.totalPacketLength.value = 0;
        //   },
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: Color(0xFFEC1D24),
        //     padding: EdgeInsets.symmetric(vertical: 16),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //   ),
        //   child: Text(
        //     'Done',
        //     style: GoogleFonts.inter(
        //       fontSize: 16,
        //       fontWeight: FontWeight.w600,
        //       color: Colors.white,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final platformFile = PlatformFile(
          name: result.files.single.name,
          path: result.files.single.path,
          size: await file.length(),
          bytes: await file.readAsBytes(),
        );

        _controller.selectFirmwareFile(platformFile);

        setState(() {
          _selectedFile = platformFile;
          _isUploading = false;
          _validationResult = null;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      logger.Logger('Error picking file: $e');
      setState(() {
        _isUploading = false;
        _errorMessage = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _goToFileDetails() async {
    if (_selectedFile == null) return;

    setState(() {
      _currentStep = FirmwareUpgradeStep.fileDetails;
      _isValidating = true;
      _validationResult = null;
      _errorMessage = null;
    });

    final result = _controller.validateSelectedFile(
      requiredProductId: fw.FirmwareUpgradeService.expectedProductId,
    );

    setState(() {
      _validationResult = result;
      _isValidating = false;
      if (result == null) {
        _errorMessage = 'No file selected. Please upload again.';
      } else if (!result.isValid) {
        _errorMessage = result.error ?? 'CRC validation failed.';
      }
    });
  }

  bool _isVersionMissing(String? value) =>
      value == null || value.trim().isEmpty;

  bool _bleVersionsNotRecovered() =>
      _isVersionMissing(ble.bleHardwareVersion.value) ||
      _isVersionMissing(ble.bleFirmwareVersion.value);

  Future<void> _onValidationContinuePressed() async {
    final md = _selectedDevice?.manufacturerData;
    final inBootloader = md != null && BleMsdUtils.isBootloader(md);

    if (_bleVersionsNotRecovered()) {
      final shouldProceed = await _confirmAndUpgrade(
        message:
            'Device hardware and firmware versions could not be read from '
            'Bluetooth. Do you still want to update?',
      );
      if (shouldProceed) {
        await _startUpgrade(
          isChipInBootLoader: inBootloader,
          firmwareVersion: _validationResult?.firmwareVersion,
        );
      }
      return;
    }

    await _startUpgrade(
      isChipInBootLoader: inBootloader,
      firmwareVersion: _validationResult?.firmwareVersion,
    );

    // if ((_validationResult?.hardwareVersion == ble.bleHardwareVersion.value) &&
    //     (_validationResult?.firmwareVersion != ble.bleFirmwareVersion.value)) {
    //   await _startUpgrade(
    //     isChipInBootLoader: inBootloader,
    //     firmwareVersion: _validationResult?.firmwareVersion,
    //   );
    // } else if (_validationResult?.hardwareVersion !=
    //     ble.bleHardwareVersion.value) {
    //   await _showHardwareVersionMismatch();
    // } else {
    //   await _showSameFirmwareVersionPopUp();
    // }
  }

  Future<void> _showSameFirmwareVersionPopUp() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Firmware Update',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "The Firware is already upto date with the current firmware version",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC1D24),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC1D24).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Okay',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHardwareVersionMismatch() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Firmware Update',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Invalid bin file, hardware versions don't match",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),
                Text(
                  "Bin File Hardware Version: ${_validationResult?.hardwareVersion}\nBLE Hardware Version: ${ble.bleHardwareVersion.value}",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC1D24),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC1D24).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmAndUpgrade({String? message}) async {
    final shouldUpgrade = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Firmware Update',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEEEE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD0D0D0),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC1D24),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC1D24).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldUpgrade ?? false;
  }

  int compareFirmwareVersion({
    required String currentVersion,
    required String newVersion,
  }) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();

      final incoming = newVersion.split('.').map(int.parse).toList();

      final maxLength =
          current.length > incoming.length ? current.length : incoming.length;

      while (current.length < maxLength) {
        current.add(0);
      }

      while (incoming.length < maxLength) {
        incoming.add(0);
      }

      for (int i = 0; i < maxLength; i++) {
        if (incoming[i] > current[i]) {
          return 1; // upgrade
        }

        if (incoming[i] < current[i]) {
          return -1; // downgrade
        }
      }

      return 0; // same
    } catch (e) {
      return -999; // invalid version
    }
  }

  Future<void> _startUpgrade({
    bool? isChipInBootLoader = false,
    String? firmwareVersion = '',
  }) async {
    // print("isChipInBootLoader: $isChipInBootLoader");

    if (firmwareVersion != null &&
        firmwareVersion.isNotEmpty &&
        !_isVersionMissing(ble.bleFirmwareVersion.value)) {
      final int comparedValue = compareFirmwareVersion(
        currentVersion: ble.bleFirmwareVersion.value,
        newVersion: firmwareVersion,
      );
      final shouldUpgrade = await _confirmAndUpgrade(
        message:
            comparedValue == 1
                ? "Do you want to upgrade to $firmwareVersion?"
                : comparedValue == -1
                ? "Do you want to downgrade to $firmwareVersion?"
                : "The versions are same, continue?",
      );

      if (!shouldUpgrade) {
        return;
      }
    }

    _controller.downloadingStatus.value = fw.DownloadStatus.upgrading;

    setState(() {
      _isUpgrading = true;
      _currentStep = FirmwareUpgradeStep.progress;
      _currentBleStateMessage = 'Preparing Firmware Upgrade...';
      _errorMessage = null;
    });

    final prepared = await _controller.preparePackets();
    if (!prepared || _controller.totalPacketLength.value == 0) {
      setState(() {
        _isUpgrading = false;
        _currentStep = FirmwareUpgradeStep.result;
        _errorMessage =
            _controller.validationError ??
            'No packets to process. Please re-upload the file.';
      });
      _controller.downloadingStatus.value = fw.DownloadStatus.failed;
      return;
    }

    // Test mode: skip BLE, just simulate
    if (_testMode) {
      setState(() {
        _currentBleStateMessage = 'Simulating packet sends...';
      });
      await _controller.simulateUpgradeProgress();
      final bool isSuccess =
          _controller.downloadingStatus.value == fw.DownloadStatus.completed;
      setState(() {
        _isUpgrading = false;
        _currentStep = FirmwareUpgradeStep.result;
        _errorMessage = isSuccess ? null : 'Upgrade simulation failed.';
        _currentBleStateMessage = null;
      });
      return;
    }

    // Real BLE path: send packets
    try {
      await _sendPacketsOverBle(isChipInBootLoader: isChipInBootLoader);
      final bool isSuccess =
          _controller.downloadingStatus.value == fw.DownloadStatus.completed;
      setState(() {
        _isUpgrading = false;
        _currentStep = FirmwareUpgradeStep.result;
        _errorMessage = isSuccess ? null : 'Firmware transfer failed.';
        _currentBleStateMessage = null;
      });
    } catch (e) {
      setState(() {
        _isUpgrading = false;
        _currentStep = FirmwareUpgradeStep.result;
        _errorMessage = 'Error sending packets: $e';
        _currentBleStateMessage = null;
      });
      _controller.downloadingStatus.value = fw.DownloadStatus.failed;
    }
  }
}

// Radar painters (from scanning_screen.dart)
class _RadarPainter extends CustomPainter {
  final Animation<double> sweepAnimation;
  _RadarPainter({required this.sweepAnimation})
    : super(repaint: sweepAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final int rings = 4;
    for (int i = 1; i <= rings; i++) {
      paint.color = Colors.green.withOpacity(0.12 + i * 0.03);
      canvas.drawCircle(center, (size.width / 2) * (i / (rings + 1)), paint);
    }

    final centerPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(center, 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => true;
}

class _SweepPainter extends CustomPainter {
  final double progress;
  _SweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.green.withOpacity(0.22),
              Colors.green.withOpacity(0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.fill;

    final angle = progress * 2 * pi;
    final double sweep = pi / 6;
    final path = Path()..moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      angle - sweep / 2,
      sweep,
      false,
    );
    path.close();

    canvas.drawPath(path, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AnimatedGridCard extends StatefulWidget {
  final Widget child;
  final bool highlight;

  const _AnimatedGridCard({required this.child, required this.highlight});

  @override
  State<_AnimatedGridCard> createState() => _AnimatedGridCardState();
}

class _AnimatedGridCardState extends State<_AnimatedGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: Stack(
          children: [widget.child, if (widget.highlight) const _PulseGlow()],
        ),
      ),
    );
  }
}

class _PulseGlow extends StatefulWidget {
  const _PulseGlow();

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(
                    0.25 * (1 - _controller.value),
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
