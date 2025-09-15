import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'dart:async';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/utils/serial_communication_service.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';

class LogRetrievalLoadingScreen extends StatefulWidget {
  const LogRetrievalLoadingScreen({super.key});

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

  // Log retrieval state
  late SerialCommunicationService _serialService;
  List<LogModel> _retrievedLogs = [];
  String _connectionStatus = "Disconnected";
  int _logsCount = 0;
  bool _logRetrievalCompleted = false;
  StreamSubscription? _logSubscription;
  StreamSubscription? _statusSubscription;
  String? _capturedPanelId; // Capture panel ID before potential disconnect

  @override
  void initState() {
    super.initState();
    _accessCodeController = TextEditingController();
    _accessCodeController.addListener(() {
      setState(() {});
    });

    // Initialize serial service
    _serialService = AppServices.serialService;

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

    // Start log retrieval instead of animation
    _startLogRetrieval();
  }

  void _startLogRetrieval() {
    // Check if already connected and start log retrieval
    if (AppServices.isConnected) {
      // Capture the panel ID before starting log retrieval (before potential disconnect)
      _capturedPanelId = AppServices.serialService.currentPanelId;
      print("DEBUG: LogRetrieval - Captured panel ID: $_capturedPanelId");

      _connectionStatus = "Starting log retrieval...";

      // Listen to log stream
      _logSubscription = _serialService.logStream.listen((logModel) {
        setState(() {
          _retrievedLogs.add(logModel);
          _logsCount = _retrievedLogs.length;
        });
      });

      // Listen to status stream
      _statusSubscription = _serialService.statusStream.listen((status) {
        setState(() {
          _connectionStatus = status;

          // Check if log retrieval is completed
          if (status.contains("Completed") || status.contains("Disconnected")) {
            _logRetrievalCompleted = true;
            _controller.forward().then((_) {
              // Navigate to EventLogScreen with retrieved logs and captured panel ID
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) => EventLogScreen(
                        logDataList: _retrievedLogs,
                        panelName: 'RHINO2008',
                        panelVersionNo: '0.98',
                        isStandalone: true, // This is standalone mode
                        panelId: _capturedPanelId, // Pass the captured panel ID
                      ),
                ),
              );
            });
          }
        });
      });

      // Start the actual log retrieval process
      _serialService.startLogRetrieval();
    } else {
      _connectionStatus = "Device not connected";
      // Fallback navigation after 5 seconds if not connected
      _controller.forward();
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (context) => EventLogScreen(
                    logDataList: [], // Empty list if not connected
                    panelName: 'RHINO2008',
                    panelVersionNo: '0.98',
                  ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: EdgeInsets.only(top: 54),
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
                            // Disconnect Bluetooth when going back
                            await NavigationService.navigateBackToScanning(
                              context,
                            );
                          },
                          child: SvgPicture.asset(
                            'assets/svgs/arrow_back_icon.svg',
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Event Log Retrieval ',
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
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Retrieving',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF918F8F),
                      ),
                    ),
                    Text(
                      'Event Log',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3A3A3A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CupertinoActivityIndicator(radius: 20, color: Color(0xFFEC1D24)),
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Text(
                'Please Wait...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _logRetrievalCompleted
                          ? '${(_progress * 100).toInt()}%'
                          : '$_logsCount logs',
                      style: GoogleFonts.inter(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                    ),
                    SizedBox(height: 31),
                    LinearPercentIndicator(
                      lineHeight: 11.0,
                      percent: _progress,
                      backgroundColor: Color(0xFFD9D9D9),
                      progressColor: Color(0xFFEC1D24),
                      barRadius: Radius.circular(20),
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          _connectionStatus.isNotEmpty
                              ? _connectionStatus
                              : 'Fetching Logs...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildBottomBar() {
  //   return Padding(
  //     padding: const EdgeInsets.all(20),
  //     child: Row(
  //       children: [
  //         Opacity(
  //           opacity: 0.2,
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color: Color(0xFFEFEEEE),
  //               borderRadius: BorderRadius.circular(28.5),
  //             ),
  //             child: Padding(
  //               padding: const EdgeInsets.only(
  //                 top: 18,
  //                 bottom: 18,
  //                 left: 16,
  //                 right: 34,
  //               ),
  //               child: Row(
  //                 children: [
  //                   Icon(Icons.arrow_back, color: Color(0xFF49454F)),
  //                   SizedBox(width: 6),
  //                   Text(
  //                     'Back',
  //                     style: GoogleFonts.inter(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //         Spacer(),
  //         GestureDetector(
  //           onTap: () {
  //             if (_accessCodeController.text.isEmpty) {
  //               return;
  //             }
  //           },
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color:
  //                   _accessCodeController.text.isEmpty
  //                       ? Color(0xFFDADADA)
  //                       : Color(0xFFEC1D24),
  //               borderRadius: BorderRadius.circular(28.5),
  //             ),
  //             child: Padding(
  //               padding: const EdgeInsets.only(
  //                 top: 18,
  //                 bottom: 18,
  //                 left: 27,
  //                 right: 23,
  //               ),
  //               child: Row(
  //                 children: [
  //                   Text(
  //                     'Retrieve Data',
  //                     style: GoogleFonts.inter(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                   SizedBox(width: 13),
  //                   Icon(Icons.arrow_forward, color: Colors.white),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _accessCodeController.dispose();
    _controller.dispose();
    _timer?.cancel();
    _logSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
