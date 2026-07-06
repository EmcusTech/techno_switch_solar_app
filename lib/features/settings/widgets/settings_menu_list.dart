import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/features/settings/widgets/settings_menu_tile.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class SettingsMenuList extends StatelessWidget {
  const SettingsMenuList({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in SettingsController.menuItems) ...[
          Divider(
            color: ColorConstants.blackMaterial.withValues(alpha: 0.18),
            thickness: 1,
          ),
          SettingsMenuTile(
            title: item.title,
            onTap: () => controller.onMenuItemTap(item.action),
          ),
        ],
        Divider(
          color: ColorConstants.blackMaterial.withValues(alpha: 0.18),
          thickness: 1,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
