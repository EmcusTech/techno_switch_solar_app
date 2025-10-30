import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF696969),
          ),
        ),
        Spacer(),
        GestureDetector(
          onTap: () => _showDropdownDialog(context),
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
