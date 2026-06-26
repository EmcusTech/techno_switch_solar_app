import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

abstract final class StyleConstants {
  StyleConstants._();

  static TextStyle get heading24SemiBoldMuted => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textMuted,
  );

  static TextStyle get heading20Bold => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: ColorConstants.textDark,
  );

  static TextStyle get heading18Bold => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: ColorConstants.textDark,
  );

  static TextStyle get body16SemiBoldWhite => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorConstants.white,
  );

  static TextStyle get body16SemiBoldPrimary => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorConstants.primary,
  );

  static TextStyle get body16SemiBoldGray => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textGray,
  );

  static TextStyle get body16RegularGray => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ColorConstants.textGray,
  );

  static TextStyle get body14SemiBoldWhite => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorConstants.white,
  );

  static TextStyle get body14SemiBoldDark => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ColorConstants.textDark,
  );

  static TextStyle get body14RegularMuted => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorConstants.textMuted,
  );

  static TextStyle get body14RegularGray => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ColorConstants.textGray,
  );

  static TextStyle get body12RegularMuted => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ColorConstants.textMuted,
  );

  static TextStyle get body12RegularGray => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: ColorConstants.textGray,
  );

  static TextStyle get percent32Bold => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle get title24BoldSuccess => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ColorConstants.success,
  );

  static TextStyle get title24BoldPrimary => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ColorConstants.primary,
  );
}
