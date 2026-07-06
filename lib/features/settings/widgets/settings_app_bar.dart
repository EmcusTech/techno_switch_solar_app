import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SettingsAppBar extends StatelessWidget {
  const SettingsAppBar({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      child: Row(
        children: [
          if (!controller.embedded)
            GestureDetector(
              onTap: controller.handleBackNavigation,
              child: SvgPicture.asset(AssetConstants.arrowBackIcon),
            ),
          if (!controller.embedded) const SizedBox(width: 8),
          Text(
            StringConstants.projectSettings,
            style: StyleConstants.black20w700Style,
          ),
        ],
      ),
    );
  }
}
