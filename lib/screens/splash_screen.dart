import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:techno_switch_solar_app/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
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
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: SvgPicture.asset(
                      'assets/svgs/splashscreen_background_1.svg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Expanded(
                    child: SvgPicture.asset(
                      'assets/svgs/splashscreen_background_2.svg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 32,
                    ),
                    child: Image.asset('assets/images/full_logo.png'),
                  ),
                  // Text(
                  //   'Techno Switch',
                  //   style: GoogleFonts.inter(
                  //     fontSize: 22,
                  //     fontWeight: FontWeight.w700,
                  //     color: const Color(0xFF3D3D3D),
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   'Smart monitoring for fire panels',
                  //   style: GoogleFonts.inter(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w500,
                  //     color: Colors.grey.shade600,
                  //   ),
                  // ),
                  // const SizedBox(height: 6),
                  Text(
                    'Panel Configuration Tool',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      // fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D3D3D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      height: 2,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFEC1D24),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  //last production version : v0.0.8
                  Text(
                    'v0.0.41 -- testing version',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEC1D24),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LoadingAnimationWidget.waveDots(
                    color: const Color(0xFFEC1D24),
                    size: 54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
