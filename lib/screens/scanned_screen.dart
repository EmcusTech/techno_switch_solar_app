import 'dart:async';
import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/logs/event_log_screen.dart';
import 'package:techno_switch_solar_app/screens/logs/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/panel_site_connect_flow.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/screens/sites/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/panel_config/post_connect_bulk_download_offer.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/panel_access_code_dialog.dart';
import 'package:techno_switch_solar_app/utils/ble/bootloader_connect_flow.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/bluetooth_service.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class ScannedScreen extends StatefulWidget {
  final List<dynamic> discoveredDevices;
  final ScanType scanType;
  final bool? isLiveEvent;
  final bool? isLiveEventLogs;
  final String? createProjectExpectedPanelType;
  final VoidCallback? onCreateProjectPanelVerified;

  const ScannedScreen({
    super.key,
    this.discoveredDevices = const [],
    required this.scanType,
    this.isLiveEvent = false,
    this.isLiveEventLogs = false,
    this.createProjectExpectedPanelType,
    this.onCreateProjectPanelVerified,
  });

  @override
  State<ScannedScreen> createState() => _ScannedScreenState();
}

class _ScannedScreenState extends State<ScannedScreen> {
  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();
  final BleManager _bleManager = Get.find<BleManager>();
  final BluetoothService _bluetoothService = BluetoothService();

  Future<int?> _promptUserToPickOrCreateSite({
    required List<SiteModel> sites,
    required String panelId,
    required String panelName,
  }) async {
    if (!mounted) return null;

    if (sites.isEmpty) {
      final shouldCreate = await showDialog<bool>(
        context: context,
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

      final createdSiteId = await Navigator.of(context).push<int?>(
        MaterialPageRoute(
          builder:
              (_) => SimpleSiteCreationScreen(
                retrievedLogs: const [],
                panelName: panelName,
                panelVersionNo: '',
                panelId: panelId,
                returnCreatedSiteId: true,
              ),
        ),
      );
      return createdSiteId;
    }

    SiteModel? selected;
    final action = await showDialog<String>(
      context: context,
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
      final createdSiteId = await Navigator.of(context).push<int?>(
        MaterialPageRoute(
          builder:
              (_) => SimpleSiteCreationScreen(
                retrievedLogs: const [],
                panelName: panelName,
                panelVersionNo: '',
                panelId: panelId,
                returnCreatedSiteId: true,
              ),
        ),
      );
      return createdSiteId;
    }

    return null;
  }

  Future<int?> _ensureConnectedPanelHasSite({
    required DiscoveredDevice device,
  }) async {
    final bleName = device.name.trim();
    if (bleName.isEmpty) return null;

    final recoveredSiteId =
        await PanelSiteConnectFlow.tryTechnoswitchRecoveredSite(
          context: context,
          device: device,
          panelService: _panelService,
          siteService: _siteService,
        );
    if (recoveredSiteId == -1) return null;
    if (recoveredSiteId != null) return recoveredSiteId;

    try {
      final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
      var existingPanel =
          (logicalId != null
              ? await _panelService.getPanelByPanelId(logicalId)
              : null) ??
          await _panelService.getPanelByPanelId(bleName) ??
          await _panelService.getPanelByBleName(bleName);
      final existingSiteId = existingPanel?.siteId;
      if (existingSiteId != null) return existingSiteId;
    } catch (_) {}

    final sites = await _siteService.getAllSites();
    final pickedSiteId = await _promptUserToPickOrCreateSite(
      sites: sites,
      panelId: bleName,
      panelName: bleName,
    );
    if (pickedSiteId == null) return null;

    final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
    final panel =
        (logicalId != null
            ? await _panelService.getPanelByPanelId(logicalId)
            : null) ??
        await _panelService.getPanelByPanelId(bleName) ??
        await _panelService.getPanelByBleName(bleName);
    final panelIdToUse = panel?.panelId ?? logicalId ?? bleName;
    await _siteService.assignPanelToSite(
      panelIdToUse,
      pickedSiteId,
      panelName: bleName,
    );
    if (logicalId != null) {
      await _panelService.markPanelBleLinked(
        logicalId,
        macAddress: device.id,
        bleName: bleName,
        rssi: device.rssi,
      );
      await PeripheralSetupCache.migrateDeviceCache(
        fromDeviceId: logicalId,
        toDeviceId: device.id,
      );
    }
    return pickedSiteId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
          ),
        ),
        child: Column(
          children: [_buildHeader(context), _buildDevicesIdentified()],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Align(
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 166,
                height: 166,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        SvgPicture.asset(AssetConstants.background1),
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: GestureDetector(
                    onTap: () async {
                      await NavigationService.navigateToScanAgain(context);
                      if (context.mounted) {
                        final navigator = Navigator.of(context);
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const ScanningScreen(),
                          ),
                          (route) => route.isFirst,
                        );
                      }
                    },
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.errorIconBackground,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: SvgPicture.asset(
                          AssetConstants.logo,
                          height: 59.29,
                          width: 51,
                          colorFilter: ColorFilter.mode(
                            ColorConstants.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Text(
                StringConstants.tapToScanAgain,
                style: StyleConstants.textDark14w400Style,
              ),
            ],
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConstants.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.blackMaterial.withOpacity(0.1),
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
        ),
      ],
    );
  }

  Widget _buildDevicesIdentified() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 48),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              StringConstants.panelsIdentified,
              style: StyleConstants.textDark18w700Style,
            ),
          ),
          SizedBox(height: 20),
          widget.discoveredDevices.isEmpty
              ? _buildNoDevicesFound()
              : _buildDevicesList(),
        ],
      ),
    );
  }

  Widget _buildNoDevicesFound() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            widget.scanType == ScanType.usb
                ? Icons.usb_off
                : Icons.bluetooth_disabled,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No ${widget.scanType == ScanType.usb ? 'USB' : StringConstants.bluetooth} Devices Found',
            style: StyleConstants.black16w600Style.copyWith(
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.scanType == ScanType.usb
                ? 'Make sure your solar devices are connected via USB and powered on.'
                : UiStrings.bluetoothPairingModeHintMessage,
            textAlign: TextAlign.center,
            style: StyleConstants.black12w400Style.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _waitForReceivedPanelName(BleLogController bleController) async {
    const attempts = 80;
    for (var i = 0; i < attempts; i++) {
      if (bleController.bleProcess.receivedPanelName.value.trim().isNotEmpty) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  bool _panelTypeMatchesReceived(
    String expectedPanelType,
    String receivedName,
  ) {
    final e = expectedPanelType.trim().toUpperCase();
    final r = receivedName.trim().toUpperCase();
    if (e.isEmpty || r.isEmpty) return false;
    return r.contains(e) || e.contains(r);
  }

  Future<void> _showWrongPanelTypeDialog({
    required BuildContext context,
    required String expected,
    required String received,
  }) {
    return showDialog<void>(
      context: context,
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

  void _showConnectingDialog({
    required DiscoveredDevice device,
    required BuildContext context,
  }) {
    final screenContext = context;
    final bleController = Get.find<BleLogController>();
    final connectionNotifier = bleController.bleManager.isConnectedNotifier;
    final handshakeCompleteNotifier =
        bleController.bleManager.handshakeCompleteNotifier;
    final maxBleConnectionRetriesReachedNotifier =
        bleController.bleManager.maxBleConnectionRetriesReached;
    final networkCommFailureNotifier =
        bleController.bleProcess.communicationFailureMessage;
    final maxOtherPacketsRetriesNotifier =
        bleController.bleProcess.maxOtherPacketsRetriesReached;
    bool hasNavigated = false;

    final mergedListenable = Listenable.merge([
      connectionNotifier,
      handshakeCompleteNotifier,
      maxBleConnectionRetriesReachedNotifier,
      networkCommFailureNotifier,
      maxOtherPacketsRetriesNotifier,
    ]);

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        return ListenableBuilder(
          listenable: mergedListenable,
          builder: (_, __) {
            final isConnected = connectionNotifier.value;
            final handshakeComplete = handshakeCompleteNotifier.value;
            final maxBleConnectionRetriesReached =
                maxBleConnectionRetriesReachedNotifier.value;
            final networkCommMessage = networkCommFailureNotifier.value;
            final showNetworkCommError =
                networkCommMessage != null && networkCommMessage.isNotEmpty;
            final showConnectionError =
                maxBleConnectionRetriesReached || showNetworkCommError;

            // When handshake complete, close dialog and navigate
            if (handshakeComplete &&
                !hasNavigated &&
                !maxBleConnectionRetriesReached &&
                !showNetworkCommError) {
              hasNavigated = true;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext, rootNavigator: true).pop(true);

                await Future.delayed(const Duration(milliseconds: 150));

                if (!screenContext.mounted) return;

                var activeDevice = device;
                if (widget.scanType == ScanType.bluetooth) {
                  final resolvedDevice = await resolveBootloaderModeOnConnect(
                    context: screenContext,
                    bleController: bleController,
                    bluetoothService: _bluetoothService,
                    device: device,
                  );
                  if (resolvedDevice == null) return;
                  activeDevice = resolvedDevice;
                }

                if (widget.isLiveEvent == true) {
                  bleController.bleProcess.processDesc.value = "";
                  if (bleController.bleProcess.sessionAccessCodeReady.value &&
                      bleController.bleProcess.accessKey.value.isNotEmpty) {
                    await bleController.startLogRetrieval();
                    await Future.delayed(const Duration(seconds: 1));
                    if (!screenContext.mounted) return;
                    Navigator.of(screenContext).push(
                      MaterialPageRoute(
                        builder:
                            (context) => LogRetrievalLoadingScreen(
                              scanType: ScanType.bluetooth,
                              selectedDevice: activeDevice,
                              isLiveEvent: widget.isLiveEvent,
                            ),
                      ),
                    );
                  } else {
                    await showPanelAccessCodeLogRetrievalSheet(
                      context: screenContext,
                      device: activeDevice,
                      isLiveEvent: widget.isLiveEvent,
                      onStartValidation:
                          () => bleController.startLogRetrieval(),
                    );
                  }
                } else {
                  final expectedPanel =
                      widget.createProjectExpectedPanelType?.trim() ?? '';
                  if (expectedPanel.isNotEmpty) {
                    final ok = await showPanelAccessCodeGatewayDialog(
                      context: screenContext,
                      onStartValidation:
                          () =>
                              bleController.startSessionAccessCodeValidation(),
                    );
                    if (!ok || !screenContext.mounted) {
                      bleController.bleManager.disconnectConnectedDevice();
                      return;
                    }
                    await _waitForReceivedPanelName(bleController);
                    if (!screenContext.mounted) return;
                    final received =
                        bleController.bleProcess.receivedPanelName.value.trim();
                    if (!_panelTypeMatchesReceived(expectedPanel, received)) {
                      await bleController.bleManager
                          .disconnectConnectedDevice();
                      if (screenContext.mounted) {
                        await _showWrongPanelTypeDialog(
                          context: screenContext,
                          expected: expectedPanel,
                          received: received.isEmpty ? '-' : received,
                        );
                      }
                      return;
                    }
                    if (widget.onCreateProjectPanelVerified != null) {
                      widget.onCreateProjectPanelVerified!();
                    } else if (screenContext.mounted) {
                      Navigator.of(
                        screenContext,
                        rootNavigator: true,
                      ).pop(true);
                    }
                    return;
                  }

                  final bleNameForSiteLookup = activeDevice.name.trim();
                  final preAssocPanel =
                      await _panelService.getPanelByPanelId(
                        bleNameForSiteLookup,
                      ) ??
                      await _panelService.getPanelByBleName(
                        bleNameForSiteLookup,
                      );
                  final panelHadNoSiteBeforeConnect =
                      preAssocPanel?.siteId == null;

                  final siteId = await _ensureConnectedPanelHasSite(
                    device: activeDevice,
                  );

                  if (siteId == null) {
                    if (screenContext.mounted) {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            StringConstants
                                .noSiteSelectedPleaseSelectOrCreateASite,
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  if (!screenContext.mounted) return;

                  if (widget.isLiveEventLogs == true) {
                    Navigator.of(
                      screenContext,
                      rootNavigator: true,
                    ).pushReplacement(
                      MaterialPageRoute(
                        builder:
                            (_) => EventLogScreen(
                              connectedDevice: activeDevice,
                              logDataList: [],
                              panelVersionNo: activeDevice.id,
                              panelName: activeDevice.name,
                              isLiveEventLogs: widget.isLiveEventLogs,
                            ),
                      ),
                    );
                  } else {
                    final ok = await showPanelAccessCodeGatewayDialog(
                      context: screenContext,
                      onStartValidation:
                          () =>
                              bleController.startSessionAccessCodeValidation(),
                    );
                    if (!ok || !screenContext.mounted) {
                      bleController.bleManager.disconnectConnectedDevice();
                      return;
                    }

                    await offerOptionalFullConfigDownloadAfterConnect(
                      context: screenContext,
                      isMounted: () => screenContext.mounted,
                      device: activeDevice,
                      awaitDownloadIfAccepted: true,
                      showConfigLogCompareAfterDownload: true,
                      panelHadNoSiteBeforeConnect: panelHadNoSiteBeforeConnect,
                    );
                    if (!screenContext.mounted) return;

                    Navigator.of(
                      screenContext,
                      rootNavigator: true,
                    ).pushReplacement(
                      MaterialPageRoute(
                        builder:
                            (_) => ProjectDashboardScreen(
                              selectedDevice: activeDevice,
                              panelVersionNo: activeDevice.id,
                              panelName: activeDevice.name,
                              siteId: siteId,
                            ),
                      ),
                    );
                  }
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
                            handshakeComplete && !showConnectionError
                                ? Colors.green.withValues(alpha: 0.1)
                                : ColorConstants.errorIconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            handshakeComplete && !showConnectionError
                                ? Icon(
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
                    SizedBox(height: 16),
                    Text(
                      showNetworkCommError
                          ? StringConstants.connectionProblem
                          : maxBleConnectionRetriesReached
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
                    Text(
                      maxBleConnectionRetriesReached
                          ? StringConstants.pleaseScanAgainAndConnectToTheDevice
                          : showNetworkCommError
                          ? networkCommMessage
                          : handshakeComplete
                          ? StringConstants.preparingToNavigate
                          : isConnected
                          ? StringConstants.encryptingAndAuthenticating
                          : 'Please wait while we connect to ${device.name}',
                      style: StyleConstants.textMuted14w400Style,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
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

  Widget _buildDevicesList() {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.discoveredDevices.length,
      separatorBuilder: (context, index) {
        return SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final DiscoveredDevice device = widget.discoveredDevices[index];
        return GestureDetector(
          onTap: () async {
            _showConnectingDialog(device: device, context: context);
            await Get.find<BleLogController>().connectToDevice(device: device);
          },
          child: Container(
            decoration: BoxDecoration(
              color: ColorConstants.white,
              border: Border.all(
                color: ColorConstants.iconDisabled.withValues(alpha: 0.31),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: (widget.scanType == ScanType.usb
                              ? ColorConstants.primary
                              : Colors.blue)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SvgPicture.asset(AssetConstants.panelIcon),
                  ),
                  SizedBox(width: 14.31),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          BleNameUtils.getDisplayPrefixFromBleName(
                            _getDeviceName(device),
                          ),
                          style: StyleConstants.textDark14w700Style,
                        ),
                        Text(
                          BleNameUtils.getDisplayIdFromBleName(
                            _getDeviceName(device),
                          ),
                          style: StyleConstants.textMuted14w700Style,
                        ),
                        Text(
                          _getDeviceInfo(device),
                          style: StyleConstants.textMuted12w400Style,
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset(AssetConstants.arrowRightColoredIcon),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getDeviceName(dynamic device) {
    if (widget.scanType == ScanType.usb && device is UsbDevice) {
      return device.productName ?? StringConstants.usbSolarDevice;
    } else if (widget.scanType == ScanType.bluetooth &&
        device is DiscoveredDevice) {
      return device.name.isNotEmpty
          ? device.name
          : StringConstants.bleSolarDevice;
    }
    return StringConstants.unknownDevice;
  }

  String _getDeviceInfo(dynamic device) {
    if (widget.scanType == ScanType.usb && device is UsbDevice) {
      return 'VID: ${device.vid?.toRadixString(16) ?? 'Unknown'} | PID: ${device.pid?.toRadixString(16) ?? 'Unknown'}';
    } else if (widget.scanType == ScanType.bluetooth &&
        device is DiscoveredDevice) {
      return 'RSSI: ${device.rssi} dBm';
    }
    return StringConstants.noInformationAvailable;
  }
}
