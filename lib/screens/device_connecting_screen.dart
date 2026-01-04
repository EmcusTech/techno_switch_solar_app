import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';
import 'package:techno_switch_solar_app/screens/access_code_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

// Shared BLE instance used across screens
final BleManager ble = Get.find<BleManager>();

class DeviceConnectingScreen extends StatefulWidget {
  final DiscoveredDevice selectedDevice;
  final ScanType scanType;
  final bool? isLiveEvent;

  const DeviceConnectingScreen({
    super.key,
    required this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
  });

  @override
  State<DeviceConnectingScreen> createState() => _DeviceConnectingScreenState();
}

class _DeviceConnectingScreenState extends State<DeviceConnectingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _connectionStatus = "Initializing...";
  bool _connectionFailed = false;
  String? _errorMessage;
  StreamSubscription<BleHandshakeEvent>? _handshakeSubscription;
  bool _passkeyScreenOpened = false;
  StreamSubscription<DeviceConnectionState>? _connectionSub;
  Uuid primaryServiceGuid = BleUuids.primaryService;
  Uuid primaryReadCharGuid = BleUuids.primaryReadChar;
  Uuid primaryWriteCharGuid = BleUuids.primaryWriteChar;
  QualifiedCharacteristic? readCharacteristic;
  QualifiedCharacteristic? writeCharacteristic;
  bool _maxBleConnectionRetriesReached = false;
  bool _maxOtherPacketsRetriesReached = false;
  bool _firstLogReceived = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start connection attempt
    // _connectToDevice();
    // ble.bleProcess.runStateMachine();

    // Get.find<BleLogController>().startLogRetrieval();

    // Listen for first valid log to navigate to event log screen
    ble.bleProcess.isValidLogRecieved.addListener(_onFirstValidLogReceived);

    ble.maxBleConnectionRetriesReached.addListener(
      _onMaxBleConnectionRetriesReached,
    );

    ble.maxOtherPacketsRetriesReached.addListener(
      _onMaxOtherPacketsRetriesReached,
    );

    // _handshakeSubscription ??= AppServices.bleService.handshakeEvents.listen(
    //   _handleHandshakeEvent,
    // );

    // BtUtils().connectToDevice(widget.selectedDevice);
  }

  void _onMaxBleConnectionRetriesReached() {
    setState(() {
      _maxBleConnectionRetriesReached =
          ble.maxBleConnectionRetriesReached.value;
    });
  }

  void _onMaxOtherPacketsRetriesReached() {
    setState(() {
      _maxOtherPacketsRetriesReached = ble.maxOtherPacketsRetriesReached.value;
    });
  }

  void _onFirstValidLogReceived() {
    if (ble.bleProcess.isValidLogRecieved.value && mounted) {
      // Instead of navigating, just set state to show button
      setState(() {
        _firstLogReceived = true;
      });
    }
  }

  // Add method to navigate to EventLogScreen
  void _navigateToEventLogScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => EventLogScreen(
              logDataList: [], // Will be populated via ValueListenableBuilder
              panelName: _getDeviceName(),
              panelVersionNo: 'N/A',
              isStandalone: true,
            ),
      ),
    );
  }

  @override
  void dispose() {
    ble.bleProcess.isValidLogRecieved.removeListener(_onFirstValidLogReceived);
    _handshakeSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildStatusText() {
    return ValueListenableBuilder<String>(
      valueListenable: ble.processDesc,
      builder: (context, value, _) {
        return Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    _connectionFailed
                        ? const Color(0xFFEC1D24)
                        : const Color(0xFF3D3D3D),
              ),
            ),
            if (!_connectionFailed &&
                !_maxBleConnectionRetriesReached &&
                !_maxOtherPacketsRetriesReached) ...[
              const SizedBox(height: 8),
              Text(
                'Please wait...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF918F8F),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _connectToDevice() async {
    if (widget.selectedDevice == null) {
      _handleConnectionFailure("No Device selected");
      return;
    }

    if (widget.scanType == ScanType.bluetooth &&
        widget.selectedDevice is! DiscoveredDevice) {
      _handleConnectionFailure("Invalid BLE Device selected");
      return;
    }

    setState(() {
      _connectionStatus = "Connecting to ${_getDeviceName()}";
    });

    try {
      if (widget.scanType == ScanType.bluetooth) {
        final DiscoveredDevice device =
            widget.selectedDevice as DiscoveredDevice;

        /// listen to handshake events only once
        _handshakeSubscription ??= AppServices.bleService.handshakeEvents
            .listen(_handleHandshakeEvent);

        setState(() {
          _connectionStatus = "Establishing Bluetooth connection...";
        });

        /// 🔥 LISTEN to the BLE connection stream
        _connectionSub = AppServices.bleService
            .connectToDevice(device)
            .listen(
              (DeviceConnectionState state) async {
                switch (state) {
                  case DeviceConnectionState.connecting:
                    setState(() {
                      _connectionStatus = "Connecting...";
                    });
                    break;

                  case DeviceConnectionState.connected:
                    setState(() {
                      _connectionStatus =
                          "Connected. Waiting for BLE handshake...";
                    });
                    // await prepareCharacteristics(device);
                    readCharacteristic = QualifiedCharacteristic(
                      characteristicId: primaryReadCharGuid,
                      serviceId: primaryServiceGuid,
                      deviceId: device.id,
                    );

                    writeCharacteristic = QualifiedCharacteristic(
                      characteristicId: primaryWriteCharGuid,
                      serviceId: primaryServiceGuid,
                      deviceId: device.id,
                    );
                    // Handshake + notify flow continues via streams
                    break;

                  case DeviceConnectionState.disconnected:
                    _handleConnectionFailure("Device disconnected");
                    await _connectionSub?.cancel();
                    break;
                  default:
                    print("reached defualt when connecting");
                    break;
                }
              },
              onError: (e) {
                _handleConnectionFailure("Connection error: $e");
              },
            );
      } else {
        // USB path (unchanged logic)
        setState(() {
          _connectionStatus = "Establishing USB connection...";
        });

        // await AppServices.serialService.connectToDevice();
      }
    } catch (e) {
      _handleConnectionFailure("Connection error: $e");
    }
  }

  void _handleHandshakeEvent(BleHandshakeEvent event) async {
    if (!mounted) return;

    switch (event.type) {
      case BleHandshakeEventType.stateChanged:
        if (event.message != null) {
          setState(() {
            _connectionStatus = event.message!;
          });
        }
        break;

      case BleHandshakeEventType.encryptionKeyReceived:
        setState(() {
          _connectionStatus = "Encryption key received";
        });
        break;

      case BleHandshakeEventType.authenticated:
        setState(() {
          _connectionStatus = "Device authenticated successfully";
        });

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => AccessCodeScreen(
                  scanType: widget.scanType,
                  selectedDevice: widget.selectedDevice,
                  isLiveEvent: widget.isLiveEvent,
                ),
          ),
        );
        break;

      case BleHandshakeEventType.passkeyRequested:
        setState(() {
          _connectionStatus = "Submitting passkey automatically...";
        });

        if (!_passkeyScreenOpened) {
          _passkeyScreenOpened = true;

          Future.microtask(() async {
            if (!mounted) return;
            try {
              await AppServices.bleService.submitPasskey("1974");
              setState(() {
                _connectionStatus = "Passkey submitted: 1974";
              });
            } catch (e) {
              setState(() {
                _connectionStatus = "Error submitting passkey: $e";
              });
            }
          });
        }
        break;

      case BleHandshakeEventType.passkeyAccepted:
        setState(() {
          _connectionStatus = "Passkey accepted";
        });
        break;

      case BleHandshakeEventType.error:
        _handleConnectionFailure(event.message ?? "Handshake error");
        break;
    }
  }

  void _handleConnectionFailure(String error) {
    setState(() {
      _connectionFailed = true;
      _errorMessage = error;
      _connectionStatus = "Connection Failed";
    });
    _animationController.stop();
  }

  String _getDeviceName() {
    final device = widget.selectedDevice;

    if (device == null) {
      return "Unknown Device";
    }

    if (widget.scanType == ScanType.bluetooth) {
      if (device is DiscoveredDevice) {
        if (device.name.isNotEmpty) {
          return device.name;
        }
        return "BLE-${device.id.substring(0, 5)}";
      }
      return "BLE Device";
    }

    // if (widget.scanType == ScanType.usb) {
    //   if (device is UsbDevice) {
    //     return device.productName ?? "USB Device";
    //   }
    // }

    return "Unknown Device";

    //

    // if (widget.selectedDevice == null) return "Unknown Device";

    // if (widget.scanType == ScanType.bluetooth) {
    //   if (widget.selectedDevice is ScanResult) {
    //     final name = (widget.selectedDevice as ScanResult).device.platformName;
    //     return name.isNotEmpty ? name : "BLE Device";
    //   } else if (widget.selectedDevice is DiscoveredDevice) {
    //     final name = (widget.selectedDevice as DiscoveredDevice).name;
    //     return name.isNotEmpty ? name : "BLE Device";
    //   }
    // } else {
    //   if (widget.selectedDevice is UsbDevice) {
    //     return (widget.selectedDevice as UsbDevice).productName ?? "USB Device";
    //   }
    // }

    // return "Unknown Device";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      _buildConnectionAnimation(),
                      const SizedBox(height: 20),
                      _buildDeviceInfo(),
                      const SizedBox(height: 24),
                      _buildStatusText(),
                      // Add progress bar
                      if (!_connectionFailed) ...[
                        const SizedBox(height: 24),
                        _buildProgressBar(),
                      ],
                      // Add button when first log is received
                      if (_firstLogReceived) ...[
                        const SizedBox(height: 16),
                        _buildViewLogsButton(),
                      ],
                      if (_connectionFailed) ...[
                        const SizedBox(height: 16),
                        _buildErrorMessage(),
                      ],
                      const Spacer(),
                      if (_connectionFailed) _buildRetryButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ValueListenableBuilder(
          valueListenable: ble.maxBleConnectionRetriesReached,
          builder: (context, value, _) {
            return Lottie.asset(
              'assets/jsons/ble_connecting.json',
              animate:
                  !_connectionFailed &&
                  !_maxBleConnectionRetriesReached &&
                  !_maxOtherPacketsRetriesReached,
            );
          },
        );
        // return Container(
        //   width: 150,
        //   height: 150,
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     color:
        //         _connectionFailed
        //             ? Color(0xFFEC1D24).withOpacity(0.1)
        //             : Color(0xFFEC1D24).withOpacity(0.08),
        //     boxShadow:
        //         _connectionFailed
        //             ? []
        //             : [
        //               BoxShadow(
        //                 color: Color(
        //                   0xFFEC1D24,
        //                 ).withOpacity(0.3 * (1 - _animationController.value)),
        //                 blurRadius: 30 * _animationController.value,
        //                 spreadRadius: 20 * _animationController.value,
        //               ),
        //             ],
        //   ),
        //   child: Center(
        //     child: Icon(
        //       _connectionFailed
        //           ? Icons.error_outline
        //           : (widget.scanType == ScanType.bluetooth
        //               ? Icons.bluetooth_searching
        //               : Icons.usb),
        //       size: 60,
        //       color: _connectionFailed ? Color(0xFFEC1D24) : Color(0xFFEC1D24),
        //     ),
        //   ),
        // );
      },
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFB9B9B9).withOpacity(0.31),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (widget.scanType == ScanType.usb
                      ? Color(0xFFEC1D24)
                      : Colors.blue)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SvgPicture.asset('assets/svgs/panel_icon.svg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDeviceName(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
                Text(
                  widget.scanType == ScanType.usb
                      ? 'USB Device'
                      : 'Bluetooth Device',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFEC1D24).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFEC1D24).withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            _errorMessage ?? "Unknown error occurred",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFEC1D24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please make sure the device is powered on and in range.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF696969),
            ),
          ),
        ],
      ),
    );
  }

  // Add progress bar widget
  Widget _buildProgressBar() {
    return ValueListenableBuilder<int>(
      valueListenable: ble.bleProcess.read1000LogsCount,
      builder: (context, readCount, child) {
        return ValueListenableBuilder<List<LogModel>>(
          valueListenable: ble.bleProcess.validEventLogs,
          builder: (context, validLogs, child) {
            final progress = readCount / 1000.0;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFFB9B9B9).withOpacity(0.31),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: $readCount / 1000',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3D3D3D),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'Valid Logs: ${validLogs.length}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEC1D24),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFEC1D24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Add button widget for navigating to EventLogScreen
  Widget _buildViewLogsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GestureDetector(
        onTap: _navigateToEventLogScreen,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Color(0xFFEC1D24),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFEC1D24).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'View Event Logs',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFEFEEEE),
                  borderRadius: BorderRadius.circular(28.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: Color(0xFF49454F)),
                      const SizedBox(width: 8),
                      Text(
                        'Go Back',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF49454F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _connectionFailed = false;
                  _errorMessage = null;
                  _connectionStatus = "Retrying...";
                });
                _animationController.repeat();
                _connectToDevice();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFEC1D24),
                  borderRadius: BorderRadius.circular(28.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Retry',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.refresh, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
