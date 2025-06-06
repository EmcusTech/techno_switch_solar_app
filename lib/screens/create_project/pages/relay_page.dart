import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class RelayPage extends StatefulWidget {
  final String relayText;
  final String test;
  final String relay;
  final String group;
  final String function;
  final Function(String, String) onRelaySettingChanged;

  const RelayPage({
    super.key,
    required this.relayText,
    required this.test,
    required this.relay,
    required this.group,
    required this.function,
    required this.onRelaySettingChanged,
  });

  @override
  State<RelayPage> createState() => _RelayPageState();
}

class _RelayPageState extends State<RelayPage> {
  late TextEditingController _relayTextController;

  @override
  void initState() {
    super.initState();
    _relayTextController = TextEditingController(text: widget.relayText);
  }

  @override
  void dispose() {
    _relayTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relay',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Relay Text Section
                Text(
                  'Relay Text',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF696969),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: _relayTextController,
                    onChanged: (value) {
                      widget.onRelaySettingChanged('Relay Text', value);
                    },
                    onTapOutside: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: 'Enter relay text',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Relay Configuration Fields
                _buildDropdownField(
                  'Test',
                  widget.test,
                  ['No', 'Yes'],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Relay',
                  widget.relay,
                  ['Enable', 'Disable'],
                ),
                SizedBox(height: 32),

                // Programming Group Section
                Text(
                  'Programming Group',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Group',
                  widget.group,
                  [
                    'Group A',
                    'Group B',
                    'Group C',
                    'Group D',
                  ],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  'Function',
                  widget.function,
                  [
                    'Function 1A',
                    'Function 1B',
                    'Function 2A',
                    'Function 2B',
                    'Function 3A',
                    'Function 3B',
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
                      widget.onRelaySettingChanged(label, selectedValue);
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