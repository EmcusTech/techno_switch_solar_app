import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_site_list_item.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HomeRecentSitesSection extends StatelessWidget {
  const HomeRecentSitesSection({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                StringConstants.recentSites,
                style: StyleConstants.textDark18w700Style,
              ),
              if (controller.sites.isNotEmpty)
                Text(
                  StringConstants.viewAll,
                  style: StyleConstants.textGray14w500Style,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: ColorConstants.primary),
              ),
            )
          else if (controller.sites.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  StringConstants.noSitesYet,
                  style: StyleConstants.textDark14w400Style,
                ),
              ),
            )
          else
            for (var i = 0; i < controller.sites.length; i++) ...[
              HomeSiteListItem(
                controller: controller,
                siteWithLogCount: controller.sites[i],
                onTap: () => controller.openSite(controller.sites[i]),
              ),
              if (i < controller.sites.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
