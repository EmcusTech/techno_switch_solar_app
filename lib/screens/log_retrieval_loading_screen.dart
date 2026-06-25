import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'dart:async';
import 'package:techno_switch_solar_app/screens/log_retreival_completed_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/utils/ble_msd_utils.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';

final BleManager ble = Get.find<BleManager>();

class LogRetrievalLoadingScreen extends StatefulWidget {
  final dynamic selectedDevice;
  final ScanType scanType;
  final bool? isLiveEvent;
  final DiscoveredDevice? connectedDevice;
  final String? panelId;

  const LogRetrievalLoadingScreen({
    super.key,
    this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
    this.connectedDevice,
    this.panelId,
  });

  @override
  State<LogRetrievalLoadingScreen> createState() =>
      _LogRetrievalLoadingScreenState();
}

class _LogRetrievalLoadingScreenState extends State<LogRetrievalLoadingScreen> {
  bool _hasNavigatedToEventLog = false;
  bool _allowExit = false;

  final BleManager _bleManager = Get.find<BleManager>();

  @override
  void initState() {
    super.initState();

    _hasNavigatedToEventLog = false;

    ble.bleProcess.read1000LogsCount.addListener(_onLogRetrievalCompleted);
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
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.popUntil((route) => route is PageRoute);
    }

    navigator.pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => LogRetrievalCompletedScreen(
              logs: List.from(ble.bleProcess.validEventLogs.value),
              panelId: _resolvePanelId(),
              panelName: _getDeviceName(),
              connectedDevice: widget.connectedDevice,
              isDirectLogRet: widget.isLiveEvent,
            ),
      ),
    );
  }

  String _resolvePanelId() {
    if ((widget.panelId ?? '').isNotEmpty) {
      return widget.panelId!;
    }

    final device = widget.connectedDevice ?? widget.selectedDevice;
    if (device is DiscoveredDevice) {
      final msdPanelId = BleMsdUtils.panelId(device.manufacturerData);
      if (msdPanelId != null) {
        return msdPanelId.toString();
      }
      if (device.name.isNotEmpty) {
        return BleNameUtils.getDisplayPrefixFromBleName(device.name);
      }
    }

    return _getDeviceName();
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
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEC1D24),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Stop Log Retrieval',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to stop the log retrieval process? This action cannot be undone.',
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
                              'Yes, Stop',
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

    if (confirmed == true && mounted) {
      await _sendStopControlCommand();

      if (widget.isLiveEvent == true) {
        await _bleManager.disconnectConnectedDevice();
      }
    }
  }

  String _getDeviceName() {
    final device = widget.selectedDevice ?? widget.connectedDevice;

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

    return "Unknown Device";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowExit,
      child: Scaffold(
        body: Container(
          height: MediaQuery.sizeOf(context).height,
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
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              _showStopConfirmationDialog();
                            },
                            child: SvgPicture.asset(
                              'assets/svgs/arrow_back_icon.svg',
                            ),
                          ),
                          SizedBox(width: 8),
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
                    SizedBox(height: 19),
                    _buildRetrievingLogsContainer(),
                  ],
                ),
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
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 45),
                child: Text(
                  'Retrieving Logs...',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF918F8F),
                  ),
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
                builder: (context, value, _) {
                  return Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF918F8F),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 120),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: ble.bleProcess.read1000LogsCount,
                      builder: (context, readCount, _) {
                        final percent =
                            (readCount / 1000.0).clamp(0.0, 1.0).toDouble();
                        return Column(
                          children: [
                            Text(
                              '${(percent * 100).toStringAsFixed(1)}%',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                              maxLines: 1,
                            ),
                            SizedBox(height: 23),
                            LinearPercentIndicator(
                              lineHeight: 11.0,
                              percent: percent,
                              backgroundColor: Color(0xFFD9D9D9),
                              progressColor: Color(0xFFEC1D24),
                              barRadius: Radius.circular(20),
                            ),
                            SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: _buildCancelLogRetrievalButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelLogRetrievalButton() {
    return GestureDetector(
      onTap: _showStopConfirmationDialog,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFFEC1D24),
          borderRadius: BorderRadius.circular(28.5),
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
    ble.bleProcess.read1000LogsCount.removeListener(_onLogRetrievalCompleted);
    super.dispose();
  }
}
