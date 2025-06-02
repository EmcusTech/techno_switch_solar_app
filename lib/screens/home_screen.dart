import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF6EBEB), 
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: 0.3,
                      child: Container(
                        width: 166,
                        height: 166,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffEC1D24).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                SvgPicture.asset('assets/svgs/background_1.svg'),
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFBDEE1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(25.0),
                              child: SvgPicture.asset(
                                'assets/svgs/logo.svg',
                                height: 59.29,
                                width: 51,
                                colorFilter: ColorFilter.mode(
                                  Color(0xFFEC1D24),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Tap to connect',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
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
