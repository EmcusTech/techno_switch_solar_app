import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class RetrieveLogWidget extends StatefulWidget {
  const RetrieveLogWidget({super.key});

  @override
  State<RetrieveLogWidget> createState() => _RetrieveLogWidgetState();
}

class _RetrieveLogWidgetState extends State<RetrieveLogWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.w(378),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(context.r(15)),
      ),
      padding: context.edgeInsets(horizontal: 20, vertical: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _returnRetrieveLogIcon(),
          context.verticalSpace(30),
          _returnRetrieveLogText(),
          context.verticalSpace(3),
          _returnRetrieveLogSubText(),
        ],
      ),
    );
  }

  Widget _returnRetrieveLogIcon() {
    return Container(
      height: context.h(46),
      width: context.w(46),
      decoration: BoxDecoration(
        color: ColorConstants.lightPurpleColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: context.edgeInsets(all: 10),
        child: SvgPicture.asset('assets/svgs/download_icon.svg'),
      ),
    );
  }

  Widget _returnRetrieveLogText() {
    return Text(
      'Retrieve Log',
      style: GoogleFonts.inter(
        fontSize: context.sp(16),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _returnRetrieveLogSubText() {
    return Text(
      'Download system log',
      style: GoogleFonts.inter(
        fontSize: context.sp(12),
        fontWeight: FontWeight.w400,
        color: Color(0xFF717171),
      ),
    );
  }
}
