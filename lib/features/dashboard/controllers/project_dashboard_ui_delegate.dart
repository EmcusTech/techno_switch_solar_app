import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';

abstract class ProjectDashboardUiDelegate {
  bool get isMounted;

  BuildContext get uiContext;

  void showSnackBar(String message, {Color? backgroundColor});

  Future<bool?> showDisconnectConfirmDialog();

  Future<bool?> showEventLogRetrievalConfirmDialog();

  void popScreen();

  void closeModalOverlaysAboveDashboard();

  void showUnexpectedBleDisconnectDialog();

  void dismissRootNavigatorIfCanPop();

  void showConnectingDialog(DiscoveredDevice device);

  void popTopDialogIfMounted();

  Future<bool> showPanelAccessCodeGatewayDialog({
    required VoidCallback onStartValidation,
  });

  Future<void> offerOptionalFullConfigDownload(DiscoveredDevice device);

  Future<DiscoveredDevice?> resolveBootloaderOnConnect(DiscoveredDevice device);

  Future<void> showBluetoothOffDialog();

  void showExportBottomSheet();

  Future<void> showBootloaderModeDialog();

  void showApplySuccessDialog(String message, {String? subtitle});

  void showDownloadSuccessDialog(String message);

  void showDiagnosticStopDialog();

  void showConfigLogBottomSheet();

  void showConfigLogPasswordPopup({
    required VoidCallback onCall,
    bool isExtOut = false,
    bool isInputSetup = false,
    bool isRelaySetup = false,
    bool isZoneSetup = false,
    bool isLBusSetup = false,
    bool isSounderSetup = false,
    bool isServiceDueSetup = false,
    bool isAccessCodeSetup = false,
    bool isPanelInfoSetup = false,
    bool isGeneralModuleSetup = false,
    bool isAdcSetup = false,
    bool isConfigLogBulk = false,
    bool isConfigLogBulkApply = false,
    bool showDetailedConfigLogBulkBleProgressInAccessDialog = true,
    String? mode,
    Future<void> Function()? onDownloadComplete,
    String? downloadSuccessMessage,
    Future<void> Function(BuildContext context)? onAfterApplySuccess,
  });

  void showPasswordPopup({
    required VoidCallback onCall,
    bool isExtOut = false,
    bool isInputSetup = false,
    bool isRelaySetup = false,
    bool isZoneSetup = false,
    bool isLBusSetup = false,
    bool isSounderSetup = false,
    bool isServiceDueSetup = false,
    bool isAccessCodeSetup = false,
    bool isPanelInfoSetup = false,
    bool isGeneralModuleSetup = false,
    bool isAdcSetup = false,
    bool isConfigLogBulk = false,
    bool isConfigLogBulkApply = false,
    bool showDetailedConfigLogBulkBleProgressInAccessDialog = true,
    String? mode,
    Future<void> Function()? onDownloadComplete,
    String? downloadSuccessMessage,
    Future<void> Function(BuildContext context)? onAfterApplySuccess,
  });

  void showLBusSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showSounderSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showServiceDueSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showAccessCodeSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showPanelInfoSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showGeneralModuleSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showAdcDiagnosticsSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onStop,
  });

  void showModuleSetupBottomSheet({required VoidCallback onDownload});

  void showExtOutBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showInputSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showRelaySetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showZoneSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showWalkTestZoneBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showTestModeSounderBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showTestModeRelayBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  void showTestModeChoiceBottomSheet({
    required VoidCallback onDownloadRelays,
    required VoidCallback onDownloadSounders,
    required VoidCallback onApplyRelays,
    required VoidCallback onApplySounders,
    required ValueNotifier<int> relayRefreshTrigger,
    required ValueNotifier<int> sounderRefreshTrigger,
  });

  void showRadioSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  });

  Future<void> showWalkTestResultConfirmation();

  Future<void> showRelayTestResultConfirmation();

  Future<void> showSounderTestResultConfirmation();

  Future<void> showFirmwareUpgradeBottomSheet();
}
