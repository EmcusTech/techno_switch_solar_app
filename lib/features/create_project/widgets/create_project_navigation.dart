import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class CreateProjectNavigation extends StatelessWidget {
  const CreateProjectNavigation({super.key, required this.controller});

  final CreateProjectController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (controller.currentStep == 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: controller.skipPanelConnectAndContinue,
              child: Text(
                StringConstants.skipConnectionEnterPanelIDManually,
                style: StyleConstants.primary13w600Style,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Row(
          children: [
            Opacity(
              opacity: controller.currentStep == 1 ? 0.2 : 1.0,
              child: GestureDetector(
                onTap: controller.goToPreviousStep,
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorConstants.buttonSecondaryBackground,
                    borderRadius: BorderRadius.circular(28.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 34,
                      top: 18,
                      bottom: 18,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: ColorConstants.labelText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          StringConstants.back,
                          style: StyleConstants.labelText14w700Style,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: controller.goToNextStep,
              child: Container(
                decoration: BoxDecoration(
                  color: ColorConstants.primary,
                  borderRadius: BorderRadius.circular(28.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 28,
                    right: 23,
                    top: 18,
                    bottom: 18,
                  ),
                  child: Row(
                    children: [
                      Text(
                        controller.nextButtonLabel,
                        style: StyleConstants.white14w700Style,
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        color: ColorConstants.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
