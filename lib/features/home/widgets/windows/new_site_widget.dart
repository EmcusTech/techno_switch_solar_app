import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class NewSiteWidget extends StatefulWidget {
  const NewSiteWidget({super.key});

  @override
  State<NewSiteWidget> createState() => _NewSiteWidgetState();
}

class _NewSiteWidgetState extends State<NewSiteWidget> {
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
          _returnNewSiteIcon(),
          context.verticalSpace(30),
          _returnNewSiteText(),
          context.verticalSpace(3),
          _returnNewSiteSubText(),
        ],
      ),
    );
  }

  Widget _returnNewSiteIcon() {
    return Container(
      height: context.h(46),
      width: context.w(46),
      decoration: BoxDecoration(
        color: ColorConstants.primaryBlueColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: context.edgeInsets(all: 8),
        child: SvgPicture.asset('assets/svgs/add_icon.svg'),
      ),
    );
  }

  Widget _returnNewSiteText() {
    return Text(
      'New Site',
      style: GoogleFonts.inter(
        fontSize: context.sp(16),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _returnNewSiteSubText() {
    return Text(
      'Create a new setup project',
      style: GoogleFonts.inter(
        fontSize: context.sp(12),
        fontWeight: FontWeight.w400,
        color: Color(0xFF717171),
      ),
    );
  }
}
