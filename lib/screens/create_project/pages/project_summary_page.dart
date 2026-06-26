import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class ProjectSummaryPage extends StatefulWidget {
  final String enabled;
  final String actuatorType;
  final String function;
  final String autoCountdown;
  final String manualCountdown;
  final String releaseTime;
  final String resetInCount;
  final String holdCount;
  final String action;
  final Function(String, String) onExtinguishingSettingChanged;
  final Function() onUploadToPanel;

  const ProjectSummaryPage({
    super.key,
    required this.enabled,
    required this.actuatorType,
    required this.function,
    required this.autoCountdown,
    required this.manualCountdown,
    required this.releaseTime,
    required this.resetInCount,
    required this.holdCount,
    required this.action,
    required this.onExtinguishingSettingChanged,
    required this.onUploadToPanel,
  });

  @override
  State<ProjectSummaryPage> createState() => _ProjectSummaryPageState();
}

class _ProjectSummaryPageState extends State<ProjectSummaryPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ColorConstants.highlightYellow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ColorConstants.highlightGold),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: CustomPaint(painter: DiagonalStripesPainter()),
                        ),
                        Column(
                          children: [
                            SizedBox(height: 36),
                            Text(
                              StringConstants.extinguishingOUT,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ColorConstants.textBodyDark,
                                letterSpacing: 4.0,
                              ),
                            ),
                            SizedBox(height: 31),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Divider(
                                color: ColorConstants.blackMaterial.withValues(alpha: 0.17),
                                thickness: 1,
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              child: Column(
                                children: [
                                  _buildDropdownField(
                                    StringConstants.enabled,
                                    widget.enabled,
                                    [StringConstants.yes, StringConstants.no],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(
                                    StringConstants.actuatorType,
                                    widget.actuatorType,
                                    [StringConstants.typeA, StringConstants.typeB, StringConstants.typeC],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(
                                    'Function',
                                    widget.function,
                                    [StringConstants.functionA, StringConstants.functionB, StringConstants.functionC],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(
                                    StringConstants.autoCountdown,
                                    widget.autoCountdown,
                                    [StringConstants.s10Sec, StringConstants.s15Sec, StringConstants.s20Sec, StringConstants.s30Sec],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(
                                    StringConstants.manualCountdown,
                                    widget.manualCountdown,
                                    [StringConstants.s15Sec, StringConstants.s30Sec, StringConstants.s45Sec, StringConstants.s60Sec],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(
                                    StringConstants.releaseTime,
                                    widget.releaseTime,
                                    [StringConstants.s30Sec, StringConstants.s45Sec, StringConstants.s60Sec, StringConstants.s90Sec],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(
                                    StringConstants.resetInCount,
                                    widget.resetInCount,
                                    [StringConstants.yes, StringConstants.no],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(
                                    StringConstants.holdCount,
                                    widget.holdCount,
                                    [StringConstants.s3Sec, StringConstants.s5Sec, StringConstants.s10Sec, StringConstants.s15Sec],
                                  ),
                                  SizedBox(height: 20),
                                  _buildDropdownField(StringConstants.action, widget.action, [
                                    'Extinguish',
                                    StringConstants.alert,
                                    StringConstants.test,
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: CustomPaint(painter: DiagonalStripesPainter()),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _showUploadDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              StringConstants.uploadToPanel,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorConstants.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textDark,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => _showDropdownDialog(label, value, options),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.criticalRed,
                  ),
                ),
                SizedBox(width: 2),
                SvgPicture.asset('assets/svgs/drop_down_red_icon.svg'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDropdownDialog(
    String label,
    String currentValue,
    List<String> options,
  ) {
    String selectedValue = currentValue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textBodyDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                options.map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: ColorConstants.textDark,
                      ),
                    ),
                    value: option,
                    groupValue: selectedValue,
                    activeColor: ColorConstants.primary,
                    onChanged: (String? value) {
                      selectedValue = value!;
                      Navigator.of(context).pop();
                      widget.onExtinguishingSettingChanged(
                        label,
                        selectedValue,
                      );
                    },
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                StringConstants.cancel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            StringConstants.uploadToPanel,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textBodyDark,
            ),
          ),
          content: Text(
            StringConstants.areYouSureYouWantToUploadThisConfigurationToThePanel,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                StringConstants.cancel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onUploadToPanel();
                _showSuccessDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upload',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: ColorConstants.successMaterial, size: 24),
              SizedBox(width: 8),
              Text(
                StringConstants.uploadSuccessful,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textBodyDark,
                ),
              ),
            ],
          ),
          content: Text(
            StringConstants.configurationHasBeenSuccessfullyUploadedToThePanel,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.textSecondary,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                StringConstants.ok,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint =
        Paint()
          ..color = ColorConstants.brightYellow
          ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final stripePaint =
        Paint()
          ..color = ColorConstants.black
          ..style = PaintingStyle.fill;

    const double stripeWidth = 6;
    const double totalStripeWidth = 12;
    final double diagonalOffset = size.height;
    for (
      double i = -diagonalOffset;
      i < size.width + diagonalOffset;
      i += totalStripeWidth
    ) {
      final path = Path();
      path.moveTo(i, 0);
      path.lineTo(i + stripeWidth, 0);
      path.lineTo(i + stripeWidth + diagonalOffset, size.height);
      path.lineTo(i + diagonalOffset, size.height);
      path.close();

      canvas.drawPath(path, stripePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
