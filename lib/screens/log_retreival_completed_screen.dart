import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class LogRetrievalCompletedScreen extends StatefulWidget {
  final List<LogModel> logs;
  final String panelId;
  final String panelName;
  final DiscoveredDevice? connectedDevice;
  const LogRetrievalCompletedScreen({
    super.key,
    required this.logs,
    required this.panelId,
    required this.panelName,
    this.connectedDevice,
  });

  @override
  State<LogRetrievalCompletedScreen> createState() =>
      _LogRetrievalCompletedScreenState();
}

class _LogRetrievalCompletedScreenState
    extends State<LogRetrievalCompletedScreen> {
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
                            Navigator.of(context).pop();
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
                  _buildCompletedLogsContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedLogsContainer() {
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
              alignment: Alignment.topCenter,
              child: SvgPicture.asset('assets/svgs/background_3.svg'),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 45),
                child: Text(
                  'Retrieval\nCompleted!',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00A706),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Lottie.asset(
              'assets/jsons/firmware_upgrade_success.json',
              height: 180,
              width: 180,
              repeat: false,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEFEEEE),
                          borderRadius: BorderRadius.circular(28.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 30,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_back, color: Color(0xFF49454F)),
                              SizedBox(width: 6),
                              Text(
                                "Back",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF49454F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder:
                                (context) => EventLogScreen(
                                  logDataList: widget.logs,
                                  panelName: widget.panelName,
                                  panelVersionNo: '0.98',
                                  isStandalone: true,
                                  panelId: widget.panelId,
                                  connectedDevice: widget.connectedDevice,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xffEC1D24),
                          borderRadius: BorderRadius.circular(28.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 30,
                            right: 16,
                            top: 20,
                            bottom: 20,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Next",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward, color: Colors.white),
                            ],
                          ),
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => EventLogScreen(
                  logDataList: widget.logs,
                  panelName: widget.panelName,
                  panelVersionNo: '0.98',
                  isStandalone: true,
                  panelId: widget.panelId,
                ),
          ),
        );
      },
      child: Container(
        height: 70,
        width: 200,
        color: Colors.red,
        child: Center(child: Text("Go")),
      ),
    );
  }
}
