import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class CommonNumericKeypadTileWidget extends StatefulWidget {
  final String? numericValue;
  final double? height;
  final double? width;
  final bool? isClear;
  final bool? isDelete;
  final Color? fillColor;
  final VoidCallback? onTap;
  const CommonNumericKeypadTileWidget({
    super.key,
    this.numericValue,
    this.height = 66,
    this.width = 100,
    this.isClear = false,
    this.isDelete = false,
    this.fillColor,
    this.onTap,
  });

  @override
  State<CommonNumericKeypadTileWidget> createState() =>
      _CommonNumericKeypadTileWidgetState();
}

class _CommonNumericKeypadTileWidgetState
    extends State<CommonNumericKeypadTileWidget> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return numericKeypadBox(
      numericValue: widget.numericValue,
      height: widget.height,
      width: widget.width,
    );
  }

  Widget numericKeypadBox({
    String? numericValue,
    double? height,
    double? width,
  }) {
    return GestureDetector(
      onTapUp: (details) async {
        widget.onTap?.call();
        await Future.delayed(Duration(milliseconds: 35), () {
          setState(() {
            isPressed = false;
          });
        });
      },
      onTapDown: (details) async {
        setState(() {
          isPressed = true;
        });
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.7),
          border: Border.all(
            color: ColorConstants.blackMaterial.withOpacity(0.08),
            width: 0.696,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isPressed
                    ? [
                      Color.fromARGB(255, 218, 154, 154),
                      Color.fromARGB(255, 238, 62, 62),
                      Color.fromARGB(255, 207, 47, 47),
                    ]
                    : [
                      widget.fillColor ?? ColorConstants.white,
                      widget.fillColor ?? ColorConstants.white,
                      widget.fillColor ?? ColorConstants.white,
                    ],
            stops: [0.0, 0.0, 1.0],
          ),
          boxShadow: [
            // inset shadows are not directly supported in BoxDecoration
            // these outer shadows approximate the neumorphic effect
            BoxShadow(
              color: ColorConstants.color4Dffffff, // rgba(255,255,255,0.30)
              offset: Offset(1.186, -1.186),
              blurRadius: 2.372,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: ColorConstants.color80E1E1E1, // rgba(225,225,225,0.50)
              offset: Offset(-1.186, 1.186),
              blurRadius: 2.372,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: ColorConstants.shadowLight, // rgba(225,225,225,0.20)
              offset: Offset(-1.186, -1.186),
              blurRadius: 2.372,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: ColorConstants.shadowLight, // rgba(225,225,225,0.20)
              offset: Offset(1.186, 1.186),
              blurRadius: 2.372,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: ColorConstants.colorE6Ffffff, // rgba(255,255,255,0.90)
              offset: Offset(-1.186, 1.186),
              blurRadius: 2.372,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: ColorConstants.colorE6E1E1E1, // rgba(225,225,225,0.90)
              offset: Offset(1.186, -1.186),
              blurRadius: 3.558,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child:
              widget.isDelete == true
                  ? SvgPicture.asset(
                    "assets/svgs/keypad_delete_icon.svg",
                    colorFilter: ColorFilter.mode(
                      isPressed
                          ? ColorConstants.white
                          : Color.fromARGB(255, 207, 47, 47),
                      BlendMode.srcIn,
                    ),
                  )
                  : widget.isClear == true
                  ? SvgPicture.asset("assets/svgs/keypad_clear_icon.svg")
                  : Text(
                    numericValue ?? "",
                    style: GoogleFonts.inter(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: isPressed ? ColorConstants.white : ColorConstants.textDark,
                    ),
                  ),
        ),
      ),
    );
  }
}
