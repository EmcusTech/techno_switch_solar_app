import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SounderSettingsPage extends StatefulWidget {
  final String fireSoundTone;
  final String fireSounderDelay;
  final String countDownAction;
  final String holdAction;
  final String releaseAction;
  final String extSounderDelay;
  final Function(String, String) onSounderSettingChanged;

  const SounderSettingsPage({
    super.key,
    required this.fireSoundTone,
    required this.fireSounderDelay,
    required this.countDownAction,
    required this.holdAction,
    required this.releaseAction,
    required this.extSounderDelay,
    required this.onSounderSettingChanged,
  });

  @override
  State<SounderSettingsPage> createState() => _SounderSettingsPageState();
}

class _SounderSettingsPageState extends State<SounderSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Sounder Settings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3A3A3A),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Icon(
                  Icons.close,
                  color: Color(0xFF696969),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sounder Tone Section
                Text(
                  'Sounder Tone',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Fire Sound',
                  widget.fireSoundTone,
                  [
                    'Pulsing 1s ON, 4s OFF',
                    'Pulsing 2s ON, 2s OFF',
                    'Continuous',
                    'Warble',
                  ],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Sounder Delay',
                  widget.fireSounderDelay,
                  [
                    '300 Sec',
                    '600 Sec',
                    '900 Sec',
                    '1200 Sec',
                  ],
                ),
                SizedBox(height: 32),
                
                // Ext Sound Section
                Text(
                  'Ext Sound 1/Ext Sound 2/Man Release Sound',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Count Down Action',
                  widget.countDownAction,
                  [
                    'Pulsing 1s ON, 4s OFF',
                    'Pulsing 2s ON, 2s OFF',
                    'Continuous',
                    'Warble',
                  ],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Hold Action',
                  widget.holdAction,
                  [
                    'Pulsing 1s ON, 4s OFF',
                    'Pulsing 2s ON, 2s OFF',
                    'Continuous',
                    'Warble',
                  ],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Release Action',
                  widget.releaseAction,
                  [
                    'Pulsing 1s ON, 4s OFF',
                    'Pulsing 2s ON, 2s OFF',
                    'Continuous',
                    'Warble',
                  ],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Sounder Delay',
                  widget.extSounderDelay,
                  [
                    '300 Sec',
                    '600 Sec',
                    '900 Sec',
                    '1200 Sec',
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF696969),
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () => _showDropdownDialog(label, value, options),
              child: Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF3D3D3D),
                    ),
                  ),
                  SizedBox(width: 2),
                  SvgPicture.asset('assets/svgs/drop_down_red_icon.svg'),
                ],
              ),
            ),
          ],
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
                      widget.onSounderSettingChanged(label, selectedValue);
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
} 