import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/screens/access_code_screen.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';

class ScannedScreen extends StatefulWidget {
  const ScannedScreen({super.key});

  @override
  State<ScannedScreen> createState() => _ScannedScreenState();
}

class _ScannedScreenState extends State<ScannedScreen> {
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              _buildDevicesIdentified(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
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
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ScanningScreen(),
                        ),
                      );
                    },
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
              ),
              SizedBox(height: 15),
              Text(
                'Tap to Scan Again',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesIdentified() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 48),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Devices Identified',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D3D3D),
              ),
            ),
          ),
          SizedBox(height: 20),
          _buildRecentProjectItem(),
        ],
      ),
    );
  }

  Widget _buildRecentProjectItem() {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 10,
      separatorBuilder: (context, index) {
        return SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AccessCodeScreen(),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Color(0xFFB9B9B9).withValues(alpha: 0.31),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  // SvgPicture.asset('assets/svgs/panel_icon.svg'),
                  Image.asset('assets/images/panel_icon.png'),
                  SizedBox(width: 14.31),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Name',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3D3D3D),
                        ),
                      ),
                      Text(
                        'location',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF918F8F),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  SvgPicture.asset('assets/svgs/arrow_right_colored_icon.svg'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
