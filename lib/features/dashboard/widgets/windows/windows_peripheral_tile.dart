import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class WindowsDashboardTileConfig {
  const WindowsDashboardTileConfig({
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
  final WindowsDashboardTileConfig config;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.bleController.bleProcess.sessionAccessCodeReady,
      builder: (context, sessionReady, _) {
        final locked = !sessionReady;
        final inactive = config.isDisabled || locked;
        return GestureDetector(
          onTap: () async {
            if (inactive) return;
            controller.pendingWindowsTileLabel = config.label;
            await controller.onPeripheralTileTap(config.onTap);
          },
          child: Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: controller.selectedWindowsTile,
                  builder: (context, selectedLabel, _) {
                    final isSelected = selectedLabel == config.label && !locked;
                    return Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? ColorConstants.primary.withValues(alpha: 0.1)
                                : ColorConstants.backgroundSubtle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? ColorConstants.primary
                                  : ColorConstants.borderMedium,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          config.iconPath,
                          colorFilter: ColorFilter.mode(
                            inactive
                                ? ColorConstants.textGray.withValues(alpha: 0.2)
                                : ColorConstants.primary,
                            BlendMode.srcIn,
                          ),
                          height: config.iconHeight,
                          width: config.iconWidth,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                config.label,
                style:
                    inactive
                        ? StyleConstants.textSecondary10w500Style.copyWith(
                          color: ColorConstants.textGray.withValues(alpha: 0.2),
                        )
                        : StyleConstants.textSecondary10w500Style,
              ),
            ],
          ),
        );
      },
    );
  }
}

class WindowsDashboardTileGrid extends StatelessWidget {
  const WindowsDashboardTileGrid({
    super.key,
    required this.controller,
    required this.tiles,
    required this.heightFactor,
  });

  final ProjectDashboardController controller;
  final List<WindowsDashboardTileConfig> tiles;
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
        childAspectRatio: 1,
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
