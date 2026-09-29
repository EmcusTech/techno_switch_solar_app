import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';

class UsbConnectWidget extends StatefulWidget {
  const UsbConnectWidget({super.key});

  @override
  State<UsbConnectWidget> createState() => _UsbConnectWidgetState();
}

class _UsbConnectWidgetState extends State<UsbConnectWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(context.r(15)),
      ),
      child: Padding(
        padding: context.edgeInsets(horizontal: 30, vertical: 18),
        child: Column(
          children: [
            _returnUsbConnectIcon(),
            context.verticalSpace(12),
            _returnUsbConnectText(),
            context.verticalSpace(12),
            _returnUsbConnectSubText(),
            context.verticalSpace(20),
            _returnUsbConnectButton(),
          ],
        ),
      ),
    );
  }

  Widget _returnUsbConnectIcon() {
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
                color: ColorConstants.primaryBlueColor,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: context.edgeInsets(all: 21),
                child: SvgPicture.asset('assets/svgs/usb_connect_icon.svg'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _returnUsbConnectText() {
    return Text(
      StringConstants.usbConnectText,
      style: GoogleFonts.inter(
        fontSize: context.sp(16),
        fontWeight: FontWeight.w600,
        color: Color(0xFF18181B),
      ),
    );
  }

  Widget _returnUsbConnectSubText() {
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

  Widget _returnUsbConnectButton() {
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
