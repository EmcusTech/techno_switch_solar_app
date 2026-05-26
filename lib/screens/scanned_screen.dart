import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/screens/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/screens/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/panel_config/post_connect_bulk_download_offer.dart';
import 'package:techno_switch_solar_app/widgets/panel_access_code_dialog.dart';
import 'package:usb_serial/usb_serial.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScannedScreen extends StatefulWidget {
  final List<dynamic>
  discoveredDevices; // Can hold both UsbDevice and ScanResult
  final ScanType scanType;
  final bool? isLiveEvent;
  final bool? isLiveEventLogs;

  /// Mirrors [ScanningScreen]: create-site wizard panel type check (see that screen).
  final String? createProjectExpectedPanelType;

  /// If non-null, called instead of [Navigator.pop] when create-project verification succeeds.
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

  Future<int?> _promptUserToPickOrCreateSite({
    required List<SiteModel> sites,
    required String panelId,
    required String panelName,
  }) async {
    if (!mounted) return null;

    // If there are no sites at all, force create flow.
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBDEE1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.domain_add,
                        size: 32,
                        color: Color(0xFFEC1D24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create a site?',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D3D3D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This panel is not associated with any site yet. Create a site to continue.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF918F8F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            side: const BorderSide(color: Color(0xFFEC1D24)),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                            _bleManager.disconnectConnectedDevice();
                          },
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEC1D24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC1D24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                          child: Text(
                            'Create',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
            visibleCount * siteRowHeight + ((visibleCount - 1) * 8); // spacing

        return StatefulBuilder(
          builder: (_, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ───────── Icon ─────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBDEE1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_city,
                          size: 32,
                          color: Color(0xFFEC1D24),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ───────── Title ─────────
                    Text(
                      'Select a site',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D3D3D),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Choose the site where this panel should be assigned.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF918F8F),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // ───────── Site List (dynamic height) ─────────
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
                                        ? const Color(
                                          0xFFEC1D24,
                                        ).withOpacity(0.08)
                                        : const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? const Color(0xFFEC1D24)
                                          : const Color(0xFFD0D0D0),
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
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3D3D3D),
                                          ),
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
                                                  .join(' • '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF918F8F),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFFEC1D24),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ───────── Actions ─────────
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC1D24),
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
                              'Continue',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF918F8F),
                                  ),
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
                                    color: Color(0xFFEC1D24),
                                    width: 1.5,
                                  ),
                                  backgroundColor: const Color(
                                    0xFFEC1D24,
                                  ).withOpacity(0.04),
                                ),
                                onPressed:
                                    () => Navigator.of(
                                      dialogContext,
                                    ).pop('create'),
                                child: Text(
                                  'Create',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEC1D24),
                                  ),
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

    try {
      // Look up by full BLE name (panelId or panelName)
      var existingPanel =
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

    // Use full BLE name as panelId for new panels; use existing panelId if panel exists
    final panel =
        await _panelService.getPanelByPanelId(bleName) ??
        await _panelService.getPanelByBleName(bleName);
    final panelIdToUse = panel?.panelId ?? bleName;
    await _siteService.assignPanelToSite(
      panelIdToUse,
      pickedSiteId,
      panelName: bleName,
    );
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
            colors: [Color(0xFFF6EBEB), Colors.white],
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
                  color: Color(0xffEC1D24).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        SvgPicture.asset('assets/svgs/background_1.svg'),
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
                      // Disconnect Bluetooth before going back to scan
                      await NavigationService.navigateToScanAgain(context);

                      // Then navigate to scanning screen
                      if (context.mounted) {
                        final navigator = Navigator.of(context);
                        // navigator.pop(); // close dialog
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
                        color: Color(0xFFFBDEE1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: SvgPicture.asset(
                          'assets/svgs/logo.svg',
                          height: 59.29,
                          width: 51,
                          colorFilter: ColorFilter.mode(
                            Color(0xFFEC1D24),
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
                'Tap to Scan Again',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3D3D3D),
                ),
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
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF3D3D3D),
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
              'Panels Identified',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D3D3D),
              ),
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
            'No ${widget.scanType == ScanType.usb ? 'USB' : 'Bluetooth'} Devices Found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.scanType == ScanType.usb
                ? 'Make sure your solar devices are connected via USB and powered on.'
                : 'Make sure Bluetooth is enabled and solar devices are in pairing mode.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 32,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wrong panel type',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This device does not match the panel type you selected ($expected). '
                  'The connected panel reported: $received.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF918F8F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC1D24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.5),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
            if (handshakeComplete && !hasNavigated) {
              hasNavigated = true;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext, rootNavigator: true).pop(true);

                await Future.delayed(const Duration(milliseconds: 150));

                if (!screenContext.mounted) return;

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
                              selectedDevice: device,
                              isLiveEvent: widget.isLiveEvent,
                            ),
                      ),
                    );
                  } else {
                    await showPanelAccessCodeLogRetrievalSheet(
                      context: screenContext,
                      device: device,
                      isLiveEvent: widget.isLiveEvent,
                      onStartValidation: () => bleController.startLogRetrieval(),
                    );
                  }
                } else {
                  // Create-site flow: verify panel model (matches [ScanningScreen]).
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
                      await bleController.bleManager.disconnectConnectedDevice();
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

                  final bleNameForSiteLookup = device.name.trim();
                  final preAssocPanel =
                      await _panelService.getPanelByPanelId(bleNameForSiteLookup) ??
                      await _panelService.getPanelByBleName(bleNameForSiteLookup);
                  final panelHadNoSiteBeforeConnect =
                      preAssocPanel?.siteId == null;

                  final siteId = await _ensureConnectedPanelHasSite(
                    device: device,
                  );

                  if (siteId == null) {
                    if (screenContext.mounted) {
                      ScaffoldMessenger.of(screenContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No site selected. Please select or create a site.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  if (!screenContext.mounted) return;

                  if (widget.isLiveEventLogs == true) {
                    Navigator.of(screenContext, rootNavigator: true).pushReplacement(
                      MaterialPageRoute(
                        builder:
                            (_) => EventLogScreen(
                              connectedDevice: device,
                              logDataList: [],
                              panelVersionNo: device.id,
                              panelName: device.name,
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
                      device: device,
                      awaitDownloadIfAccepted: true,
                      showConfigLogCompareAfterDownload: true,
                      panelHadNoSiteBeforeConnect:
                          panelHadNoSiteBeforeConnect,
                    );
                    if (!screenContext.mounted) return;

                    Navigator.of(
                      screenContext,
                      rootNavigator: true,
                    ).pushReplacement(
                      MaterialPageRoute(
                        builder:
                            (_) => ProjectDashboardScreen(
                              selectedDevice: device,
                              panelVersionNo: device.id,
                              panelName: device.name,
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
                  color: Colors.white,
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
                            handshakeComplete
                                ? Colors.green.withValues(alpha: 0.1)
                                : Color(0xFFFBDEE1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child:
                            handshakeComplete
                                ? Icon(
                                  Icons.check_circle,
                                  size: 32,
                                  color: Colors.green,
                                )
                                : showNetworkCommError
                                ? const Icon(
                                  Icons.error_outline,
                                  size: 32,
                                  color: Color(0xFFEC1D24),
                                )
                                : Lottie.asset(
                                  'assets/jsons/ble_connecting.json',
                                  animate: !showConnectionError,
                                ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Title
                    Text(
                      showNetworkCommError
                          ? 'Connection problem'
                          : handshakeComplete
                          ? 'Device Connected!'
                          : maxBleConnectionRetriesReached
                          ? 'Max Connection Retries Reached!'
                          : isConnected
                          ? 'Establishing secure connection...'
                          : 'Connecting...',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D3D3D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    // Subtitle
                    Text(
                      handshakeComplete
                          ? 'Preparing to navigate...'
                          : showNetworkCommError
                          ? networkCommMessage
                          : maxBleConnectionRetriesReached
                          ? 'Please scan again and connect to the device'
                          : isConnected
                          ? 'Encrypting and authenticating...'
                          : 'Please wait while we connect to ${device.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF918F8F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    if (showConnectionError)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEC1D24),
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
                            'OK',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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

            // Start connection
            await Get.find<BleLogController>().connectToDevice(device: device);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Color(0xFFB9B9B9).withValues(alpha: 0.31),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    // width: 48,
                    // height: 48,
                    decoration: BoxDecoration(
                      color: (widget.scanType == ScanType.usb
                              ? Color(0xFFEC1D24)
                              : Colors.blue)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SvgPicture.asset('assets/svgs/panel_icon.svg'),
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
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D3D3D),
                          ),
                        ),
                        Text(
                          BleNameUtils.getDisplayIdFromBleName(
                            _getDeviceName(device),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF918F8F),
                          ),
                        ),
                        Text(
                          _getDeviceInfo(device),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF918F8F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SvgPicture.asset('assets/svgs/arrow_right_colored_icon.svg'),
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
      return device.productName ?? 'USB Solar Device';
    } else if (widget.scanType == ScanType.bluetooth &&
        device is DiscoveredDevice) {
      return device.name.isNotEmpty ? device.name : 'BLE Solar Device';
    }
    return 'Unknown Device';
  }

  String _getDeviceInfo(dynamic device) {
    if (widget.scanType == ScanType.usb && device is UsbDevice) {
      return 'VID: ${device.vid?.toRadixString(16) ?? 'Unknown'} | PID: ${device.pid?.toRadixString(16) ?? 'Unknown'}';
    } else if (widget.scanType == ScanType.bluetooth &&
        device is DiscoveredDevice) {
      return 'RSSI: ${device.rssi} dBm';
    }
    return 'No information available';
  }
}
