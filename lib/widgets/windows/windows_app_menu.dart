import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/ble/ble_manager.dart';
import 'package:Technoswitch/features/create_project/bindings/create_project_binding.dart';
import 'package:Technoswitch/features/create_project/views/create_project_screen.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/features/help/bindings/help_screen_binding.dart';
import 'package:Technoswitch/features/help/views/help_screen.dart';
import 'package:Technoswitch/features/scan/bindings/scan_binding.dart';
import 'package:Technoswitch/features/scan/models/scan_flow_args.dart';
import 'package:Technoswitch/features/scan/views/windows/windows_scanning_screen.dart';
import 'package:Technoswitch/features/settings/bindings/settings_binding.dart';
import 'package:Technoswitch/features/settings/controllers/settings_controller.dart';
import 'package:Technoswitch/features/settings/models/settings_args.dart';
import 'package:Technoswitch/features/settings/views/settings_screen.dart';
import 'package:Technoswitch/features/settings/widgets/settings_content_panel.dart';
import 'package:Technoswitch/utils/app/app_services.dart';
import 'package:Technoswitch/utils/app/navigation_service.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';
import 'package:Technoswitch/utils/constants/string_constants.dart';
import 'package:window_manager/window_manager.dart';

abstract final class WindowsAppMenu {
  const WindowsAppMenu._();

  static Future<void> openNewSite() async {
    CreateProjectBinding().dependencies();
    await _push(const CreateSiteScreen());
  }

  static Future<void> openConnect() async {
    await _disconnectBleIfConnected();
    await _openScanning(ScanFlowArgs.scanning());
  }

  static Future<void> openLiveEvents() async {
    await _openScanning(ScanFlowArgs.scanning(isLiveEventLogs: true));
  }

  static Future<void> openRetrieveLog() async {
    await _openScanning(ScanFlowArgs.scanning(isLiveEvent: true));
  }

  static Future<void> openSettings() async {
    final dashboardHostsSettings =
        Get.isRegistered<ProjectDashboardController>();
    if (!dashboardHostsSettings) {
      final hasSettings = Get.isRegistered<SettingsController>();
      final replaceEmbedded =
          hasSettings && Get.find<SettingsController>().embedded;
      if (!hasSettings || replaceEmbedded) {
        SettingsBinding(
          args: const SettingsArgs(
            panelName: StringConstants.rhino2008,
            panelVersionNo: StringConstants.s098,
            embedded: false,
          ),
        ).dependencies();
      }
    }

    await _push(
      dashboardHostsSettings
          ? const _DashboardSettingsPage()
          : const SettingsScreen(),
    );
  }

  static Future<void> openHelp() async {
    HelpScreenBinding().dependencies();
    await _push(const _WindowsHelpPage());
  }

  static Future<void> exitApp() async {
    await AppServices.disconnect();
    await windowManager.close();
  }

  static Future<void> _openScanning(ScanFlowArgs args) async {
    ScanBinding(args: args).dependencies();
    await _push(const WindowsScanningScreen());
  }

  static Future<void> _disconnectBleIfConnected() async {
    final bleManager = Get.find<BleManager>();
    if (bleManager.isConnected) {
      await bleManager.disconnectConnectedDevice();
    }
  }

  static Future<void> _push(Widget page) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;
    await navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _DashboardSettingsPage extends StatelessWidget {
  const _DashboardSettingsPage();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    return Scaffold(
      backgroundColor: ColorConstants.backgroundSubtle,
      appBar: AppBar(
        title: const Text(StringConstants.projectSettings),
        backgroundColor: ColorConstants.backgroundSubtle,
        foregroundColor: ColorConstants.black,
        surfaceTintColor: ColorConstants.transparent,
        elevation: 0,
      ),
      body: SettingsContentPanel(controller: controller),
    );
  }
}

class _WindowsHelpPage extends StatelessWidget {
  const _WindowsHelpPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstants.scaffoldGradientTop,
        foregroundColor: ColorConstants.black,
        surfaceTintColor: ColorConstants.transparent,
        elevation: 0,
      ),
      body: const HelpScreen(),
    );
  }
}
