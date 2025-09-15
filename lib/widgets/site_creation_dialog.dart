import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SiteCreationDialog extends StatelessWidget {
  final VoidCallback onCreateSite;
  final VoidCallback onSkip;
  final int logCount;

  const SiteCreationDialog({
    super.key,
    required this.onCreateSite,
    required this.onSkip,
    required this.logCount,
  });

  @override
  Widget build(BuildContext context) {
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
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color(0xFFFBDEE1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svgs/new_project_icon.svg',
                  height: 32,
                  width: 32,
                  colorFilter: ColorFilter.mode(
                    Color(0xFFEC1D24),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Title
            Text(
              'Create Site for Logs?',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D3D3D),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12),

            // Description
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: 'You retrieved '),
                  TextSpan(
                    text: '$logCount log${logCount == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                  TextSpan(
                    text:
                        ' from the device, but they are not associated with any site.\n\n',
                  ),
                  TextSpan(
                    text:
                        'Would you like to create a site to save these logs? ',
                  ),
                  TextSpan(
                    text: 'If you skip this step, the logs will be lost.',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Skip Button
                Expanded(
                  child: GestureDetector(
                    onTap: onSkip,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFEFEEEE),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Color(0xFFD0D0D0), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Create Site Button
                Expanded(
                  child: GestureDetector(
                    onTap: onCreateSite,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFEC1D24),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFEC1D24).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Create Site',
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
  }
}

/// Show the site creation dialog
Future<bool?> showSiteCreationDialog(
  BuildContext context, {
  required int logCount,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return SiteCreationDialog(
        logCount: logCount,
        onCreateSite: () {
          Navigator.of(context).pop(true);
        },
        onSkip: () {
          Navigator.of(context).pop(false);
        },
      );
    },
  );
}
