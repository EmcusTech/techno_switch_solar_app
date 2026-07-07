import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class SettingsMenuTile extends StatelessWidget {
  const SettingsMenuTile({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SvgPicture.asset(
              AssetConstants.settingsIcon,
              colorFilter: ColorFilter.mode(
                ColorConstants.textHeading.withValues(alpha: 0.72),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: StyleConstants.black16w400Style),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: ColorConstants.textSecondary.withValues(alpha: 0.47),
            ),
          ],
        ),
      ),
    );
  }
}
