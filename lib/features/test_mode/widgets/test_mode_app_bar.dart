import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/features/test_mode/controllers/test_mode_controller.dart';
import 'package:Technoswitch/utils/constants/asset_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class TestModeAppBar extends StatelessWidget {
  const TestModeAppBar({super.key, required this.controller});

  final TestModeController controller;

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
            StringConstants.testMode,
            style: StyleConstants.black20w700Style,
          ),
        ],
      ),
    );
  }
}
