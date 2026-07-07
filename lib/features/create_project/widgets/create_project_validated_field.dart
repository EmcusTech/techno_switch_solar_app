import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class CreateProjectFormLabel extends StatelessWidget {
  const CreateProjectFormLabel({
    super.key,
    required this.label,
    this.validationKey,
    this.validationErrors,
    this.isRequired = false,
  });

  final String label;
  final String? validationKey;
  final Map<String, String>? validationErrors;
  final bool isRequired;

  bool get _hasError =>
      validationKey != null &&
      validationErrors?.containsKey(validationKey) == true;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: StyleConstants.primary13w600Style.copyWith(
              color:
                  _hasError
                      ? ColorConstants.primary
                      : ColorConstants.textSecondary,
            ),
          ),
          if (isRequired)
            TextSpan(
              text: StringConstants.strb411bc68,
              style: StyleConstants.primary13w600Style,
            ),
        ],
      ),
    );
  }
}

class CreateProjectValidationError extends StatelessWidget {
  const CreateProjectValidationError({
    super.key,
    required this.validationKey,
    this.validationErrors,
  });

  final String validationKey;
  final Map<String, String>? validationErrors;

  @override
  Widget build(BuildContext context) {
    final hasError = validationErrors?.containsKey(validationKey) == true;
    final message = validationErrors?[validationKey];
    if (!hasError || message == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(message, style: StyleConstants.primary12w500Style),
    );
  }
}

class CreateProjectValidatedField extends StatelessWidget {
  const CreateProjectValidatedField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.validationKey,
    this.validationErrors,
    this.isRequired = false,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final String? validationKey;
  final Map<String, String>? validationErrors;
  final bool isRequired;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  bool get _hasError =>
      validationKey != null &&
      validationErrors?.containsKey(validationKey) == true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreateProjectFormLabel(
          label: label,
          validationKey: validationKey,
          validationErrors: validationErrors,
          isRequired: isRequired,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color:
                  _hasError ? ColorConstants.primary : ColorConstants.borderGray,
              width: _hasError ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            onTapOutside: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: StyleConstants.divider13w400Style,
            ),
          ),
        ),
        if (validationKey != null)
          CreateProjectValidationError(
            validationKey: validationKey!,
            validationErrors: validationErrors,
          ),
      ],
    );
  }
}
