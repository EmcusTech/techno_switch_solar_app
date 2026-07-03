import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/bindings/firmware_binding.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_history_screen.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/features/settings/views/settings_screen.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_controller.dart';
import 'package:techno_switch_solar_app/features/test_mode/views/test_mode_screen.dart';
import 'package:techno_switch_solar_app/panel_config/panel_access_password_popup.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_bulk_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_feedback_dialogs.dart';
import 'package:techno_switch_solar_app/panel_config/post_connect_bulk_download_offer.dart';
import 'package:techno_switch_solar_app/utils/commissioning_test_results_helper.dart';
import 'package:techno_switch_solar_app/utils/storage/commissioning_test_results_cache.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/ble_connecting_dialog.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_msd_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/widgets/export_tile.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/access_code_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/diagnostic_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/general_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/input_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/l_bus_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/module_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/panel_info_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/radio_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/relay_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/service_due_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/setting_bottom_sheets/ext_out_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/config_log_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/sounder_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/test_mode_choice_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/test_mode_relay_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/test_mode_sounder_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/walk_test_zone_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/firmware_upgrade_bottom_sheet.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/panel_access_code_dialog.dart'
    as panel_access_dialog;
import 'package:techno_switch_solar_app/utils/ble/bootloader_connect_flow.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ProjectDashboardScreen extends GetView<ProjectDashboardController> {
  const ProjectDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProjectDashboardPageHost(controller: controller);
  }
}

class _ProjectDashboardPageHost extends StatefulWidget {
  const _ProjectDashboardPageHost({required this.controller});

  final ProjectDashboardController controller;

  @override
  State<_ProjectDashboardPageHost> createState() =>
      _ProjectDashboardPageHostState();
}

class _ProjectDashboardPageHostState extends State<_ProjectDashboardPageHost>
    implements ProjectDashboardUiDelegate {
  ProjectDashboardController get _controller => widget.controller;

  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  void initState() {
    super.initState();
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
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: ColorConstants.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.disconnectDevice,
                  style: StyleConstants.textDark18w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants.goingBackWillDisconnectTheDeviceAreYouSure,
                  style: StyleConstants.textGray14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(false),
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
                              StringConstants.cancel,
                              style: StyleConstants.textGray16w600Style,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(true),
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
                              'Disconnect',
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
    if (!mounted || _controller.isUnexpectedDisconnectDialogOpen) return;
    _controller.isUnexpectedDisconnectDialogOpen = true;
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
                        _controller.markUnexpectedDisconnectDialogClosed();
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
      _controller.markUnexpectedDisconnectDialogClosed();
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
      refreshNotifiers: _controller.panelRefreshNotifiers,
      navigatingToDeviceConnecting: _controller.navigatingToDeviceConnecting,
    );
  }

  @override
  Future<DiscoveredDevice?> resolveBootloaderOnConnect(
    DiscoveredDevice device,
  ) {
    return resolveBootloaderModeOnConnect(
      context: uiContext,
      bleController: _controller.bleController,
      bluetoothService: _controller.bluetoothService,
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
      deviceId: _controller.selectedDevice.id,
      type: CommissioningTestType.walkTest,
      manager: _controller.bleManager,
    );
  }

  @override
  Future<void> showRelayTestResultConfirmation() {
    return showCommissioningTestResultConfirmation(
      context: uiContext,
      deviceId: _controller.selectedDevice.id,
      type: CommissioningTestType.relayTest,
      manager: _controller.bleManager,
    );
  }

  @override
  Future<void> showSounderTestResultConfirmation() {
    return showCommissioningTestResultConfirmation(
      context: uiContext,
      deviceId: _controller.selectedDevice.id,
      type: CommissioningTestType.sounderTest,
      manager: _controller.bleManager,
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
            connectedDevice: _controller.selectedDevice,
          ),
    );
    Get.delete<UpdatesController>();
  }

  @override
  void showConnectingDialog(DiscoveredDevice device) {
    final connectionNotifier =
        _controller.bleController.bleManager.isConnectedNotifier;
    final handshakeCompleteNotifier =
        _controller.bleController.bleManager.handshakeCompleteNotifier;
    final maxBleConnectionRetriesReachedNotifier =
        _controller.bleController.bleManager.maxBleConnectionRetriesReached;
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

  List<Widget> _screens() {
    return [
      _buildDashboardTab(),
      const SettingsScreen(),
      const TestModeScreen(),
      LogHistoryScreen(
        panelName: _controller.panelName,
        panelVersionNo: _controller.panelVersionNo,
        siteId: _controller.siteId,
      ),
    ];
  }

  Widget _buildDashboardTab() {
    return WillPopScope(
      onWillPop: _controller.handleWillPop,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset(AssetConstants.background1),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _controller.handleBackNavigation,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ColorConstants.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ColorConstants.blackMaterial
                                      .withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: ColorConstants.textDark,
                              size: 18,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            StringConstants.projectDashboard,
                            style: StyleConstants.black20w700Style,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showExportBottomSheet(),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SvgPicture.asset(AssetConstants.shareIcon),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildDashboardContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
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
                  _controller.exportProjectPdf();
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
      _controller.selectedDevice.manufacturerData,
    );
    final wantUpgrade = await showBootloaderUpgradeOfferFromDashboardDialog(
      uiContext,
      bootloaderFileCorrupted: bootloaderFileCorrupted,
    );
    if (wantUpgrade != true || !context.mounted) return;

    final upgraded = await showFirmwareUpgradeBottomSheetForConnect(
      context: uiContext,
      connectedDevice: _controller.selectedDevice,
    );
    if (!upgraded || !mounted) return;

    await _controller.bleController.bleManager.disconnectConnectedDevice();

    final refreshed = await runWithBleConnectingDialog<DiscoveredDevice?>(
      context: uiContext,
      device: _controller.selectedDevice,
      bleController: _controller.bleController,
      messages: BleConnectingDialogMessages.afterFirmwareUpgrade,
      operation:
          () => reconnectBleDeviceInAppModeAfterUpgrade(
            bleController: _controller.bleController,
            bluetoothService: _controller.bluetoothService,
            originalDevice: _controller.selectedDevice,
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

    _controller.updateSelectedDevice(refreshed);

    _controller.bleController.bleProcess.clearSessionAccessCode();
    final ok = await panel_access_dialog.showPanelAccessCodeGatewayDialog(
      context: uiContext,
      onStartValidation:
          () => _controller.bleController.startSessionAccessCodeValidation(),
    );
    if (!ok || !mounted) {
      _controller.bleController.bleManager.disconnectConnectedDevice();
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
                          await _controller.connectToDeviceByName();
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
      _controller.bleManager.bleProcess,
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
                      !_controller.ble.bleProcess.isLbusFetchHasErrors.value,
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
                      _controller.ble.bleProcess.isLbusFetchHasErrors.value,
                  child: Text(
                    StringConstants.thereWasAnErrorDownloading,
                    style: StyleConstants.textMuted14w400Style,
                    textAlign: TextAlign.center,
                  ),
                ),
                Visibility(
                  visible:
                      _controller.ble.bleProcess.isLbusFetchHasErrors.value,
                  child: Text(
                    'L-Bus ${_controller.ble.bleProcess.lbusFetchErrors.value.join(", ")} - Comms Fault',
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => ConfigLogBottomSheet(
            deviceId: _controller.selectedDevice.id,
            compareResult: _controller.configLogCompareResult,
            isWorking: _controller.configLogWorking,
            onDownloadAndCompare: _controller.onConfigLogDownloadAndCompare,
            onUsePanelDataInApp: _controller.onConfigLogUsePanelDataInApp,
            onApplyLocalToPanel: _controller.onConfigLogApplyLocalToPanel,
          ),
    ).whenComplete(_controller.clearConfigLogState);
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
      bleManager: _controller.bleManager,
      bleController: _controller.bleController,
      selectedDevice: _controller.selectedDevice,
      navigatingToDeviceConnecting: _controller.navigatingToDeviceConnecting,
      delegates: PanelAccessPasswordDelegates(
        saveExtOutCache: _controller.saveExtOutCacheAndNotifyRefresh,
        saveInputCache: _controller.saveInputCacheAndNotifyRefresh,
        saveRelayCache: _controller.saveRelayCacheAndNotifyRefresh,
        saveZoneCache: _controller.saveZoneCacheAndNotifyRefresh,
        saveRadioCache: _controller.saveRadioCacheAndNotifyRefresh,
        saveLBusCache: _controller.saveLBusCacheAndNotifyRefresh,
        saveSounderCache: _controller.saveSounderCacheAndNotifyRefresh,
        saveServiceDueCache: _controller.saveServiceDueCacheAndNotifyRefresh,
        saveAccessCodeCache: _controller.saveAccessCodeCacheAndNotifyRefresh,
        savePanelInfoCache: _controller.savePanelInfoCacheAndNotifyRefresh,
        saveGeneralModuleCache:
            _controller.saveGeneralModuleCacheAndNotifyRefresh,
        showApplySuccess:
            (ctx, message, {subtitle}) =>
                showApplySuccessDialog(message, subtitle: subtitle),
        showDownloadSuccess:
            (ctx, message) => showDownloadSuccessDialog(message),
        openLogRetrievalLoading: (dialogContext) {
          LogBinding(
            args: LogFlowArgs.loading(
              scanType: ScanType.bluetooth,
              selectedDevice: _controller.selectedDevice,
              connectedDevice: _controller.selectedDevice,
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
                      _controller.bleController,
                      _controller.bleManager,
                    );
                    await _controller.saveAllPeripheralCachesFromBle();
                    if (!mounted) return;
                    _controller.configLogCompareResult.value =
                        await PanelConfigBulkSync.buildConfigCompareResultFromCache(
                          _controller.bleManager,
                          _controller.selectedDevice.id,
                        );
                    if (!mounted) return;
                    showApplySuccessDialog(
                      StringConstants.configuration,
                      subtitle:
                          StringConstants
                              .yourSavedSetupHasBeenAppliedToThePanel,
                    );
                  } finally {
                    _controller.bleManager.bleProcess
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
      configLogWorking: _controller.configLogWorking,
    );
  }

  Widget _buildDashboardContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPanelInfoHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      _buildPeripheralOverview(),
                      _buildPanelActions(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelInfoHeader() {
    return Row(
      children: [
        SvgPicture.asset(AssetConstants.panelIcon, height: 62, width: 62),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                BleNameUtils.getDisplayPrefixFromBleName(_controller.panelName),
                style: StyleConstants.black16w700Style,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                BleNameUtils.getDisplayIdFromBleName(_controller.panelName),
                style: StyleConstants.textDisabled14w500Style,
                overflow: TextOverflow.ellipsis,
              ),
              ValueListenableBuilder(
                valueListenable: _controller.ble.isConnectedNotifier,
                builder: (context, isConnected, child) {
                  if (isConnected) {
                    return Text(
                      StringConstants.connected,
                      style: StyleConstants.success14w500Style,
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: StringConstants.disconnected,
                                  style: StyleConstants.primary14w500Style,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),

        ValueListenableBuilder(
          valueListenable: _controller.ble.isConnectedNotifier,
          builder: (context, isConnected, child) {
            if (!isConnected) {
              return GetBuilder<ProjectDashboardController>(
                builder:
                    (c) =>
                        c.isConnecting
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorConstants.primary,
                                ),
                              ),
                            )
                            : GestureDetector(
                              onTap: _controller.connectToDeviceByName,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstants.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Connect',
                                  style: StyleConstants.white12w600Style,
                                ),
                              ),
                            ),
              );
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPeripheralOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConstants.peripheralOverview,
          style: StyleConstants.black16w700Style,
        ),
        SizedBox(height: 8),
        SizedBox(
          height:
              (MediaQuery.of(context).size.height +
                  MediaQuery.of(context).size.width) *
              0.2,
          width: double.infinity,
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _peripheralTile(
                peripheralName: StringConstants.relays,
                iconPath: AssetConstants.peripheralRelayIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showRelaySetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isRelaySetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startRelaySetupFetch();
                        },
                        isRelaySetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveRelayCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isRelaySetupCommandApplyActive
                              .value = true;
                          _controller.bleController.startRelaySetupApply();
                        },
                        isRelaySetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.relayRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.inputs,
                iconPath: AssetConstants.peripheralInputIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showInputSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isInputSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startInputSetupFetch();
                        },
                        isInputSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveInputCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isInputSetupApplyActive
                              .value = true;
                          _controller.bleController.startInputSetupApply();
                        },
                        isInputSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.inputRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.zones,
                iconPath: AssetConstants.peripheralZonesIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showZoneSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isZoneSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startZoneSetupFetch();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveZoneCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isZoneSetupCommandApplyActive
                              .value = true;
                          _controller.bleController.startZoneSetupApply();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.sounders,
                iconPath: AssetConstants.peripheralSounderIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showSounderSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isSounderSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startSounderSetupFetch();
                        },
                        isSounderSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveSounderCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Sounder',
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isSounderSetupApplyCommandActive
                              .value = true;
                          _controller.bleController.startSounderSetupApply();
                        },
                        isSounderSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.sounderRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.radio,
                iconPath: AssetConstants.peripheralProgHoldIcon,
                isDisabled: true,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showRadioSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isRadioSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startRadioSetupFetch();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveRadioCacheAndNotifyRefresh,
                        downloadSuccessMessage: StringConstants.radio,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isRadioSetupCommandApplyActive
                              .value = true;
                          _controller.bleController.startRadioSetupApply();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.moduleInfo,
                iconPath: AssetConstants.peripheralAuxIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showModuleSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isModuleSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startModuleSetupFetch();
                        },
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveModuleCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Module',
                      );
                    },
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.lBus,
                iconPath: AssetConstants.peripheralLBusIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showLBusSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isLBusSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startLBusSetupFetch();
                        },
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveLBusCacheAndNotifyRefresh,
                        downloadSuccessMessage: StringConstants.lBus,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isLBusSetupApplyCommandActive
                              .value = true;
                          _controller.bleController.startLBusSetupApply();
                        },
                        isLBusSetup: true,
                        mode: 'bottomsheet_apply',
                        downloadSuccessMessage: StringConstants.lBus,
                      );
                    },
                    refreshTrigger: _controller.zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.extOut2,
                iconPath: AssetConstants.peripheralExtOutIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showExtOutBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isExtOutCommandFetchActive
                              .value = true;
                          _controller.bleController.startExtOutFetch();
                        },
                        isExtOut: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveExtOutCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isExtOutCommandApplyActive
                              .value = true;
                          _controller.bleController.startExtOutApply();
                        },
                        isExtOut: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.extOutRefreshTrigger,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void showLBusSetupBottomSheet({
    required VoidCallback onDownload,
    required VoidCallback onApply,
    required ValueNotifier<int> refreshTrigger,
  }) {
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => LBusBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => SounderModeBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => ServiceDueBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => AccessCodesBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => PanelInfoBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => GeneralModuleBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => DiagnosticInfoBottomSheet(
            deviceId: _controller.selectedDevice.id,
            onDownload: onDownload,
            onStop: onStop,
          ),
    ).whenComplete(() {
      if (!mounted) return;
      _controller.ble.bleProcess.isAdcSetupFetchCommandActive.value = false;
    });
  }

  @override
  void showModuleSetupBottomSheet({required VoidCallback onDownload}) {
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => ModuleInfoBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => ExtOutBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => InputModeBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => RelayModeBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => ZoneBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => WalkTestZoneBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => TestModeSounderBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => TestModeRelayBottomSheet(
            deviceId: _controller.selectedDevice.id,
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
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
    showModalBottomSheet(
      context: uiContext,
      isScrollControlled: true,
      backgroundColor: ColorConstants.transparent,
      barrierColor: ColorConstants.blackMaterial.withOpacity(0.4),
      builder:
          (_) => RadioModeBottomSheet(
            deviceId: _controller.selectedDevice.id,
            onDownload: onDownload,
            onApply: onApply,
            refreshTrigger: refreshTrigger,
          ),
    );
  }

  Widget _peripheralTile({
    required String peripheralName,
    required String iconPath,
    VoidCallback? onTap,
    bool? isDisabled = false,
  }) {
    return GestureDetector(
      onTap: () async {
        if (isDisabled == true) return;
        await _controller.onPeripheralTileTap(onTap);
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ColorConstants.backgroundSubtle,
                border: Border.all(color: ColorConstants.borderMedium),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  colorFilter: ColorFilter.mode(
                    isDisabled == true
                        ? ColorConstants.textGray.withValues(alpha: 0.2)
                        : ColorConstants.primary,
                    BlendMode.srcIn,
                  ),
                  height:
                      iconPath.contains("general_module")
                          ? 36
                          : iconPath.contains("peripheral_prog_hold_icon")
                          ? 24
                          : iconPath.contains("walk_test_icon")
                          ? 32
                          : null,
                  width:
                      iconPath.contains("general_module")
                          ? 36
                          : iconPath.contains("peripheral_prog_hold_icon")
                          ? 24
                          : iconPath.contains("walk_test_icon")
                          ? 32
                          : null,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(peripheralName, style: StyleConstants.textSecondary10w500Style),
        ],
      ),
    );
  }

  Widget _buildPanelActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StringConstants.panelActions,
          style: StyleConstants.black16w700Style,
        ),
        SizedBox(height: 8),
        SizedBox(
          height:
              (MediaQuery.of(context).size.height +
                  MediaQuery.of(context).size.width) *
              0.35,
          width: double.infinity,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _peripheralTile(
                peripheralName: StringConstants.eventLog,
                iconPath: AssetConstants.panelActionEventLogIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showPasswordPopup(
                    onCall: () {
                      _controller
                          .ble
                          .bleProcess
                          .isEventLogRetrievalFetchCommandActive
                          .value = true;
                      _controller.bleController.startLogRetrieval();
                    },
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.fwUpgrade,
                iconPath: AssetConstants.firmwareIcon,
                onTap: showFirmwareUpgradeBottomSheet,
              ),
              _peripheralTile(
                peripheralName: StringConstants.serviceDue,
                iconPath: AssetConstants.panelActionServiceDueIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showServiceDueSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isServiceDueFetchCommandActive
                              .value = true;
                          _controller.bleController.startServiceDueFetch();
                        },
                        isServiceDueSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveServiceDueCacheAndNotifyRefresh,
                        downloadSuccessMessage: StringConstants.serviceDue,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isServiceDueApplyCommandActive
                              .value = true;
                          _controller.bleController.startServiceDueApply();
                        },
                        isServiceDueSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.serviceDueRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.accessCode,
                iconPath: AssetConstants.panelActionAccessCodeIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }

                  showAccessCodeSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isAccessCodeSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startAccessCodeSetupFetch();
                        },
                        isAccessCodeSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveAccessCodeCacheAndNotifyRefresh,
                        downloadSuccessMessage: StringConstants.accessCode,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isAccessCodeSetupApplyCommandActive
                              .value = true;
                          _controller.bleController.startAccessCodeSetupApply();
                        },
                        isAccessCodeSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.accessCodeRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.panelInfo,
                iconPath: AssetConstants.panelActionPanelInfoIcon,
                onTap: () {
                  showPanelInfoSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isPanelInfoSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startPanelInfoSetupFetch();
                        },
                        isPanelInfoSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.savePanelInfoCacheAndNotifyRefresh,
                        downloadSuccessMessage: StringConstants.panelInfo,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isPanelInfoSetupApplyCommandActive
                              .value = true;
                          _controller.bleController.startPanelInfoSetupApply();
                        },
                        isPanelInfoSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.panelInfoRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: 'General',
                iconPath: AssetConstants.panelActionGeneralModuleIcon,
                onTap: () {
                  showGeneralModuleSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isGeneralModuleSetupFetchCommandActive
                              .value = true;
                          _controller.bleController
                              .startGeneralModuleSetupFetch();
                        },
                        isGeneralModuleSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveGeneralModuleCacheAndNotifyRefresh,
                        downloadSuccessMessage: StringConstants.generalModule,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isGeneralModuleSetupApplyCommandActive
                              .value = true;
                          _controller.bleController
                              .startGeneralModuleSetupApply();
                        },
                        isGeneralModuleSetup: true,
                        mode: 'bottomsheet_apply',
                      );
                    },
                    refreshTrigger: _controller.generalModuleRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName:
                    StringConstants
                        .liveDataIsBeingStreamedFromTheDeviceInRealTime,
                iconPath: AssetConstants.diagnosticIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showAdcDiagnosticsSetupBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isAdcSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startAdcSetupFetch();
                        },
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveModuleCacheAndNotifyRefresh,
                        downloadSuccessMessage:
                            StringConstants
                                .liveDataIsBeingStreamedFromTheDeviceInRealTime,
                      );
                    },
                    onStop: () {
                      _controller
                          .ble
                          .bleProcess
                          .isAdcSetupFetchCommandActive
                          .value = false;
                      showDiagnosticStopDialog();
                    },
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.walkTest,
                iconPath: AssetConstants.walkTestIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showWalkTestZoneBottomSheet(
                    onDownload: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isZoneSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startZoneSetupFetch();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveZoneCacheAndNotifyRefresh,
                      );
                    },
                    onApply: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isZoneSetupCommandApplyActive
                              .value = true;
                          _controller.bleController.startZoneSetupApply();
                        },
                        isZoneSetup: true,
                        mode: 'bottomsheet_apply',
                        onAfterApplySuccess:
                            (_) => showWalkTestResultConfirmation(),
                      );
                    },
                    refreshTrigger: _controller.zoneRefreshTrigger,
                  );
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.configLog,
                iconPath: AssetConstants.panelActionConfigLogIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showConfigLogBottomSheet();
                },
              ),
              _peripheralTile(
                peripheralName: StringConstants.testMode,
                iconPath: AssetConstants.peripheralProgHoldIcon,
                onTap: () {
                  if (BleMsdUtils.isBootloader(
                    _controller.selectedDevice.manufacturerData,
                  )) {
                    showBootloaderModeDialog();
                    return;
                  }
                  showTestModeChoiceBottomSheet(
                    onDownloadRelays: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isRelaySetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startRelaySetupFetch();
                        },
                        isRelaySetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveRelayCacheAndNotifyRefresh,
                      );
                    },
                    onDownloadSounders: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isSounderSetupFetchCommandActive
                              .value = true;
                          _controller.bleController.startSounderSetupFetch();
                        },
                        isSounderSetup: true,
                        mode: 'bottomsheet_download',
                        onDownloadComplete:
                            _controller.saveSounderCacheAndNotifyRefresh,
                        downloadSuccessMessage: 'Sounder',
                      );
                    },
                    onApplyRelays: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isRelaySetupCommandApplyActive
                              .value = true;
                          _controller.bleController.startRelaySetupApply();
                        },
                        isRelaySetup: true,
                        mode: 'bottomsheet_apply',
                        onAfterApplySuccess:
                            (_) => showRelayTestResultConfirmation(),
                      );
                    },
                    onApplySounders: () {
                      showPasswordPopup(
                        onCall: () {
                          _controller
                              .ble
                              .bleProcess
                              .isSounderSetupApplyCommandActive
                              .value = true;
                          _controller.bleController.startSounderSetupApply();
                        },
                        isSounderSetup: true,
                        mode: 'bottomsheet_apply',
                        onAfterApplySuccess:
                            (_) => showSounderTestResultConfirmation(),
                      );
                    },
                    relayRefreshTrigger: _controller.relayRefreshTrigger,
                    sounderRefreshTrigger: _controller.sounderRefreshTrigger,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectDashboardController>(
      builder: (c) {
        const disabledIndexes = [1, 2];

        Color itemColor(int index) {
          if (disabledIndexes.contains(index)) {
            return Colors.grey;
          }
          return c.selectedIndex == index
              ? ColorConstants.white
              : ColorConstants.blackMaterial;
        }

        Widget navItem({
          required int index,
          required String label,
          required String asset,
        }) {
          final color = itemColor(index);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                asset,
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: StyleConstants.black12w400Style.copyWith(color: color),
              ),
            ],
          );
        }

        return Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: _screens()[c.selectedIndex],
          bottomNavigationBar: Container(
            height: 80,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.blackMaterial.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: BottomNavigationBar(
                backgroundColor: ColorConstants.primary,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                currentIndex: c.selectedIndex,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                onTap: (index) {
                  if (disabledIndexes.contains(index)) return;
                  c.setSelectedIndex(index);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: navItem(
                      index: 0,
                      label: StringConstants.dashboard,
                      asset: AssetConstants.dashboardIcon,
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: navItem(
                      index: 1,
                      label: StringConstants.settings,
                      asset: AssetConstants.settingIcon,
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: navItem(
                      index: 2,
                      label: StringConstants.testMode,
                      asset: AssetConstants.testModeIcon,
                    ),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: navItem(
                      index: 3,
                      label: StringConstants.logHistory,
                      asset: AssetConstants.logHistoryIcon,
                    ),
                    label: '',
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
