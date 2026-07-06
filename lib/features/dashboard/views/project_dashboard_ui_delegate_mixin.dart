import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/bindings/firmware_binding.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/disconnect_device_dialog.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/dashboard/widgets/show_dashboard_peripheral_sheet.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/features/peripherals/access_code/sheets/access_code_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/config_log/sheets/config_log_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/diagnostics/sheets/diagnostic_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/ext_out/sheets/ext_out_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/firmware/controllers/firmware_controller.dart';
import 'package:techno_switch_solar_app/features/peripherals/firmware/sheets/firmware_upgrade_bottom_sheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/general/sheets/general_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/inputs/sheets/input_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/l_bus/sheets/l_bus_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/module/sheets/module_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/panel_info/sheets/panel_info_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/radio/sheets/radio_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/relays/sheets/relay_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/service_due/sheets/service_due_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/sounders/sheets/sounder_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/test_mode/sheets/test_mode_choice_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/test_mode/sheets/test_mode_relay_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/test_mode/sheets/test_mode_sounder_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/walk_test/sheets/walk_test_zone_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/peripherals/zones/sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_access_password_popup.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_bulk_sync.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_feedback_dialogs.dart';
import 'package:techno_switch_solar_app/utils/panel_config/post_connect_bulk_download_offer.dart';
import 'package:techno_switch_solar_app/utils/ble/bootloader_connect_flow.dart';
import 'package:techno_switch_solar_app/utils/commissioning_test_results_helper.dart';
import 'package:techno_switch_solar_app/utils/storage/commissioning_test_results_cache.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/ble_connecting_dialog.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/panel_access_code_dialog.dart'
    as panel_access_dialog;
import 'package:techno_switch_solar_app/widgets/export_tile.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_msd_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

mixin ProjectDashboardUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements ProjectDashboardUiDelegate {
  ProjectDashboardController get dashboardController;

  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  void showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(uiContext).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Future<bool?> showDisconnectConfirmDialog() {
    return showDialog<bool>(
      context: uiContext,
      barrierDismissible: false,
      builder: (_) => const DisconnectDeviceDialog(),
    );
  }

  @override
  void popScreen() {
    if (mounted) {
      Navigator.of(uiContext).pop();
    }
  }

  @override
  void closeModalOverlaysAboveDashboard() {
    if (!mounted) return;
    final route = ModalRoute.of(uiContext);
    if (route == null) return;
    Navigator.of(uiContext).popUntil((r) => r == route);
  }

  @override
  void showUnexpectedBleDisconnectDialog() {
    if (!mounted || dashboardController.isUnexpectedDisconnectDialogOpen) {
      return;
    }
    dashboardController.isUnexpectedDisconnectDialogOpen = true;
    showDialog<void>(
      context: uiContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: ColorConstants.errorIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bluetooth_disabled,
                        color: ColorConstants.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    StringConstants.bluetoothDisconnected,
                    style: StyleConstants.textDark18w700Style,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UiStrings.connectionLostUseConnectMessage,
                    style: StyleConstants.textGray14w400Style,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        dashboardController
                            .markUnexpectedDisconnectDialogClosed();
                        Navigator.of(dialogContext).pop();
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: ColorConstants.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            StringConstants.ok,
                            style: StyleConstants.white16w600Style,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      dashboardController.markUnexpectedDisconnectDialogClosed();
    });
  }

  @override
  void dismissRootNavigatorIfCanPop() {
    if (!mounted) return;
    if (Navigator.of(uiContext, rootNavigator: true).canPop()) {
      Navigator.of(uiContext, rootNavigator: true).pop();
    }
  }

  @override
  void popTopDialogIfMounted() {
    if (!mounted) return;
    try {
      Navigator.of(uiContext).pop();
    } catch (_) {}
  }

  @override
  Future<bool> showPanelAccessCodeGatewayDialog({
    required VoidCallback onStartValidation,
  }) {
    return panel_access_dialog.showPanelAccessCodeGatewayDialog(
      context: uiContext,
      onStartValidation: () async => onStartValidation(),
    );
  }

  @override
  Future<void> offerOptionalFullConfigDownload(DiscoveredDevice device) {
    return offerOptionalFullConfigDownloadAfterConnect(
      context: uiContext,
      isMounted: () => mounted,
      device: device,
      refreshNotifiers: dashboardController.panelRefreshNotifiers,
      navigatingToDeviceConnecting:
          dashboardController.navigatingToDeviceConnecting,
    );
  }

  @override
  Future<DiscoveredDevice?> resolveBootloaderOnConnect(
    DiscoveredDevice device,
  ) {
    return resolveBootloaderModeOnConnect(
      context: uiContext,
      bleController: dashboardController.bleController,
      bluetoothService: dashboardController.bluetoothService,
      device: device,
    );
  }

  @override
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
  }) {
    showPasswordPopup(
      onCall: onCall,
      isExtOut: isExtOut,
      isInputSetup: isInputSetup,
      isRelaySetup: isRelaySetup,
      isZoneSetup: isZoneSetup,
      isLBusSetup: isLBusSetup,
      isSounderSetup: isSounderSetup,
      isServiceDueSetup: isServiceDueSetup,
      isAccessCodeSetup: isAccessCodeSetup,
      isPanelInfoSetup: isPanelInfoSetup,
      isGeneralModuleSetup: isGeneralModuleSetup,
      isAdcSetup: isAdcSetup,
      isConfigLogBulk: isConfigLogBulk,
      isConfigLogBulkApply: isConfigLogBulkApply,
      showDetailedConfigLogBulkBleProgressInAccessDialog:
          showDetailedConfigLogBulkBleProgressInAccessDialog,
      mode: mode,
      onDownloadComplete: onDownloadComplete,
      downloadSuccessMessage: downloadSuccessMessage,
      onAfterApplySuccess: onAfterApplySuccess,
    );
  }

  @override
  Future<void> showWalkTestResultConfirmation() {
    return showCommissioningTestResultConfirmation(
      context: uiContext,
      deviceId: dashboardController.selectedDevice.id,
      type: CommissioningTestType.walkTest,
      manager: dashboardController.bleManager,
    );
  }

  @override
  Future<void> showRelayTestResultConfirmation() {
    return showCommissioningTestResultConfirmation(
      context: uiContext,
      deviceId: dashboardController.selectedDevice.id,
      type: CommissioningTestType.relayTest,
      manager: dashboardController.bleManager,
    );
  }

  @override
  Future<void> showSounderTestResultConfirmation() {
    return showCommissioningTestResultConfirmation(
      context: uiContext,
      deviceId: dashboardController.selectedDevice.id,
      type: CommissioningTestType.sounderTest,
      manager: dashboardController.bleManager,
    );
  }

  @override
  Future<void> showFirmwareUpgradeBottomSheet() async {
    FirmwareBinding().dependencies();
    await showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      isDismissible: false,
      enableDrag: false,
      builder:
          (context) => FirmwareUpgradeBottomSheet(
            connectedDevice: dashboardController.selectedDevice,
          ),
    );
    Get.delete<FirmwareController>();
  }

  @override
  void showConnectingDialog(DiscoveredDevice device) {
    final connectionNotifier =
        dashboardController.bleController.bleManager.isConnectedNotifier;
    final handshakeCompleteNotifier =
        dashboardController.bleController.bleManager.handshakeCompleteNotifier;
    final maxBleConnectionRetriesReachedNotifier =
        dashboardController
            .bleController
            .bleManager
            .maxBleConnectionRetriesReached;
    bool hasNavigated = false;

    final mergedListenable = Listenable.merge([
      connectionNotifier,
      handshakeCompleteNotifier,
      maxBleConnectionRetriesReachedNotifier,
    ]);

    showDialog(
      context: uiContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: mergedListenable,
          builder: (context, _) {
            final isConnected = connectionNotifier.value;
            final handshakeComplete = handshakeCompleteNotifier.value;
            final maxBleConnectionRetriesReached =
                maxBleConnectionRetriesReachedNotifier.value;

            if (handshakeComplete &&
                !hasNavigated &&
                !maxBleConnectionRetriesReached) {
              hasNavigated = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted && hasNavigated) {
                  Navigator.of(dialogContext).pop();
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ColorConstants.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            handshakeComplete && !maxBleConnectionRetriesReached
                                ? Colors.green.withValues(alpha: 0.1)
                                : ColorConstants.errorIconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            handshakeComplete && !maxBleConnectionRetriesReached
                                ? Icon(
                                  Icons.check_circle,
                                  size: 32,
                                  color: Colors.green,
                                )
                                : Lottie.asset(
                                  AssetConstants.bleConnectingJson,
                                  animate: !maxBleConnectionRetriesReached,
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      maxBleConnectionRetriesReached
                          ? StringConstants.maxConnectionRetriesReached
                          : handshakeComplete
                          ? 'Device Connected!'
                          : isConnected
                          ? 'Establishing secure connection...'
                          : StringConstants.establishingSecureConnection,
                      style: StyleConstants.textDark20w700Style,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // Subtitle
                    Text(
                      handshakeComplete && !maxBleConnectionRetriesReached
                          ? StringConstants.ready
                          : maxBleConnectionRetriesReached
                          ? StringConstants.pleaseTryConnectingAgain
                          : isConnected
                          ? StringConstants.encryptingAndAuthenticating
                          : 'Please wait while we connect to ${device.name}',
                      style: StyleConstants.textMuted14w400Style,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    if (maxBleConnectionRetriesReached)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.5),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            StringConstants.ok,
                            style: StyleConstants.white14w600Style,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void showExportBottomSheet() {
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
                  Navigator.pop(context);
                  dashboardController.exportProjectPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Future<void> showBootloaderModeDialog() async {
    final bootloaderFileCorrupted = BleMsdUtils.isBootloaderCorrupt(
      dashboardController.selectedDevice.manufacturerData,
    );
    final wantUpgrade = await showBootloaderUpgradeOfferFromDashboardDialog(
      uiContext,
      bootloaderFileCorrupted: bootloaderFileCorrupted,
    );
    if (wantUpgrade != true || !context.mounted) return;

    final upgraded = await showFirmwareUpgradeBottomSheetForConnect(
      context: uiContext,
      connectedDevice: dashboardController.selectedDevice,
    );
    if (!upgraded || !mounted) return;

    await dashboardController.bleController.bleManager
        .disconnectConnectedDevice();

    final refreshed = await runWithBleConnectingDialog<DiscoveredDevice?>(
      context: uiContext,
      device: dashboardController.selectedDevice,
      bleController: dashboardController.bleController,
      messages: BleConnectingDialogMessages.afterFirmwareUpgrade,
      operation:
          () => reconnectBleDeviceInAppModeAfterUpgrade(
            bleController: dashboardController.bleController,
            bluetoothService: dashboardController.bluetoothService,
            originalDevice: dashboardController.selectedDevice,
          ),
    );
    if (refreshed == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              UiStrings.deviceNotFoundAfterFirmwareUpgradeReconnectMessage,
            ),
          ),
        );
      }
      return;
    }

    dashboardController.updateSelectedDevice(refreshed);

    dashboardController.bleController.bleProcess.clearSessionAccessCode();
    final ok = await panel_access_dialog.showPanelAccessCodeGatewayDialog(
      context: uiContext,
      onStartValidation:
          () =>
              dashboardController.bleController
                  .startSessionAccessCodeValidation(),
    );
    if (!ok || !mounted) {
      dashboardController.bleController.bleManager.disconnectConnectedDevice();
    }
  }

  @override
  Future<void> showBluetoothOffDialog() async {
    await showDialog(
      context: uiContext,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bluetooth_disabled,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.deviceNotConnected,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants
                      .bleDeviceIsNotConnectedTapOnConnectToConnectAgain,
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.buttonSecondaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: ColorConstants.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Close',
                              style: StyleConstants.textGray16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          navigator.pop(); // close dialog
                          await dashboardController.connectToDeviceByName();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorConstants.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ColorConstants.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Connect',
                              style: StyleConstants.white16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void showApplySuccessDialog(String message, {String? subtitle}) {
    showPanelApplySuccessDialog(
      uiContext,
      dashboardController.bleManager.bleProcess,
      message,
      subtitle: subtitle,
    );
  }

  @override
  void showDownloadSuccessDialog(String message) {
    showDialog(
      context: uiContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.successBackgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AssetConstants.checkCircleIcon,
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  message ==
                          StringConstants
                              .liveDataIsBeingStreamedFromTheDeviceInRealTime
                      ? "Live Diagnostics Active"
                      : "$message Downloaded",
                  style: StyleConstants.textDark20w700Style,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Visibility(
                  visible:
                      !dashboardController
                          .ble
                          .bleProcess
                          .isLbusFetchHasErrors
                          .value,
                  child: Text(
                    message ==
                            StringConstants
                                .liveDataIsBeingStreamedFromTheDeviceInRealTime
                        ? StringConstants
                            .theMessageHasBeenSuccessfullyDownloadedFromTheDevice
                        : 'The $message has been successfully downloaded from the device.',
                    style: StyleConstants.textMuted14w400Style,
                    textAlign: TextAlign.center,
                  ),
                ),
                Visibility(
                  visible:
                      dashboardController
                          .ble
                          .bleProcess
                          .isLbusFetchHasErrors
                          .value,
                  child: Text(
                    StringConstants.thereWasAnErrorDownloading,
                    style: StyleConstants.textMuted14w400Style,
                    textAlign: TextAlign.center,
                  ),
                ),
                Visibility(
                  visible:
                      dashboardController
                          .ble
                          .bleProcess
                          .isLbusFetchHasErrors
                          .value,
                  child: Text(
                    'L-Bus ${dashboardController.ble.bleProcess.lbusFetchErrors.value.join(", ")} - Comms Fault',
                    style: StyleConstants.primary14w400Style,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void showDiagnosticStopDialog() {
    showDialog(
      context: uiContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ColorConstants.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: ColorConstants.successBackgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AssetConstants.checkCircleIcon,
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  StringConstants.liveDiagnosticsStopped,
                  style: StyleConstants.textDark20w700Style,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  StringConstants.liveDataStreamingFromTheDeviceHasBeenStopped,
                  style: StyleConstants.textMuted14w400Style,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  void showConfigLogBottomSheet() {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => ConfigLogBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            compareResult: dashboardController.configLogCompareResult,
            isWorking: dashboardController.configLogWorking,
            onDownloadAndCompare:
                dashboardController.onConfigLogDownloadAndCompare,
            onUsePanelDataInApp:
                dashboardController.onConfigLogUsePanelDataInApp,
            onApplyLocalToPanel:
                dashboardController.onConfigLogApplyLocalToPanel,
          ),
    ).whenComplete(dashboardController.clearConfigLogState);
  }

  @override
  void showPasswordPopup({
    required Function() onCall,
    bool? isExtOut = false,
    bool? isInputSetup = false,
    bool? isRelaySetup = false,
    bool? isZoneSetup = false,
    bool? isLBusSetup = false,
    bool? isSounderSetup = false,
    bool? isServiceDueSetup = false,
    bool? isAccessCodeSetup = false,
    bool? isPanelInfoSetup = false,
    bool? isGeneralModuleSetup = false,
    bool? isAdcSetup = false,
    bool isConfigLogBulk = false,
    bool isConfigLogBulkApply = false,
    bool showDetailedConfigLogBulkBleProgressInAccessDialog = true,
    String? mode,
    Future<void> Function()? onDownloadComplete,
    String? downloadSuccessMessage,
    Future<void> Function(BuildContext context)? onAfterApplySuccess,
  }) {
    showPanelAccessPasswordPopup(
      context: uiContext,
      isMounted: () => mounted,
      bleManager: dashboardController.bleManager,
      bleController: dashboardController.bleController,
      selectedDevice: dashboardController.selectedDevice,
      navigatingToDeviceConnecting:
          dashboardController.navigatingToDeviceConnecting,
      delegates: PanelAccessPasswordDelegates(
        saveExtOutCache: dashboardController.saveExtOutCacheAndNotifyRefresh,
        saveInputCache: dashboardController.saveInputCacheAndNotifyRefresh,
        saveRelayCache: dashboardController.saveRelayCacheAndNotifyRefresh,
        saveZoneCache: dashboardController.saveZoneCacheAndNotifyRefresh,
        saveRadioCache: dashboardController.saveRadioCacheAndNotifyRefresh,
        saveLBusCache: dashboardController.saveLBusCacheAndNotifyRefresh,
        saveSounderCache: dashboardController.saveSounderCacheAndNotifyRefresh,
        saveServiceDueCache:
            dashboardController.saveServiceDueCacheAndNotifyRefresh,
        saveAccessCodeCache:
            dashboardController.saveAccessCodeCacheAndNotifyRefresh,
        savePanelInfoCache:
            dashboardController.savePanelInfoCacheAndNotifyRefresh,
        saveGeneralModuleCache:
            dashboardController.saveGeneralModuleCacheAndNotifyRefresh,
        showApplySuccess:
            (ctx, message, {subtitle}) =>
                showApplySuccessDialog(message, subtitle: subtitle),
        showDownloadSuccess:
            (ctx, message) => showDownloadSuccessDialog(message),
        openLogRetrievalLoading: (dialogContext) {
          LogBinding(
            args: LogFlowArgs.loading(
              scanType: ScanType.bluetooth,
              selectedDevice: dashboardController.selectedDevice,
              connectedDevice: dashboardController.selectedDevice,
              siteId: dashboardController.siteId,
              fromProjectDashboard: true,
            ),
          ).dependencies();
          Navigator.of(dialogContext).push(
            MaterialPageRoute(
              builder: (_) => const LogRetrievalLoadingScreen(),
            ),
          );
        },
        afterBulkApplyAccessGranted:
            (isConfigLogBulkApply && mode == 'bottomsheet_apply')
                ? () async {
                  try {
                    await PanelConfigBulkSync.runConfigLogApplyRemaining(
                      dashboardController.bleController,
                      dashboardController.bleManager,
                    );
                    await dashboardController.saveAllPeripheralCachesFromBle();
                    if (!mounted) return;
                    dashboardController.configLogCompareResult.value =
                        await PanelConfigBulkSync.buildConfigCompareResultFromCache(
                          dashboardController.bleManager,
                          dashboardController.selectedDevice.id,
                        );
                    if (!mounted) return;
                    showApplySuccessDialog(
                      StringConstants.configuration,
                      subtitle:
                          StringConstants
                              .yourSavedSetupHasBeenAppliedToThePanel,
                    );
                  } finally {
                    dashboardController.bleManager.bleProcess
                        .clearPeripheralApplyDoneFlags();
                  }
                }
                : null,
      ),
      onCall: onCall,
      isExtOut: isExtOut ?? false,
      isInputSetup: isInputSetup ?? false,
      isRelaySetup: isRelaySetup ?? false,
      isZoneSetup: isZoneSetup ?? false,
      isLBusSetup: isLBusSetup ?? false,
      isSounderSetup: isSounderSetup ?? false,
      isServiceDueSetup: isServiceDueSetup ?? false,
      isAccessCodeSetup: isAccessCodeSetup ?? false,
      isPanelInfoSetup: isPanelInfoSetup ?? false,
      isGeneralModuleSetup: isGeneralModuleSetup ?? false,
      isAdcSetup: isAdcSetup ?? false,
      isConfigLogBulk: isConfigLogBulk,
      isConfigLogBulkApply: isConfigLogBulkApply,
      showDetailedConfigLogBulkBleProgressInAccessDialog:
          showDetailedConfigLogBulkBleProgressInAccessDialog,
      mode: mode,
      onDownloadComplete: onDownloadComplete,
      downloadSuccessMessage: downloadSuccessMessage,
      onAfterApplySuccess: onAfterApplySuccess,
      configLogWorking: dashboardController.configLogWorking,
    );
  }

  @override
  void showLBusSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => LBusBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showSounderSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => SounderModeBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showServiceDueSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => ServiceDueBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showAccessCodeSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => AccessCodesBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showPanelInfoSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => PanelInfoBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showGeneralModuleSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => GeneralModuleBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showAdcDiagnosticsSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onStop,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => DiagnosticInfoBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onStop: onStop,
          ),
    ).whenComplete(() {
      if (!mounted) return;
      dashboardController.ble.bleProcess.isAdcSetupFetchCommandActive.value =
          false;
    });
  }

  @override
  void showModuleSetupBottomSheet({required VoidCallback onDownload}) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => ModuleInfoBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
          ),
    );
  }

  @override
  void showExtOutBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => ExtOutBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showInputSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => InputModeBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showRelaySetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => RelayModeBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showZoneSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => ZoneBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showWalkTestZoneBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => WalkTestZoneBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showTestModeSounderBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => TestModeSounderBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showTestModeRelayBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => TestModeRelayBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  @override
  void showTestModeChoiceBottomSheet({
    required VoidCallback onDownloadRelays,
    required VoidCallback onDownloadSounders,
    required VoidCallback onApplyRelays,
    required VoidCallback onApplySounders,
    required ValueNotifier<int> relayRefreshTrigger,
    required ValueNotifier<int> sounderRefreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder: (sheetContext) {
        return TestModeChoiceBottomSheet(
          onSounders: () {
            Navigator.pop(sheetContext);
            showTestModeSounderBottomSheet(
              onDownload: onDownloadSounders,
              onApply: onApplySounders,
              refreshTrigger: sounderRefreshTrigger,
            );
          },
          onRelays: () {
            Navigator.pop(sheetContext);
            showTestModeRelayBottomSheet(
              onDownload: onDownloadRelays,
              onApply: onApplyRelays,
              refreshTrigger: relayRefreshTrigger,
            );
          },
        );
      },
    );
  }

  @override
  void showRadioSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showDashboardPeripheralSheet(
      uiContext,
      builder:
          (_) => RadioModeBottomSheet(
            deviceId: dashboardController.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }
}
