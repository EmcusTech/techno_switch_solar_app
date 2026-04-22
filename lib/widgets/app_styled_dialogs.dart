import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Decision dialogs matching the app pattern (rounded [Dialog], icon circle, two actions).
Future<T?> showAppStyledTwoActionDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required String leadingActionLabel,
  required String trailingActionLabel,
  required T leadingValue,
  required T trailingValue,
  IconData icon = Icons.info_outline_rounded,
  Color iconColor = const Color(0xFFEC1D24),
  Color iconCircleColor = const Color(0xFFFBDEE1),
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconCircleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D3D3D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(leadingValue),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFEEEE),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFD0D0D0),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            leadingActionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.of(dialogContext).pop(trailingValue),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC1D24),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEC1D24).withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            trailingActionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
