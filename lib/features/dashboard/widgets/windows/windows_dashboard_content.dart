import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_panel_header.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_tile_registry.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_peripheral_tile.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/features/dashboard/widgets/dashboard_tile_registry.dart';
import 'package:Technoswitch/features/dashboard/widgets/peripheral_tile.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:Technoswitch/utils/constants/style_constants.dart';

class WindowsDashboardContent extends StatelessWidget {
  const WindowsDashboardContent({super.key, required this.controller});

  final ProjectDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: WindowsDashboardPanelHeader(controller: controller),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              StringConstants.peripheralOverview,
                              style: StyleConstants.black16w700Style,
                            ),
                            const SizedBox(height: 8),
                            WindowsDashboardTileGrid(
                              controller: controller,
                              tiles: WindowsDashboardTileRegistry.overviewTiles(
                                controller,
                              ),
                              heightFactor: 0.1,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              StringConstants.panelActions,
                              style: StyleConstants.black16w700Style,
                            ),
                            const SizedBox(height: 8),
                            WindowsDashboardTileGrid(
                              controller: controller,
                              tiles:
                                  WindowsDashboardTileRegistry.panelActionTiles(
                                    controller,
                                  ),
                              heightFactor: 0.35,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Expanded(flex: 2, child: SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
