import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/scanned_screen.dart';
import 'package:techno_switch_solar_app/widgets/scanning_widget.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
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
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                SvgPicture.asset('assets/svgs/background_1.svg'),
                Spacer(),
                Transform.rotate(
                  angle: 3.14159,
                  child: SvgPicture.asset('assets/svgs/background_1.svg'),
                ),
              ],
            ),
            
            Align(alignment: Alignment.center, child: ScanningAnimation()),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannedScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFEC1D24),
                        borderRadius: BorderRadius.circular(28.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Stop Scanning',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    'Please wait till scan identifies the devices....',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
