import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Shown when the panel does not respond after repeated network-flow retries.
class BleCommunicationFailureDialog {
  BleCommunicationFailureDialog._();

  static const String defaultMessage =
      StringConstants.thePanelDidNotRespondPleaseScanAndConnectAgain;

  static Future<void> show({
    required BuildContext context,
    String message = defaultMessage,
    String title = StringConstants.connectionProblem,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorConstants.textDark,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.textMuted,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.5),
                  ),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  StringConstants.ok,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
