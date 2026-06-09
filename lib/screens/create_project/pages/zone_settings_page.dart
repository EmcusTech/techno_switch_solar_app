import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class ZoneSettingsPage extends StatefulWidget {
  final String? expandedZone;
  final Map<String, String> zoneTexts;
  final Map<String, String> zoneTypes;
  final Map<String, String> zoneStates;
  final Map<String, String> zoneTests;
  final Map<String, String> zoneModes;
  final Map<String, String> zoneVerificationTimes;
  final Function(String?) onZoneExpanded;
  final Function(String, String, String) onZoneFieldChanged;

  const ZoneSettingsPage({
    super.key,
    required this.expandedZone,
    required this.zoneTexts,
    required this.zoneTypes,
    required this.zoneStates,
    required this.zoneTests,
    required this.zoneModes,
    required this.zoneVerificationTimes,
    required this.onZoneExpanded,
    required this.onZoneFieldChanged,
  });

  @override
  State<ZoneSettingsPage> createState() => _ZoneSettingsPageState();
}

class _ZoneSettingsPageState extends State<ZoneSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Text(
            'Zone Settings',
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
                ...widget.zoneTexts.keys.map((zoneName) {
                  return Column(
                    children: [
                      _buildZoneSection(zoneName),
                      if (zoneName != widget.zoneTexts.keys.last)
                        SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneSection(String zoneName) {
    bool isExpanded = widget.expandedZone == zoneName;

    return GestureDetector(
      onTap: () {
        widget.onZoneExpanded(isExpanded ? null : zoneName);
      },
      child: Container(
        decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 19,
                right: 17,
                top: 12,
                bottom: 12,
              ),
              child: Row(
                children: [
                  Text(
                    zoneName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                  Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Color(0xFF696969),
                    size: 20,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zone Text',
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
                          controller: TextEditingController(
                              text: widget.zoneTexts[zoneName] ?? '',
                            )
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset: widget.zoneTexts[zoneName]?.length ?? 0,
                              ),
                            ),
                          onChanged: (value) {
                            widget.onZoneFieldChanged(
                              zoneName,
                              'zoneText',
                              value,
                            );
                          },
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Enter Zone Text',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        'Zone Type',
                        widget.zoneTypes[zoneName]!,
                        ['Double Knock', 'Single Knock', 'Manual'],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            'zoneType',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        'Zone',
                        widget.zoneStates[zoneName]!,
                        ['Enable', 'Disable'],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            'zoneState',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        'Zone Test',
                        widget.zoneTests[zoneName]!,
                        ['Yes', 'No'],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            'zoneTest',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        'Zone Mode',
                        widget.zoneModes[zoneName]!,
                        ['Yes', 'No'],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            'zoneMode',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        'Zone Verification Time',
                        widget.zoneVerificationTimes[zoneName]!,
                        ['300 Sec', '500 Sec', '1000 Sec'],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            'zoneVerificationTime',
                            value,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoneDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Row(
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
          onTap:
              () => _showZoneDropdownDialog(label, value, options, onChanged),
          child: Row(
            children: [
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
      ],
    );
  }

  void _showZoneDropdownDialog(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
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
                      onChanged(selectedValue);
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
