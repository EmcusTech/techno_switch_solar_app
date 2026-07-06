import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/widgets/dashboard_tile_registry.dart';
import 'package:techno_switch_solar_app/features/dashboard/widgets/peripheral_tile.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/features/dashboard/widgets/dashboard_panel_header.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key, required this.controller});

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
              child: DashboardPanelHeader(controller: controller),
            ),
            Expanded(
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
                      DashboardTileGrid(
                        controller: controller,
                        tiles: DashboardTileRegistry.overviewTiles(controller),
                        heightFactor: 0.2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        StringConstants.panelActions,
                        style: StyleConstants.black16w700Style,
                      ),
                      const SizedBox(height: 8),
                      DashboardTileGrid(
                        controller: controller,
                        tiles: DashboardTileRegistry.panelActionTiles(controller),
                        heightFactor: 0.35,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
