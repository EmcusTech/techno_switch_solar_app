import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_quick_link_item.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HomeQuickLinksSection extends StatelessWidget {
  const HomeQuickLinksSection({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              StringConstants.quickLinks,
              style: StyleConstants.textDark18w700Style,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HomeQuickLinkItem(
                imagePath: AssetConstants.newProjectIcon,
                label: StringConstants.newSite,
                onTap: controller.openNewSite,
              ),
              const HomeQuickLinkItem(
                imagePath: AssetConstants.openProjectIcon,
                label: StringConstants.openSite,
                isEnabled: false,
              ),
              HomeQuickLinkItem(
                imagePath: AssetConstants.maintenanceIcon,
                label: StringConstants.liveEvents,
                onTap: controller.openLiveEventsScan,
              ),
              HomeQuickLinkItem(
                imagePath: AssetConstants.retrieveLogIcon,
                label: StringConstants.retrieveLog,
                onTap: controller.openRetrieveLogScan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
