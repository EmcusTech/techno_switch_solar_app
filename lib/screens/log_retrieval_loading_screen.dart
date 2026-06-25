import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'dart:async';
import 'package:techno_switch_solar_app/screens/log_retreival_completed_screen.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/ble_notify_data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_handler.dart';
import 'package:techno_switch_solar_app/utils/bluetooth/data_helper.dart';
import 'package:techno_switch_solar_app/utils/bluetooth_constants.dart';
import 'package:techno_switch_solar_app/utils/event_constants.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/utils/timestamp_converter.dart';
import 'package:techno_switch_solar_app/models/frame_data.dart';

final BleManager ble = Get.find<BleManager>();

class LogRetrievalLoadingScreen extends StatefulWidget {
  final dynamic selectedDevice;
  final ScanType scanType;
  final bool? isLiveEvent;
  final DiscoveredDevice? connectedDevice;
  const LogRetrievalLoadingScreen({
    super.key,
    this.selectedDevice,
    required this.scanType,
    this.isLiveEvent = false,
    this.connectedDevice,
  });

  @override
  State<LogRetrievalLoadingScreen> createState() =>
      _LogRetrievalLoadingScreenState();
}

class _LogRetrievalLoadingScreenState extends State<LogRetrievalLoadingScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _accessCodeController;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _progress = 0.0;
  Timer? _timer;
  String connectionStatus = "Initializing...";
  bool connectionFailed = false;
  String? _errorMessage;
  StreamSubscription<BleHandshakeEvent>? _handshakeSubscription;
  StreamSubscription<DeviceConnectionState>? _connectionSub;
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

  late SerialCommunicationService _serialService;
  final List<LogModel> _retrievedLogs = [];
  int _logsCount = 0;
  StreamSubscription? _logSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _bleNotificationSubscription;
  String? _capturedPanelId;
  static const int totalExpectedLogs = 1000;

  BleNotifyDataHandler? _bleHandler;
  DiscoveredDevice? _connectedBleDevice;
  bool _isReceivingLogs = false;
  int _logEvtSearchNumber = 999;
  Timer? _logRetrievalTimeout;
  final BleManager _bleManager = Get.find<BleManager>();

  @override
  void initState() {
    super.initState();
    _accessCodeController = TextEditingController();
    _accessCodeController.addListener(() {
      setState(() {});
    });

    _serialService = AppServices.serialService;
    _capturedPanelId = _serialService.currentPanelId;

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {
          _progress = _animation.value;
        });
      });

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

    final _ = _handleBleNotification;
  }

  void _onMaxBleConnectionRetriesReached() {
    setState(() {
      _maxBleConnectionRetriesReached =
          ble.maxBleConnectionRetriesReached.value;
      if (_maxBleConnectionRetriesReached) {
        connectionFailed = true;
        _errorMessage = "Maximum BLE connection retries reached";
        connectionStatus = _errorMessage!;
      }
    });
  }

  void _onMaxOtherPacketsRetriesReached() {
    setState(() {
      _maxOtherPacketsRetriesReached = ble.maxOtherPacketsRetriesReached.value;
      if (_maxOtherPacketsRetriesReached) {
        connectionFailed = true;
        _errorMessage = "Maximum packet retries reached";
        connectionStatus = _errorMessage!;
      }
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
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);

    if (navigator.canPop()) {
      navigator.popUntil((route) => route is PageRoute);
    }

    navigator.pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => LogRetrievalCompletedScreen(
              logs: _retrievedLogs,
              panelId: _capturedPanelId ?? '',
              panelName: _getDeviceName(),
              connectedDevice: widget.connectedDevice,
              isDirectLogRet: widget.isLiveEvent,
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
    final device = widget.selectedDevice ?? _connectedBleDevice;

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

  void _handleBleNotification(List<int> rxData) async {
    if (rxData.isEmpty || !_isReceivingLogs) return;

    try {
      final bool shouldDecrypt =
          _bleHandler != null &&
          _bleHandler!.encryptionDecryptionState.value ==
              EncryptionDecryptionState.enabled;

      FrameData? frame;
      if (shouldDecrypt) {
        try {
          frame = await DataHandler().decryptTheDataPacketWithoutConversion(
            rxData,
          );
        } catch (e) {
          print("DEBUG: LogRetrieval - Failed to decrypt frame: $e");
          return;
        }
      } else {
        frame = DataHandler().parseRxFrame(rxData);
      }

      if (frame == null) {
        print("DEBUG: LogRetrieval - Failed to parse frame");
        return;
      }

      List<int> technoswitchFrameBytes = convertStringListToHex(
        frame.payloadData,
      );

      if (technoswitchFrameBytes.length != 216) {
        print(
          "DEBUG: LogRetrieval - Invalid frame length: ${technoswitchFrameBytes.length}",
        );
        return;
      }

      const int frameSot = 0xFE;
      const int frameEot = 0xFD;
      if (technoswitchFrameBytes[0] != frameSot ||
          technoswitchFrameBytes[215] != frameEot) {
        print("DEBUG: LogRetrieval - Invalid frame markers");
        return;
      }

      int pktTyp = technoswitchFrameBytes[3];
      int mode = technoswitchFrameBytes[10];
      int cmd = technoswitchFrameBytes[12];

      const int packetTypeNrm = 1;
      const int dbSetupReq = 2;
      const int eventStatusCmd = 2;

      if (pktTyp == packetTypeNrm &&
          mode == dbSetupReq &&
          cmd == eventStatusCmd) {
        print("DEBUG: LogRetrieval - Log packet received");
        _processLogPacket(technoswitchFrameBytes);

        if (_logEvtSearchNumber > 0) {
          _logEvtSearchNumber--;
        } else {
          _completeLogRetrieval();
        }
      } else {
        print(
          "DEBUG: LogRetrieval - Non-log packet: pktTyp=$pktTyp, mode=$mode, cmd=$cmd",
        );
      }
    } catch (e) {
      print("DEBUG: LogRetrieval - Error processing notification: $e");
    }
  }

  void _processLogPacket(List<int> evtData) {
    try {
      List<int> timestamp = evtData.sublist(12, 16);
      int timestampDecimal =
          timestamp[3] |
          (timestamp[2] << 8) |
          (timestamp[1] << 16) |
          (timestamp[0] << 24);

      DateTime eventTime =
          timestampDecimal != 0x00
              ? TimestampConverter.clockTimeFromTimeStamp(timestampDecimal)
              : DateTime.now();

      int eventId =
          (evtData[126] << 24) |
          (evtData[127] << 16) |
          (evtData[128] << 8) |
          (evtData[129] << 0);

      String evtTextAscii;
      List<int> evtText = evtData.sublist(42, 124);
      if (evtText.length > 1 && evtText[1] != 0x00) {
        int textLen = evtText[1];
        List<int> evtTextValue = evtText.sublist(2, 2 + textLen);
        evtTextAscii = String.fromCharCodes(evtTextValue);
      } else {
        evtTextAscii = "NO-TEXT";
      }

      String panelSource;
      if (evtData[9] == EventConstants.evtTypeNetworkAddress) {
        panelSource =
            evtData[29] == 0
                ? "Module"
                : evtData[29] == 1
                ? "Panel No. ${evtData[30]}"
                : evtData[29] == 2
                ? "Repeater No. ${evtData[30]}"
                : evtData[29] == 3
                ? "SOLAR"
                : evtData[29] == 4
                ? "Server No. ${evtData[30]}"
                : "";
      } else if (evtData[9] == EventConstants.evtTypeAccess) {
        panelSource =
            evtData[29] == 0
                ? "Control"
                : evtData[29] == 1
                ? "Keyboard"
                : evtData[29] == 2
                ? "SOLAR"
                : evtData[29] == 3
                ? "Server"
                : "";
      } else {
        panelSource = "";
      }

      if (eventId != 0) {
        LogModel logModel = LogModel(
          panelText: panelSource,
          eventId: (eventId + 1).toString(),
          eventDateTime: eventTime,
          panelNo: evtData[0].toString(),
          lBusNo: evtData[1].toString(),
          moduleNo: evtData[2].toString(),
          eventStatus: EventConstants.getEventStatusValue(evtData[10]),
          eventClass: EventConstants.getEventClassValue(evtData[7]),
          eventSource: panelSource,
          eventType: EventConstants.getEventType(evtData[9]),
          eventSubType: EventConstants.getEventDescription(
            evtData[9],
            evtData[11],
          ),
          identifier: EventConstants.getEventIdentifier(
            evtData[9],
            evtData[29],
            evtData[30],
            evtData[31],
            evtData[16],
            evtData[18],
            evtData[20],
          ),
          text: evtTextAscii,
          isValid: timestampDecimal != 0x00,
          retrievedAt: DateTime.now(),
        );

        if (mounted) {
          setState(() {
            _retrievedLogs.add(logModel);
            _logsCount = _retrievedLogs.length;
            _progress = (_logsCount / totalExpectedLogs).clamp(0.0, 1.0);
            connectionStatus =
                "Receiving logs... $_logsCount logs received (${(_progress * 100).toInt()}%)";
          });
        }

        print(
          "DEBUG: LogRetrieval - Log $_logsCount received: ${logModel.eventType}",
        );
      }
    } catch (e) {
      print("DEBUG: LogRetrieval - Error processing log packet: $e");
    }
  }

  void _completeLogRetrieval() {
    if (!_isReceivingLogs) return;

    _isReceivingLogs = false;
    _logRetrievalTimeout?.cancel();

    if (mounted) {
      setState(() {
        _progress = 1.0;
        connectionStatus = "Log retrieval completed. Total: $_logsCount logs";
      });

      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _navigateToEventLogScreen();
        }
      });
    }
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
                  final statusText = value;
                  return Text(
                    statusText,
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
                        final displayProgress =
                            readCount == 0 ? _progress : percent;
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
                              percent: displayProgress,
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
    _accessCodeController.dispose();
    _controller.dispose();
    _timer?.cancel();
    _logSubscription?.cancel();
    _statusSubscription?.cancel();
    _handshakeSubscription?.cancel();
    _bleNotificationSubscription?.cancel();
    _logRetrievalTimeout?.cancel();
    _connectionSub?.cancel();
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
