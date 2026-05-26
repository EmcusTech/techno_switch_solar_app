import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown when the panel does not respond after repeated network-flow retries.
class BleCommunicationFailureDialog {
  BleCommunicationFailureDialog._();

  static const String defaultMessage =
      'The panel did not respond. Please scan and connect again.';

  static Future<void> show({
    required BuildContext context,
    String message = defaultMessage,
    String title = 'Connection problem',
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
              color: const Color(0xFF3D3D3D),
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF918F8F),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC1D24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.5),
                  ),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
