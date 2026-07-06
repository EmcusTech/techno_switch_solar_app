import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_header.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_quick_links_section.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_recent_sites_section.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_shell.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return HomeShell(
      child: RefreshIndicator(
        color: ColorConstants.primary,
        onRefresh: controller.refreshSites,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: HomeHeader(controller: controller)),
            SliverToBoxAdapter(
              child: HomeQuickLinksSection(controller: controller),
            ),
            SliverToBoxAdapter(
              child: HomeRecentSitesSection(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}
