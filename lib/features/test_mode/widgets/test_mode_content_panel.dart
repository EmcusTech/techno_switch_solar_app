import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_controller.dart';
import 'package:techno_switch_solar_app/features/test_mode/widgets/test_mode_menu_option.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class TestModeContentPanel extends StatelessWidget {
  const TestModeContentPanel({super.key, required this.controller});

  final TestModeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.white,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(AssetConstants.background2),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 24),
            child: Column(
              children: [
                Text(
                  StringConstants.testMode,
                  style: StyleConstants.textMuted20w600Style,
                ),
                Text(
                  StringConstants.configuration,
                  style: StyleConstants.textBodyDark32w700Style,
                ),
                const SizedBox(height: 32),
                for (final item in TestModeController.menuItems) ...[
                  TestModeMenuOption(
                    item: item,
                    onTap: () => controller.onMenuItemTap(item.action),
                  ),
                  if (item != TestModeController.menuItems.last)
                    const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
