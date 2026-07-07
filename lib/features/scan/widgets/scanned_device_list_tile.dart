import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ScannedDeviceListTile extends StatelessWidget {
  const ScannedDeviceListTile({
    super.key,
    required this.scanType,
    required this.displayPrefix,
    required this.displayId,
    required this.subtitle,
    required this.onTap,
  });

  final ScanType scanType;
  final String displayPrefix;
  final String displayId;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        scanType == ScanType.usb ? ColorConstants.primary : Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          border: Border.all(
            color: ColorConstants.iconDisabled.withValues(alpha: 0.31),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(AssetConstants.panelIcon),
              ),
              const SizedBox(width: 14.31),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayPrefix,
                      style: StyleConstants.textDark14w700Style,
                    ),
                    Text(
                      displayId,
                      style: StyleConstants.textMuted14w700Style,
                    ),
                    Text(
                      subtitle,
                      style: StyleConstants.textMuted12w400Style,
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(AssetConstants.arrowRightColoredIcon),
            ],
          ),
        ),
      ),
    );
  }
}
