import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class DashboardPanelHeader extends StatelessWidget {
  const DashboardPanelHeader({super.key, required this.controller});

  final ProjectDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(AssetConstants.panelIcon, height: 62, width: 62),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BleNameUtils.getDisplayPrefixFromBleName(controller.panelName),
                style: StyleConstants.black16w700Style,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                BleNameUtils.getDisplayIdFromBleName(controller.panelName),
                style: StyleConstants.textDisabled14w500Style,
                overflow: TextOverflow.ellipsis,
              ),
              ValueListenableBuilder<bool>(
                valueListenable: controller.ble.isConnectedNotifier,
                builder: (context, isConnected, child) {
                  if (isConnected) {
                    return Text(
                      StringConstants.connected,
                      style: StyleConstants.success14w500Style,
                    );
                  }
                  return Text(
                    StringConstants.disconnected,
                    style: StyleConstants.primary14w500Style,
                  );
                },
              ),
            ],
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: controller.ble.isConnectedNotifier,
          builder: (context, isConnected, child) {
            if (isConnected) return const SizedBox.shrink();
            return GetBuilder<ProjectDashboardController>(
              builder: (c) {
                if (c.isConnecting) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.primary,
                      ),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: controller.connectToDeviceByName,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Connect',
                      style: StyleConstants.white12w600Style,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
