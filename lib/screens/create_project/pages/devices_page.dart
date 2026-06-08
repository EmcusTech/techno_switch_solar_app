import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LBusDevicesPage extends StatefulWidget {
  final String? expandedLBus;
  final Map<String, String> lbusInputs;
  final Map<String, String> lbusInputTexts;
  final Map<String, String> lbusProducts;
  final Map<String, String> lbusGroups;
  final Map<String, String> lbusFunctions;
  final Map<String, String> lbusEnabled;
  final Map<String, String> lbusTests;
  final Map<String, String> lbusInverted;
  final Function(String?) onLBusExpanded;
  final Function(String, String, String) onLBusFieldChanged;

  const LBusDevicesPage({
    super.key,
    required this.expandedLBus,
    required this.lbusInputs,
    required this.lbusInputTexts,
    required this.lbusProducts,
    required this.lbusGroups,
    required this.lbusFunctions,
    required this.lbusEnabled,
    required this.lbusTests,
    required this.lbusInverted,
    required this.onLBusExpanded,
    required this.onLBusFieldChanged,
  });

  @override
  State<LBusDevicesPage> createState() => _LBusDevicesPageState();
}

class _LBusDevicesPageState extends State<LBusDevicesPage> {
  final Map<String, TextEditingController> _inputControllers = {};
  final Map<String, TextEditingController> _inputTextControllers = {};

  @override
  void initState() {
    super.initState();
    for (String lbus in ['L-BUS 1', 'L-BUS 2']) {
      _inputControllers[lbus] = TextEditingController(
        text: widget.lbusInputs[lbus] ?? '',
      );
      _inputTextControllers[lbus] = TextEditingController(
        text: widget.lbusInputTexts[lbus] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _inputControllers.values) {
      controller.dispose();
    }
    for (var controller in _inputTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 19, right: 20),
          child: Row(
            children: [
              Text(
                'L-Bus Devices',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              Spacer(),
              SvgPicture.asset(
                'assets/svgs/add_circle_icon.svg',
                width: 24,
                height: 24,
              ),
              SizedBox(width: 25),
              SvgPicture.asset(
                'assets/svgs/edit_icon.svg',
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),
        SizedBox(height: 27),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildLBusSection('L-BUS 1'),
                SizedBox(height: 10),
                _buildLBusSection('L-BUS 2'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLBusSection(String lbusName) {
    bool isExpanded = widget.expandedLBus == lbusName;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            widget.onLBusExpanded(isExpanded ? null : lbusName);
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
            child: Row(
              children: [
                Text(
                  lbusName,
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
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Input',
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
                    controller: _inputControllers[lbusName],
                    onChanged: (value) {
                      widget.onLBusFieldChanged(lbusName, 'input', value);
                    },
                    onTapOutside: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: 'Enter Input Text',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Input Text',
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
                    controller: _inputTextControllers[lbusName],
                    onChanged: (value) {
                      widget.onLBusFieldChanged(lbusName, 'inputText', value);
                    },
                    onTapOutside: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: 'Enter Input Text',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                _buildDropdownField(
                  lbusName,
                  'Product',
                  widget.lbusProducts[lbusName] ?? 'ONYX202',
                  ['ONYX202', 'ONYX204', 'ONYX205', 'ONYX206'],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  'Group',
                  widget.lbusGroups[lbusName] ?? 'Group A',
                  ['Group A', 'Group B', 'Group C', 'Group D'],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  'Function',
                  widget.lbusFunctions[lbusName] ?? 'Function A',
                  ['Function A', 'Function B', 'Function C', 'Function D'],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  'Enabled',
                  widget.lbusEnabled[lbusName] ?? 'Yes',
                  ['Yes', 'No'],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  'Test',
                  widget.lbusTests[lbusName] ?? 'No',
                  ['No', 'Yes'],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  'Inverted',
                  widget.lbusInverted[lbusName] ?? 'No',
                  ['No', 'Yes'],
                ),
              ],
            ),
          ),
          Divider(color: Color(0xFFBDBDBD), thickness: 1),
        ],
      ],
    );
  }

  Widget _buildDropdownField(
    String lbusName,
    String label,
    String value,
    List<String> options,
  ) {
    return Row(
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
        GestureDetector(
          onTap: () => _showDropdownDialog(lbusName, label, value, options),
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

  void _showDropdownDialog(
    String lbusName,
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
                      String fieldType = label.toLowerCase().replaceAll(
                        ' ',
                        '',
                      );
                      widget.onLBusFieldChanged(
                        lbusName,
                        fieldType,
                        selectedValue,
                      );
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
