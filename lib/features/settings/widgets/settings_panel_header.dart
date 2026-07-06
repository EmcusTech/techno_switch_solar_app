import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SettingsPanelHeader extends StatelessWidget {
  const SettingsPanelHeader({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(AssetConstants.panelIcon, height: 62, width: 62),
        const SizedBox(width: 14),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.displayPrefix,
              style: StyleConstants.black16w700Style,
            ),
            Text(
              controller.displayId,
              style: StyleConstants.textDisabled14w500Style,
            ),
            ValueListenableBuilder(
              valueListenable: controller.bleManager.isConnectedNotifier,
              builder: (context, isConnected, child) {
                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: StringConstants.status4,
                        style: StyleConstants.textDisabled14w500Style,
                      ),
                      TextSpan(
                        text:
                            isConnected
                                ? StringConstants.connected
                                : StringConstants.disconnected,
                        style: StyleConstants.primary14w500Style.copyWith(
                          color:
                              isConnected
                                  ? ColorConstants.success
                                  : ColorConstants.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
