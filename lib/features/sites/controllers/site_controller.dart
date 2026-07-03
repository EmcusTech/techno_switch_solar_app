import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/log_retrieval_service.dart';
import 'package:techno_switch_solar_app/utils/logger.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class SiteController extends GetxController {
  SiteController({required this.args});

  final SiteArgs args;

  SiteUiDelegate? _ui;

  final SiteService _siteService = SiteService();
  final LogRetrievalService _logRetrievalService = LogRetrievalService();
  final PanelService _panelService = PanelService();

  List<PanelModel> panels = [];
  bool isLoading = true;
  bool isDeletingSite = false;
  int? lastRetrievalLogCount;
  DateTime? lastRetrievalDate;

  SiteModel get site => args.site;

  SiteWithLogCount get siteWithLogCount => args.siteWithLogCount;

  void attachUi(SiteUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  @override
  void onInit() {
    super.onInit();
    loadPanels();
    loadLatestRetrievalInfo();
  }

  Future<void> loadPanels() async {
    try {
      panels = await _siteService.getSitePanels(site.id!);
      isLoading = false;
      update();
    } catch (_) {
      isLoading = false;
      update();
    }
  }

  Future<void> loadLatestRetrievalInfo() async {
    try {
      final latest = await _logRetrievalService.getMostRecentLogRetrieval(
        site.id!,
      );
      lastRetrievalLogCount = latest?.logCount;
      lastRetrievalDate = latest?.retrievalDate;
      update();
    } catch (error) {
      Logger('Error loading latest retrieval info: $error');
    }
  }

  Future<void> refreshPanels() async {
    isLoading = true;
    update();
    await loadPanels();
  }

  Future<void> confirmDeleteSite() async {
    if (site.id == null || isDeletingSite) return;

    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    final shouldDelete = await ui.showDeleteSiteDialog(siteName: site.siteName);
    if (shouldDelete == true) {
      await deleteSite();
    }
  }

  Future<void> deleteSite() async {
    final ui = _ui;
    if (ui == null || !ui.isMounted || site.id == null) return;

    isDeletingSite = true;
    update();

    try {
      final deleted = await _siteService.deleteSite(site.id!);
      if (_ui == null || !_ui!.isMounted) return;

      if (deleted) {
        ui.showSnackBar(
          StringConstants.siteDeletedMessage(site.siteName),
          backgroundColor: ColorConstants.primary,
        );
        ui.popScreen(true);
      } else {
        ui.showSnackBar(
          StringConstants.unableToDeleteSite,
          backgroundColor: ColorConstants.primary,
        );
      }
    } catch (error) {
      if (_ui?.isMounted == true) {
        ui.showSnackBar(
          '${StringConstants.errorDeletingSitePrefix}$error',
          backgroundColor: ColorConstants.primary,
        );
      }
    } finally {
      isDeletingSite = false;
      update();
    }
  }

  Future<void> confirmDeletePanel(PanelModel panel) async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    final shouldDelete = await ui.showDeletePanelDialog(panel: panel);
    if (shouldDelete == true) {
      await deletePanel(panel);
    }
  }

  Future<void> deletePanel(PanelModel panel) async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    isLoading = true;
    update();

    try {
      final deleted = await _panelService.deletePanel(panel.panelId);
      if (_ui == null || !_ui!.isMounted) return;

      if (deleted) {
        ui.showSnackBar(
          StringConstants.panelDeletedMessage(panel.panelName),
          backgroundColor: ColorConstants.primary,
        );
      } else {
        ui.showSnackBar(
          StringConstants.unableToDeletePanel,
          backgroundColor: ColorConstants.primary,
        );
      }
    } catch (error) {
      if (_ui?.isMounted == true) {
        ui.showSnackBar(
          '${StringConstants.errorDeletingPanelPrefix}$error',
          backgroundColor: ColorConstants.primary,
        );
      }
    } finally {
      await loadPanels();
    }
  }

  Future<void> openSiteDetail() async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    await ui.openSiteDetail(siteWithLogCount: siteWithLogCount);
  }

  void openPanelDashboard(PanelModel panel) {
    final ui = _ui;
    if (ui == null || !ui.isMounted || site.id == null) return;

    final panelName = panel.panelName;
    final selectedDevice = DiscoveredDevice(
      name: panelName,
      id: panel.panelId,
      rssi: 0,
      serviceData: {},
      manufacturerData: Uint8List(0),
      serviceUuids: [],
    );

    ui.openProjectDashboard(
      args: ProjectDashboardArgs(
        panelVersionNo: panel.deviceDisplayInfo,
        panelName: panelName,
        selectedDevice: selectedDevice,
        siteId: site.id!,
        siteName: site.siteName,
      ),
    );
  }

  void popBack() {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    ui.popScreen();
  }
}

class SiteDetailController extends GetxController {
  SiteDetailController({required this.args});

  final SiteDetailArgs args;

  SiteDetailUiDelegate? _ui;

  SiteWithLogCount get siteWithLogCount => args.siteWithLogCount;

  void attachUi(SiteDetailUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  void popBack() {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;
    ui.popScreen();
  }
}
