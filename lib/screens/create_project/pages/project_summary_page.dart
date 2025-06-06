import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
        Text(
          'Extinguishing Out',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3A3A3A),
          ),
        ),
        SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Main configuration container with yellow background and stripes
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF59D), // Light yellow background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    children: [
                      // Top diagonal stripes
                      Container(
                        width: double.infinity,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: CustomPaint(
                          painter: DiagonalStripesPainter(),
                        ),
                      ),
                      
                      // Main content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          children: [
                            Text(
                              'EXTINGUISHING OUT',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000000),
                                letterSpacing: 2.0,
                              ),
                            ),
                            SizedBox(height: 32),
                            
                            // Configuration fields
                            _buildDropdownField('Enabled', widget.enabled, ['Yes', 'No']),
                            SizedBox(height: 20),
                            _buildDropdownField('Actuator Type', widget.actuatorType, ['Type A', 'Type B', 'Type C']),
                            SizedBox(height: 20),
                            _buildDropdownField('Function', widget.function, ['Function A', 'Function B', 'Function C']),
                            SizedBox(height: 20),
                            _buildDropdownField('Auto Countdown', widget.autoCountdown, ['10 Sec', '15 Sec', '20 Sec', '30 Sec']),
                            SizedBox(height: 20),
                            _buildDropdownField('Manual Countdown', widget.manualCountdown, ['15 Sec', '30 Sec', '45 Sec', '60 Sec']),
                            SizedBox(height: 20),
                            _buildDropdownField('Release Time', widget.releaseTime, ['30 Sec', '45 Sec', '60 Sec', '90 Sec']),
                            SizedBox(height: 20),
                            _buildDropdownField('Reset in Count', widget.resetInCount, ['Yes', 'No']),
                            SizedBox(height: 20),
                            _buildDropdownField('Hold / Count', widget.holdCount, ['3 Sec', '5 Sec', '10 Sec', '15 Sec']),
                            SizedBox(height: 20),
                            _buildDropdownField('Action', widget.action, ['Extinguish', 'Alert', 'Test']),
                          ],
                        ),
                      ),
                      
                      // Bottom diagonal stripes
                      Container(
                        width: double.infinity,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: CustomPaint(
                          painter: DiagonalStripesPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
        
        // Upload to Panel button - Fixed at bottom
        Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Handle upload to panel
              _showUploadDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEC1D24),
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              'Upload to Panel',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF000000),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => _showDropdownDialog(label, value, options),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFEC1D24),
                      ),
                    ),
                  ),
                  SvgPicture.asset('assets/svgs/drop_down_red_icon.svg'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDropdownDialog(String label, String currentValue, List<String> options) {
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
              color: Color(0xFF3A3A3A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      option,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF3D3D3D),
                      ),
                    ),
                    value: option,
                    groupValue: selectedValue,
                    activeColor: Color(0xFFEC1D24),
                    onChanged: (String? value) {
                      selectedValue = value!;
                      Navigator.of(context).pop();
                      widget.onExtinguishingSettingChanged(label, selectedValue);
                    },
                  );
                })
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF696969),
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
            'Upload to Panel',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
          content: Text(
            'Are you sure you want to upload this configuration to the panel?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF696969),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF696969),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle successful upload
                _showSuccessDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEC1D24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upload',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
              Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Upload Successful',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                ),
              ),
            ],
          ),
          content: Text(
            'Configuration has been successfully uploaded to the panel.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF696969),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEC1D24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double stripeSpacing = 12;
    
    for (double i = -size.height; i < size.width + size.height; i += stripeSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 