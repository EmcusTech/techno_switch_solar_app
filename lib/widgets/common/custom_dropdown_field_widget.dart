import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
/// Reusable dropdown field widget with consistent styling
class CustomDropdownFieldWidget extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final Function(String) onChanged;

  const CustomDropdownFieldWidget({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: StyleConstants.textSecondary13w600Style,
        ),
        Spacer(),
        GestureDetector(
          onTap: () => _showDropdownDialog(context),
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

  void _showDropdownDialog(BuildContext context) {
    String selectedValue = value;

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
