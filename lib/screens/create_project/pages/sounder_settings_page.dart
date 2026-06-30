import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

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
        Padding(
          padding: const EdgeInsets.only(left: 19, right: 22),
          child: Row(
            children: [
              Text(
                StringConstants.sounderSettings,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textBodyDark,
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
                  decoration: BoxDecoration(color: ColorConstants.transparent),
                  child: Icon(Icons.close, color: ColorConstants.textPrimaryMaterial, size: 20),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 29),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StringConstants.sounderTone,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textBodyDark,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildDropdownField('Fire Sound', widget.fireSoundTone, [
                        'Pulsing 1s ON, 4s OFF',
                        StringConstants.pulsing2sON2sOFF,
                        'Continuous',
                        StringConstants.warble,
                      ]),
                      SizedBox(height: 20),
                      _buildDropdownField(
                        StringConstants.sounderDelay,
                        widget.fireSounderDelay,
                        [StringConstants.s300Sec, StringConstants.s600Sec, StringConstants.s900Sec, StringConstants.s1200Sec],
                      ),
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
                        StringConstants.extSound1ExtSound2ManReleaseSound,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textBodyDark,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildDropdownField(
                        StringConstants.countDownAction,
                        widget.countDownAction,
                        [
                          'Pulsing 1s ON, 4s OFF',
                          StringConstants.pulsing2sON2sOFF,
                          'Continuous',
                          StringConstants.warble,
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildDropdownField('Hold Action', widget.holdAction, [
                        'Pulsing 1s ON, 4s OFF',
                        StringConstants.pulsing2sON2sOFF,
                        'Continuous',
                        StringConstants.warble,
                      ]),
                      SizedBox(height: 20),
                      _buildDropdownField(
                        StringConstants.releaseAction,
                        widget.releaseAction,
                        [
                          'Pulsing 1s ON, 4s OFF',
                          StringConstants.pulsing2sON2sOFF,
                          'Continuous',
                          StringConstants.warble,
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildDropdownField(
                        StringConstants.sounderDelay,
                        widget.extSounderDelay,
                        [StringConstants.s300Sec, StringConstants.s600Sec, StringConstants.s900Sec, StringConstants.s1200Sec],
                      ),
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
                      color: ColorConstants.textMuted,
                    ),
                  ),
                  SizedBox(width: 2),
                  SvgPicture.asset(AssetConstants.dropDownRedIcon),
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
                      widget.onSounderSettingChanged(label, selectedValue);
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
