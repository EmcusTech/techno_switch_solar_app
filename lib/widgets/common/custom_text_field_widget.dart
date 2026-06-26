import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

/// Reusable text field widget with consistent styling and validation support
class CustomTextFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? validationKey;
  final Map<String, String>? validationErrors;
  final int? maxLines;
  final void Function(String)? onChanged;

  const CustomTextFieldWidget({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.validationKey,
    this.validationErrors,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError =
        validationKey != null &&
        validationErrors?.containsKey(validationKey) == true;
    final String? errorMessage =
        (validationKey != null && validationErrors != null)
            ? validationErrors![validationKey]
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: hasError ? ColorConstants.primary : ColorConstants.textSecondary,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: hasError ? ColorConstants.primary : ColorConstants.borderGray,
              width: hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            onTapOutside: (value) {
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: ColorConstants.divider,
              ),
            ),
          ),
        ),
        if (hasError && errorMessage != null) ...[
          SizedBox(height: 4),
          Text(
            errorMessage,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ColorConstants.primary,
            ),
          ),
        ],
      ],
    );
  }
}
