import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/ble_session_idle_policy.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_ui_delegate.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_form_data.dart';
import 'package:techno_switch_solar_app/models/create_project/panel_selection_page_model.dart';
import 'package:techno_switch_solar_app/models/create_project/site_creation_page_model.dart';
import 'package:techno_switch_solar_app/models/create_project/relay_data.dart';
import 'package:techno_switch_solar_app/models/create_project/site_form_data.dart';
import 'package:techno_switch_solar_app/models/create_project/sounder_data.dart';
import 'package:techno_switch_solar_app/models/create_project/zone_settings_data.dart';
import 'package:techno_switch_solar_app/models/panel_type_config.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_configuration_coordinator.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

class CreateProjectController extends GetxController {
  static const int totalSteps = 11;

  final TextEditingController siteNameController = TextEditingController(
    text: '',
  );
  final TextEditingController installerNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController saqccRegNumberController = TextEditingController(
    text: '',
  );
  final TextEditingController buildingNameController = TextEditingController();
  final TextEditingController installerContactNumberController =
      TextEditingController();
  final TextEditingController installerEmailController =
      TextEditingController();
  final TextEditingController siteDescriptionController =
      TextEditingController();
  final TextEditingController panelNameController = TextEditingController(
    text: '',
  );

  SiteFormData siteData = SiteFormData();
  PanelFormData panelData = PanelFormData();
  ZoneSettingsData zoneSettings = ZoneSettingsData();
  SounderData sounderData = SounderData();
  RelayData relayData = RelayData();

  Map<String, String> validationErrors = {};

  bool createProjectPanelBleVerified = false;
  DiscoveredDevice? connectedDevice;
  bool skippedPanelConnect = false;
  String manualPanelId = '';

  int currentStep = 1;
  String wizardDeviceId = '';
  bool offeredBulkDownload = false;
  Map<String, Object?>? downloadedConfigBaseline;
  bool bulkDownloadCompleted = false;

  CreateProjectUiDelegate? _ui;
  Future<void> Function()? _animateNextPage;
  Future<void> Function()? _animatePreviousPage;
  Future<bool> Function()? commitCurrentStepHandler;
  Future<bool> Function()? commitPanelInfoHandler;

  final SiteService _siteService = SiteService();
  final PanelService _panelService = PanelService();
  late final BleManager _bleManager;
  late final BleLogController _bleController;

  final ValueNotifier<int> relayRefresh = ValueNotifier(0);
  final ValueNotifier<int> inputRefresh = ValueNotifier(0);
  final ValueNotifier<int> zoneRefresh = ValueNotifier(0);
  final ValueNotifier<int> extOutRefresh = ValueNotifier(0);
  final ValueNotifier<int> sounderRefresh = ValueNotifier(0);
  final ValueNotifier<int> serviceDueRefresh = ValueNotifier(0);
  final ValueNotifier<int> accessCodeRefresh = ValueNotifier(0);
  final ValueNotifier<int> panelInfoRefresh = ValueNotifier(0);
  final ValueNotifier<int> generalModuleRefresh = ValueNotifier(0);
  final ValueNotifier<bool> navigatingToDeviceConnecting = ValueNotifier(false);

  late final PanelConfigRefreshNotifiers panelRefreshNotifiers;

  List<PanelTypeOption> get availablePanelTypeOptions =>
      PanelTypeConfig.availablePanels
          .map(
            (panel) => PanelTypeOption(
              typeName: panel.typeName,
              zoneCount: panel.zoneCount,
              sounderCount: panel.sounderCount,
              relayCount: panel.relayCount,
              fireExtinguisherCount: panel.fireExtinguisherCount,
            ),
          )
          .toList();

  SiteCreationPageModel get siteCreationPageModel => SiteCreationPageModel(
    siteNameController: siteNameController,
    installerNameController: installerNameController,
    companyNameController: companyNameController,
    saqccRegNumberController: saqccRegNumberController,
    buildingNameController: buildingNameController,
    installerContactNumberController: installerContactNumberController,
    installerEmailController: installerEmailController,
    siteDescriptionController: siteDescriptionController,
    validationErrors: validationErrors,
  );

  PanelSelectionPageModel get panelSelectionPageModel =>
      PanelSelectionPageModel(
        panelNameController: panelNameController,
        selectedPanelType: panelData.selectedPanelType,
        validationErrors: validationErrors,
        panelTypes: availablePanelTypeOptions,
        onPanelTypeChanged: updatePanelType,
      );

  void attachUi(CreateProjectUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  void setupPageNavigation({
    required Future<void> Function() animateNext,
    required Future<void> Function() animatePrevious,
  }) {
    _animateNextPage = animateNext;
    _animatePreviousPage = animatePrevious;
  }

  void setCurrentStep(int step) {
    currentStep = step;
    update();
  }

  void setCreateProjectPanelBleVerified(bool value) {
    createProjectPanelBleVerified = value;
    update();
  }

  void setConnectedDevice(DiscoveredDevice? device) {
    connectedDevice = device;
    update();
  }

  void setSkippedPanelConnect({required bool skipped, String? panelId}) {
    skippedPanelConnect = skipped;
    manualPanelId = skipped ? (panelId ?? '').trim() : '';
    if (skipped) {
      createProjectPanelBleVerified = false;
      connectedDevice = null;
    }
    update();
  }

  void clearSkippedPanelConnect() {
    skippedPanelConnect = false;
    manualPanelId = '';
    update();
  }

  @override
  void onInit() {
    super.onInit();
    _bleManager = Get.find<BleManager>();
    _bleController = Get.find<BleLogController>();
    panelRefreshNotifiers = PanelConfigRefreshNotifiers(
      relay: relayRefresh,
      input: inputRefresh,
      zone: zoneRefresh,
      extOut: extOutRefresh,
      sounder: sounderRefresh,
      serviceDue: serviceDueRefresh,
      accessCode: accessCodeRefresh,
      panelInfo: panelInfoRefresh,
      generalModule: generalModuleRefresh,
    );
    BleSessionIdlePolicy.suppressIdleDisconnect.value = true;
    _initializeControllerListeners();
    if (PanelTypeConfig.availablePanels.length == 1) {
      updatePanelType(PanelTypeConfig.availablePanels.first.typeName);
    }
  }

  void _initializeControllerListeners() {
    siteNameController.addListener(() {
      siteData = siteData.copyWith(siteName: siteNameController.text);
    });

    installerNameController.addListener(() {
      siteData = siteData.copyWith(installerName: installerNameController.text);
    });

    companyNameController.addListener(() {
      siteData = siteData.copyWith(companyName: companyNameController.text);
    });

    saqccRegNumberController.addListener(() {
      siteData = siteData.copyWith(
        saqccRegNumber: saqccRegNumberController.text,
      );
    });

    buildingNameController.addListener(() {
      siteData = siteData.copyWith(buildingName: buildingNameController.text);
    });

    installerContactNumberController.addListener(() {
      siteData = siteData.copyWith(
        installerContactNumber: installerContactNumberController.text,
      );
    });

    installerEmailController.addListener(() {
      siteData = siteData.copyWith(
        installerEmail: installerEmailController.text,
      );
    });

    siteDescriptionController.addListener(() {
      siteData = siteData.copyWith(
        siteDescription: siteDescriptionController.text,
      );
    });

    panelNameController.addListener(() {
      panelData = panelData.copyWith(panelName: panelNameController.text);
    });
  }

  void updatePanelType(String? panelType) {
    panelData = panelData.copyWith(selectedPanelType: panelType);

    if (panelType != null) {
      final panelConfig = PanelTypeConfig.getByTypeName(panelType);
      if (panelConfig != null) {
        zoneSettings.initializeZones(panelConfig.zoneCount);
        sounderData.initializeSounders(
          panelConfig.sounderCount,
          zoneSettings.zoneTexts.keys.isNotEmpty
              ? zoneSettings.zoneTexts.keys.first
              : 'Zone 1',
        );
        relayData.initializeRelays(panelConfig.relayCount);
      }
    }
    update();
  }

  bool validateStep(int step) {
    validationErrors.clear();

    if (step == 1) {
      if (siteNameController.text.trim().isEmpty) {
        validationErrors[StringConstants.sitename] =
            StringConstants.siteNameRequired;
      }
      if (saqccRegNumberController.text.trim().isEmpty) {
        validationErrors[StringConstants.saqccregnumber] =
            StringConstants.saqccRegNumberRequired;
      }
    } else if (step == 2) {
      if (panelNameController.text.trim().isEmpty) {
        validationErrors[StringConstants.panelname] =
            StringConstants.panelNameRequired;
      }
      if (panelData.selectedPanelType == null) {
        validationErrors[StringConstants.paneltype] =
            StringConstants.panelTypeRequired;
      }
    }

    if (validationErrors.isNotEmpty) {
      update();
      return false;
    }

    return true;
  }

  void clearValidationErrors() {
    validationErrors.clear();
    update();
  }

  String get nextButtonLabel {
    if (currentStep == 2) {
      return StringConstants.connectPanel;
    }
    if (currentStep == 11) {
      return skippedPanelConnect
          ? UiStrings.createSiteDialogTitle
          : StringConstants.finish;
    }
    return UiStrings.nextButton;
  }

  Future<void> onLeadingBackPressed() async {
    final ui = _ui;
    if (ui == null) return;

    if (_bleController.isConnected) {
      final shouldPop = await confirmAndDisconnect();
      if (shouldPop) {
        ui.popScreen();
      }
    } else {
      ui.popScreen();
    }
  }

  Future<bool> confirmAndDisconnect() async {
    final ui = _ui;
    if (ui == null) return false;

    final shouldDisconnect = await ui.showDisconnectConfirmDialog();

    if (shouldDisconnect == true) {
      if (_bleManager.isConnected) {
        await _bleManager.disconnectConnectedDevice();
      }
      setCreateProjectPanelBleVerified(false);
      setConnectedDevice(null);
      clearSkippedPanelConnect();
      wizardDeviceId = '';
      offeredBulkDownload = false;
      _clearDownloadedConfigBaseline();
      update();
      return true;
    }
    return false;
  }

  void _captureDownloadedConfigBaseline() {
    downloadedConfigBaseline = PeripheralConfigSnapshot.fromBleManager(_bleManager);
    bulkDownloadCompleted = true;
  }

  void _clearDownloadedConfigBaseline() {
    downloadedConfigBaseline = null;
    bulkDownloadCompleted = false;
  }

  bool get hasPanelConfigChanges {
    if (!bulkDownloadCompleted || downloadedConfigBaseline == null) {
      return true;
    }

    final current = PeripheralConfigSnapshot.fromBleManager(_bleManager);
    final result = PeripheralConfigSnapshot.compare(
      panelBySection: downloadedConfigBaseline!,
      localBySection: current,
    );

    return kPeripheralConfigApplyOrder.any(
      (section) => result.sectionMatch[section.key] != true,
    );
  }

  Future<void> confirmFinishAndApply() async {
    final ui = _ui;
    if (ui == null) return;

    await ui.settleImeBeforeShowingDialog();
    if (!ui.isMounted) return;

    if (skippedPanelConnect) {
      final proceed = await ui.showCreateSiteConfirmDialog();
      if (proceed != true || !ui.isMounted) return;
      await finishCreateSiteWithoutPanel();
      return;
    }

    if (commitPanelInfoHandler == null ||
        !(await commitPanelInfoHandler!.call())) {
      ui.showSnackBar(StringConstants.fixPanelInformationFields, isError: true);
      return;
    }

    if (!bulkDownloadCompleted) {
      ui.showSnackBar(
        UiStrings.configDownloadRequiredSnackBar,
        isError: true,
      );
      return;
    }

    final needsUpload = hasPanelConfigChanges;
    final proceed =
        needsUpload
            ? await ui.showApplyPanelSettingsConfirmDialog()
            : await ui.showCreateSiteNoConfigChangesConfirmDialog();
    if (proceed != true || !ui.isMounted) return;
    await finishCreateSiteBulkApplyAndOpenDashboard(skipUpload: !needsUpload);
  }

  Future<bool> runPostConnectAssignedPanelFlow() async {
    final ui = _ui;
    if (ui == null) return false;

    final device = connectedDevice;
    if (device == null) return false;

    final bleName = device.name.trim();
    if (bleName.isEmpty) return true;

    var panel =
        await _panelService.getPanelByPanelId(bleName) ??
        await _panelService.getPanelByBleName(bleName);
    if (panel?.siteId == null) return true;

    if (!ui.isMounted) return false;
    await ui.settleImeBeforeShowingDialog();
    if (!ui.isMounted) return false;

    final choice = await ui.showPanelAlreadyOnSiteDialog();

    if (choice == 'skip') {
      if (_bleManager.isConnected) {
        await _bleManager.disconnectConnectedDevice();
      }
      setCreateProjectPanelBleVerified(false);
      setConnectedDevice(null);
      wizardDeviceId = '';
      update();
      ui.popToHome();
      return false;
    }

    if (choice == 'move') {
      await _panelService.unassignPanelFromSite(panel!.panelId);
    }
    return true;
  }

  /// Downloads full panel config after connect. Required before continuing the
  /// wizard or finishing with a connected panel.
  ///
  /// Returns true when download completed successfully (or panel connect was
  /// skipped). Returns false when download failed or was not run.
  Future<bool> requireBulkDownloadIfNeeded() async {
    final ui = _ui;
    if (ui == null) return false;

    if (skippedPanelConnect) return true;
    if (bulkDownloadCompleted) return true;

    if (!ui.isMounted) return false;
    await ui.settleImeBeforeShowingDialog();
    if (!ui.isMounted) return false;

    if (!offeredBulkDownload) {
      offeredBulkDownload = true;
      await ui.showMandatoryConfigDownloadDialog();
      if (!ui.isMounted) return false;
    }

    if (connectedDevice == null) return false;
    await runBulkDownload();
    return bulkDownloadCompleted;
  }

  PanelConfigurationCoordinator _panelCoordinator(
    DiscoveredDevice device, {
    bool useDialogOnlyBulkProgress = false,
  }) {
    return PanelConfigurationCoordinator(
      bleManager: _bleManager,
      bleController: _bleController,
      device: device,
      refreshNotifiers: panelRefreshNotifiers,
      navigatingToDeviceConnecting: navigatingToDeviceConnecting,
      useDialogOnlyBulkProgress: useDialogOnlyBulkProgress,
    );
  }

  Future<void> runBulkDownload() async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    final device = connectedDevice;
    if (device == null) return;

    _clearDownloadedConfigBaseline();
    final downloadCompleted = await _panelCoordinator(
      device,
      useDialogOnlyBulkProgress: true,
    ).startBulkDownloadAwaitCompletion(
      context: ui.uiContext,
      isMounted: () => ui.isMounted,
    );
    if (!ui.isMounted) return;
    if (downloadCompleted) {
      _captureDownloadedConfigBaseline();
    }
  }

  Future<void> runBulkApply() async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    final device = connectedDevice ?? _bleManager.selectedDevice;
    if (device == null) return;

    await _panelCoordinator(
      device,
    ).startBulkApply(context: ui.uiContext, isMounted: () => ui.isMounted);
  }

  Future<void> finishCreateSiteBulkApplyAndOpenDashboard({
    bool skipUpload = false,
  }) async {
    final ui = _ui;
    if (ui == null) return;

    final device = connectedDevice ?? _bleManager.selectedDevice;
    if (device == null) {
      ui.showSnackBar(StringConstants.noConnectedPanel, isError: true);
      return;
    }

    final errors = _siteService.validateSiteData(
      siteName: siteNameController.text,
      installerName: installerNameController.text,
      companyName: companyNameController.text,
      saqccRegNumber: saqccRegNumberController.text,
      buildingName: buildingNameController.text,
      installerContactNumber: installerContactNumberController.text,
      installerEmail: installerEmailController.text,
      siteDescription: siteDescriptionController.text,
    );
    if (errors.isNotEmpty) {
      ui.showSnackBar(StringConstants.pleaseFixTheSiteFormStep1, isError: true);
      return;
    }

    try {
      final site = await _siteService.createSite(
        siteName: siteNameController.text,
        installerName: installerNameController.text,
        companyName: companyNameController.text,
        saqccRegNumber: saqccRegNumberController.text,
        buildingName: buildingNameController.text,
        installerContactNumber: installerContactNumberController.text,
        installerEmail: installerEmailController.text,
        siteDescription: siteDescriptionController.text,
      );

      final siteId = site.id;
      if (siteId == null) {
        ui.showSnackBar(StringConstants.siteCreatedButMissingId, isError: true);
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
        ui.showSnackBar(
          StringConstants.couldNotAssignPanelToSite,
          isError: true,
        );
        return;
      }

      if (!ui.isMounted) return;

      if (skipUpload) {
        await PanelConfigCacheSync.saveAllFromBle(
          _bleManager,
          device.id,
          panelRefreshNotifiers,
        );
      } else {
        await runBulkApply();
      }

      if (!ui.isMounted) return;

      ui.showSnackBar(
        StringConstants.siteReadyOpeningDashboard,
        isError: false,
      );

      ui.openProjectDashboard(
        device: device,
        siteId: siteId,
        siteName: site.siteName,
      );
    } catch (e) {
      ui.showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> finishCreateSiteWithoutPanel() async {
    final ui = _ui;
    if (ui == null) return;

    if (commitPanelInfoHandler == null ||
        !(await commitPanelInfoHandler!.call())) {
      ui.showSnackBar(StringConstants.fixPanelInformationFields, isError: true);
      return;
    }

    final normalizedPanelId = BleNameUtils.normalizeManualPanelId(
      manualPanelId,
    );
    if (normalizedPanelId.isEmpty) {
      ui.showSnackBar(StringConstants.panelIDIsMissing, isError: true);
      return;
    }

    final errors = _siteService.validateSiteData(
      siteName: siteNameController.text,
      installerName: installerNameController.text,
      companyName: companyNameController.text,
      saqccRegNumber: saqccRegNumberController.text,
      buildingName: buildingNameController.text,
      installerContactNumber: installerContactNumberController.text,
      installerEmail: installerEmailController.text,
      siteDescription: siteDescriptionController.text,
    );
    if (errors.isNotEmpty) {
      ui.showSnackBar(StringConstants.pleaseFixTheSiteFormStep1, isError: true);
      return;
    }

    try {
      final site = await _siteService.createSite(
        siteName: siteNameController.text,
        installerName: installerNameController.text,
        companyName: companyNameController.text,
        saqccRegNumber: saqccRegNumberController.text,
        buildingName: buildingNameController.text,
        installerContactNumber: installerContactNumberController.text,
        installerEmail: installerEmailController.text,
        siteDescription: siteDescriptionController.text,
      );

      final siteId = site.id;
      if (siteId == null) {
        ui.showSnackBar(StringConstants.siteCreatedButMissingId, isError: true);
        return;
      }

      final bleDisplayName = BleNameUtils.technoswitchBleNameForPanelId(
        normalizedPanelId,
      );
      final assigned = await _siteService.assignPanelToSite(
        normalizedPanelId,
        siteId,
        panelName: bleDisplayName,
        offlineProvisioned: true,
      );
      if (!assigned) {
        ui.showSnackBar(
          StringConstants.couldNotAssignPanelToSite,
          isError: true,
        );
        return;
      }

      if (!ui.isMounted) return;

      ui.showSnackBar(StringConstants.siteCreatedSuccessfully, isError: false);

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

      if (!ui.isMounted) return;

      ui.openSiteScreen(site: site, siteWithLogCount: siteWithLogCount);
    } catch (e) {
      ui.showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> skipPanelConnectAndContinue() async {
    final ui = _ui;
    if (ui == null) return;

    if (!validateStep(2)) {
      ui.showSnackBar(
        StringConstants.pleaseFillInAllRequiredFields,
        isError: true,
      );
      return;
    }

    await ui.settleImeBeforeShowingDialog();
    if (!ui.isMounted) return;

    final existingId = BleNameUtils.normalizeManualPanelId(manualPanelId);
    final entered = await ui.showEnterPanelIdDialog(
      initialValue: existingId.isNotEmpty ? existingId : null,
    );

    if (!ui.isMounted || entered == null) return;

    final panelId = BleNameUtils.normalizeManualPanelId(entered);
    final existingPanel = await _panelService.getPanelByPanelId(panelId);
    if (existingPanel?.siteId != null) {
      if (!ui.isMounted) return;
      await ui.showPanelAlreadyAssignedDialog();
      return;
    }

    setSkippedPanelConnect(skipped: true, panelId: panelId);
    setCreateProjectPanelBleVerified(false);
    setConnectedDevice(null);
    wizardDeviceId = panelId;
    offeredBulkDownload = false;
    _clearDownloadedConfigBaseline();

    clearValidationErrors();
    await ui.dismissKeyboardFully();
    if (!ui.isMounted) return;
    await _animateNextPage?.call();
  }

  Future<void> goToNextStep() async {
    final ui = _ui;
    if (ui == null) return;

    await ui.dismissKeyboardFully();
    if (!ui.isMounted) return;

    if (currentStep == 11) {
      await confirmFinishAndApply();
      return;
    }

    if (currentStep <= 2 && !validateStep(currentStep)) {
      ui.showSnackBar(
        StringConstants.pleaseFillInAllRequiredFields,
        isError: true,
      );
      return;
    }

    if (currentStep == 2) {
      clearValidationErrors();
      await ui.dismissKeyboardFully();
      if (!ui.isMounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!ui.isMounted) return;

      final verified = await ui.openScanningScreen(panelData.selectedPanelType);
      if (!ui.isMounted) return;
      if (verified != true) return;

      final device = _bleManager.selectedDevice;
      if (device == null) {
        ui.showSnackBar(StringConstants.connectionLostNoDevice, isError: true);
        return;
      }

      setCreateProjectPanelBleVerified(true);
      setConnectedDevice(device);
      clearSkippedPanelConnect();
      wizardDeviceId = device.id;
      update();

      final proceed = await runPostConnectAssignedPanelFlow();
      if (!proceed || !ui.isMounted) return;

      final downloaded = await requireBulkDownloadIfNeeded();
      if (!ui.isMounted) return;
      if (!downloaded) {
        offeredBulkDownload = false;
        ui.showSnackBar(
          UiStrings.configDownloadFailedSnackBar,
          isError: true,
        );
        return;
      }

      clearValidationErrors();
      await ui.dismissKeyboardFully();
      if (!ui.isMounted) return;
      await _animateNextPage?.call();
      return;
    }

    if (currentStep >= 3 && currentStep <= 10) {
      final ok = await commitCurrentStepHandler?.call() ?? true;
      if (!ok) {
        ui.showSnackBar(
          StringConstants.fixTheFieldsOnThisStepBeforeContinuing,
          isError: true,
        );
        return;
      }
    }

    clearValidationErrors();
    await ui.dismissKeyboardFully();
    if (!ui.isMounted) return;
    await _animateNextPage?.call();
  }

  Future<void> goToPreviousStep() async {
    if (currentStep > 1) {
      if (currentStep == 3) {
        if (skippedPanelConnect) {
          clearSkippedPanelConnect();
        } else {
          _bleManager.disconnectConnectedDevice();
          setCreateProjectPanelBleVerified(false);
          setConnectedDevice(null);
        }
        wizardDeviceId = '';
        offeredBulkDownload = false;
        _clearDownloadedConfigBaseline();
        update();
      }
      await _animatePreviousPage?.call();
    }
  }

  @override
  void onClose() {
    detachUi();
    BleSessionIdlePolicy.suppressIdleDisconnect.value = false;
    relayRefresh.dispose();
    inputRefresh.dispose();
    zoneRefresh.dispose();
    extOutRefresh.dispose();
    sounderRefresh.dispose();
    serviceDueRefresh.dispose();
    accessCodeRefresh.dispose();
    panelInfoRefresh.dispose();
    generalModuleRefresh.dispose();
    navigatingToDeviceConnecting.dispose();
    siteNameController.dispose();
    installerNameController.dispose();
    companyNameController.dispose();
    saqccRegNumberController.dispose();
    buildingNameController.dispose();
    installerContactNumberController.dispose();
    installerEmailController.dispose();
    siteDescriptionController.dispose();
    panelNameController.dispose();
    super.onClose();
  }
}
