import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_circle_back_button.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SiteAppBar extends StatelessWidget {
  const SiteAppBar({super.key, required this.controller});

  final SiteController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SiteCircleBackButton(onTap: controller.popBack),
          const SizedBox(width: 12),
          Text(
            StringConstants.siteInformation,
            style: StyleConstants.black20w700Style,
          ),
        ],
      ),
    );
  }
}
