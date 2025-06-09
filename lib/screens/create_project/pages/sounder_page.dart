import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              Spacer(),
              SvgPicture.asset('assets/svgs/settings_icon.svg'),
            ],
          ),
        ),
        SizedBox(height: 23),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSounderSection('Sounder 1'),
                SizedBox(height: 16),
                _buildSounderSection('Sounder 2'),
                SizedBox(height: 16),
                _buildSounderSection('Sounder 3'),
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
        decoration: BoxDecoration(
          color: Color(0xFFF5F5F5),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Sounder header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    sounderName,
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
                      // Sounder Text
                      Text(
                        'Sounder Text',
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
                          onChanged: (value) {
                            widget.onSounderFieldChanged(
                              sounderName,
                              'sounderText',
                              value,
                            );
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Enter Sounder Text',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Sounder
                      _buildSounderDropdownField(
                        'Sounder',
                        widget.sounderStates[sounderName]!,
                        ['Enable', 'Disable'],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            'sounderState',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),

                      // Sounder Test
                      _buildSounderDropdownField(
                        'Sounder Test',
                        widget.sounderTests[sounderName]!,
                        ['Yes', 'No'],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            'sounderTest',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),

                      // Sounder Type
                      _buildSounderDropdownField(
                        'Sounder Type',
                        widget.sounderTypes[sounderName]!,
                        ['Horn', 'Bell', 'Siren', 'Chime'],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            'sounderType',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),

                      // Sounder Group
                      _buildSounderDropdownField(
                        'Sounder Group',
                        widget.sounderGroups[sounderName]!,
                        ['Zone 1', 'Zone 2', 'Zone 3', 'Zone 4'],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            'sounderGroup',
                            value,
                          );
                        },
                      ),
                      SizedBox(height: 20),

                      // Sounder Function
                      _buildSounderDropdownField(
                        'Sounder Function',
                        widget.sounderFunctions[sounderName]!,
                        ['P1', 'P2', 'P3', 'P4'],
                        (value) {
                          widget.onSounderFieldChanged(
                            sounderName,
                            'sounderFunction',
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
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF696969),
          ),
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
