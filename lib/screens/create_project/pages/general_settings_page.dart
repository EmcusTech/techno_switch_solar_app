import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/widgets/custom_slider_thumb_widget.dart';
import 'package:techno_switch_solar_app/widgets/custom_vertical_tick_mark_shape_widget.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

class GeneralSettingsPage extends StatefulWidget {
  final String levelTimeout;
  final double timerSettings;
  final String faultLatching;
  final String panelDateTime;
  final String serviceDue;
  final String serviceDueReminder;
  final String eventReminder;
  final String? expandedField;
  final Function(String, String) onFieldChanged;
  final Function(String, double) onSliderChanged;
  final Function(String?) onExpandedChanged;

  const GeneralSettingsPage({
    super.key,
    required this.levelTimeout,
    required this.timerSettings,
    required this.faultLatching,
    required this.panelDateTime,
    required this.serviceDue,
    required this.serviceDueReminder,
    required this.eventReminder,
    required this.expandedField,
    required this.onFieldChanged,
    required this.onSliderChanged,
    required this.onExpandedChanged,
  });

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Text(
            StringConstants.generalSettings,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textBodyDark,
            ),
          ),
        ),
        SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownField('Level Timeout', widget.levelTimeout, [
                  StringConstants.s300Seconds,
                  StringConstants.s500Seconds,
                  StringConstants.s1000Seconds,
                ]),
                SizedBox(height: 24),
                _buildDropdownField(StringConstants.faultLatching, widget.faultLatching, [
                  StringConstants.yes,
                  StringConstants.no,
                ]),
                SizedBox(height: 24),
                _buildDropdownField('Panel Date & Time', widget.panelDateTime, [
                  StringConstants.s13052025103102,
                  StringConstants.s14052025113203,
                ]),
                SizedBox(height: 24),
                _buildDropdownField('Service Due', widget.serviceDue, [
                  StringConstants.s13092025,
                  StringConstants.s14092025,
                  StringConstants.s15092025,
                ]),
                SizedBox(height: 24),
                _buildDropdownField(
                  StringConstants.serviceDueReminder,
                  widget.serviceDueReminder,
                  [StringConstants.s13092025, StringConstants.s14092025, StringConstants.s15092025],
                ),
                SizedBox(height: 24),
                _buildDropdownField(StringConstants.eventReminder, widget.eventReminder, [
                  StringConstants.s13092025,
                  StringConstants.s14092025,
                  StringConstants.s15092025,
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options) {
    bool isSliderField = value.contains(StringConstants.seconds);
    bool isExpanded = widget.expandedField == label;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (isSliderField) {
              widget.onExpandedChanged(isExpanded ? null : label);
            } else {
              _showDropdownDialog(label, value, options);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Row(
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
        ),
        if (isSliderField && isExpanded) ...[
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 13, bottom: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          StringConstants.timerSettings,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.textBodyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: ColorConstants.linkBlue,
                      inactiveTrackColor: ColorConstants.surfaceBorder,
                      thumbColor: ColorConstants.linkBlue,
                      overlayColor: ColorConstants.linkBlue.withValues(alpha: 0.2),
                      thumbShape: CustomSliderThumbShape(
                        enabledThumbRadius: 7.5,
                      ),
                      trackHeight: 1,
                      tickMarkShape: CustomVerticalTickMarkShape(),
                      activeTickMarkColor: ColorConstants.surfaceBorder,
                      inactiveTickMarkColor: ColorConstants.surfaceBorder,
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 25),
                    ),
                    child: Slider(
                      value: _getSliderValue(label),
                      min: 0,
                      max: 300,
                      divisions: 6,
                      onChanged: (double newValue) {
                        widget.onSliderChanged(label, newValue);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  double _getSliderValue(String label) {
    switch (label) {
      case 'Level Timeout':
        return double.parse(widget.levelTimeout.replaceAll(' Seconds', ''));
      case StringConstants.timerSettings:
        return widget.timerSettings;
      default:
        return 300;
    }
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
                      widget.onFieldChanged(label, selectedValue);
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
