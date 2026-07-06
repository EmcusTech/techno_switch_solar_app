import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_app_bar.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_panel_section.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_shell.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_summary_card.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class SiteScreen extends StatefulWidget {
  const SiteScreen({super.key});

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> with SiteUiDelegateMixin {
  late final SiteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SiteController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<SiteController>()) {
      Get.delete<SiteController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SiteController>(
      init: _controller,
      builder: (controller) {
        return Scaffold(
          body: SiteShell(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SiteAppBar(controller: controller),
                  Expanded(
                    child: RefreshIndicator(
                      color: ColorConstants.primary,
                      onRefresh: controller.refreshPanels,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: SiteSummaryCard(controller: controller),
                          ),
                          SliverToBoxAdapter(
                            child: SitePanelSection(controller: controller),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
