import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
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
    for (String lbus in [StringConstants.lBUS1, StringConstants.lBUS2]) {
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
                StringConstants.lBusDevices,
                style: StyleConstants.textBodyDark18w600Style,
              ),
              Spacer(),
              SvgPicture.asset(
                AssetConstants.addCircleIcon,
                width: 24,
                height: 24,
              ),
              SizedBox(width: 25),
              SvgPicture.asset(
                AssetConstants.editIcon,
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
                _buildLBusSection(StringConstants.lBUS1),
                SizedBox(height: 10),
                _buildLBusSection(StringConstants.lBUS2),
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
            decoration: BoxDecoration(color: ColorConstants.backgroundGray),
            child: Row(
              children: [
                Text(
                  lbusName,
                  style: StyleConstants.textBodyDark14w600Style,
                ),
                Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: ColorConstants.textSecondary,
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
                  StringConstants.inputModeConfiguration,
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
                      hintText: StringConstants.enterInputText,
                      hintStyle: StyleConstants.divider13w400Style,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  StringConstants.inputText,
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
                    controller: _inputTextControllers[lbusName],
                    onChanged: (value) {
                      widget.onLBusFieldChanged(lbusName, StringConstants.inputtext, value);
                    },
                    onTapOutside: (value) {
                      FocusScope.of(context).unfocus();
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                      hintText: StringConstants.enterInputText,
                      hintStyle: StyleConstants.divider13w400Style,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                _buildDropdownField(
                  lbusName,
                  StringConstants.product,
                  widget.lbusProducts[lbusName] ?? StringConstants.onyx202,
                  [StringConstants.onyx202, StringConstants.onyx204, StringConstants.onyx205, StringConstants.onyx206],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  'Group',
                  widget.lbusGroups[lbusName] ?? StringConstants.groupA,
                  [StringConstants.groupA, StringConstants.groupB, StringConstants.groupC, StringConstants.groupD],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  'Function',
                  widget.lbusFunctions[lbusName] ?? StringConstants.functionA,
                  [StringConstants.functionA, StringConstants.functionB, StringConstants.functionC, StringConstants.functionD],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  StringConstants.enabled,
                  widget.lbusEnabled[lbusName] ?? StringConstants.yes,
                  [StringConstants.yes, StringConstants.no],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  StringConstants.test,
                  widget.lbusTests[lbusName] ?? StringConstants.no,
                  [StringConstants.no, StringConstants.yes],
                ),
                SizedBox(height: 20),
                _buildDropdownField(
                  lbusName,
                  StringConstants.inverted,
                  widget.lbusInverted[lbusName] ?? StringConstants.no,
                  [StringConstants.no, StringConstants.yes],
                ),
              ],
            ),
          ),
          Divider(color: ColorConstants.divider, thickness: 1),
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
          style: StyleConstants.textSecondary13w600Style,
        ),
        Spacer(),
        GestureDetector(
          onTap: () => _showDropdownDialog(lbusName, label, value, options),
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
