import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ScanDeviceCard extends StatelessWidget {
  const ScanDeviceCard({
    super.key,
    required this.controller,
    required this.device,
  });

  final ScanController controller;
  final DiscoveredDevice device;

  @override
  Widget build(BuildContext context) {
    final label = device.name;

    return GestureDetector(
      onTap:
          () => controller.onDeviceSelected(
            device,
            isScanningConnectFlow: true,
          ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                BleNameUtils.getDisplayPrefixFromBleName(label),
                style: StyleConstants.textDark8boldStyle,
              ),
              const SizedBox(height: 6),
              SvgPicture.asset(AssetConstants.panelIcon, width: 60, height: 60),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  BleNameUtils.getDisplayIdFromBleName(label),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: StyleConstants.black12boldStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
