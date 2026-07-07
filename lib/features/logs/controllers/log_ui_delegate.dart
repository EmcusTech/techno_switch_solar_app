import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';

abstract class LogUiDelegate {
  bool get isMounted;

  BuildContext get uiContext;

  void showSnackBar(String message);

  void popScreen();

  void popRootDialog();

  void showLoadingDialog();

  Future<bool?> showStopLogRetrievalDialog();

  Future<bool?> showClearLogsDialog();

  Future<bool?> showSiteCreationDialog({required int logCount});

  void navigateBackToScanning();

  /// Pops log screens pushed on top of [ProjectDashboardScreen].
  void returnAfterProjectDashboardLogSave({int pops = 2});

  void navigateBackToHome();

  void openEventLogScreen({required LogFlowArgs args});

  void openCompletedScreen({required LogFlowArgs args});

  void openSimpleSiteCreationScreen({
    required List<LogModel> logs,
    required String panelName,
    required String panelVersionNo,
    required String panelId,
  });

  void showExportBottomSheet({required Future<void> Function() onExportPdf});

  Future<DateTime?> pickDate({
    required bool isFromDate,
    DateTime? fromDate,
    DateTime? toDate,
  });

  void showFilterBottomSheet({
    required VoidCallback onApply,
    required VoidCallback onReset,
    required Widget Function(StateSetter setSheetState) builder,
  });

  Future<void> disconnectConnectedDevice(DiscoveredDevice device);
}
