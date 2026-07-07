import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class DashboardAppBar extends StatelessWidget {
  const DashboardAppBar({
    super.key,
    required this.onBack,
    required this.onExport,
  });

  final VoidCallback onBack;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConstants.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.blackMaterial.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: ColorConstants.textDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              StringConstants.projectDashboard,
              style: StyleConstants.black20w700Style,
            ),
          ),
          GestureDetector(
            onTap: onExport,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SvgPicture.asset(AssetConstants.shareIcon),
            ),
          ),
        ],
      ),
    );
  }
}
