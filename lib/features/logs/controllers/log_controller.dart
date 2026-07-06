import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_type.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/models/log_retrieval_model.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_msd_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/log_retrieval_service.dart';
import 'package:techno_switch_solar_app/utils/panel_service.dart';
import 'package:techno_switch_solar_app/utils/pdf/pdf_report_util.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

class LogController extends GetxController {
  LogController({required this.args});

  /// Guards against duplicate saves when programmatically popping Completed.
  static bool suppressCompletedBackSave = false;

  /// Set after logs are persisted for a dashboard retrieval session.
  static bool dashboardLogsStoredThisSession = false;

  static void resetDashboardLogSessionFlags() {
    suppressCompletedBackSave = false;
    dashboardLogsStoredThisSession = false;
  }

  static bool consumeSuppressCompletedBackSave() {
    if (!suppressCompletedBackSave) return false;
    suppressCompletedBackSave = false;
    return true;
  }

  final LogFlowArgs args;

  LogUiDelegate? _ui;

  late final BleManager bleManager;
  late final BleLogController bleLogController;
  final LogRetrievalService _logRetrievalService = LogRetrievalService();
  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();

  List<LogRetrievalModel> logRetrievals = [];
  bool isLoading = true;
  bool hasNavigatedToCompleted = false;
  bool allowExit = false;
  bool isHandlingBack = false;

  bool isListSelected = true;
  int selectedViewIndex = 0;
  bool useProvidedLogs = false;
  DateTime? fromDate;
  DateTime? toDate;
  final Set<String> selectedStatuses = {};
  final Set<String> selectedEventClasses = {};
  String? alarmCount;
  List<LogModel> filteredLogs = [];
  bool filtersApplied = false;
  int textFieldResetKey = 0;
  List<LogModel>? providedLogsOverride;

  final TextEditingController eventIdFilterController = TextEditingController();

  Timer? failedAutoPopTimer;
  VoidCallback? _logRetrievalListener;

  void attachUi(LogUiDelegate ui) {
    _ui = ui;
  }

  void detachUi() {
    _ui = null;
  }

  LogHistoryArgs? get historyArgs => args.history;
  LogLoadingArgs? get loadingArgs => args.loading;
  LogCompletedArgs? get completedArgs => args.completed;
  LogEventLogArgs? get eventLogArgs => args.eventLog;

  BleManager get ble => bleManager;

  @override
  void onInit() {
    super.onInit();
    bleManager = Get.find<BleManager>();
    bleLogController = Get.find<BleLogController>();

    switch (args.mode) {
      case LogFlowMode.history:
        loadHistory();
      case LogFlowMode.loading:
        if (loadingArgs?.fromProjectDashboard == true) {
          resetDashboardLogSessionFlags();
        }
        _setupLoadingListener();
      case LogFlowMode.failed:
        _startFailedAutoPop();
      case LogFlowMode.eventLog:
        _initEventLog();
      case LogFlowMode.completed:
        break;
    }
  }

  @override
  void onClose() {
    _teardownLoadingListener();
    failedAutoPopTimer?.cancel();
    if (args.mode == LogFlowMode.eventLog &&
        eventLogArgs?.isLiveEventLogs == true) {
      bleLogController.stopLiveEventSetup();
    }
    eventIdFilterController.dispose();
    super.onClose();
  }

  void reinitializeForHistoryTab() {
    if (args.mode != LogFlowMode.history) return;
    if (!Get.isRegistered<LogController>(tag: LogBinding.historyTag)) return;
    loadHistory();
  }

  Future<void> loadHistory() async {
    final history = historyArgs;
    if (history == null) return;

    isLoading = true;
    update();

    if (history.siteId == null || history.siteId == 0) {
      logRetrievals = [];
      isLoading = false;
      update();
      return;
    }

    try {
      logRetrievals = await _logRetrievalService.getLogRetrievalsForSite(
        history.siteId!,
      );
    } catch (_) {
      logRetrievals = [];
    }

    isLoading = false;
    update();
  }

  Future<void> openLogSession(LogRetrievalModel logRetrieval) async {
    final ui = _ui;
    if (ui == null) return;

    if (logRetrieval.id == null) {
      ui.showSnackBar(StringConstants.unableToOpenThisLogSessionMissingId);
      return;
    }

    ui.showLoadingDialog();

    try {
      final logs = await _logRetrievalService.getLogsForRetrieval(logRetrieval);
      if (_ui?.isMounted != true) return;
      ui.popRootDialog();
      ui.openEventLogScreen(
        args: LogFlowArgs.eventLog(
          logDataList: logs,
          panelName: historyArgs!.panelName,
          panelVersionNo: historyArgs!.panelVersionNo,
          isHistoryView: true,
          siteId: historyArgs!.siteId,
        ),
      );
    } catch (e) {
      if (_ui?.isMounted == true) {
        ui.popRootDialog();
        ui.showSnackBar('${StringConstants.failedToLoadLogsPrefix}$e');
      }
    }
  }

  void _setupLoadingListener() {
    _logRetrievalListener = _onLogRetrievalCompleted;
    bleManager.bleProcess.read1000LogsCount.addListener(_logRetrievalListener!);
  }

  void _teardownLoadingListener() {
    if (_logRetrievalListener != null) {
      bleManager.bleProcess.read1000LogsCount.removeListener(
        _logRetrievalListener!,
      );
    }
  }

  void _onLogRetrievalCompleted() {
    if (bleManager.bleProcess.read1000LogsCount.value >= 1000 &&
        !hasNavigatedToCompleted) {
      hasNavigatedToCompleted = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_ui?.isMounted == true) {
          _navigateToCompletedScreen();
        }
      });
    }
  }

  void _navigateToCompletedScreen() {
    final ui = _ui;
    final loading = loadingArgs;
    if (ui == null || loading == null) return;

    ui.openCompletedScreen(
      args: LogFlowArgs.completed(
        logs: List.from(bleManager.bleProcess.validEventLogs.value),
        panelId: resolvePanelId(),
        panelName: resolveDeviceName(),
        connectedDevice: loading.connectedDevice,
        isDirectLogRet: loading.isLiveEvent,
        siteId: loading.siteId,
        fromProjectDashboard: loading.fromProjectDashboard,
      ),
    );
  }

  String resolvePanelIdFromDevice(DiscoveredDevice device) {
    if ((loadingArgs?.panelId ?? '').isNotEmpty) {
      return loadingArgs!.panelId!;
    }

    final msdPanelId = BleMsdUtils.panelId(device.manufacturerData);
    if (msdPanelId != null) {
      return msdPanelId.toString();
    }

    final bleName = device.name.trim();
    if (bleName.isNotEmpty) {
      final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
      if (logicalId != null) return logicalId;
      return bleName;
    }

    return device.id;
  }

  String resolvePanelId() {
    final loading = loadingArgs;
    if (loading == null) return '';

    if ((loading.panelId ?? '').isNotEmpty) {
      return loading.panelId!;
    }

    final device = loading.connectedDevice ?? loading.selectedDevice;
    if (device is DiscoveredDevice) {
      return resolvePanelIdFromDevice(device);
    }

    return resolveDeviceName();
  }

  Future<PanelModel?> _findPanel({
    required String panelId,
    required String panelName,
  }) async {
    if (panelId.isNotEmpty) {
      final byId = await _panelService.getPanelByPanelId(panelId);
      if (byId != null) return byId;
    }

    final bleName = panelName.trim();
    if (bleName.isEmpty) return null;

    final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
    if (logicalId != null) {
      final byLogical = await _panelService.getPanelByPanelId(logicalId);
      if (byLogical != null) return byLogical;
    }

    final byBleName = await _panelService.getPanelByPanelId(bleName);
    if (byBleName != null) return byBleName;

    return _panelService.getPanelByBleName(bleName);
  }

  Future<int?> _resolveSiteIdForLogs({
    int? explicitSiteId,
    required String panelId,
    required String panelName,
  }) async {
    if (explicitSiteId != null && explicitSiteId > 0) {
      final site = await _siteService.getSiteById(explicitSiteId);
      if (site != null) return explicitSiteId;
    }

    final panel = await _findPanel(panelId: panelId, panelName: panelName);
    if (panel?.siteId != null) {
      final site = await _siteService.getSiteById(panel!.siteId!);
      if (site != null) return site.id;
    }

    return null;
  }

  Future<void> _storeLogsAndNavigateBack({
    required List<LogModel> logs,
    required int siteId,
    required bool fromProjectDashboard,
    bool isDirectLogRet = false,
    int dashboardPops = 2,
  }) async {
    final ui = _ui;
    if (ui == null || logs.isEmpty) return;

    if (fromProjectDashboard && dashboardLogsStoredThisSession) {
      ui.returnAfterProjectDashboardLogSave(pops: dashboardPops);
      return;
    }

    await _siteService.storeLogs(logs, siteId: siteId);

    if (_ui?.isMounted != true) return;

    if (fromProjectDashboard) {
      dashboardLogsStoredThisSession = true;
      suppressCompletedBackSave = true;
      _notifyProjectDashboardLogsSaved();
      ui.returnAfterProjectDashboardLogSave(pops: dashboardPops);
      return;
    }

    ui.navigateBackToScanning();
    if (isDirectLogRet && _ui?.isMounted == true) {
      ui.popScreen();
    }
  }

  void _notifyProjectDashboardLogsSaved() {
    if (!Get.isRegistered<ProjectDashboardController>()) return;
    Get.find<ProjectDashboardController>().onLogsSavedToSite();
  }

  String resolveDeviceName() {
    final loading = loadingArgs;
    if (loading == null) return StringConstants.unknownDevice;

    final device = loading.selectedDevice ?? loading.connectedDevice;
    if (device == null) return StringConstants.unknownDevice;

    if (loading.scanType == ScanType.bluetooth) {
      if (device is DiscoveredDevice) {
        if (device.name.isNotEmpty) return device.name;
        return 'BLE-${device.id.substring(0, 5)}';
      }
      return StringConstants.bleDevice;
    }

    return StringConstants.unknownDevice;
  }

  Future<void> showStopConfirmationAndCancel() async {
    final ui = _ui;
    if (ui == null) return;

    final confirmed = await ui.showStopLogRetrievalDialog();
    if (confirmed != true || _ui?.isMounted != true) return;

    await sendStopControlCommand();

    if (loadingArgs?.isLiveEvent == true) {
      await bleManager.disconnectConnectedDevice();
    }
  }

  Future<void> sendStopControlCommand() async {
    bleManager.bleProcess.isOtaCompleted = true;
    bleManager.bleProcess.processNextOtaFrame = false;
    bleManager.otaProcessState = OtaProcessState.notInUse;
    bleManager.bleProcess.cancelRxTimeout();
    bleManager.bleProcess.processDesc.value = '';
    await bleManager.sendStopCntrlCmdPkt();
    allowExit = true;
    update();
    _ui?.popScreen();
  }

  void _startFailedAutoPop() {
    failedAutoPopTimer = Timer(const Duration(seconds: 4), () {
      if (_ui?.isMounted == true) {
        _ui!.popScreen();
      }
    });
  }

  void _initEventLog() {
    final event = eventLogArgs;
    if (event == null) return;

    if (event.isLiveEventLogs) {
      bleLogController.startLiveEventSetup();
    }

    useProvidedLogs = event.logDataList.isNotEmpty;
    final initialLogs =
        event.logDataList.isNotEmpty
            ? event.logDataList
            : bleManager.bleProcess.validEventLogs.value;
    filteredLogs = sortLogsByEventId(initialLogs);
    update();
  }

  String resolvedPanelName() {
    return (eventLogArgs?.panelName ?? completedArgs?.panelName ?? '').trim();
  }

  String panelDisplayName(String name) {
    return BleNameUtils.getDisplayPrefixFromBleName(name);
  }

  String resolvedPanelId() {
    final event = eventLogArgs;
    if (event != null) {
      if ((event.panelId ?? '').isNotEmpty) return event.panelId!;
      final bleName = event.panelName.trim();
      if (bleName.isNotEmpty) {
        final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
        if (logicalId != null) return logicalId;
      }
      return event.panelName;
    }
    final completed = completedArgs;
    if (completed != null) {
      if (completed.panelId.isNotEmpty) return completed.panelId;
      final bleName = completed.panelName.trim();
      if (bleName.isNotEmpty) {
        final logicalId = BleNameUtils.parseTechnoswitchPanelId(bleName);
        if (logicalId != null) return logicalId;
      }
      return completed.panelName;
    }
    return '';
  }

  bool get canClearLogs => eventLogArgs?.isLiveEventLogs == true;

  List<LogModel> sortLogsByEventId(List<LogModel> logs) {
    final sorted = List<LogModel>.from(logs);
    sorted.sort((a, b) {
      final aNum = int.tryParse(a.eventId ?? '');
      final bNum = int.tryParse(b.eventId ?? '');
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      if (aNum != null) return -1;
      if (bNum != null) return 1;
      return (a.eventId ?? '').compareTo(b.eventId ?? '');
    });
    return sorted;
  }

  List<LogModel> providedSourceLogs() {
    return providedLogsOverride ?? eventLogArgs?.logDataList ?? [];
  }

  List<LogModel> getBaseLogs() {
    final sourceLogs =
        useProvidedLogs
            ? providedSourceLogs()
            : bleManager.bleProcess.validEventLogs.value;
    return sortLogsByEventId(sourceLogs);
  }

  List<LogModel> getDisplayLogs() {
    final baseLogs = getBaseLogs();
    final afterSheetFilters = filtersApplied ? filteredLogs : baseLogs;
    final afterQuickFilter = applyEventIdQuickFilter(afterSheetFilters);
    return applyLiveDisplayOrder(afterQuickFilter);
  }

  /// Live event logs show newest entries first; history/export use ascending order.
  List<LogModel> applyLiveDisplayOrder(List<LogModel> logs) {
    if (eventLogArgs?.isLiveEventLogs != true) return logs;
    final sorted = List<LogModel>.from(logs);
    sorted.sort((a, b) {
      final aId = int.tryParse(a.eventId ?? '0') ?? 0;
      final bId = int.tryParse(b.eventId ?? '0') ?? 0;
      return bId.compareTo(aId);
    });
    return sorted;
  }

  List<LogModel> applyEventIdQuickFilter(List<LogModel> logs) {
    final q = eventIdFilterController.text.trim();
    if (q.isEmpty) return logs;
    return logs.where((log) {
      final eid = log.eventId?.trim() ?? '';
      if (eid.isEmpty) return false;
      if (eid == q) return true;
      final qNum = int.tryParse(q);
      final eNum = int.tryParse(eid);
      if (qNum != null && eNum != null && qNum == eNum) return true;
      return false;
    }).toList();
  }

  Future<void> confirmAndClearLogs() async {
    final ui = _ui;
    if (ui == null) return;

    final confirmed = await ui.showClearLogsDialog();
    if (confirmed == true) {
      performClearLogs();
    }
  }

  void performClearLogs() {
    if (useProvidedLogs) {
      providedLogsOverride = <LogModel>[];
    } else {
      bleManager.bleProcess.validEventLogs.value = <LogModel>[];
    }
    filteredLogs = [];
    filtersApplied = false;
    fromDate = null;
    toDate = null;
    selectedStatuses.clear();
    selectedEventClasses.clear();
    alarmCount = null;
    eventIdFilterController.clear();
    update();
  }

  void applyFilters() {
    final allLogs = getBaseLogs();
    filteredLogs =
        allLogs.where((log) {
          if (fromDate != null || toDate != null) {
            if (log.eventDateTime == null) return false;
            final logDate = DateTime(
              log.eventDateTime!.year,
              log.eventDateTime!.month,
              log.eventDateTime!.day,
            );
            if (fromDate != null) {
              final from = DateTime(
                fromDate!.year,
                fromDate!.month,
                fromDate!.day,
              );
              if (logDate.isBefore(from)) return false;
            }
            if (toDate != null) {
              final to = DateTime(
                toDate!.year,
                toDate!.month,
                toDate!.day,
              ).add(const Duration(days: 1));
              if (logDate.isAfter(to.subtract(const Duration(seconds: 1)))) {
                return false;
              }
            }
          }

          if (selectedStatuses.isNotEmpty) {
            if (log.eventStatus == null ||
                !selectedStatuses.contains(log.eventStatus)) {
              return false;
            }
          }

          if (selectedEventClasses.isNotEmpty) {
            if (log.eventClass == null ||
                !selectedEventClasses.contains(log.eventClass)) {
              return false;
            }
          }

          if (alarmCount != null && alarmCount!.isNotEmpty) {
            final count = int.tryParse(alarmCount!);
            if (count != null) {
              final eventId = int.tryParse(log.eventId ?? '0') ?? 0;
              if (eventId != count) return false;
            }
          }

          return true;
        }).toList();
    filteredLogs = sortLogsByEventId(filteredLogs);
    filtersApplied =
        fromDate != null ||
        toDate != null ||
        selectedStatuses.isNotEmpty ||
        selectedEventClasses.isNotEmpty ||
        (alarmCount != null && alarmCount!.isNotEmpty);
    update();
  }

  void resetFilters() {
    fromDate = null;
    toDate = null;
    selectedStatuses.clear();
    selectedEventClasses.clear();
    alarmCount = null;
    filtersApplied = false;
    textFieldResetKey++;
    filteredLogs = getBaseLogs();
    update();
  }

  Future<void> selectDate(bool isFromDate) async {
    final ui = _ui;
    if (ui == null) return;

    final picked = await ui.pickDate(
      isFromDate: isFromDate,
      fromDate: fromDate,
      toDate: toDate,
    );
    if (picked != null) {
      if (isFromDate) {
        fromDate = picked;
      } else {
        toDate = picked;
      }
      update();
    }
  }

  Future<void> exportEventLogPdf() async {
    final logs = getDisplayLogs();
    if (logs.isEmpty) return;

    var siteName = '-';
    var installerName = '-';
    var saqccNo = '-';

    final siteId = eventLogArgs?.siteId;
    if (siteId != null) {
      final site = await _siteService.getSiteById(siteId);
      if (site != null) {
        siteName = site.siteName;
        installerName = site.installerName;
        saqccNo = site.saqccRegNumber;
      }
    } else {
      final panelId = resolvedPanelId();
      if (panelId.isNotEmpty) {
        final panel = await _panelService.getPanelByPanelId(panelId);
        if (panel?.siteId != null) {
          final site = await _siteService.getSiteById(panel!.siteId!);
          if (site != null) {
            siteName = site.siteName;
            installerName = site.installerName;
            saqccNo = site.saqccRegNumber;
          }
        }
      }
    }

    await LogReportPdfUtil.generate(
      logs: logs,
      siteName: siteName,
      panelName: BleNameUtils.getDisplayPrefixFromBleName(resolvedPanelName()),
      panelSerialNumber: BleNameUtils.getDisplayIdFromBleName(
        resolvedPanelName(),
      ),
      installerName: installerName,
      saqccNo: saqccNo,
    );
  }

  Future<void> handleEventLogBackNavigation() async {
    final ui = _ui;
    final event = eventLogArgs;
    if (ui == null || event == null) return;

    if (event.isLiveEventLogs) {
      await bleLogController.stopLiveEventSetup();
      if (bleManager.isConnected) {
        await bleManager.disconnectConnectedDevice();
      }
      ui.navigateBackToHome();
      return;
    }

    if (isHandlingBack) return;
    isHandlingBack = true;
    try {
      if (event.isHistoryView) {
        ui.popScreen();
        return;
      }

      await handleRetrievalBackNavigation(
        logs: getBaseLogs(),
        panelId: resolvedPanelId(),
        panelName: resolvedPanelName(),
        panelVersionNo: event.panelVersionNo,
        connectedDevice: event.connectedDevice,
        isDirectLogRet: event.isDirectLogRet,
        isStandalone: event.isStandalone,
        siteId: event.siteId,
        fromProjectDashboard: event.fromProjectDashboard,
      );
    } finally {
      isHandlingBack = false;
    }
  }

  Future<void> handleCompletedBackNavigation() async {
    if (consumeSuppressCompletedBackSave()) return;
    if (isHandlingBack) return;

    final completed = completedArgs;
    if (completed == null) return;

    if (completed.fromProjectDashboard && dashboardLogsStoredThisSession) {
      returnAfterProjectDashboardIfMounted(pops: 1);
      return;
    }

    isHandlingBack = true;
    try {
      await handleRetrievalBackNavigation(
        logs: getBaseLogs(),
        panelId: resolvedPanelId(),
        panelName: resolvedPanelName(),
        panelVersionNo: StringConstants.s098,
        connectedDevice: completed.connectedDevice,
        isDirectLogRet: completed.isDirectLogRet,
        isStandalone: false,
        siteId: completed.siteId,
        fromProjectDashboard: completed.fromProjectDashboard,
        dashboardPops: 1,
      );
    } finally {
      isHandlingBack = false;
    }
  }

  void returnAfterProjectDashboardIfMounted({required int pops}) {
    if (_ui?.isMounted == true) {
      _ui!.returnAfterProjectDashboardLogSave(pops: pops);
    }
  }

  Future<void> handleRetrievalBackNavigation({
    required List<LogModel> logs,
    required String panelId,
    required String panelName,
    required String panelVersionNo,
    DiscoveredDevice? connectedDevice,
    bool isDirectLogRet = false,
    bool isStandalone = false,
    int? siteId,
    bool fromProjectDashboard = false,
    int dashboardPops = 2,
  }) async {
    final ui = _ui;
    if (ui == null) return;

    if (logs.isEmpty) {
      if (fromProjectDashboard) {
        ui.returnAfterProjectDashboardLogSave(pops: dashboardPops);
      } else {
        ui.navigateBackToScanning();
      }
      return;
    }

    if (fromProjectDashboard && dashboardLogsStoredThisSession) {
      ui.returnAfterProjectDashboardLogSave(pops: dashboardPops);
      return;
    }

    final resolvedSiteId = await _resolveSiteIdForLogs(
      explicitSiteId: siteId,
      panelId: panelId,
      panelName: panelName,
    );

    if (resolvedSiteId != null) {
      await _storeLogsAndNavigateBack(
        logs: logs,
        siteId: resolvedSiteId,
        fromProjectDashboard: fromProjectDashboard,
        isDirectLogRet: isDirectLogRet,
        dashboardPops: dashboardPops,
      );
      return;
    }

    if (isStandalone && logs.isNotEmpty) {
      final shouldCreateSite = await ui.showSiteCreationDialog(
        logCount: logs.length,
      );
      final displayName = panelDisplayName(panelName);

      if (shouldCreateSite == true) {
        if (connectedDevice != null) {
          await ui.disconnectConnectedDevice(connectedDevice);
        }
        if (_ui?.isMounted == true) {
          ui.openSimpleSiteCreationScreen(
            logs: logs,
            panelName: displayName,
            panelVersionNo: panelVersionNo,
            panelId: panelId,
          );
        }
        return;
      }
    } else if (logs.isNotEmpty) {
      final shouldCreateSite = await ui.showSiteCreationDialog(
        logCount: logs.length,
      );
      final displayName = panelDisplayName(panelName);

      if (shouldCreateSite == true) {
        if (connectedDevice != null) {
          await ui.disconnectConnectedDevice(connectedDevice);
        }
        if (_ui?.isMounted == true) {
          ui.openSimpleSiteCreationScreen(
            logs: logs,
            panelName: displayName,
            panelVersionNo: panelVersionNo,
            panelId: panelId,
          );
        }
        return;
      }
    }

    if (_ui?.isMounted == true) {
      if (fromProjectDashboard) {
        ui.returnAfterProjectDashboardLogSave(pops: dashboardPops);
      } else {
        ui.navigateBackToScanning();
      }
    }
  }

  void openEventLogFromCompleted() {
    final completed = completedArgs;
    final ui = _ui;
    if (completed == null || ui == null) return;

    ui.openEventLogScreen(
      args: LogFlowArgs.eventLog(
        logDataList: completed.logs,
        panelName: completed.panelName,
        panelVersionNo: StringConstants.s098,
        isStandalone: !completed.fromProjectDashboard,
        panelId: completed.panelId,
        connectedDevice: completed.connectedDevice,
        isDirectLogRet: completed.isDirectLogRet,
        siteId: completed.siteId,
        fromProjectDashboard: completed.fromProjectDashboard,
      ),
    );
  }

  void setListSelected(bool value) {
    isListSelected = value;
    update();
  }

  void setSelectedViewIndex(int index) {
    selectedViewIndex = index;
    update();
  }

  void onEventIdFilterChanged() {
    update();
  }

  void syncLogsFromWidget(List<LogModel> logDataList) {
    if (!listEquals(logDataList, eventLogArgs?.logDataList ?? [])) {
      providedLogsOverride = null;
      useProvidedLogs = logDataList.isNotEmpty;
      filteredLogs = sortLogsByEventId(
        logDataList.isNotEmpty
            ? logDataList
            : bleManager.bleProcess.validEventLogs.value,
      );
      update();
    }
  }
}
