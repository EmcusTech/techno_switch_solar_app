import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/views/event_log_screen.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_retreival_completed_screen.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/site_creation_dialog.dart'
    as site_dialog;
import 'package:techno_switch_solar_app/widgets/export_tile.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

mixin LogUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements LogUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  Future<bool?> showStopLogRetrievalDialog() async => null;

  @override
  Future<bool?> showClearLogsDialog() async => null;

  @override
  void showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(uiContext).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void popScreen() {
    if (!mounted) return;
    Navigator.of(uiContext).pop();
  }

  @override
  void popRootDialog() {
    if (!mounted) return;
    Navigator.of(uiContext, rootNavigator: true).pop();
  }

  @override
  void showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: uiContext,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: ColorConstants.primary),
          ),
    );
  }

  @override
  Future<bool?> showSiteCreationDialog({required int logCount}) {
    return site_dialog.showSiteCreationDialog(uiContext, logCount: logCount);
  }

  @override
  void navigateBackToScanning() {
    NavigationService.navigateBackToScanning(uiContext);
  }

  @override
  void returnAfterProjectDashboardLogSave({int pops = 2}) {
    if (!mounted) return;
    LogController.suppressCompletedBackSave = true;
    final nav = Navigator.of(uiContext, rootNavigator: true);
    for (var i = 0; i < pops && nav.canPop(); i++) {
      nav.pop();
    }
  }

  @override
  void navigateBackToHome() {
    NavigationService.navigateBackToHome(uiContext);
  }

  @override
  void openEventLogScreen({required LogFlowArgs args}) {
    LogBinding(args: args).dependencies();
    Navigator.of(uiContext).push(
      MaterialPageRoute(builder: (_) => const EventLogScreen()),
    );
  }

  @override
  void openCompletedScreen({required LogFlowArgs args}) {
    LogBinding(args: args).dependencies();
    final fromDashboard = args.completed?.fromProjectDashboard ?? false;
    final navigator = Navigator.of(uiContext, rootNavigator: true);

    if (fromDashboard) {
      final localNav = Navigator.of(uiContext);
      if (localNav.canPop()) {
        localNav.pop();
      }
      navigator.push(
        MaterialPageRoute(builder: (_) => const LogRetrievalCompletedScreen()),
      );
      return;
    }

    if (navigator.canPop()) {
      navigator.popUntil((route) => route is PageRoute);
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LogRetrievalCompletedScreen()),
    );
  }

  @override
  void openSimpleSiteCreationScreen({
    required List<LogModel> logs,
    required String panelName,
    required String panelVersionNo,
    required String panelId,
  }) {
    SimpleSiteCreationBinding(
      args: SimpleSiteCreationArgs(
        retrievedLogs: logs,
        panelName: panelName,
        panelVersionNo: panelVersionNo,
        panelId: panelId,
      ),
    ).dependencies();
    Navigator.of(uiContext).pushReplacement(
      MaterialPageRoute(builder: (_) => const SimpleSiteCreationScreen()),
    );
  }

  @override
  void showExportBottomSheet({
    required Future<void> Function() onExportPdf,
  }) {
    showModalBottomSheet(
      context: uiContext,
      backgroundColor: ColorConstants.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: ColorConstants.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                StringConstants.export,
                style: StyleConstants.textBodyDark18w700Style,
              ),
              const SizedBox(height: 12),
              ExportTile(
                iconPath: AssetConstants.shareIconRed,
                title: StringConstants.exportAsPDF,
                onTap: () async {
                  Navigator.pop(uiContext);
                  await onExportPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Future<DateTime?> pickDate({
    required bool isFromDate,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return showDatePicker(
      context: uiContext,
      initialDate:
          isFromDate ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  @override
  void showFilterBottomSheet({
    required VoidCallback onApply,
    required VoidCallback onReset,
    required Widget Function(StateSetter setSheetState) builder,
  }) {
    showModalBottomSheet(
      context: uiContext,
      backgroundColor: ColorConstants.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) => builder(setSheetState),
        );
      },
    );
  }

  @override
  Future<void> disconnectConnectedDevice(DiscoveredDevice device) async {
    await device.device!.disconnect();
  }
}
