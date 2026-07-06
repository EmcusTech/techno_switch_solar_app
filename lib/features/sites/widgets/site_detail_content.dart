import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_circle_back_button.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_detail_field.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteDetailAppBar extends StatelessWidget {
  const SiteDetailAppBar({super.key, required this.controller});

  final SiteDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          SiteCircleBackButton(onTap: controller.popBack),
          const SizedBox(width: 12),
          Text(
            StringConstants.siteDetails,
            style: StyleConstants.black20w700Style,
          ),
        ],
      ),
    );
  }
}

class SiteDetailContent extends StatelessWidget {
  const SiteDetailContent({super.key, required this.controller});

  final SiteDetailController controller;

  @override
  Widget build(BuildContext context) {
    final site = controller.siteWithLogCount.site;
    final fields = siteDetailFields(
      siteNameLabel: StringConstants.siteName,
      installerNameLabel: StringConstants.installerName,
      companyNameLabel: StringConstants.companyName,
      saqccRegNumberLabel: StringConstants.saqccRegistrationNumber,
      buildingNameLabel: StringConstants.buildingName,
      installerContactNumberLabel: StringConstants.installerContactNumber,
      installerEmailLabel: StringConstants.installerEmail,
      siteDescriptionLabel: StringConstants.siteDescription,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in fields)
                SiteDetailField(
                  label: field.label,
                  value: field.value(site),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
