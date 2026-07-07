import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/site_creation_form.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/simple_site_creation_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SimpleSiteCreationAppBar extends StatelessWidget {
  const SimpleSiteCreationAppBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: SvgPicture.asset(AssetConstants.arrowBackIcon),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Text(
            StringConstants.createSite,
            style: StyleConstants.textBodyDark20w700Style,
          ),
        ),
      ],
    );
  }
}

class SimpleSiteCreationActions extends StatelessWidget {
  const SimpleSiteCreationActions({super.key, required this.controller});

  final SimpleSiteCreationController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: controller.isLoading ? null : controller.cancel,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color:
                    controller.isLoading
                        ? ColorConstants.buttonSecondaryBackground.withValues(
                          alpha: 0.5,
                        )
                        : ColorConstants.buttonSecondaryBackground,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  StringConstants.cancel,
                  style: StyleConstants.labelText14w700Style.copyWith(
                    color:
                        controller.isLoading
                            ? ColorConstants.labelText.withValues(alpha: 0.5)
                            : ColorConstants.labelText,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: controller.isLoading ? null : controller.submit,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color:
                    controller.isLoading
                        ? ColorConstants.primary.withValues(alpha: 0.5)
                        : ColorConstants.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child:
                    controller.isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ColorConstants.white,
                            ),
                          ),
                        )
                        : Text(
                          StringConstants.createSite,
                          style: StyleConstants.white14w700Style,
                        ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SimpleSiteCreationContent extends StatelessWidget {
  const SimpleSiteCreationContent({super.key, required this.controller});

  final SimpleSiteCreationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: SiteCreationForm(model: controller.siteCreationPageModel),
            ),
            const SizedBox(height: 20),
            SimpleSiteCreationActions(controller: controller),
          ],
        ),
      ),
    );
  }
}
