import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

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
            StringConstants.zoneSettings,
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
        decoration: BoxDecoration(color: ColorConstants.backgroundGray),
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
                      color: ColorConstants.textBodyDark,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: ColorConstants.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (isExpanded) ...[
              Container(
                color: ColorConstants.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StringConstants.zoneText,
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
                              StringConstants.zonetext,
                              value,
                            );
                          },
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: StringConstants.enterZoneText,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: ColorConstants.divider,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        StringConstants.zoneType,
                        widget.zoneTypes[zoneName]!,
                        [StringConstants.doubleKnock, StringConstants.singleKnock, StringConstants.manual],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            StringConstants.zonetype,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        'Zone',
                        widget.zoneStates[zoneName]!,
                        [StringConstants.enable, StringConstants.disable],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            StringConstants.zonestate,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        StringConstants.zoneTest,
                        widget.zoneTests[zoneName]!,
                        [StringConstants.yes, StringConstants.no],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            StringConstants.zonetest,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        StringConstants.zoneMode,
                        widget.zoneModes[zoneName]!,
                        [StringConstants.yes, StringConstants.no],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            StringConstants.zonemode,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildZoneDropdownField(
                        StringConstants.zoneVerificationTime,
                        widget.zoneVerificationTimes[zoneName]!,
                        [StringConstants.s300Sec, StringConstants.s500Sec, StringConstants.s1000Sec],
                        (value) {
                          widget.onZoneFieldChanged(
                            zoneName,
                            StringConstants.zoneverificationtime,
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
            color: ColorConstants.textSecondary,
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
                  color: ColorConstants.textMuted,
                ),
              ),
              SizedBox(width: 2),
              SvgPicture.asset(AssetConstants.dropDownRedIcon),
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
