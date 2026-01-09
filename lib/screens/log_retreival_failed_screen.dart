import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/home_screen.dart';

class LogRetrievalFailedScreen extends StatefulWidget {
  const LogRetrievalFailedScreen({super.key});

  @override
  State<LogRetrievalFailedScreen> createState() =>
      _LogRetrievalFailedScreenState();
}

class _LogRetrievalFailedScreenState extends State<LogRetrievalFailedScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
    super.initState();
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
                          'Log Retrieval Failed',
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
              child: SvgPicture.asset('assets/svgs/background_2.svg'),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 45),
                child: Text(
                  'Event Log Retrieval\nFailed!',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC1D24),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFEC1D24),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                  SizedBox(height: 120),
                  Text(
                    "Unable to connect to the panel. Please check your connection and try again.",
                    style: GoogleFonts.inter(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // @override
    // Widget build(BuildContext context) {
    //   return Scaffold(
    //     body: Center(
    //       child: Padding(
    //         padding: const EdgeInsets.symmetric(horizontal: 24.0),
    //         child: Column(
    //           // mainAxisAlignment: MainAxisAlignment.center,
    //           children: [
    //             SizedBox(height: 100),
    //             Text(
    //               "Log Retrieval Failed!",
    //               style: GoogleFonts.inter(
    //                 fontSize: 30,
    //                 fontWeight: FontWeight.bold,
    //                 color: Color(0xFFEC1D24),
    //               ),
    //             ),
    //             SizedBox(height: 80),
    // Container(
    //   decoration: BoxDecoration(
    //     color: Color(0xFFEC1D24),
    //     shape: BoxShape.circle,
    //   ),
    //   child: Padding(
    //     padding: const EdgeInsets.all(28.0),
    //     child: Icon(
    //       Icons.close_rounded,
    //       color: Colors.white,
    //       size: 56,
    //     ),
    //   ),
    // ),
    //             SizedBox(height: 80),
    //             Text(
    //               "Unable to connect to the panel. Please check your connection and try again.",
    //               style: GoogleFonts.inter(
    //                 fontSize: 14,
    //                 fontWeight: FontWeight.w500,
    //                 color: Color(0xFF666666),
    //               ),
    //               textAlign: TextAlign.center,
    //             ),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );
    // }
  }
}
