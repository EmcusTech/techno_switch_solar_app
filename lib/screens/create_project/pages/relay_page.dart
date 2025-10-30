import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
                // Dynamically build relay sections based on available relays
                ...widget.relayTexts.keys.map((relayName) {
                  return Column(
                    children: [
                      _buildRelaySection(relayName),
                      if (relayName !=
                          widget
                              .relayTexts
                              .keys
                              .last) // Don't add spacing after last relay
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
        decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
        child: Column(
          children: [
            // Relay header
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

            // Expanded content
            if (isExpanded) ...[
              Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Relay Text
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
                              'relayText',
                              value,
                            );
                          },
                          onTapOutside: (value) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Enter Relay Text',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Test
                      _buildRelayDropdownField(
                        'Test',
                        widget.relayTests[relayName]!,
                        ['No', 'Yes'],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            'relayTest',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),

                      // Relay State
                      _buildRelayDropdownField(
                        'Relay',
                        widget.relayStates[relayName]!,
                        ['Enable', 'Disable'],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            'relayState',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 24),

                      // Programming Group Section Header
                      Text(
                        'Programming Group',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3A3A3A),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Group
                      _buildRelayDropdownField(
                        'Group',
                        widget.relayGroups[relayName]!,
                        ['Group A', 'Group B', 'Group C', 'Group D'],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            'relayGroup',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),

                      // Function
                      _buildRelayDropdownField(
                        'Function',
                        widget.relayFunctions[relayName]!,
                        [
                          'Function 1A',
                          'Function 1B',
                          'Function 2A',
                          'Function 2B',
                          'Function 3A',
                          'Function 3B',
                        ],
                        (value) {
                          widget.onRelayFieldChanged(
                            relayName,
                            'relayFunction',
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
            color: Color(0xFF696969),
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
                  color: Color(0xFF3D3D3D),
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
