import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/features/home/controllers/home_screen_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';

class BleConnectWidget extends StatefulWidget {
  const BleConnectWidget({super.key, required this.controller});
  final HomeScreenController controller;

  @override
  State<BleConnectWidget> createState() => _BleConnectWidgetState();
}

class _BleConnectWidgetState extends State<BleConnectWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.controller.openTapToConnectScan,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFFE4E4E7)),
          borderRadius: BorderRadius.circular(context.r(15)),
        ),
        child: Padding(
          padding: context.edgeInsets(horizontal: 30, vertical: 20),
          child: Column(
            children: [
              _returnBleConnectIcon(),
              context.verticalSpace(12),
              _returnBleConnectText(),
              context.verticalSpace(12),
              _returnBleConnectSubText(),
              context.verticalSpace(20),
              _returnBleConnectButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _returnBleConnectIcon() {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.tertiaryBlueColor,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: context.edgeInsets(all: 20),
        child: Container(
          decoration: BoxDecoration(
            color: ColorConstants.secondaryBlueColor,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: context.edgeInsets(all: 15),
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: context.edgeInsets(all: 21),
                child: SvgPicture.asset('assets/svgs/ble_connect_icon.svg'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _returnBleConnectText() {
    return Text(
      StringConstants.bleConnectText,
      style: GoogleFonts.inter(
        fontSize: context.sp(16),
        fontWeight: FontWeight.w600,
        color: Color(0xFF18181B),
      ),
    );
  }

  Widget _returnBleConnectSubText() {
    return Text(
      StringConstants.connectSubText,
      style: GoogleFonts.inter(
        fontSize: context.sp(12),
        fontWeight: FontWeight.w400,
        color: Color(0xFF64748B),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _returnBleConnectButton() {
    return TextButton(
      onPressed: () {},
      child: Text(
        'Connect',
        style: GoogleFonts.inter(
          fontSize: context.sp(14),
          fontWeight: FontWeight.w500,
          color: ColorConstants.primaryBlueColor,
        ),
      ),
    );
  }
}
