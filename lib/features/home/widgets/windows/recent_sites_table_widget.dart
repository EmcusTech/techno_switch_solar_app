import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentSitesTableWidget extends StatefulWidget {
  const RecentSitesTableWidget({super.key});

  @override
  State<RecentSitesTableWidget> createState() => _RecentSitesTableWidgetState();
}

class _RecentSitesTableWidgetState extends State<RecentSitesTableWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Sites",
          style: GoogleFonts.inter(
            fontSize: context.sp(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        context.verticalSpace(10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFE4E4E7)),
            borderRadius: BorderRadius.circular(context.r(16)),
          ),
          child: Column(
            children: [
              Row(),
              Text(
                "Site Name",
                style: GoogleFonts.inter(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Site Description",
                style: GoogleFonts.inter(
                  fontSize: context.sp(12),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
