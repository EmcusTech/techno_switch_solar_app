import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class InputPage extends StatefulWidget {
  final String inputText;
  final String inverted;
  final String test;
  final String input1;
  final String group;
  final String function;
  final Function(String, String) onInputSettingChanged;

  const InputPage({
    super.key,
    required this.inputText,
    required this.inverted,
    required this.test,
    required this.input1,
    required this.group,
    required this.function,
    required this.onInputSettingChanged,
  });

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  late TextEditingController _inputTextController;

  @override
  void initState() {
    super.initState();
    _inputTextController = TextEditingController(text: widget.inputText);
  }

  @override
  void dispose() {
    _inputTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 19),
          child: Text(
            'Input',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ),
        SizedBox(height: 29),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Text Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Input Text',
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
                          controller: _inputTextController,
                          onChanged: (value) {
                            widget.onInputSettingChanged('Input Text', value);
                          },
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Enter Input Text',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildDropdownField('Inverted', widget.inverted, [
                        'No',
                        'Yes',
                      ]),
                      SizedBox(height: 20),
                      _buildDropdownField('Test', widget.test, ['No', 'Yes']),
                      SizedBox(height: 20),
                      _buildDropdownField('Input 1', widget.input1, [
                        'Enable',
                        'Disable',
                      ]),
                    ],
                  ),
                ),
                Divider(color: Color(0xFFBDBDBD), thickness: 1),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Programming Group',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildDropdownField('Group', widget.group, [
                        'Group A',
                        'Group B',
                        'Group C',
                        'Group D',
                      ]),
                      SizedBox(height: 20),
                      _buildDropdownField('Function', widget.function, [
                        'Function 1A',
                        'Function 1B',
                        'Function 2A',
                        'Function 2B',
                        'Function 3A',
                        'Function 3B',
                      ]),
                    ],
                  ),
                ),
                Divider(color: Color(0xFFBDBDBD), thickness: 1),
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
            children:
                options.map((option) {
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
                      widget.onInputSettingChanged(label, selectedValue);
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
