import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class RelayPage extends StatefulWidget {
  final String? expandedRelay;
  final Map<String, String> relayTexts;
  final Map<String, String> relayTests;
  final Map<String, String> relayStates;
  final Map<String, String> relayGroups;
  final Map<String, String> relayFunctions;
  final Function(String?) onRelayExpanded;
  final Function(String, String, String) onRelayFieldChanged;

  const RelayPage({
    super.key,
    required this.expandedRelay,
    required this.relayTexts,
    required this.relayTests,
    required this.relayStates,
    required this.relayGroups,
    required this.relayFunctions,
    required this.onRelayExpanded,
    required this.onRelayFieldChanged,
  });

  @override
  State<RelayPage> createState() => _RelayPageState();
}

class _RelayPageState extends State<RelayPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Text(
            'Relay',
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
                ...widget.relayTexts.keys.map((relayName) {
                  return Column(
                    children: [
                      _buildRelaySection(relayName),
                      if (relayName != widget.relayTexts.keys.last)
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

  Widget _buildRelaySection(String relayName) {
    bool isExpanded = widget.expandedRelay == relayName;

    return GestureDetector(
      onTap: () {
        widget.onRelayExpanded(isExpanded ? null : relayName);
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
                    relayName,
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
                        StringConstants.relayText,
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
                              text: widget.relayTexts[relayName] ?? '',
                            )
                            ..selection = TextSelection.fromPosition(
                              TextPosition(
                                offset:
                                    widget.relayTexts[relayName]?.length ?? 0,
                              ),
                            ),
                          onChanged: (value) {
                            widget.onRelayFieldChanged(
                              relayName,
                              StringConstants.relaytext,
                              value,
                            );
                          },
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: StringConstants.enterRelayText,
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: ColorConstants.divider,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildRelayDropdownField(
                        StringConstants.test,
                        widget.relayTests[relayName]!,
                        [StringConstants.no, StringConstants.yes],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            StringConstants.relaytest,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildRelayDropdownField(
                        'Relay',
                        widget.relayStates[relayName]!,
                        [StringConstants.enable, StringConstants.disable],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            StringConstants.relaystate,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 24),
                      Text(
                        StringConstants.programmingGroup,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.textBodyDark,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildRelayDropdownField(
                        'Group',
                        widget.relayGroups[relayName]!,
                        [StringConstants.groupA, StringConstants.groupB, StringConstants.groupC, StringConstants.groupD],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            StringConstants.relaygroup,
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      _buildRelayDropdownField(
                        'Function',
                        widget.relayFunctions[relayName]!,
                        [
                          'Function 1A',
                          StringConstants.function1B,
                          StringConstants.function2A,
                          StringConstants.function2B,
                          StringConstants.function3A,
                          StringConstants.function3B,
                        ],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            StringConstants.relayfunction,
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

  Widget _buildRelayDropdownField(
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
              () => _showRelayDropdownDialog(label, value, options, onChanged),
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
    );
  }

  void _showRelayDropdownDialog(
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
