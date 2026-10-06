import 'package:flutter/material.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/utils/panel_config/panel_config_cache_sync.dart';
import 'package:Technoswitch/widgets/common/common_windows_access_code_dialog.dart';

/// Access-code entry in the Windows dashboard detail pane.
class WindowsDashboardAccessCodePane extends StatelessWidget {
  const WindowsDashboardAccessCodePane({super.key, required this.controller});

  final ProjectDashboardController controller;

  Future<void> _onAccessGranted(BuildContext context) async {
    final bleProcess = controller.bleController.bleProcess;
    final code = bleProcess.accessKey.value;
    try {
      if (!context.mounted) return;
      await PanelConfigCacheSync.restoreAllFromCacheToBle(
        controller.ble,
        controller.selectedDevice.id,
        controller.panelRefreshNotifiers,
      );
    } finally {
      bleProcess.setSessionAccessCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonWindowsAccessCodeDialog(
      bleProcess: controller.bleController.bleProcess,
      onStartValidation:
          controller.bleController.startSessionAccessCodeValidation,
      sheetContext: context,
      successCloseDelay: const Duration(seconds: 2),
      persistSessionAccessCode: false,
      embedded: true,
      onAccessGranted: () => _onAccessGranted(context),
    );
  }
}
