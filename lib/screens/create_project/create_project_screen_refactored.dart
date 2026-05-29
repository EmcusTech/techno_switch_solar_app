import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_session_idle_policy.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/create_project_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_configuration_coordinator.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/panel_selection_page.dart';
import 'package:techno_switch_solar_app/screens/create_project/pages/site_creation_page.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/screens/site_screen.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/general_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/input_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/l_bus_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/panel_info_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/relay_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/service_due_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/setting_bottom_sheets/ext_out_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/sounder_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/zone_mode_bottomsheet.dart';
import 'package:techno_switch_solar_app/widgets/app_styled_dialogs.dart';

/// Create-site wizard: site → panel → BLE connect → nine dashboard-equivalent
/// configuration steps → create site, assign panel, bulk apply, open dashboard.
class CreateSiteScreenRefactored extends StatefulWidget {
  const CreateSiteScreenRefactored({super.key});

  @override
  State<CreateSiteScreenRefactored> createState() =>
      _CreateSiteScreenRefactoredState();
}

class _CreateSiteScreenRefactoredState
    extends State<CreateSiteScreenRefactored> {
  late CreateProjectController _controller;
  late PageController _pageController;
  final SiteService _siteService = SiteService();
  final PanelService _panelService = PanelService();
  final BleLogController _bleController = Get.find<BleLogController>();
  final BleManager _bleManager = Get.find<BleManager>();

  int _currentStep = 1;
  static const int _totalSteps = 11;

  final ValueNotifier<int> _relayRefresh = ValueNotifier(0);
  final ValueNotifier<int> _inputRefresh = ValueNotifier(0);
  final ValueNotifier<int> _zoneRefresh = ValueNotifier(0);
  final ValueNotifier<int> _extOutRefresh = ValueNotifier(0);
  final ValueNotifier<int> _sounderRefresh = ValueNotifier(0);
  final ValueNotifier<int> _serviceDueRefresh = ValueNotifier(0);
  final ValueNotifier<int> _accessCodeRefresh = ValueNotifier(0);
  final ValueNotifier<int> _panelInfoRefresh = ValueNotifier(0);
  final ValueNotifier<int> _generalModuleRefresh = ValueNotifier(0);
  final ValueNotifier<bool> _navigatingToDeviceConnecting = ValueNotifier(
    false,
  );

  late final PanelConfigRefreshNotifiers _panelRefreshNotifiers;

  final GlobalKey<GeneralModuleBottomSheetState> _generalSheetKey =
      GlobalKey<GeneralModuleBottomSheetState>();
  final GlobalKey<ServiceDueBottomSheetState> _serviceDueSheetKey =
      GlobalKey<ServiceDueBottomSheetState>();
  final GlobalKey<ZoneBottomSheetState> _zoneSheetKey =
      GlobalKey<ZoneBottomSheetState>();
  final GlobalKey<SounderModeBottomSheetState> _sounderSheetKey =
      GlobalKey<SounderModeBottomSheetState>();
  final GlobalKey<InputModeBottomSheetState> _inputSheetKey =
      GlobalKey<InputModeBottomSheetState>();
  final GlobalKey<RelayModeBottomSheetState> _relaySheetKey =
      GlobalKey<RelayModeBottomSheetState>();
  final GlobalKey<ExtOutBottomSheetState> _extOutSheetKey =
      GlobalKey<ExtOutBottomSheetState>();
  final GlobalKey<LBusBottomSheetState> _lBusSheetKey =
      GlobalKey<LBusBottomSheetState>();
  final GlobalKey<PanelInfoBottomSheetState> _panelInfoSheetKey =
      GlobalKey<PanelInfoBottomSheetState>();

  bool _offeredBulkDownload = false;

  /// BLE device id for peripheral caches; set only after a successful connect.
  String _wizardDeviceId = '';

  void _noop() {}

  /// Hides the soft keyboard and drops focus so step transitions (e.g. Connect
  /// panel → scan route) do not fight with the Panel Name field.
  Future<void> _dismissKeyboardFully() async {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<Object>('TextInput.hide');
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await WidgetsBinding.instance.endOfFrame;
  }

  /// After scan / access-code routes, keyboard [viewInsets] can still animate.
  /// Showing [Dialog]s while that happens makes them shift vertically. Tear down
  /// the IME and wait a beat so the overlay is stable.
  Future<void> _settleImeBeforeShowingDialog() async {
    await _dismissKeyboardFully();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await _dismissKeyboardFully();
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 280));
  }

  Future<void> _confirmFinishAndApply() async {
    await _settleImeBeforeShowingDialog();
    if (!mounted) return;

    if (_controller.skippedPanelConnect) {
      final proceed = await showAppStyledTwoActionDialog<bool>(
        context: context,
        title: 'Create site',
        message:
            'This will save the site and panel ID. Configuration will be stored locally and can be applied when you connect the panel later.',
        leadingActionLabel: 'Cancel',
        trailingActionLabel: 'Create',
        leadingValue: false,
        trailingValue: true,
      );
      if (proceed != true || !mounted) return;
      await _finishCreateSiteWithoutPanel();
      return;
    }

    final proceed = await showAppStyledTwoActionDialog<bool>(
      context: context,
      title: 'Update panel settings',
      message:
          'This will update the panel settings with the values you configured in this setup.',
      leadingActionLabel: 'Cancel',
      trailingActionLabel: 'Next',
      leadingValue: false,
      trailingValue: true,
    );
    if (proceed != true || !mounted) return;
    await _finishCreateSiteBulkApplyAndOpenDashboard();
  }

  @override
  void initState() {
    super.initState();
    BleSessionIdlePolicy.suppressIdleDisconnect.value = true;
    _controller = CreateProjectController();
    _pageController = PageController();
    _controller.addListener(_onControllerUpdate);
    _panelRefreshNotifiers = PanelConfigRefreshNotifiers(
      relay: _relayRefresh,
      input: _inputRefresh,
      zone: _zoneRefresh,
      extOut: _extOutRefresh,
      sounder: _sounderRefresh,
      serviceDue: _serviceDueRefresh,
      accessCode: _accessCodeRefresh,
      panelInfo: _panelInfoRefresh,
      generalModule: _generalModuleRefresh,
    );
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    BleSessionIdlePolicy.suppressIdleDisconnect.value = false;
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _pageController.dispose();
    _relayRefresh.dispose();
    _inputRefresh.dispose();
    _zoneRefresh.dispose();
    _extOutRefresh.dispose();
    _sounderRefresh.dispose();
    _serviceDueRefresh.dispose();
    _accessCodeRefresh.dispose();
    _panelInfoRefresh.dispose();
    _generalModuleRefresh.dispose();
    _navigatingToDeviceConnecting.dispose();
    super.dispose();
  }

  /// Same flow as [ProjectDashboardScreen] / `_ProjectDashboardContentState`.
  Future<bool> _confirmAndDisconnect() async {
    final shouldDisconnect = await showDialog<bool>(
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_off,
                      color: Color(0xFFEC1D24),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Disconnect device?',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Going back will disconnect the device. Are you sure?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
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
                            color: const Color(0xFFEFEEEE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFD0D0D0),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
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
                            color: const Color(0xFFEC1D24),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEC1D24).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Disconnect',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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

    if (shouldDisconnect == true) {
      if (_bleManager.isConnected) {
        await _bleManager.disconnectConnectedDevice();
      }
      _controller.setCreateProjectPanelBleVerified(false);
      _controller.setConnectedDevice(null);
      _controller.clearSkippedPanelConnect();
      _wizardDeviceId = '';
      return true;
    }
    return false;
  }

  Future<void> _onLeadingBackPressed() async {
    if (_bleController.isConnected) {
      final shouldPop = await _confirmAndDisconnect();
      if (shouldPop && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFEC1D24) : const Color(0xFF00A706),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Returns `false` if the user chose to abort the wizard (e.g. skip → Home).
  Future<bool> _runPostConnectAssignedPanelFlow() async {
    final device = _controller.connectedDevice;
    if (device == null) return false;

    final bleName = device.name.trim();
    if (bleName.isEmpty) return true;

    var panel =
        await _panelService.getPanelByPanelId(bleName) ??
        await _panelService.getPanelByBleName(bleName);
    if (panel?.siteId == null) return true;

    if (!mounted) return false;
    await _settleImeBeforeShowingDialog();
    if (!mounted) return false;
    final choice = await showAppStyledTwoActionDialog<String>(
      context: context,
      title: 'Panel already on a site',
      message:
          'This panel is assigned to another site. Move it to the new site you are creating, or skip and return home.',
      leadingActionLabel: 'Skip',
      trailingActionLabel: 'Replace',
      leadingValue: 'skip',
      trailingValue: 'move',
    );

    if (choice == 'skip') {
      if (_bleManager.isConnected) {
        await _bleManager.disconnectConnectedDevice();
      }
      _controller.setCreateProjectPanelBleVerified(false);
      _controller.setConnectedDevice(null);
      _wizardDeviceId = '';
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return false;
    }

    if (choice == 'move') {
      await _panelService.unassignPanelFromSite(panel!.panelId);
    }
    return true;
  }

  Future<void> _offerBulkDownloadIfNeeded() async {
    if (_controller.skippedPanelConnect) return;
    if (_offeredBulkDownload) return;
    _offeredBulkDownload = true;
    if (!mounted) return;

    await _settleImeBeforeShowingDialog();
    if (!mounted) return;

    final download = await showAppStyledTwoActionDialog<bool>(
      context: context,
      title: 'Download panel configuration?',
      message:
          'Download the full configuration from the panel now? This matches the dashboard “download all” flow and fills local caches before you edit.',
      leadingActionLabel: 'No',
      trailingActionLabel: 'Yes',
      leadingValue: false,
      trailingValue: true,
    );

    if (download != true || !mounted) return;

    final device = _controller.connectedDevice;
    if (device == null) return;

    PanelConfigurationCoordinator(
      bleManager: _bleManager,
      bleController: _bleController,
      device: device,
      refreshNotifiers: _panelRefreshNotifiers,
      navigatingToDeviceConnecting: _navigatingToDeviceConnecting,
      useDialogOnlyBulkProgress: true,
    ).startBulkDownload(context: context, isMounted: () => mounted);
  }

  Future<bool> _commitConfigStepForCurrentPage() async {
    switch (_currentStep) {
      case 3:
        return await _generalSheetKey.currentState?.commitLocal() ?? false;
      case 4:
        return await _serviceDueSheetKey.currentState?.commitLocal() ?? false;
      case 5:
        return await _zoneSheetKey.currentState?.commitLocal() ?? false;
      case 6:
        return await _sounderSheetKey.currentState?.commitLocal() ?? false;
      case 7:
        return await _inputSheetKey.currentState?.commitLocal() ?? false;
      case 8:
        return await _relaySheetKey.currentState?.commitLocal() ?? false;
      case 9:
        return await _extOutSheetKey.currentState?.commitLocal() ?? false;
      case 10:
        return await _lBusSheetKey.currentState?.commitLocal() ?? false;
      default:
        return true;
    }
  }

  Future<void> _finishCreateSiteBulkApplyAndOpenDashboard() async {
    final device = _controller.connectedDevice ?? _bleManager.selectedDevice;
    if (device == null) {
      _showSnackBar('No connected panel', isError: true);
      return;
    }

    final panelState = _panelInfoSheetKey.currentState;
    if (panelState == null || !(await panelState.commitLocal())) {
      _showSnackBar('Fix panel information fields', isError: true);
      return;
    }

    final errors = _siteService.validateSiteData(
      siteName: _controller.siteNameController.text,
      installerName: _controller.installerNameController.text,
      companyName: _controller.companyNameController.text,
      saqccRegNumber: _controller.saqccRegNumberController.text,
      buildingName: _controller.buildingNameController.text,
      installerContactNumber: _controller.installerContactNumberController.text,
      installerEmail: _controller.installerEmailController.text,
      siteDescription: _controller.siteDescriptionController.text,
    );
    if (errors.isNotEmpty) {
      _showSnackBar('Please fix the site form (step 1)', isError: true);
      return;
    }

    try {
      final site = await _siteService.createSite(
        siteName: _controller.siteNameController.text,
        installerName: _controller.installerNameController.text,
        companyName: _controller.companyNameController.text,
        saqccRegNumber: _controller.saqccRegNumberController.text,
        buildingName: _controller.buildingNameController.text,
        installerContactNumber:
            _controller.installerContactNumberController.text,
        installerEmail: _controller.installerEmailController.text,
        siteDescription: _controller.siteDescriptionController.text,
      );

      final siteId = site.id;
      if (siteId == null) {
        _showSnackBar('Site created but missing id', isError: true);
        return;
      }

      final bleName = device.name.trim();
      final panel =
          await _panelService.getPanelByPanelId(bleName) ??
          await _panelService.getPanelByBleName(bleName);
      final panelIdToUse = panel?.panelId ?? bleName;

      final assigned = await _siteService.assignPanelToSite(
        panelIdToUse,
        siteId,
        panelName: bleName.isNotEmpty ? bleName : null,
      );
      if (!assigned) {
        _showSnackBar('Could not assign panel to site', isError: true);
        return;
      }

      if (!mounted) return;

      final coordinator = PanelConfigurationCoordinator(
        bleManager: _bleManager,
        bleController: _bleController,
        device: device,
        refreshNotifiers: _panelRefreshNotifiers,
        navigatingToDeviceConnecting: _navigatingToDeviceConnecting,
      );

      await coordinator.startBulkApply(
        context: context,
        isMounted: () => mounted,
      );

      if (!mounted) return;

      _showSnackBar('Site ready - opening dashboard', isError: false);

      // Match connect flow: replace wizard so back from dashboard returns to the
      // screen below (e.g. home), not an empty navigator.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => ProjectDashboardScreen(
                selectedDevice: device,
                panelName: device.name,
                panelVersionNo: device.id,
                siteId: siteId,
                siteName: site.siteName,
              ),
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _finishCreateSiteWithoutPanel() async {
    final panelState = _panelInfoSheetKey.currentState;
    if (panelState == null || !(await panelState.commitLocal())) {
      _showSnackBar('Fix panel information fields', isError: true);
      return;
    }

    final manualPanelId = BleNameUtils.normalizeManualPanelId(
      _controller.manualPanelId,
    );
    if (manualPanelId.isEmpty) {
      _showSnackBar('Panel ID is missing', isError: true);
      return;
    }

    final errors = _siteService.validateSiteData(
      siteName: _controller.siteNameController.text,
      installerName: _controller.installerNameController.text,
      companyName: _controller.companyNameController.text,
      saqccRegNumber: _controller.saqccRegNumberController.text,
      buildingName: _controller.buildingNameController.text,
      installerContactNumber: _controller.installerContactNumberController.text,
      installerEmail: _controller.installerEmailController.text,
      siteDescription: _controller.siteDescriptionController.text,
    );
    if (errors.isNotEmpty) {
      _showSnackBar('Please fix the site form (step 1)', isError: true);
      return;
    }

    try {
      final site = await _siteService.createSite(
        siteName: _controller.siteNameController.text,
        installerName: _controller.installerNameController.text,
        companyName: _controller.companyNameController.text,
        saqccRegNumber: _controller.saqccRegNumberController.text,
        buildingName: _controller.buildingNameController.text,
        installerContactNumber:
            _controller.installerContactNumberController.text,
        installerEmail: _controller.installerEmailController.text,
        siteDescription: _controller.siteDescriptionController.text,
      );

      final siteId = site.id;
      if (siteId == null) {
        _showSnackBar('Site created but missing id', isError: true);
        return;
      }

      final bleDisplayName = BleNameUtils.technoswitchBleNameForPanelId(
        manualPanelId,
      );
      final assigned = await _siteService.assignPanelToSite(
        manualPanelId,
        siteId,
        panelName: bleDisplayName,
        offlineProvisioned: true,
      );
      if (!assigned) {
        _showSnackBar('Could not assign panel to site', isError: true);
        return;
      }

      if (!mounted) return;

      _showSnackBar('Site created successfully', isError: false);

      final sitesWithLogCount = await _siteService.getSitesWithLogCount();
      final siteWithLogCount = sitesWithLogCount.firstWhere(
        (entry) => entry.site.id == siteId,
        orElse:
            () => SiteWithLogCount(
              site: site,
              logCount: 0,
              lastLogRetrieved: null,
            ),
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => SiteScreen(
                site: site,
                siteWithLogCount: siteWithLogCount,
              ),
        ),
      );
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _skipPanelConnectAndContinue() async {
    if (!_controller.validateStep(2)) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    await _settleImeBeforeShowingDialog();
    if (!mounted) return;

    final existingId = BleNameUtils.normalizeManualPanelId(
      _controller.manualPanelId,
    );
    final entered = await showAppStyledTextInputDialog(
      context: context,
      title: 'Enter panel ID',
      message:
          'Enter the panel ID for this site (e.g. AB12). It should match the ID in the panel BLE name TECHNOSWITCH_XXXX when you connect later.',
      hintText: 'Panel ID',
      initialValue: existingId.isNotEmpty ? existingId : null,
      validator: (value) {
        if (!BleNameUtils.isValidManualPanelId(value)) {
          return 'Enter a valid panel ID (letters, numbers, - or _)';
        }
        return null;
      },
    );

    if (!mounted || entered == null) return;

    final panelId = BleNameUtils.normalizeManualPanelId(entered);
    final existingPanel = await _panelService.getPanelByPanelId(panelId);
    if (existingPanel?.siteId != null) {
      if (!mounted) return;
      await showAppStyledOneActionDialog(
        context: context,
        title: 'Panel already assigned',
        message:
            'This panel ID is already linked to a site. Use a different ID or connect to the panel instead.',
      );
      return;
    }

    _controller.setSkippedPanelConnect(skipped: true, panelId: panelId);
    _controller.setCreateProjectPanelBleVerified(false);
    _controller.setConnectedDevice(null);
    _wizardDeviceId = panelId;
    _offeredBulkDownload = false;

    _controller.clearValidationErrors();
    await _dismissKeyboardFully();
    if (!mounted) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToNextStep() async {
    await _dismissKeyboardFully();
    if (!mounted) return;

    if (_currentStep == 11) {
      await _confirmFinishAndApply();
      return;
    }

    if (_currentStep <= 2 && !_controller.validateStep(_currentStep)) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }

    if (_currentStep == 2) {
      _controller.clearValidationErrors();
      await _dismissKeyboardFully();
      if (!mounted) return;
      // Let the IME fully close before route push to avoid keyboard resize jank.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder:
              (_) => ScanningScreen(
                createProjectExpectedPanelType:
                    _controller.panelData.selectedPanelType,
              ),
        ),
      );
      if (!mounted) return;
      if (verified != true) return;

      final device = _bleManager.selectedDevice;
      if (device == null) {
        _showSnackBar('Connection lost - no device', isError: true);
        return;
      }

      _controller.setCreateProjectPanelBleVerified(true);
      _controller.setConnectedDevice(device);
      _controller.clearSkippedPanelConnect();
      _wizardDeviceId = device.id;

      final proceed = await _runPostConnectAssignedPanelFlow();
      if (!proceed || !mounted) return;

      await _offerBulkDownloadIfNeeded();
      if (!mounted) return;

      _controller.clearValidationErrors();
      await _dismissKeyboardFully();
      if (!mounted) return;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    if (_currentStep >= 3 && _currentStep <= 10) {
      final ok = await _commitConfigStepForCurrentPage();
      if (!ok) {
        _showSnackBar(
          'Fix the fields on this step before continuing',
          isError: true,
        );
        return;
      }
    }

    _controller.clearValidationErrors();
    await _dismissKeyboardFully();
    if (!mounted) return;
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      if (_currentStep == 3) {
        if (_controller.skippedPanelConnect) {
          _controller.clearSkippedPanelConnect();
        } else {
          _bleManager.disconnectConnectedDevice();
          _controller.setCreateProjectPanelBleVerified(false);
          _controller.setConnectedDevice(null);
        }
        _wizardDeviceId = '';
        _offeredBulkDownload = false;
      }
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentStep = page + 1;
    });
  }

  Widget _embeddedSheetPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_bleController.isConnected,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final disconnect = await _confirmAndDisconnect();
        if (disconnect && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6EBEB), Colors.white],
            ),
          ),
          child: Stack(
            children: [
              SvgPicture.asset('assets/svgs/background_1.svg'),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 22, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildPageView()),
                              const SizedBox(height: 20),
                              _buildNavigation(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _onLeadingBackPressed,
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
        const SizedBox(width: 12),
        Text(
          'Create Site',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3A3A3A),
          ),
        ),
        const Spacer(),
        Text(
          'Step',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEC1D24),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 7,
              right: 6,
              top: 2,
              bottom: 3,
            ),
            child: Text(
              '$_currentStep/$_totalSteps',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageView() {
    final id = _wizardDeviceId;

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _totalSteps,
      itemBuilder: (context, index) {
        switch (index) {
          case 0:
            return SiteCreationPage(
              siteNameController: _controller.siteNameController,
              installerNameController: _controller.installerNameController,
              companyNameController: _controller.companyNameController,
              saqccRegNumberController: _controller.saqccRegNumberController,
              buildingNameController: _controller.buildingNameController,
              installerContactNumberController:
                  _controller.installerContactNumberController,
              installerEmailController: _controller.installerEmailController,
              siteDescriptionController: _controller.siteDescriptionController,
              validationErrors: _controller.validationErrors,
            );
          case 1:
            return PanelSelectionPage(
              selectedPanelType: _controller.panelData.selectedPanelType,
              panelNameController: _controller.panelNameController,
              onPanelTypeChanged: _controller.updatePanelType,
              validationErrors: _controller.validationErrors,
            );
          case 2:
          case 3:
          case 4:
          case 5:
          case 6:
          case 7:
          case 8:
          case 9:
          case 10:
            if (id.isEmpty) {
              return Center(
                child: Text(
                  'Connect a panel to configure peripherals.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            switch (index) {
              case 2:
                return _embeddedSheetPadding(
                  child: GeneralModuleBottomSheet(
                    key: _generalSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _generalModuleRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 3:
                return _embeddedSheetPadding(
                  child: ServiceDueBottomSheet(
                    key: _serviceDueSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _serviceDueRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 4:
                return _embeddedSheetPadding(
                  child: ZoneBottomSheet(
                    key: _zoneSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _zoneRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 5:
                return _embeddedSheetPadding(
                  child: SounderModeBottomSheet(
                    key: _sounderSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _sounderRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 6:
                return _embeddedSheetPadding(
                  child: InputModeBottomSheet(
                    key: _inputSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _inputRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 7:
                return _embeddedSheetPadding(
                  child: RelayModeBottomSheet(
                    key: _relaySheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _relayRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 8:
                return _embeddedSheetPadding(
                  child: ExtOutBottomSheet(
                    key: _extOutSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _extOutRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 9:
                return _embeddedSheetPadding(
                  child: LBusBottomSheet(
                    key: _lBusSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _zoneRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              case 10:
                return _embeddedSheetPadding(
                  child: PanelInfoBottomSheet(
                    key: _panelInfoSheetKey,
                    deviceId: id,
                    onDownload: _noop,
                    onApply: _noop,
                    refreshTrigger: _panelInfoRefresh,
                    embedInCreateFlow: true,
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildNavigation() {
    final nextLabel =
        _currentStep == 2
            ? 'Connect panel'
            : _currentStep == 11
            ? (_controller.skippedPanelConnect ? 'Create site' : 'Finish')
            : 'Next';

    return Column(
      children: [
        if (_currentStep == 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: _skipPanelConnectAndContinue,
              child: Text(
                'Skip connection — enter panel ID manually',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEC1D24),
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Row(
      children: [
        Opacity(
          opacity: _currentStep == 1 ? 0.2 : 1.0,
          child: GestureDetector(
            onTap: _goToPreviousStep,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFEEEE),
                borderRadius: BorderRadius.circular(28.5),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 34,
                  top: 18,
                  bottom: 18,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, color: Color(0xFF49454F)),
                    const SizedBox(width: 6),
                    Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF49454F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _goToNextStep(),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEC1D24),
              borderRadius: BorderRadius.circular(28.5),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 28,
                right: 23,
                top: 18,
                bottom: 18,
              ),
              child: Row(
                children: [
                  Text(
                    nextLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
      ],
    );
  }
}
