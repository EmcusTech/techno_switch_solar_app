import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/widgets/custom_slider_thumb_widget.dart';
import 'package:techno_switch_solar_app/widgets/custom_vertical_tick_mark_shape_widget.dart';

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
            'General Settings',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A3A3A),
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
                  '300 Seconds',
                  '500 Seconds',
                  '1000 Seconds',
                ]),
                SizedBox(height: 24),
                _buildDropdownField('Fault Latching', widget.faultLatching, [
                  'Yes',
                  'No',
                ]),
                SizedBox(height: 24),
                _buildDropdownField('Panel Date & Time', widget.panelDateTime, [
                  '13/05/2025 - 10:31:02',
                  '14/05/2025 - 11:32:03',
                ]),
                SizedBox(height: 24),
                _buildDropdownField('Service Due', widget.serviceDue, [
                  '13/09/2025',
                  '14/09/2025',
                  '15/09/2025',
                ]),
                SizedBox(height: 24),
                _buildDropdownField(
                  'Service Due Reminder',
                  widget.serviceDueReminder,
                  ['13/09/2025', '14/09/2025', '15/09/2025'],
                ),
                SizedBox(height: 24),
                _buildDropdownField('Event Reminder', widget.eventReminder, [
                  '13/09/2025',
                  '14/09/2025',
                  '15/09/2025',
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
    bool isSliderField = value.contains('Seconds');
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
                    color: Color(0xFF696969),
                  ),
                ),
                Spacer(),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF918F8F),
                  ),
                ),
                SizedBox(width: 2),
                SvgPicture.asset('assets/svgs/drop_down_red_icon.svg'),
              ],
            ),
          ),
        ),
        if (isSliderField && isExpanded) ...[
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                          'Timer Settings',
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
                            color: Color(0xFF3A3A3A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Color(0xFF007AFF),
                      inactiveTrackColor: Color(0xFFE5E5E7),
                      thumbColor: Color(0xFF007AFF),
                      overlayColor: Color(0xFF007AFF).withValues(alpha: 0.2),
                      thumbShape: CustomSliderThumbShape(
                        enabledThumbRadius: 7.5,
                      ),
                      trackHeight: 1,
                      tickMarkShape: CustomVerticalTickMarkShape(),
                      activeTickMarkColor: Color(0xFFE5E5E7),
                      inactiveTickMarkColor: Color(0xFFE5E5E7),
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
      case 'Timer Settings':
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
