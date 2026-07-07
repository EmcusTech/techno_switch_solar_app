import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/views/project_dashboard_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/dashboard/widgets/dashboard_bottom_nav.dart';
import 'package:techno_switch_solar_app/features/dashboard/widgets/dashboard_tab.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_history_screen.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/features/settings/views/settings_screen.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_controller.dart';
import 'package:techno_switch_solar_app/features/test_mode/views/test_mode_screen.dart';

class ProjectDashboardScreen extends StatefulWidget {
  const ProjectDashboardScreen({super.key});

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen>
    with ProjectDashboardUiDelegateMixin {
  late final ProjectDashboardController _controller;

  @override
  ProjectDashboardController get dashboardController => _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProjectDashboardController>();
    _controller.attachUi(this);
  }

  @override
  void dispose() {
    _controller.detachUi();
    if (Get.isRegistered<ProjectDashboardController>()) {
      Get.delete<ProjectDashboardController>();
    }
    if (Get.isRegistered<SettingsController>()) {
      Get.delete<SettingsController>();
    }
    if (Get.isRegistered<TestModeController>()) {
      Get.delete<TestModeController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectDashboardController>(
      init: _controller,
      builder: (controller) {
        return PopScope(
          canPop: !controller.bleController.isConnected,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await controller.handleWillPop();
            if (shouldPop) {
              popScreen();
            }
          },
          child: Scaffold(
            extendBody: true,
            resizeToAvoidBottomInset: false,
            body: IndexedStack(
              index: controller.selectedIndex,
              children: [
                DashboardTab(
                  controller: controller,
                  onExport: showExportBottomSheet,
                ),
                const SettingsScreen(),
                const TestModeScreen(),
                LogHistoryScreen(
                  panelName: controller.panelName,
                  panelVersionNo: controller.panelVersionNo,
                  siteId: controller.siteId,
                  refreshTrigger: controller.logHistoryRefreshTrigger,
                  embedded: true,
                ),
              ],
            ),
            bottomNavigationBar: DashboardBottomNav(controller: controller),
          ),
        );
      },
    );
  }
}
