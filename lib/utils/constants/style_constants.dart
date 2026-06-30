import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

abstract final class StyleConstants {
  StyleConstants._();

  static TextStyle get textMuted20w600Style => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ColorConstants.textDark,
  );

  static TextStyle get textDark24w600Style => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textDark,
  );

  static TextStyle get borderLight24w600Style => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ColorConstants.borderLight,
  );

  static TextStyle get primary14w600Style => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorConstants.primary,
  );

  static TextStyle get white16w600Style => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorConstants.white,
  );

  static TextStyle get black16w600Style => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorConstants.black,
  );

  static TextStyle get textDark20w700Style => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ColorConstants.textDark,
  );

  static TextStyle get textMuted14w400Style => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorConstants.textMuted,
  );
}
