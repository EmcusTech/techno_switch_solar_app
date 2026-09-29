import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class OpenSiteWidget extends StatefulWidget {
  const OpenSiteWidget({super.key});

  @override
  State<OpenSiteWidget> createState() => _OpenSiteWidgetState();
}

class _OpenSiteWidgetState extends State<OpenSiteWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.w(385),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(context.r(15)),
      ),
      padding: context.edgeInsets(horizontal: 20, vertical: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _returnOpenSiteIcon(),
          context.verticalSpace(30),
          _returnOpenSiteText(),
          context.verticalSpace(3),
          _returnOpenSiteSubText(),
        ],
      ),
    );
  }

  Widget _returnOpenSiteIcon() {
    return Container(
      height: context.h(46),
      width: context.w(46),
      decoration: BoxDecoration(
        color: ColorConstants.lightGreenColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: context.edgeInsets(all: 10),
        child: SvgPicture.asset('assets/svgs/folder_icon.svg'),
      ),
    );
  }

  Widget _returnOpenSiteText() {
    return Text(
      'Open Site',
      style: GoogleFonts.inter(
        fontSize: context.sp(16),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _returnOpenSiteSubText() {
    return Text(
      'Access existing project',
      style: GoogleFonts.inter(
        fontSize: context.sp(12),
        fontWeight: FontWeight.w400,
        color: Color(0xFF717171),
      ),
    );
  }
}
