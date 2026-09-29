import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class LiveEventWidget extends StatefulWidget {
  const LiveEventWidget({super.key});

  @override
  State<LiveEventWidget> createState() => _LiveEventWidgetState();
}

class _LiveEventWidgetState extends State<LiveEventWidget> {
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
          _returnLiveEventIcon(),
          context.verticalSpace(30),
          _returnLiveEventText(),
          context.verticalSpace(3),
          _returnLiveEventSubText(),
        ],
      ),
    );
  }

  Widget _returnLiveEventIcon() {
    return Container(
      height: context.h(46),
      width: context.w(46),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: context.edgeInsets(all: 8),
        child: SvgPicture.asset('assets/svgs/loading_icon.svg'),
      ),
    );
  }

  Widget _returnLiveEventText() {
    return Text(
      'Live Events',
      style: GoogleFonts.inter(
        fontSize: context.sp(16),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _returnLiveEventSubText() {
    return Text(
      'Perform system checks ',
      style: GoogleFonts.inter(
        fontSize: context.sp(12),
        fontWeight: FontWeight.w400,
        color: Color(0xFF717171),
      ),
    );
  }
}
