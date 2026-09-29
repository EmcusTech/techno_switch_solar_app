import 'package:flutter/material.dart';
import 'package:Technoswitch/features/home/controllers/home_screen_controller.dart';
import 'package:Technoswitch/features/home/widgets/home_quick_links_section.dart';
import 'package:Technoswitch/features/home/widgets/home_recent_sites_section.dart';
import 'package:Technoswitch/features/home/widgets/windows/windows_home_header.dart';
import 'package:Technoswitch/features/home/widgets/windows/windows_home_shell.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class WindowsHomeTab extends StatelessWidget {
  const WindowsHomeTab({super.key, required this.controller});

  final HomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return WindowsHomeShell(
      child: RefreshIndicator(
        color: ColorConstants.primary,
        onRefresh: controller.refreshSites,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: WindowsHomeHeader(controller: controller),
            ),
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
