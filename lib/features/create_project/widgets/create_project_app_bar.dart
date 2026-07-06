import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class CreateProjectAppBar extends StatelessWidget {
  const CreateProjectAppBar({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final CreateProjectController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ColorConstants.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: ColorConstants.textDark,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          StringConstants.createSite,
          style: StyleConstants.textBodyDark20w700Style,
        ),
        const Spacer(),
        Text(StringConstants.step, style: StyleConstants.black16w500Style),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 7,
              right: 6,
              top: 2,
              bottom: 3,
            ),
            child: Text(
              '${controller.currentStep}/${CreateProjectController.totalSteps}',
              style: StyleConstants.white14w700Style,
            ),
          ),
        ),
      ],
    );
  }
}
