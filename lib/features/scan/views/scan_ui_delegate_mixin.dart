import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/bindings/project_dashboard_binding.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/dashboard/views/project_dashboard.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/views/event_log_screen.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/features/scan/bindings/scan_binding.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/views/scanned_screen.dart';
import 'package:techno_switch_solar_app/features/scan/views/scanning_screen.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/panel_config/post_connect_bulk_download_offer.dart'
    as post_connect_offer;
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/panel_access_code_dialog.dart'
    as panel_access_dialog;

mixin ScanUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements ScanUiDelegate {
  ScanController get scanController;

  BleManager get _bleManager => Get.find<BleManager>();

  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  void showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      uiContext,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void popScreen() {
    if (!mounted) return;
    Navigator.of(uiContext).pop();
  }

  @override
  void popWithResult(bool result) {
    if (!mounted) return;
    Navigator.of(uiContext, rootNavigator: true).pop(result);
  }

  @override
  void showBluetoothOffDialog() {
    if (!mounted) return;
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
                  decoration: const BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bluetooth_disabled,
                      size: 32,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.turnOnBluetooth,
                  style: StyleConstants.textDark20w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants
                      .bluetoothIsOffPleaseEnableBluetoothToContinueScanning,
                  style: StyleConstants.textMuted14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                      Navigator.of(uiContext).pop();
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
  }

  @override
  Future<void> showWrongPanelTypeDialog({
    required String expected,
    required String received,
  }) {
    return showDialog<void>(
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
                  decoration: const BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: ColorConstants.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.wrongPanelType,
                  style: StyleConstants.textDark20w700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This device does not match the panel type you selected ($expected). '
                  'The connected panel reported: $received.',
                  style: StyleConstants.textMuted14w400Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.5),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
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
  }

  @override
  Future<int?> promptUserToPickOrCreateSite({
    required List<SiteModel> sites,
    required String panelId,
    required String panelName,
  }) async {
    if (!mounted) return null;

    if (sites.isEmpty) {
      final shouldCreate = await showDialog<bool>(
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
                    decoration: const BoxDecoration(
                      color: ColorConstants.errorIconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.domain_add,
                        size: 32,
                        color: ColorConstants.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    StringConstants.createASite,
                    style: StyleConstants.textDark20w700Style,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UiStrings.panelNotAssociatedCreateSiteMessage,
                    style: StyleConstants.textMuted14w400Style,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: const BorderSide(
                              color: ColorConstants.primary,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                            _bleManager.disconnectConnectedDevice();
                          },
                          child: Text(
                            StringConstants.cancel,
                            style: StyleConstants.primary14w600Style,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          child: Text(
                            UiStrings.createButton,
                            style: StyleConstants.white14w600Style,
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

      if (shouldCreate != true) return null;

      return openSimpleSiteCreationForSitePicker(
        panelId: panelId,
        panelName: panelName,
      );
    }

    SiteModel? selected;
    final action = await showDialog<String>(
      context: uiContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        const double siteRowHeight = 64;
        const int maxVisibleSites = 3;

        final visibleCount =
            sites.length < maxVisibleSites ? sites.length : maxVisibleSites;

        final listHeight =
            visibleCount * siteRowHeight + ((visibleCount - 1) * 8);

        return StatefulBuilder(
          builder: (_, setState) {
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
                      decoration: const BoxDecoration(
                        color: ColorConstants.errorIconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_city,
                          size: 32,
                          color: ColorConstants.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      StringConstants.selectASite,
                      style: StyleConstants.textDark20w700Style,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      StringConstants
                          .chooseTheSiteWhereThisPanelShouldBeAssigned,
                      style: StyleConstants.textMuted14w400Style,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: listHeight.toDouble(),
                      child: ListView.separated(
                        physics:
                            sites.length > maxVisibleSites
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                        itemCount: sites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final site = sites[index];
                          final isSelected = selected?.id == site.id;

                          return GestureDetector(
                            onTap: () => setState(() => selected = site),
                            child: Container(
                              height: siteRowHeight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? ColorConstants.primary.withOpacity(
                                          0.08,
                                        )
                                        : ColorConstants.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? ColorConstants.primary
                                          : ColorConstants.borderLight,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          site.siteName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              StyleConstants
                                                  .textDark14w600Style,
                                        ),
                                        if (site.companyName
                                                .trim()
                                                .isNotEmpty ||
                                            site.buildingName.trim().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              [
                                                    site.companyName.trim(),
                                                    site.buildingName.trim(),
                                                  ]
                                                  .where((s) => s.isNotEmpty)
                                                  .join(
                                                    StringConstants.str6b6dfb41,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  StyleConstants
                                                      .textMuted12w400Style,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: ColorConstants.primary,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed:
                                selected == null
                                    ? null
                                    : () => Navigator.of(
                                      dialogContext,
                                    ).pop('select'),
                            child: Text(
                              StringConstants.disabled,
                              style: StyleConstants.white14w600Style,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop('cancel');
                                  _bleManager.disconnectConnectedDevice();
                                },
                                child: Text(
                                  StringConstants.cancel,
                                  style: StyleConstants.textMuted14w500Style,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  side: const BorderSide(
                                    color: ColorConstants.primary,
                                    width: 1.5,
                                  ),
                                  backgroundColor: ColorConstants.primary
                                      .withOpacity(0.04),
                                ),
                                onPressed:
                                    () => Navigator.of(
                                      dialogContext,
                                    ).pop('create'),
                                child: Text(
                                  UiStrings.createButton,
                                  style: StyleConstants.primary14w600Style,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (action == 'select') return selected?.id;
    if (action == 'create') {
      return openSimpleSiteCreationForSitePicker(
        panelId: panelId,
        panelName: panelName,
      );
    }

    return null;
  }

  @override
  Future<int?> openSimpleSiteCreationForSitePicker({
    required String panelId,
    required String panelName,
  }) {
    SimpleSiteCreationBinding(
      args: SimpleSiteCreationArgs(
        retrievedLogs: const [],
        panelName: panelName,
        panelVersionNo: '',
        panelId: panelId,
        returnCreatedSiteId: true,
      ),
    ).dependencies();
    return Navigator.of(uiContext).push<int?>(
      MaterialPageRoute(builder: (_) => const SimpleSiteCreationScreen()),
    );
  }

  @override
  void replaceWithScannedScreen() {
    Navigator.of(
      uiContext,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const ScannedScreen()));
  }

  @override
  Future<bool?> pushScannedScreen() {
    return Navigator.of(
      uiContext,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ScannedScreen()));
  }

  @override
  Future<void> openScanAgain({required ScanFlowArgs scanningArgs}) async {
    await NavigationService.navigateToScanAgain(uiContext);
    if (!mounted) return;
    ScanBinding(args: scanningArgs).dependencies();
    Navigator.of(uiContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ScanningScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  void navigateToProjectDashboard({required ProjectDashboardArgs args}) {
    ProjectDashboardBinding(args: args).dependencies();
    Navigator.of(uiContext, rootNavigator: true).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProjectDashboardScreen()),
    );
  }

  @override
  void navigateToEventLog({required LogFlowArgs args}) {
    LogBinding(args: args).dependencies();
    Navigator.of(uiContext, rootNavigator: true).pushReplacement(
      MaterialPageRoute(builder: (_) => const EventLogScreen()),
    );
  }

  @override
  void navigateToLogRetrievalLoading({required LogFlowArgs args}) {
    LogBinding(args: args).dependencies();
    Navigator.of(uiContext).push(
      MaterialPageRoute(builder: (_) => const LogRetrievalLoadingScreen()),
    );
  }

  @override
  Future<bool> showPanelAccessCodeGatewayDialog({
    required Future<void> Function() onStartValidation,
  }) {
    return panel_access_dialog.showPanelAccessCodeGatewayDialog(
      context: uiContext,
      onStartValidation: onStartValidation,
    );
  }

  @override
  Future<bool> showPanelAccessCodeLogRetrievalSheet({
    required DiscoveredDevice device,
    bool? isLiveEvent,
    required Future<void> Function() onStartValidation,
  }) {
    return panel_access_dialog.showPanelAccessCodeLogRetrievalSheet(
      context: uiContext,
      device: device,
      isLiveEvent: isLiveEvent,
      onStartValidation: onStartValidation,
    );
  }

  @override
  Future<void> offerOptionalFullConfigDownloadAfterConnect({
    required DiscoveredDevice device,
    required bool panelHadNoSiteBeforeConnect,
  }) {
    return post_connect_offer.offerOptionalFullConfigDownloadAfterConnect(
      context: uiContext,
      isMounted: () => mounted,
      device: device,
      awaitDownloadIfAccepted: true,
      showConfigLogCompareAfterDownload: true,
      panelHadNoSiteBeforeConnect: panelHadNoSiteBeforeConnect,
    );
  }

  @override
  void showConnectingDialog(
    DiscoveredDevice device, {
    VoidCallback? onPauseAnimations,
    VoidCallback? onResumeAnimations,
    bool isScanningConnectFlow = false,
  }) {
    final bleController = Get.find<BleLogController>();
    final connectionNotifier = bleController.bleManager.isConnectedNotifier;
    final handshakeCompleteNotifier =
        bleController.bleManager.handshakeCompleteNotifier;
    final maxRetriesNotifier =
        bleController.bleManager.maxBleConnectionRetriesReached;
    final networkCommFailureNotifier =
        bleController.bleProcess.communicationFailureMessage;
    final maxOtherPacketsRetriesNotifier =
        bleController.bleProcess.maxOtherPacketsRetriesReached;

    bool hasNavigated = false;

    final mergedListenable = Listenable.merge([
      connectionNotifier,
      handshakeCompleteNotifier,
      maxRetriesNotifier,
      networkCommFailureNotifier,
      maxOtherPacketsRetriesNotifier,
    ]);

    showDialog<bool>(
      context: uiContext,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: mergedListenable,
          builder: (_, __) {
            final isConnected = connectionNotifier.value;
            final handshakeComplete = handshakeCompleteNotifier.value;
            final maxRetries = maxRetriesNotifier.value;
            final networkCommMessage = networkCommFailureNotifier.value;
            final showNetworkCommError =
                networkCommMessage != null && networkCommMessage.isNotEmpty;
            final showConnectionError = maxRetries || showNetworkCommError;

            if (isScanningConnectFlow &&
                isConnected &&
                !scanController.bleConnectPauseApplied) {
              scanController.bleConnectPauseApplied = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onPauseAnimations?.call();
              });
            }

            if (handshakeComplete &&
                !hasNavigated &&
                !maxRetries &&
                !showNetworkCommError) {
              hasNavigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext, rootNavigator: true).pop(true);

                await Future.delayed(const Duration(milliseconds: 150));

                if (!mounted) return;

                await scanController.handlePostConnectRouting(
                  device: device,
                  onResumeAnimations: onResumeAnimations,
                  resolveBootloader: true,
                );
              });
            }

            final retryHint =
                isScanningConnectFlow
                    ? StringConstants.pleaseScanAgainAndReconnect
                    : StringConstants.pleaseScanAgainAndConnectToTheDevice;

            final preparingMessage =
                isScanningConnectFlow
                    ? StringConstants.preparingDashboard
                    : StringConstants.preparingToNavigate;

            String connectionTitle;
            if (showNetworkCommError) {
              connectionTitle = StringConstants.connectionProblem;
            } else if (maxRetries) {
              connectionTitle = StringConstants.maxConnectionRetriesReached;
            } else if (handshakeComplete) {
              connectionTitle = 'Device Connected!';
            } else if (isConnected) {
              connectionTitle =
                  isScanningConnectFlow
                      ? 'Device Connected!'
                      : 'Establishing secure connection...';
            } else {
              connectionTitle = StringConstants.establishingSecureConnection;
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            handshakeComplete && !showConnectionError
                                ? Colors.green.withValues(alpha: 0.1)
                                : ColorConstants.errorIconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            handshakeComplete && !showConnectionError
                                ? const Icon(
                                  Icons.check_circle,
                                  size: 32,
                                  color: Colors.green,
                                )
                                : showNetworkCommError
                                ? const Icon(
                                  Icons.error_outline,
                                  size: 32,
                                  color: ColorConstants.primary,
                                )
                                : Lottie.asset(
                                  AssetConstants.bleConnectingJson,
                                  animate: !showConnectionError,
                                ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      connectionTitle,
                      style: StyleConstants.textDark20w700Style,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      maxRetries
                          ? retryHint
                          : showNetworkCommError
                          ? networkCommMessage
                          : handshakeComplete
                          ? preparingMessage
                          : isConnected
                          ? StringConstants.encryptingAndAuthenticating
                          : 'Please wait while we connect to ${device.name}',
                      style: StyleConstants.textMuted14w400Style,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (showConnectionError)
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
                            if (showNetworkCommError) {
                              bleController.bleProcess
                                  .clearCommunicationFailure();
                            }
                            if (isScanningConnectFlow) {
                              scanController.bleConnectPauseApplied = false;
                              onResumeAnimations?.call();
                            }
                            Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop();
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
}
