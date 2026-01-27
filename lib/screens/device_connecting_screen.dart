import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  final BluetoothDevice selectedDevice;
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
  bool _maxBleConnectionRetriesReached = false;
  bool _maxOtherPacketsRetriesReached = false;
  bool _firstLogReceived = false;
  bool _hasNavigatedToEventLog = false;
  bool _allowExit = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Reset state when screen is initialized (for retry scenarios)
    _firstLogReceived = false;
    _hasNavigatedToEventLog = false;

    // Listen for first valid log to show button
    ble.bleProcess.isValidLogRecieved.addListener(_onFirstValidLogReceived);

    // Listen for log retrieval completion (1000 logs read)
    ble.bleProcess.read1000LogsCount.addListener(_onLogRetrievalCompleted);

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

  // Add listener for log retrieval completion
  void _onLogRetrievalCompleted() {
    if (mounted &&
        ble.bleProcess.read1000LogsCount.value >= 1000 &&
        !_hasNavigatedToEventLog) {
      _hasNavigatedToEventLog = true;
      // Wait a brief moment for final processing, then navigate
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToEventLogScreen();
        }
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

  //send stop control command
  Future<void> _sendStopControlCommand() async {
    ble.bleProcess.isOtaCompleted = true;
    ble.bleProcess.processNextOtaFrame = false;

    ble.otaProcessState = OtaProcessState.notInUse;
    ble.bleProcess.cancelRxTimeout();

    ble.bleProcess.processDesc.value = "";

    await ble.sendStopCntrlCmdPkt();
    _allowExit = true;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Show confirmation dialog before stopping log retrieval
  Future<void> _showStopConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEC1D24),
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stop Log Retrieval',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to stop the log retrieval process? This action cannot be undone.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEC1D24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Yes, Stop',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _sendStopControlCommand();
    }
  }

  @override
  void dispose() {
    ble.bleProcess.isValidLogRecieved.removeListener(_onFirstValidLogReceived);
    ble.bleProcess.read1000LogsCount.removeListener(_onLogRetrievalCompleted);
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

  String _getDeviceName() {
    final device = widget.selectedDevice;

    if (widget.scanType == ScanType.bluetooth) {
      if (device.platformName.isNotEmpty) {
        return device.platformName;
      }
      return "BLE-${device.remoteId.str.substring(0, 5)}";
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
    return PopScope(
      canPop: _allowExit,
      child: Scaffold(
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
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // const Spacer(),
                            _buildConnectionAnimation(),
                            const SizedBox(height: 20),
                            _buildDeviceInfo(),
                            const SizedBox(height: 24),
                            _buildStatusText(),
                            // Add progress bar
                            if (!_connectionFailed) ...[
                              const SizedBox(height: 56),
                              _buildProgressBar(),
                            ],

                            // if (_connectionFailed) ...[
                            //   const SizedBox(height: 16),
                            //   _buildErrorMessage(),
                            // ],
                            // const Spacer(),
                            // if (_connectionFailed) _buildRetryButton(),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildCancelLogRetrievalButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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

  // Add button widget for canceling log retrieval
  Widget _buildCancelLogRetrievalButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: _showStopConfirmationDialog,
        child: Container(
          height: 55,
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
              'Cancel Log Retrieval',
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
}
