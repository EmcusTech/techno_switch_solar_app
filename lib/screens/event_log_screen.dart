// event_log_screen_sync_headers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/utils/export_tile.dart';
import 'package:techno_switch_solar_app/utils/event_constants.dart';
import 'package:techno_switch_solar_app/utils/pdf_report_util.dart';
import 'package:techno_switch_solar_app/widgets/site_creation_dialog.dart';
import 'package:techno_switch_solar_app/screens/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

class EventLogScreen extends StatefulWidget {
  final List<LogModel> logDataList;
  final String panelVersionNo;
  final String panelName;
  final bool isStandalone;
  final String? panelId;
  final bool isHistoryView;
  final DiscoveredDevice? connectedDevice;
  final int? siteId;
  final bool? isDirectLogRet;
  final bool? isLiveEventLogs;
  const EventLogScreen({
    super.key,
    required this.logDataList,
    required this.panelVersionNo,
    required this.panelName,
    this.isStandalone = false,
    this.panelId,
    this.isHistoryView = false,
    this.connectedDevice,
    this.siteId,
    this.isLiveEventLogs = false,
    this.isDirectLogRet = false,
  });

  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _EventLogContent(
        logDataList: widget.logDataList,
        panelName: widget.panelName,
        panelVersionNo: widget.panelVersionNo,
        isStandalone: widget.isStandalone,
        panelId: widget.panelId,
        isHistoryView: widget.isHistoryView,
        connectedDevice: widget.connectedDevice,
        siteId: widget.siteId,
        isLiveEventLogs: widget.isLiveEventLogs,
        isDirectLogRet: widget.isDirectLogRet,
      ),
    );
  }
}

class _EventLogContent extends StatefulWidget {
  final List<LogModel> logDataList;
  final String panelName;
  final String panelVersionNo;
  final bool isStandalone;
  final String? panelId;
  final bool isHistoryView;
  final DiscoveredDevice? connectedDevice;
  final int? siteId;
  final bool? isLiveEventLogs;
  final bool? isDirectLogRet;
  const _EventLogContent({
    required this.logDataList,
    required this.panelName,
    required this.panelVersionNo,
    required this.isStandalone,
    this.panelId,
    this.isHistoryView = false,
    this.connectedDevice,
    this.siteId,
    this.isLiveEventLogs = false,
    this.isDirectLogRet = false,
  });

  @override
  State<_EventLogContent> createState() => _EventLogContentState();
}

class _EventLogContentState extends State<_EventLogContent> {
  final BleManager ble = Get.find<BleManager>();
  bool _isListSelected = true;
  int _selectedViewIndex = 0;
  bool _useProvidedLogs = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedEventClasses = {};
  String? _alarmCount;
  List<LogModel> _filteredLogs = [];
  bool _filtersApplied = false;
  int textFieldResetKey = 0;
  bool _isHandlingBack = false;
  List<LogModel>? _providedLogsOverride;
  final TextEditingController _eventIdFilterController =
      TextEditingController();
  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();

  List<LogModel> _applyLiveSortingIfNeeded(List<LogModel> logs) {
    if (widget.isLiveEventLogs == true) {
      final sorted = List<LogModel>.from(logs);
      sorted.sort((a, b) {
        final aId = int.tryParse(a.eventId ?? '0') ?? 0;
        final bId = int.tryParse(b.eventId ?? '0') ?? 0;
        return bId.compareTo(aId);
      });
      return sorted;
    }
    return logs;
  }

  String _resolvedPanelName() {
    return widget.panelName.trim();
  }

  String _resolvedPanelId() {
    if ((widget.panelId ?? '').isNotEmpty) return widget.panelId!;
    return widget.panelName;
  }

  String _panelDisplayName(String name) {
    return BleNameUtils.getDisplayPrefixFromBleName(name);
  }

  List<LogModel> _sortLogsByEventId(List<LogModel> logs) {
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

  List<LogModel> _providedSourceLogs() {
    return _providedLogsOverride ?? widget.logDataList;
  }

  List<LogModel> _getBaseLogs() {
    final sourceLogs =
        _useProvidedLogs
            ? _providedSourceLogs()
            : ble.bleProcess.validEventLogs.value;
    return _sortLogsByEventId(sourceLogs);
  }

  bool get _canClearLogs => widget.isLiveEventLogs == true;

  void _performClearLogs() {
    if (_useProvidedLogs) {
      setState(() {
        _providedLogsOverride = <LogModel>[];
        _filteredLogs = [];
        _filtersApplied = false;
        _fromDate = null;
        _toDate = null;
        _selectedStatuses.clear();
        _selectedEventClasses.clear();
        _alarmCount = null;
        _eventIdFilterController.clear();
      });
    } else {
      ble.bleProcess.validEventLogs.value = <LogModel>[];
      setState(() {
        _filteredLogs = [];
        _filtersApplied = false;
        _fromDate = null;
        _toDate = null;
        _selectedStatuses.clear();
        _selectedEventClasses.clear();
        _alarmCount = null;
        _eventIdFilterController.clear();
      });
    }
  }

  Future<void> _confirmClearLogs() async {
    final confirmed = await showDialog<bool>(
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
                  decoration: BoxDecoration(
                    color: ColorConstants.errorIconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AssetConstants.clearIcon,
                      height: 28,
                      width: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  StringConstants.clearLogs,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  StringConstants
                      .thisWillRemoveAllEntriesFromTheListThisCannotBeUndone,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorConstants.textGray,
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
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.textGray,
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
                              'Clear',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.white,
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
    if (confirmed == true && mounted) {
      _performClearLogs();
    }
  }

  List<LogModel> _getDisplayLogs() {
    final baseLogs = _getBaseLogs();
    final afterSheetFilters = _filtersApplied ? _filteredLogs : baseLogs;
    return _applyEventIdQuickFilter(afterSheetFilters);
  }

  List<LogModel> _applyEventIdQuickFilter(List<LogModel> logs) {
    final q = _eventIdFilterController.text.trim();
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

  @override
  void initState() {
    super.initState();
    if (widget.isLiveEventLogs == true) {
      Get.find<BleLogController>().startLiveEventSetup();
    }
    _useProvidedLogs = widget.logDataList.isNotEmpty;
    final initialLogs =
        widget.logDataList.isNotEmpty
            ? widget.logDataList
            : ble.bleProcess.validEventLogs.value;
    _filteredLogs = _sortLogsByEventId(initialLogs);
  }

  @override
  void didUpdateWidget(_EventLogContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.logDataList, oldWidget.logDataList)) {
      _providedLogsOverride = null;
      _useProvidedLogs = widget.logDataList.isNotEmpty;
      _filteredLogs = _sortLogsByEventId(
        widget.logDataList.isNotEmpty
            ? widget.logDataList
            : ble.bleProcess.validEventLogs.value,
      );
    }
  }

  @override
  void dispose() {
    _eventIdFilterController.dispose();
    super.dispose();
  }

  Future<void> _handleBackNavigation() async {
    if (widget.isLiveEventLogs == true) {
      Get.find<BleLogController>().stopLiveEventSetup();
      if (ble.isConnected) {
        await ble.disconnectConnectedDevice();
      }
      await NavigationService.navigateBackToHome(context);
      return;
    }
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      if (widget.isHistoryView) {
        Navigator.of(context).pop();
        return;
      }

      final bleManager = ble;
      final logs = bleManager.bleProcess.validEventLogs.value;
      final panelIdToUse = _resolvedPanelId();
      if (logs.isEmpty) {
        await NavigationService.navigateBackToScanning(context);
        return;
      }

      if (widget.isStandalone && logs.isNotEmpty) {
        final existingPanel = await _panelService.getPanelByPanelId(
          panelIdToUse,
        );
        if (existingPanel != null && existingPanel.siteId != null) {
          final existingSite = await _siteService.getSiteById(
            existingPanel.siteId!,
          );
          if (existingSite != null) {
            await _siteService.storeLogs(logs, siteId: existingSite.id!);

            // final allSitesWithLogCount =
            //     await _siteService.getSitesWithLogCount();
            // final updatedSiteWithLogCount = allSitesWithLogCount.firstWhere(
            //   (siteWithLogCount) => siteWithLogCount.site.id == existingSite.id,
            //   orElse:
            //       () => SiteWithLogCount(
            //         site: existingSite,
            //         logCount: logs.length,
            //         lastLogRetrieved: DateTime.now(),
            //       ),
            // );

            if (mounted) {
              await NavigationService.navigateBackToScanning(context);
              if (widget.isDirectLogRet == true && mounted) {
                Navigator.of(context).pop(true);
              }
            }

            return;
          }
        }

        final shouldCreateSite = await showSiteCreationDialog(
          context,
          logCount: logs.length,
        );
        final resolvedName = _resolvedPanelName();
        final displayName = _panelDisplayName(resolvedName);
        final resolvedPanelId = _resolvedPanelId();

        if (shouldCreateSite == true) {
          if (widget.connectedDevice != null) {
            await widget.connectedDevice!.device!.disconnect();
          }
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => SimpleSiteCreationScreen(
                      retrievedLogs: logs,
                      panelName: displayName,
                      panelVersionNo: widget.panelVersionNo,
                      panelId: resolvedPanelId,
                    ),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        await NavigationService.navigateBackToScanning(context);
      }
    } finally {
      _isHandlingBack = false;
    }
  }

  void _showExportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                'Export',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textBodyDark,
                ),
              ),
              const SizedBox(height: 12),
              ExportTile(
                iconPath: AssetConstants.shareIconRed,
                title: StringConstants.exportAsPDF,
                onTap: () async {
                  Navigator.pop(context);
                  final logs = _applyEventIdQuickFilter(
                    _filtersApplied ? _filteredLogs : _getBaseLogs(),
                  );
                  if (logs.isEmpty) return;

                  String siteName = '-';
                  String installerName = '-';
                  String saqccNo = '-';

                  if (widget.siteId != null) {
                    final site = await _siteService.getSiteById(widget.siteId!);
                    if (site != null) {
                      siteName = site.siteName;
                      installerName = site.installerName;
                      saqccNo = site.saqccRegNumber;
                    }
                  } else {
                    final panelId = _resolvedPanelId();
                    if (panelId.isNotEmpty) {
                      final panel = await _panelService.getPanelByPanelId(
                        panelId,
                      );
                      if (panel?.siteId != null) {
                        final site = await _siteService.getSiteById(
                          panel!.siteId!,
                        );
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
                    panelName: BleNameUtils.getDisplayPrefixFromBleName(
                      widget.panelName,
                    ),
                    panelSerialNumber: BleNameUtils.getDisplayIdFromBleName(
                      widget.panelName,
                    ),
                    installerName: installerName,
                    saqccNo: saqccNo,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      final allLogs = _getBaseLogs();
      _filteredLogs =
          allLogs.where((log) {
            if (_fromDate != null || _toDate != null) {
              if (log.eventDateTime == null) return false;
              final logDate = DateTime(
                log.eventDateTime!.year,
                log.eventDateTime!.month,
                log.eventDateTime!.day,
              );
              if (_fromDate != null) {
                final fromDate = DateTime(
                  _fromDate!.year,
                  _fromDate!.month,
                  _fromDate!.day,
                );
                if (logDate.isBefore(fromDate)) return false;
              }
              if (_toDate != null) {
                final toDate = DateTime(
                  _toDate!.year,
                  _toDate!.month,
                  _toDate!.day,
                ).add(Duration(days: 1));
                if (logDate.isAfter(toDate.subtract(Duration(seconds: 1)))) {
                  return false;
                }
              }
            }

            if (_selectedStatuses.isNotEmpty) {
              if (log.eventStatus == null ||
                  !_selectedStatuses.contains(log.eventStatus)) {
                return false;
              }
            }

            if (_selectedEventClasses.isNotEmpty) {
              if (log.eventClass == null ||
                  !_selectedEventClasses.contains(log.eventClass)) {
                return false;
              }
            }

            if (_alarmCount != null && _alarmCount!.isNotEmpty) {
              final count = int.tryParse(_alarmCount!);
              if (count != null) {
                final eventId = int.tryParse(log.eventId ?? '0') ?? 0;
                if (eventId != count) return false;
              }
            }

            return true;
          }).toList();
      _filteredLogs = _sortLogsByEventId(_filteredLogs);
      _filtersApplied =
          _fromDate != null ||
          _toDate != null ||
          _selectedStatuses.isNotEmpty ||
          _selectedEventClasses.isNotEmpty ||
          (_alarmCount != null && _alarmCount!.isNotEmpty);
    });
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedStatuses.clear();
      _selectedEventClasses.clear();
      _alarmCount = null;
      _filtersApplied = false;
      textFieldResetKey++;
      _filteredLogs = _getBaseLogs();
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isFromDate, {
    StateSetter? bottomSheetSetState,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFromDate
              ? (_fromDate ?? DateTime.now())
              : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      bottomSheetSetState?.call(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget logsSection =
        _useProvidedLogs
            ? _buildLogStatus(_getDisplayLogs())
            : ValueListenableBuilder<List<LogModel>>(
              valueListenable: ble.bleProcess.validEventLogs,
              builder: (context, validLogs, child) {
                final baseLogs = _sortLogsByEventId(validLogs);
                final afterSheetFilters =
                    _filtersApplied ? _filteredLogs : baseLogs;
                final logsToDisplay = _applyEventIdQuickFilter(
                  afterSheetFilters,
                );
                return _buildLogStatus(logsToDisplay);
              },
            );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        await _handleBackNavigation();
      },
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async => await _handleBackNavigation(),
                          child: SvgPicture.asset(
                            AssetConstants.arrowBackIcon,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          StringConstants.eventLog,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (widget.isLiveEventLogs == true)
                          Padding(
                            padding: const EdgeInsets.only(right: 18.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap:
                                  _canClearLogs
                                      ? () => _confirmClearLogs()
                                      : null,
                              child: Opacity(
                                opacity: _canClearLogs ? 1.0 : 0,
                                child: SvgPicture.asset(
                                  AssetConstants.clearIcon,
                                  height: 28,
                                  width: 28,
                                ),
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: () => _showExportBottomSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SvgPicture.asset(
                              AssetConstants.shareIcon,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showFilterBottomSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: SvgPicture.asset(
                              AssetConstants.filterIcon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.white,
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: logsSection,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorConstants.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Container(
              decoration: const BoxDecoration(
                color: ColorConstants.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: ColorConstants.buttonSecondaryBackground,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Drag handle
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

                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20.0,
                            right: 20.0,
                            bottom: 12.0,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              StringConstants.filter,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.textBodyDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StringConstants.selectDate,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.textBodyDark,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap:
                                    () => _selectDate(
                                      context,
                                      true,
                                      bottomSheetSetState: sheetSetState,
                                    ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      StringConstants.from,
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: ColorConstants.borderGray,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _fromDate != null
                                                ? DateFormat(
                                                  StringConstants
                                                      .ddMMYyyyHHMmSs,
                                                ).format(_fromDate!)
                                                : StringConstants.from,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: ColorConstants.textMuted,
                                            ),
                                          ),
                                          Spacer(),
                                          SvgPicture.asset(
                                            AssetConstants.calendarIcon,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap:
                                    () => _selectDate(
                                      context,
                                      false,
                                      bottomSheetSetState: sheetSetState,
                                    ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      StringConstants.to,
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: ColorConstants.borderGray,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _toDate != null
                                                ? DateFormat(
                                                  StringConstants
                                                      .ddMMYyyyHHMmSs,
                                                ).format(_toDate!)
                                                : StringConstants.to,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: ColorConstants.textMuted,
                                            ),
                                          ),
                                          Spacer(),
                                          SvgPicture.asset(
                                            AssetConstants.calendarIcon,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 21),
                        Text(
                          StringConstants.status2,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.textBodyDark,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              EventConstants.statusEventStatusValue.skip(1).map(
                                (status) {
                                  return SizedBox(
                                    width:
                                        (MediaQuery.of(context).size.width -
                                            56) /
                                        3,
                                    child: SizedBox(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                              56) /
                                          3,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(6),
                                        onTap: () {
                                          sheetSetState(() {
                                            if (_selectedStatuses.contains(
                                              status,
                                            )) {
                                              _selectedStatuses.remove(status);
                                            } else {
                                              _selectedStatuses.add(status);
                                            }
                                          });
                                        },
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Checkbox(
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              value: _selectedStatuses.contains(
                                                status,
                                              ),
                                              activeColor: const Color(
                                                0xFFEC1D24,
                                              ),
                                              onChanged: (value) {
                                                sheetSetState(() {
                                                  if (value == true) {
                                                    _selectedStatuses.add(
                                                      status,
                                                    );
                                                  } else {
                                                    _selectedStatuses.remove(
                                                      status,
                                                    );
                                                  }
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                status,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: const Color(
                                                    0xFF918F8F,
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
                              ).toList(),
                        ),
                        SizedBox(height: 24),
                        Text(
                          StringConstants.eventClass,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.textBodyDark,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              EventConstants.statusEventClassNames.skip(1).map((
                                eventClass,
                              ) {
                                String displayName = eventClass;
                                if (eventClass == StringConstants.release) {
                                  displayName = StringConstants.extRelease;
                                }
                                if (eventClass == StringConstants.evacuation) {
                                  displayName = StringConstants.fire;
                                }

                                return SizedBox(
                                  width:
                                      (MediaQuery.of(context).size.width - 56) /
                                      3,
                                  child: SizedBox(
                                    width:
                                        (MediaQuery.of(context).size.width -
                                            56) /
                                        3,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        sheetSetState(() {
                                          if (_selectedEventClasses.contains(
                                            eventClass,
                                          )) {
                                            _selectedEventClasses.remove(
                                              eventClass,
                                            );
                                          } else {
                                            _selectedEventClasses.add(
                                              eventClass,
                                            );
                                          }
                                        });
                                      },
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Checkbox(
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            value: _selectedEventClasses
                                                .contains(eventClass),
                                            activeColor: const Color(
                                              0xFFEC1D24,
                                            ),
                                            onChanged: (value) {
                                              sheetSetState(() {
                                                if (value == true) {
                                                  _selectedEventClasses.add(
                                                    eventClass,
                                                  );
                                                } else {
                                                  _selectedEventClasses.remove(
                                                    eventClass,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              displayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: ColorConstants.textMuted,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                _resetFilters();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 32,
                                ),
                                side: BorderSide(
                                  color: ColorConstants.transparent,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                StringConstants.reset,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstants.textBodyDark,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),

                            GestureDetector(
                              onTap: () {
                                _applyFilters();
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: ColorConstants.primary,
                                  borderRadius: BorderRadius.circular(28.5),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 13,
                                    ),
                                    child: Text(
                                      StringConstants.applyNow,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: ColorConstants.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogStatus(List<LogModel> logsToDisplay) {
    final processedLogs = _applyLiveSortingIfNeeded(logsToDisplay);
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        children: [
          // Panel Info Row
          Row(
            children: [
              SvgPicture.asset(
                AssetConstants.panelIcon,
                height: 62,
                width: 62,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _panelDisplayName(_resolvedPanelName()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.textDark,
                      ),
                    ),
                    Text(
                      BleNameUtils.getDisplayIdFromBleName(widget.panelName),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.textDisabled,
                      ),
                    ),

                    ValueListenableBuilder(
                      valueListenable: ble.isConnectedNotifier,
                      builder: (context, isConnected, child) {
                        return RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: StringConstants.status3,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ColorConstants.textDisabled,
                                ),
                              ),
                              TextSpan(
                                text:
                                    isConnected
                                        ? StringConstants.connected
                                        : StringConstants.disconnected,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isConnected
                                          ? ColorConstants.success
                                          : ColorConstants.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Divider(color: ColorConstants.black.withAlpha(46), thickness: 1),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                StringConstants.logView,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorConstants.textBodyDark,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 98,
                    height: 32,
                    child: TextField(
                      controller: _eventIdFilterController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.text,
                      textAlignVertical: TextAlignVertical.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ColorConstants.textBodyDark,
                      ),
                      decoration: InputDecoration(
                        hintText: StringConstants.id,
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: ColorConstants.divider,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: ColorConstants.borderMedium,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: ColorConstants.borderMedium,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: ColorConstants.primary,
                            width: 2,
                          ),
                        ),
                        suffixIcon:
                            _eventIdFilterController.text.isNotEmpty
                                ? IconButton(
                                  iconSize: 16,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  icon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: ColorConstants.textMuted,
                                  ),
                                  onPressed: () {
                                    _eventIdFilterController.clear();
                                    setState(() {});
                                  },
                                )
                                : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap:
                        () => setState(() {
                          _isListSelected = true;
                          _selectedViewIndex = 0;
                        }),
                    child:
                        _isListSelected
                            ? Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: ColorConstants.primary,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: SvgPicture.asset(
                                  AssetConstants.listDeselectedIcon,
                                  colorFilter: ColorFilter.mode(
                                    ColorConstants.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            )
                            : SvgPicture.asset(
                              AssetConstants.listDeselectedIcon,
                            ),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap:
                        () => setState(() {
                          _isListSelected = false;
                          _selectedViewIndex = 1;
                        }),
                    child:
                        _isListSelected
                            ? SvgPicture.asset(
                              AssetConstants.tableDeselectedIcon,
                            )
                            : Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: ColorConstants.primary,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: SvgPicture.asset(
                                  AssetConstants.tableDeselectedIcon,
                                  colorFilter: ColorFilter.mode(
                                    ColorConstants.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 15),
          Expanded(
            child: IndexedStack(
              index: _selectedViewIndex,
              children: [
                _LogListView(displayLogs: processedLogs),
                _LogTableView(displayLogs: processedLogs),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

enum DataType {
  id,
  dateTime,
  status,
  eventClass,
  type,
  subType,
  source,
  identifier,
  text,
  panelNo,
  moduleNo,
  lBusNo,
}

class _LogListView extends StatefulWidget {
  final List<LogModel> displayLogs;

  const _LogListView({required this.displayLogs});

  @override
  State<_LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<_LogListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _horizontalController = ScrollController();
  String? _sortColumn;
  bool _sortAscending = true;
  List<LogModel> _sortedLogs = [];

  static const double wEventId = 80;
  static const double wDateTime = 140;
  static const double wEventStatus = 100;
  static const double wEventClass = 90;
  static const double wEventType = 160;
  static const double wEventSubType = 200;
  static const double wEventSource = 120;
  static const double wIdentifier = 180;
  static const double wText = 150;
  static const double wPanelNo = 100;
  static const double wModuleNo = 100;
  static const double wLbusNo = 90;

  late final double _totalTableWidth =
      wEventId +
      wDateTime +
      wEventStatus +
      wEventClass +
      wEventType +
      wEventSubType +
      wEventSource +
      wIdentifier +
      wText +
      wPanelNo +
      wModuleNo +
      wLbusNo;

  static const double _rowHeight = 72.0;
  static const double _headerHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _sortedLogs = List.from(widget.displayLogs);
  }

  @override
  void didUpdateWidget(_LogListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.displayLogs.length != oldWidget.displayLogs.length ||
        !listEquals(widget.displayLogs, oldWidget.displayLogs)) {
      setState(() {
        _sortedLogs = List.from(widget.displayLogs);
        if (_sortColumn != null) {
          _sortedLogs.sort((a, b) {
            int comparison = 0;

            switch (_sortColumn) {
              case StringConstants.eventid:
                final aId = int.tryParse(a.eventId ?? '0') ?? 0;
                final bId = int.tryParse(b.eventId ?? '0') ?? 0;
                comparison = aId.compareTo(bId);
                break;
              case StringConstants.datetime:
                if (a.eventDateTime != null && b.eventDateTime != null) {
                  comparison = a.eventDateTime!.compareTo(b.eventDateTime!);
                } else if (a.eventDateTime != null) {
                  comparison = 1;
                } else if (b.eventDateTime != null) {
                  comparison = -1;
                }
                break;
              case 'status':
                comparison = (a.eventStatus ?? '').compareTo(
                  b.eventStatus ?? '',
                );
                break;
              case 'class':
                comparison = (a.eventClass ?? '').compareTo(b.eventClass ?? '');
                break;
              case 'type':
                comparison = (a.eventType ?? '').compareTo(b.eventType ?? '');
                break;
              case StringConstants.subtype:
                comparison = (a.eventSubType ?? '').compareTo(
                  b.eventSubType ?? '',
                );
                break;
              case 'source':
                comparison = (a.eventSource ?? '').compareTo(
                  b.eventSource ?? '',
                );
                break;
              case 'identifier':
                comparison = (a.identifier ?? '').compareTo(b.identifier ?? '');
                break;
              case 'text':
                comparison = (a.text ?? '').compareTo(b.text ?? '');
                break;
              case StringConstants.panelno:
                comparison = (a.panelNo ?? '').compareTo(b.panelNo ?? '');
                break;
              case StringConstants.moduleno:
                comparison = (a.moduleNo ?? '').compareTo(b.moduleNo ?? '');
                break;
              case StringConstants.lbusno:
                comparison = (a.lBusNo ?? '').compareTo(b.lBusNo ?? '');
                break;
            }

            return _sortAscending ? comparison : -comparison;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _sortLogs(String column) {
    setState(() {
      if (_sortColumn == column) {
        if (_sortAscending) {
          _sortAscending = false;
        } else {
          _sortColumn = null;
          _sortAscending = true;
          _sortedLogs = List.from(widget.displayLogs);
          return;
        }
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }

      _sortedLogs = List.from(widget.displayLogs);

      _sortedLogs.sort((a, b) {
        int comparison = 0;

        switch (column) {
          case StringConstants.eventid:
            final aId = int.tryParse(a.eventId ?? '0') ?? 0;
            final bId = int.tryParse(b.eventId ?? '0') ?? 0;
            comparison = aId.compareTo(bId);
            break;
          case StringConstants.datetime:
            if (a.eventDateTime != null && b.eventDateTime != null) {
              comparison = a.eventDateTime!.compareTo(b.eventDateTime!);
            } else if (a.eventDateTime != null) {
              comparison = 1;
            } else if (b.eventDateTime != null) {
              comparison = -1;
            }
            break;
          case 'status':
            comparison = (a.eventStatus ?? '').compareTo(b.eventStatus ?? '');
            break;
          case 'class':
            comparison = (a.eventClass ?? '').compareTo(b.eventClass ?? '');
            break;
          case 'type':
            comparison = (a.eventType ?? '').compareTo(b.eventType ?? '');
            break;
          case StringConstants.subtype:
            comparison = (a.eventSubType ?? '').compareTo(b.eventSubType ?? '');
            break;
          case 'source':
            comparison = (a.eventSource ?? '').compareTo(b.eventSource ?? '');
            break;
          case 'identifier':
            comparison = (a.identifier ?? '').compareTo(b.identifier ?? '');
            break;
          case 'text':
            comparison = (a.text ?? '').compareTo(b.text ?? '');
            break;
          case StringConstants.panelno:
            comparison = (a.panelNo ?? '').compareTo(b.panelNo ?? '');
            break;
          case StringConstants.moduleno:
            comparison = (a.moduleNo ?? '').compareTo(b.moduleNo ?? '');
            break;
          case StringConstants.lbusno:
            comparison = (a.lBusNo ?? '').compareTo(b.lBusNo ?? '');
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  Widget _buildHeader() {
    return Container(
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: ColorConstants.white,
      child: Row(
        children: [
          _buildHeaderCell(
            StringConstants.id,
            wEventId,
            StringConstants.eventid,
          ),
          _buildHeaderCell(
            StringConstants.dateTime,
            wDateTime,
            StringConstants.datetime,
          ),
          _buildHeaderCell('Status', wEventStatus, 'status'),
          _buildHeaderCell(StringConstants.classLabel, wEventClass, 'class'),
          _buildHeaderCell(StringConstants.type, wEventType, 'type'),
          _buildHeaderCell(
            StringConstants.subType,
            wEventSubType,
            StringConstants.subtype,
          ),
          _buildHeaderCell(StringConstants.source, wEventSource, 'source'),
          _buildHeaderCell('Identifier', wIdentifier, 'identifier'),
          _buildHeaderCell(StringConstants.text, wText, 'text'),
          _buildHeaderCell('Panel no', wPanelNo, StringConstants.panelno),
          _buildHeaderCell('Module no', wModuleNo, StringConstants.moduleno),
          _buildHeaderCell('L-Bus no', wLbusNo, StringConstants.lbusno),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, String columnKey) {
    final bool isActive = _sortColumn == columnKey;

    return GestureDetector(
      onTap: () => _sortLogs(columnKey),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color:
                      isActive
                          ? ColorConstants.primary
                          : ColorConstants.textBodyDark,
                ),
              ),
            ),
            SizedBox(width: 4),
            if (isActive)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: ColorConstants.primary,
              )
            else
              Icon(
                Icons.unfold_more,
                size: 16,
                color: ColorConstants.textPlaceholder,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width, DataType dataType) {
    TextStyle textStyle = TextStyle();
    if (dataType == DataType.id) {
      textStyle = GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: ColorConstants.textSecondary,
      );
    } else if (dataType == DataType.dateTime) {
      textStyle = GoogleFonts.inter(
        fontSize: 12,
        color: ColorConstants.textSecondary,
      );
    } else {
      textStyle = GoogleFonts.inter(
        fontSize: 13,
        color: ColorConstants.textSecondary,
      );
    }
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: textStyle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;

        return SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: _totalTableWidth + 16,
            height: availableHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sortedLogs.length,
                    itemBuilder: (context, index) {
                      final log = _sortedLogs[index];
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          Container(
                            color:
                                index % 2 == 0
                                    ? ColorConstants.white
                                    : ColorConstants.surfaceOffWhite,
                            height: _rowHeight,
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildDataCell(
                                  log.eventId ?? '',
                                  wEventId,
                                  DataType.id,
                                ),
                                _buildDataCell(
                                  log.eventDateTime != null
                                      ? DateFormat(
                                        'dd/MM/yyyy\nhh:mm:ss a',
                                      ).format(log.eventDateTime!)
                                      : '',
                                  wDateTime,
                                  DataType.dateTime,
                                ),
                                _buildDataCell(
                                  log.eventStatus ?? '',
                                  wEventStatus,
                                  DataType.status,
                                ),
                                _buildDataCell(
                                  log.eventClass ?? '',
                                  wEventClass,
                                  DataType.eventClass,
                                ),
                                _buildDataCell(
                                  log.eventType ?? '',
                                  wEventType,
                                  DataType.type,
                                ),
                                _buildDataCell(
                                  log.eventSubType ?? '',
                                  wEventSubType,
                                  DataType.subType,
                                ),
                                _buildDataCell(
                                  log.eventSource ?? '',
                                  wEventSource,
                                  DataType.source,
                                ),
                                _buildDataCell(
                                  log.identifier ?? '',
                                  wIdentifier,
                                  DataType.identifier,
                                ),
                                _buildDataCell(
                                  log.text ?? '',
                                  wText,
                                  DataType.text,
                                ),
                                _buildDataCell(
                                  log.panelNo ?? '',
                                  wPanelNo,
                                  DataType.panelNo,
                                ),
                                _buildDataCell(
                                  log.moduleNo ?? '',
                                  wModuleNo,
                                  DataType.moduleNo,
                                ),
                                _buildDataCell(
                                  log.lBusNo ?? '',
                                  wLbusNo,
                                  DataType.lBusNo,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogTableView extends StatefulWidget {
  final List<LogModel> displayLogs;

  const _LogTableView({required this.displayLogs});

  @override
  State<_LogTableView> createState() => _LogTableViewState();
}

class _LogTableViewState extends State<_LogTableView>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scrollbar(
      controller: _scrollController,
      trackVisibility: true,
      interactive: true,
      thickness: 12,
      radius: const Radius.circular(10),
      child: ListView.separated(
        controller: _scrollController,
        itemCount: widget.displayLogs.length,
        separatorBuilder: (context, index) => SizedBox(height: 10),
        itemBuilder: (context, index) {
          final log = widget.displayLogs[index];
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorConstants.zebraStripeLight,
              border: Border.all(color: ColorConstants.borderMedium, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 19,
                bottom: 24,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        log.eventDateTime != null
                            ? DateFormat(
                              StringConstants.ddMMYyyyHhMmSsA,
                            ).format(log.eventDateTime!.toLocal())
                            : StringConstants.nA,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: ColorConstants.textSecondary,
                        ),
                      ),
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorConstants.accentBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.5,
                            vertical: 0.5,
                          ),
                          child: Text(
                            log.eventId ?? '-',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn(
                        StringConstants.panelNo,
                        log.panelNo ?? '',
                      ),
                      _buildInfoColumn(
                        StringConstants.lBusNo,
                        log.lBusNo ?? '',
                      ),
                      _buildInfoColumn(
                        StringConstants.moduleNo,
                        log.moduleNo ?? '',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Status', log.eventStatus ?? ''),
                      _buildInfoColumn('Event Class', log.eventClass ?? ''),
                      _buildInfoColumn(
                        StringConstants.source,
                        log.eventSource ?? '',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Event Type', log.eventType ?? ''),
                      _buildInfoColumn(
                        StringConstants.eventType,
                        log.eventSubType ?? '',
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Divider(
                      color: ColorConstants.black.withAlpha(43),
                      thickness: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('Identifier', log.identifier ?? ''),
                      _buildInfoColumn(StringConstants.text, log.text ?? ''),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ColorConstants.textBodyDark,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: ColorConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
