import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';

class SiteDetailScreen extends StatelessWidget {
  final SiteWithLogCount siteWithLogCount;
  const SiteDetailScreen({super.key, required this.siteWithLogCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset('assets/svgs/background_1.svg'),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 54),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: SvgPicture.asset(
                        'assets/svgs/arrow_back_icon.svg',
                      ),
                    ),
                    SizedBox(width: 17),
                    Text(
                      "Site Details",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 23),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 35,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Site Name",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.siteName,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Installer Name",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.installerName,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Company Name",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.companyName,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "SAQCC Registration Number",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.saqccRegNumber,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Building Name",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.buildingName,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Installer Contact Number",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.installerContactNumber,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Installer Email",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.installerEmail,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "Site Description",
                          style: GoogleFonts.inter(
                            color: Color(0xFF767676),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          siteWithLogCount.site.siteDescription,
                          style: GoogleFonts.inter(
                            color: Color(0xFF3A3A3A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
