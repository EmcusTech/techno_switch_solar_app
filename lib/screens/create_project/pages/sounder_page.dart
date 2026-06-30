import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
class SounderPage extends StatefulWidget {
  final String? expandedSounder;
  final Map<String, String> sounderTexts;
  final Map<String, String> sounderStates;
  final Map<String, String> sounderTests;
  final Map<String, String> sounderTypes;
  final Map<String, String> sounderGroups;
  final Map<String, String> sounderFunctions;
  final Function(String?) onSounderExpanded;
  final Function(String, String, String) onSounderFieldChanged;
  final List<String>? availableZones;

  const SounderPage({
    super.key,
    required this.expandedSounder,
    required this.sounderTexts,
    required this.sounderStates,
    required this.sounderTests,
    required this.sounderTypes,
    required this.sounderGroups,
    required this.sounderFunctions,
    required this.onSounderExpanded,
    required this.onSounderFieldChanged,
    this.availableZones,
  });

  @override
  State<SounderPage> createState() => _SounderPageState();
}

class _SounderPageState extends State<SounderPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 19, right: 27),
          child: Row(
            children: [
              Text(
                'Sounder',
                style: StyleConstants.textBodyDark18w600Style,
              ),
              Spacer(),
              SvgPicture.asset(AssetConstants.settingsIcon),
            ],
          ),
        ),
        SizedBox(height: 23),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...widget.sounderTexts.keys.map((sounderName) {
                  return Column(
                    children: [
                      _buildSounderSection(sounderName),
                      if (sounderName != widget.sounderTexts.keys.last)
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

  Widget _buildSounderSection(String sounderName) {
    bool isExpanded = widget.expandedSounder == sounderName;

    return GestureDetector(
      onTap: () {
        widget.onSounderExpanded(isExpanded ? null : sounderName);
      },
      child: Container(
        decoration: BoxDecoration(color: ColorConstants.backgroundGray),
        child: Column(
          children: [
            // Sounder header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    sounderName,
                    style: StyleConstants.textBodyDark14w600Style,
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

            // Expanded content
            if (isExpanded) ...[
              Container(
                color: ColorConstants.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StringConstants.sounderText,
                        style: StyleConstants.textSecondary13w600Style,
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
                              text: widget.sounderTexts[sounderName] ?? '',
                            )
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset:
                                    widget.sounderTexts[sounderName]?.length ??
                                    0,
                              ),
                            ),
                          onChanged: (value) {
                            widget.onSounderFieldChanged(
                              sounderName,
                              StringConstants.soundertext,
                              value,
                            );
                          },
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: StringConstants.enterSounderText,
                            hintStyle: StyleConstants.divider13w400Style,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildSounderDropdownField(
                        'Sounder',
                        widget.sounderStates[sounderName]!,
                        [StringConstants.enable, StringConstants.disable],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            StringConstants.sounderstate,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildSounderDropdownField(
                        StringConstants.sounderTest,
                        widget.sounderTests[sounderName]!,
                        [StringConstants.yes, StringConstants.no],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            StringConstants.soundertest,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildSounderDropdownField(
                        StringConstants.sounderType,
                        widget.sounderTypes[sounderName]!,
                        [StringConstants.horn, StringConstants.bell, StringConstants.siren, StringConstants.chime],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            StringConstants.soundertype,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildSounderDropdownField(
                        StringConstants.sounderGroup,
                        widget.sounderGroups[sounderName]!,
                        widget.availableZones ?? ['Zone 1'],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            StringConstants.soundergroup,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildSounderDropdownField(
                        StringConstants.sounderFunction,
                        widget.sounderFunctions[sounderName]!,
                        [StringConstants.p1, StringConstants.p2, StringConstants.p3, StringConstants.p4],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            StringConstants.sounderfunction,
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

  Widget _buildSounderDropdownField(
    String label,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        Text(
          label,
          style: StyleConstants.textSecondary13w600Style,
        ),
        Spacer(),
        GestureDetector(
          onTap:
              () =>
                  _showSounderDropdownDialog(label, value, options, onChanged),
          child: Row(
            children: [
              Text(
                value,
                style: StyleConstants.textDark13w400Style,
              ),
              SizedBox(width: 2),
              SvgPicture.asset(AssetConstants.dropDownRedIcon),
            ],
          ),
        ),
      ],
    );
  }

  void _showSounderDropdownDialog(
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
            style: StyleConstants.textBodyDark18w600Style,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                options.map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      option,
                      style: StyleConstants.textDark14w400Style,
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
                style: StyleConstants.textSecondary14w600Style,
              ),
            ),
          ],
        );
      },
    );
  }
}
