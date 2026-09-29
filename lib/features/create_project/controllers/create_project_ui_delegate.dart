import 'package:flutter/material.dart';
import 'package:Technoswitch/ble/blue_plus_adapter.dart';
import 'package:Technoswitch/models/site_model.dart';
import 'package:Technoswitch/utils/site_service.dart';

abstract class CreateProjectUiDelegate {
  bool get isMounted;

  BuildContext get uiContext;

  Future<void> dismissKeyboardFully();

  Future<void> settleImeBeforeShowingDialog();

  void showSnackBar(String message, {required bool isError});

  Future<bool?> showCreateSiteConfirmDialog();

  Future<bool?> showApplyPanelSettingsConfirmDialog();

  Future<bool?> showCreateSiteNoConfigChangesConfirmDialog();

  Future<bool?> showDisconnectConfirmDialog();

  Future<String?> showEnterPanelIdDialog({String? initialValue});

  Future<void> showPanelAlreadyAssignedDialog();

  Future<String?> showPanelAlreadyOnSiteDialog();

  Future<void> showMandatoryConfigDownloadDialog();

  Future<bool?> openScanningScreen(String? expectedPanelType);

  void popScreen();

  void popToHome();

  void openProjectDashboard({
    required DiscoveredDevice device,
    required int siteId,
    required String siteName,
  });

  void openSiteScreen({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  });
}
