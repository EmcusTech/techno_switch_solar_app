import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/bindings/create_project_binding.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/scan/bindings/scan_binding.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/views/scanning_screen.dart';
import 'package:techno_switch_solar_app/features/create_project/views/create_project_screen.dart';
import 'package:techno_switch_solar_app/utils/app/app_services.dart';
import 'package:techno_switch_solar_app/utils/app/app_state.dart';
import 'package:techno_switch_solar_app/utils/log_retrieval_service.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:flutter/material.dart';

class HomeScreenController extends GetxController {
  HomeScreenUiDelegate? _ui;

  final SiteService _siteService = SiteService();
  final LogRetrievalService _logRetrievalService = LogRetrievalService();

  late final BleManager bleManager;

  int selectedIndex = 0;
  List<SiteWithLogCount> sites = [];
  bool isLoading = true;
  Map<int, int> lastRetrievalCounts = {};
  Map<int, DateTime?> lastRetrievalDates = {};

  void attachUi(HomeScreenUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  @override
  void onInit() {
    super.onInit();
    bleManager = Get.find<BleLogController>().bleManager;
    handleBluetoothCleanup();
    loadSites();
  }

  Future<void> handleBluetoothCleanup() async {
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }
    AppState.reset();
  }

  void setSelectedIndex(int index) {
    if (index == 1 || index == 2) return;
    selectedIndex = index;
    update();
  }

  Future<void> loadSites() async {
    try {
      final loadedSites = await _siteService.getSitesWithLogCount();
      await loadLatestRetrievals(loadedSites);
      sites = loadedSites;
      isLoading = false;
      update();
    } catch (_) {
      isLoading = false;
      update();
    }
  }

  Future<void> refreshSites() async {
    isLoading = true;
    update();
    await loadSites();
  }

  Future<void> loadLatestRetrievals(List<SiteWithLogCount> loadedSites) async {
    final counts = <int, int>{};
    final dates = <int, DateTime?>{};

    for (final siteWithCount in loadedSites) {
      final siteId = siteWithCount.site.id;
      if (siteId == null) continue;

      try {
        final latest = await _logRetrievalService.getMostRecentLogRetrieval(
          siteId,
        );
        if (latest != null) {
          counts[siteId] = latest.logCount;
          dates[siteId] = latest.retrievalDate;
        } else {
          dates[siteId] = siteWithCount.lastLogRetrieved;
        }
      } catch (_) {
        dates[siteId] = siteWithCount.lastLogRetrieved;
      }
    }

    lastRetrievalCounts = counts;
    lastRetrievalDates = dates;
  }

  DateTime siteSummaryDate(SiteWithLogCount siteWithLogCount) {
    final siteId = siteWithLogCount.site.id;
    if (siteId != null) {
      final retrievalDate = lastRetrievalDates[siteId];
      if (retrievalDate != null) return retrievalDate;
    }
    return siteWithLogCount.lastLogRetrieved ?? siteWithLogCount.site.createdAt;
  }

  Future<void> disconnectBleIfConnected() async {
    if (bleManager.isConnected) {
      await bleManager.disconnectConnectedDevice();
    }
  }

  Future<void> openTapToConnectScan() async {
    await disconnectBleIfConnected();
    await openScanning(ScanFlowArgs.scanning());
  }

  Future<void> openLiveEventsScan() async {
    await openScanning(ScanFlowArgs.scanning(isLiveEventLogs: true));
  }

  Future<void> openRetrieveLogScan() async {
    await openScanning(ScanFlowArgs.scanning(isLiveEvent: true));
  }

  Future<void> openScanning(ScanFlowArgs args) async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    ScanBinding(args: args).dependencies();
    await Navigator.of(ui.uiContext).push(
      MaterialPageRoute(builder: (_) => const ScanningScreen()),
    );
  }

  void openNewSite() {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    CreateProjectBinding().dependencies();
    Navigator.of(ui.uiContext).push(
      MaterialPageRoute(builder: (_) => const CreateSiteScreen()),
    );
  }

  Future<void> openSite(SiteWithLogCount siteWithLogCount) async {
    final ui = _ui;
    if (ui == null || !ui.isMounted) return;

    final deleted = await ui.openSite(
      site: siteWithLogCount.site,
      siteWithLogCount: siteWithLogCount,
    );

    if (deleted == true) {
      await refreshSites();
    }
  }
}
