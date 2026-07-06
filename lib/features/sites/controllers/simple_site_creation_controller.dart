import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/models/create_project/site_creation_page_model.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

class SimpleSiteCreationController extends GetxController {
  SimpleSiteCreationController({required this.args});

  final SimpleSiteCreationArgs args;

  SimpleSiteCreationUiDelegate? _ui;

  final SiteService _siteService = SiteService();
  final PanelService _panelService = PanelService();
  late final BleManager _bleManager;

  late final TextEditingController siteNameController;
  late final TextEditingController installerNameController;
  late final TextEditingController companyNameController;
  late final TextEditingController saqccRegNumberController;
  late final TextEditingController buildingNameController;
  late final TextEditingController installerContactNumberController;
  late final TextEditingController installerEmailController;
  late final TextEditingController siteDescriptionController;

  bool isLoading = false;
  Map<String, String> validationErrors = {};

  bool get returnCreatedSiteId => args.returnCreatedSiteId;

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

  void attachUi(SimpleSiteCreationUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  @override
  void onInit() {
    super.onInit();
    _bleManager = Get.find<BleManager>();
    siteNameController = TextEditingController();
    installerNameController = TextEditingController();
    companyNameController = TextEditingController();
    saqccRegNumberController = TextEditingController();
    buildingNameController = TextEditingController();
    installerContactNumberController = TextEditingController();
    installerEmailController = TextEditingController();
    siteDescriptionController = TextEditingController();
  }

  @override
  void onClose() {
    siteNameController.dispose();
    installerNameController.dispose();
    companyNameController.dispose();
    saqccRegNumberController.dispose();
    buildingNameController.dispose();
    installerContactNumberController.dispose();
    installerEmailController.dispose();
    siteDescriptionController.dispose();
    detachUi();
    super.onClose();
  }

  Future<void> submit() async {
    if (isLoading) return;

    isLoading = true;
    validationErrors = {};
    update();

    try {
      final panelIdToCheck = args.panelId;

      if (panelIdToCheck != null) {
        final existingPanel = await _panelService.getPanelByPanelId(
          panelIdToCheck,
        );

        if (existingPanel != null && existingPanel.siteId != null) {
          final existingSite = await _siteService.getSiteById(
            existingPanel.siteId!,
          );
          if (existingSite != null) {
            await _siteService.storeLogs(
              args.retrievedLogs,
              siteId: existingSite.id!,
            );
            final allSitesWithLogCount =
                await _siteService.getSitesWithLogCount();
            final updatedSiteWithLogCount = allSitesWithLogCount.firstWhere(
              (siteWithLogCount) => siteWithLogCount.site.id == existingSite.id,
              orElse:
                  () => SiteWithLogCount(
                    site: existingSite,
                    logCount: args.retrievedLogs.length,
                    lastLogRetrieved: DateTime.now(),
                  ),
            );

            final ui = _ui;
            if (ui != null && ui.isMounted) {
              await ui.openExistingSite(
                site: existingSite,
                siteWithLogCount: updatedSiteWithLogCount,
              );
            }
            return;
          }
        } else {
          Logger(
            'DEBUG: SimpleSiteCreation - Panel exists but no siteId, or panel not found',
          );
        }
      } else {
        Logger('DEBUG: SimpleSiteCreation - No panel ID to check');
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
        validationErrors = errors;
        isLoading = false;
        update();
        return;
      }

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

      await _siteService.storeLogs(args.retrievedLogs, siteId: site.id!);

      final panelIdToAssociate = args.panelId;
      if (panelIdToAssociate != null) {
        try {
          final existingPanel = await _siteService.getPanelByPanelId(
            panelIdToAssociate,
          );
          if (existingPanel != null) {
            Logger(
              'DEBUG: Existing panel details: ${existingPanel.toString()}',
            );
          } else {
            Logger(
              'DEBUG: Panel does not exist - will be created during assignment',
            );
          }

          await _siteService.associateCurrentPanelWithSite(
            panelIdToAssociate,
            site.id!,
            panelName: args.panelName,
          );
        } catch (_) {}
      } else {
        Logger(
          'DEBUG: No panel ID found - panel was not registered during connection or not passed to constructor',
        );
      }

      final ui = _ui;
      if (ui == null || !ui.isMounted) return;

      ui.showSuccessSnackBar(
        'Site created successfully! ${args.retrievedLogs.length} logs saved.',
      );

      if (args.returnCreatedSiteId) {
        ui.popScreen(site.id);
      } else {
        ui.openHomeAndClearStack();
      }
    } catch (_) {
      isLoading = false;
      update();
    }
  }

  Future<void> disconnectBleDevice() async {
    if (_bleManager.isConnected) {
      await _bleManager.disconnectConnectedDevice();
    }
  }

  Future<void> cancel() async {
    if (isLoading) return;

    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    if (args.returnCreatedSiteId) {
      ui.popScreen(null);
      await ui.disconnectBle();
    } else {
      ui.openHomeAndClearStack();
    }
  }

  void handleBackNavigation() {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    ui.popBack();
  }
}
