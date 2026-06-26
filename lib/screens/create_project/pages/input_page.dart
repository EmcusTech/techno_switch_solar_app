import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

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
            StringConstants.inputModeConfiguration,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textBodyDark,
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
                        StringConstants.inputText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: ColorConstants.borderGray),
                        ),
                        child: TextField(
                          controller: _inputTextController,
                          onChanged: (value) {
                            widget.onInputSettingChanged(StringConstants.inputText, value);
                          },
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: StringConstants.enterInputText,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: ColorConstants.divider,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      _buildDropdownField(StringConstants.inverted, widget.inverted, [
                        StringConstants.no,
                        StringConstants.yes,
                      ]),
                      SizedBox(height: 20),
                      _buildDropdownField(StringConstants.test, widget.test, [StringConstants.no, StringConstants.yes]),
                      SizedBox(height: 20),
                      _buildDropdownField('Input 1', widget.input1, [
                        StringConstants.enable,
                        StringConstants.disable,
                      ]),
                    ],
                  ),
                ),
                Divider(color: ColorConstants.divider, thickness: 1),
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
                        StringConstants.programmingGroup,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textBodyDark,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildDropdownField('Group', widget.group, [
                        StringConstants.groupA,
                        StringConstants.groupB,
                        StringConstants.groupC,
                        StringConstants.groupD,
                      ]),
                      SizedBox(height: 20),
                      _buildDropdownField('Function', widget.function, [
                        'Function 1A',
                        StringConstants.function1B,
                        StringConstants.function2A,
                        StringConstants.function2B,
                        StringConstants.function3A,
                        StringConstants.function3B,
                      ]),
                    ],
                  ),
                ),
                Divider(color: ColorConstants.divider, thickness: 1),
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
                color: ColorConstants.textSecondary,
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
                      color: ColorConstants.textDark,
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
}
