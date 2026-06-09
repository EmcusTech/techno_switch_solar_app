import 'dart:async';

import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

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
  String connectionStatus = "Initializing...";
  final bool _connectionFailed = false;
  String? errorMessage;
  StreamSubscription<BleHandshakeEvent>? _handshakeSubscription;
  Uuid primaryServiceGuid = BleUuids.primaryService;
  Uuid primaryReadCharGuid = BleUuids.primaryReadChar;
  Uuid primaryWriteCharGuid = BleUuids.primaryWriteChar;
  QualifiedCharacteristic? readCharacteristic;
  QualifiedCharacteristic? writeCharacteristic;
  bool _maxBleConnectionRetriesReached = false;
  bool _maxOtherPacketsRetriesReached = false;
  bool firstLogReceived = false;
  bool _hasNavigatedToEventLog = false;
  bool _allowExit = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    firstLogReceived = false;
    _hasNavigatedToEventLog = false;

    ble.bleProcess.isValidLogRecieved.addListener(_onFirstValidLogReceived);

    ble.bleProcess.read1000LogsCount.addListener(_onLogRetrievalCompleted);

    ble.maxBleConnectionRetriesReached.addListener(
      _onMaxBleConnectionRetriesReached,
    );

    ble.maxOtherPacketsRetriesReached.addListener(
      _onMaxOtherPacketsRetriesReached,
    );
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
      setState(() {
        firstLogReceived = true;
      });
    }
  }

  void _onLogRetrievalCompleted() {
    if (mounted &&
        ble.bleProcess.read1000LogsCount.value >= 1000 &&
        !_hasNavigatedToEventLog) {
      _hasNavigatedToEventLog = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToEventLogScreen();
        }
      });
    }
  }

  void _navigateToEventLogScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => EventLogScreen(
              logDataList: [],
              panelName: _getDeviceName(),
              panelVersionNo: 'N/A',
              isStandalone: true,
            ),
      ),
    );
  }

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
      if (device.name.isNotEmpty) {
        return device.name;
      }
      return "BLE-${device.id.substring(0, 5)}";
    }

    return "Unknown Device";
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
                            _buildConnectionAnimation(),
                            const SizedBox(height: 20),
                            _buildDeviceInfo(),
                            const SizedBox(height: 24),
                            _buildStatusText(),
                            if (!_connectionFailed) ...[
                              const SizedBox(height: 56),
                              _buildProgressBar(),
                            ],
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
