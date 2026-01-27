import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/screens/log_retreival_completed_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retreival_failed_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';

/// Shared BLE manager
final BleManager ble = Get.find<BleManager>();

class LogRetrievalLoadingScreen extends StatefulWidget {
  final dynamic selectedDevice;
  final ScanType scanType;
  final bool? isLiveEvent;

  const LogRetrievalLoadingScreen({
    super.key,
    this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
  });

  @override
  State<LogRetrievalLoadingScreen> createState() =>
      _LogRetrievalLoadingScreenState();
}

class _LogRetrievalLoadingScreenState extends State<LogRetrievalLoadingScreen> {
  bool _hasNavigatedToEventLog = false;
  bool _navigatedToFailure = false;
  bool _allowExit = false;

  @override
  void initState() {
    super.initState();

    // ---- LISTENERS ----
    ble.bleProcess.isValidLogRecieved.addListener(_onFirstValidLogReceived);
    ble.bleProcess.read1000LogsCount.addListener(_onLogRetrievalCompleted);
    ble.maxBleConnectionRetriesReached.addListener(
      _onMaxBleConnectionRetriesReached,
    );
    ble.maxOtherPacketsRetriesReached.addListener(
      _onMaxOtherPacketsRetriesReached,
    );

    // ---- START LOG RETRIEVAL ----
    Future.microtask(() async {
      try {
        await ble.startLogRetrieval();
      } catch (e) {
        _handleFailure(e.toString());
      }
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                                LISTENERS                                   */
  /* -------------------------------------------------------------------------- */

  void _onFirstValidLogReceived() {
    // No-op for now (kept for future UI hooks)
  }

  void _onLogRetrievalCompleted() {
    if (!mounted || _hasNavigatedToEventLog) return;

    if (ble.bleProcess.read1000LogsCount.value >= 1000) {
      _hasNavigatedToEventLog = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToEventLogScreen();
        }
      });
    }
  }

  void _onMaxBleConnectionRetriesReached() {
    if (ble.maxBleConnectionRetriesReached.value) {
      _handleFailure("Maximum BLE connection retries reached");
    }
  }

  void _onMaxOtherPacketsRetriesReached() {
    if (ble.maxOtherPacketsRetriesReached.value) {
      _handleFailure("Maximum packet retries reached");
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               NAVIGATION                                   */
  /* -------------------------------------------------------------------------- */

  void _navigateToEventLogScreen() {
    final List<LogModel> logs = ble.bleProcess.validEventLogs.value;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => LogRetrievalCompletedScreen(
              logs: logs,
              panelId: ble.panelName.value,
              panelName: _getDeviceName(),
            ),
      ),
    );
  }

  void _handleFailure(String message) {
    if (_navigatedToFailure) return;
    _navigatedToFailure = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LogRetrievalFailedScreen()),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                               STOP / CANCEL                                */
  /* -------------------------------------------------------------------------- */

  Future<void> _sendStopControlCommand() async {
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
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEC1D24),
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Stop Log Retrieval')),
            ],
          ),
          content: const Text(
            'Are you sure you want to stop the log retrieval process?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC1D24),
              ),
              child: const Text('Yes, Stop'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _sendStopControlCommand();
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                               HELPERS                                      */
  /* -------------------------------------------------------------------------- */

  String _getDeviceName() {
    final device = widget.selectedDevice;
    if (device == null) return "Unknown Device";

    try {
      if (device.platformName.isNotEmpty) {
        return device.platformName;
      }
      return "BLE-${device.remoteId.str.substring(0, 5)}";
    } catch (_) {
      return "BLE Device";
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                       */
  /* -------------------------------------------------------------------------- */

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
              Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showStopConfirmationDialog,
                          child: SvgPicture.asset(
                            'assets/svgs/arrow_back_icon.svg',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Event Log',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  _buildRetrievingLogsContainer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetrievingLogsContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: SvgPicture.asset('assets/svgs/background_2.svg'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 45),
              child: Text(
                'Retrieving Logs...',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF918F8F),
                ),
              ),
            ),
            Lottie.asset(
              'assets/jsons/fetching_log.json',
              height: 320,
              width: 320,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: ValueListenableBuilder<String>(
                valueListenable: ble.processDesc,
                builder: (_, value, __) {
                  return Text(
                    value.isNotEmpty ? value : "Processing...",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF918F8F),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<int>(
                  valueListenable: ble.bleProcess.read1000LogsCount,
                  builder: (_, count, __) {
                    final percent = (count / 1000.0).clamp(0.0, 1.0).toDouble();

                    return Column(
                      children: [
                        Text(
                          '${(percent * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 23),
                        LinearPercentIndicator(
                          lineHeight: 11,
                          percent: percent,
                          backgroundColor: const Color(0xFFD9D9D9),
                          progressColor: const Color(0xFFEC1D24),
                          barRadius: const Radius.circular(20),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildCancelButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _showStopConfirmationDialog,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xFFEC1D24),
          borderRadius: BorderRadius.circular(28.5),
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
    );
  }

  @override
  void dispose() {
    ble.bleProcess.isValidLogRecieved.removeListener(_onFirstValidLogReceived);
    ble.bleProcess.read1000LogsCount.removeListener(_onLogRetrievalCompleted);
    ble.maxBleConnectionRetriesReached.removeListener(
      _onMaxBleConnectionRetriesReached,
    );
    ble.maxOtherPacketsRetriesReached.removeListener(
      _onMaxOtherPacketsRetriesReached,
    );
    super.dispose();
  }
}
