import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class DashboardTileConfig {
  const DashboardTileConfig({
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.isDisabled = false,
    this.iconHeight,
    this.iconWidth,
  });

  final String label;
  final String iconPath;
  final VoidCallback onTap;
  final bool isDisabled;
  final double? iconHeight;
  final double? iconWidth;
}

class PeripheralTile extends StatelessWidget {
  const PeripheralTile({
    super.key,
    required this.controller,
    required this.config,
  });

  final ProjectDashboardController controller;
  final DashboardTileConfig config;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (config.isDisabled) return;
        await controller.onPeripheralTileTap(config.onTap);
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.backgroundSubtle,
                border: Border.all(color: ColorConstants.borderMedium),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  config.iconPath,
                  colorFilter: ColorFilter.mode(
                    config.isDisabled
                        ? ColorConstants.textGray.withValues(alpha: 0.2)
                        : ColorConstants.primary,
                    BlendMode.srcIn,
                  ),
                  height: config.iconHeight,
                  width: config.iconWidth,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(config.label, style: StyleConstants.textSecondary10w500Style),
        ],
      ),
    );
  }
}

class DashboardTileGrid extends StatelessWidget {
  const DashboardTileGrid({
    super.key,
    required this.controller,
    required this.tiles,
    required this.heightFactor,
  });

  final ProjectDashboardController controller;
  final List<DashboardTileConfig> tiles;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      height: (size.height + size.width) * heightFactor,
      width: double.infinity,
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          for (final tile in tiles)
            PeripheralTile(controller: controller, config: tile),
        ],
      ),
    );
  }
}
