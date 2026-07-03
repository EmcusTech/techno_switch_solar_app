import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';

abstract class ScanUiDelegate {
  bool get isMounted;

  BuildContext get uiContext;

  void showSnackBar(String message);

  void popScreen();

  void popWithResult(bool result);

  void showBluetoothOffDialog();

  Future<void> showWrongPanelTypeDialog({
    required String expected,
    required String received,
  });

  void showConnectingDialog(
    DiscoveredDevice device, {
    VoidCallback? onPauseAnimations,
    VoidCallback? onResumeAnimations,
    bool isScanningConnectFlow = false,
  });

  Future<int?> promptUserToPickOrCreateSite({
    required List<SiteModel> sites,
    required String panelId,
    required String panelName,
  });

  Future<int?> openSimpleSiteCreationForSitePicker({
    required String panelId,
    required String panelName,
  });

  void replaceWithScannedScreen();

  Future<bool?> pushScannedScreen();

  Future<void> openScanAgain({required ScanFlowArgs scanningArgs});

  void navigateToProjectDashboard({required ProjectDashboardArgs args});

  void navigateToEventLog({required LogFlowArgs args});

  void navigateToLogRetrievalLoading({required LogFlowArgs args});

  Future<bool> showPanelAccessCodeGatewayDialog({
    required Future<void> Function() onStartValidation,
  });

  Future<bool> showPanelAccessCodeLogRetrievalSheet({
    required DiscoveredDevice device,
    bool? isLiveEvent,
    required Future<void> Function() onStartValidation,
  });

  Future<void> offerOptionalFullConfigDownloadAfterConnect({
    required DiscoveredDevice device,
    required bool panelHadNoSiteBeforeConnect,
  });
}
