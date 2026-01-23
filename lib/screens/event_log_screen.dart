// event_log_screen_sync_headers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/screens/home_screen.dart';
import 'package:techno_switch_solar_app/services/event_log_pdf_exporter.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/utils/export_tile.dart';
import 'package:techno_switch_solar_app/utils/event_constants.dart';
import 'package:techno_switch_solar_app/utils/pdf_report_util.dart';
import 'package:techno_switch_solar_app/widgets/site_creation_dialog.dart';
import 'package:techno_switch_solar_app/screens/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/screens/device_connecting_screen.dart';

class EventLogScreen extends StatefulWidget {
  final List<LogModel> logDataList;
  final String panelVersionNo;
  final String panelName;
  final bool isStandalone; // True if accessed without site context
  final String? panelId; // Panel ID to preserve across disconnects
  final bool isHistoryView; // True when viewing saved logs from history
  const EventLogScreen({
    super.key,
    required this.logDataList,
    required this.panelVersionNo,
    required this.panelName,
    this.isStandalone = false,
    this.panelId,
    this.isHistoryView = false,
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
  const _EventLogContent({
    required this.logDataList,
    required this.panelName,
    required this.panelVersionNo,
    required this.isStandalone,
    this.panelId,
    this.isHistoryView = false,
  });

  @override
  State<_EventLogContent> createState() => _EventLogContentState();
}

class _EventLogContentState extends State<_EventLogContent> {
  bool _isListSelected = false;
  int _selectedViewIndex = 1;
  bool _useProvidedLogs = false;

  // Filter state
  DateTime? _fromDate;
  DateTime? _toDate;
  Set<String> _selectedStatuses = {};
  Set<String> _selectedEventClasses = {};
  String? _alarmCount;
  List<LogModel> _filteredLogs = [];
  bool _filtersApplied = false;
  int _textFieldResetKey = 0;
  bool _isHandlingBack = false;

  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();

  // Resolve panel name using live BLE value when available
  String _resolvedPanelName([String? panelNameValue]) {
    final live = (panelNameValue ?? ble.bleProcess.panelName.value).trim();
    return live.isNotEmpty ? live : widget.panelName;
  }

  // Prefer provided panelId, otherwise derive from scanned device name (technoswitch_xxxx)
  String _resolvedPanelId() {
    if ((widget.panelId ?? '').isNotEmpty) return widget.panelId!;

    final parts = widget.panelName.split('_');
    if (parts.length > 1 && parts.last.isNotEmpty) return parts.last;

    return widget.panelName;
  }

  String _panelDisplayName(String name) {
    final parts = name.split('_');
    return parts.isNotEmpty ? parts.first : name;
  }

  String _panelDisplayId() {
    return _resolvedPanelId();
  }

  // Keep logs sorted by eventId (numeric if possible)
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

  List<LogModel> _getBaseLogs() {
    final sourceLogs =
        _useProvidedLogs
            ? widget.logDataList
            : ble.bleProcess.validEventLogs.value;
    return _sortLogsByEventId(sourceLogs);
  }

  List<LogModel> _getDisplayLogs() {
    final baseLogs = _getBaseLogs();
    return _filtersApplied ? _filteredLogs : baseLogs;
  }

  @override
  void initState() {
    super.initState();
    _useProvidedLogs = widget.logDataList.isNotEmpty;
    // Initialize filtered logs with whichever source we have on load
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
      _useProvidedLogs = widget.logDataList.isNotEmpty;
      _filteredLogs = _sortLogsByEventId(
        widget.logDataList.isNotEmpty
            ? widget.logDataList
            : ble.bleProcess.validEventLogs.value,
      );
    }
  }

  // Future<void> _handleBackNavigation() async {
  //   final bleManager = ble;
  //   final logs = bleManager.bleProcess.validEventLogs.value;
  //   final deviceId = bleManager.connectedDeviceId.value;

  //   //Stop BLE cleanly
  //   if (bleManager.isConnected) {
  //     await bleManager.safeDisconnect();
  //   }

  //   //No logs? Just go back to scanning
  //   if (logs.isEmpty) {
  //     await NavigationService.navigateBackToScanning(context);
  //     return;
  //   }

  //   //Decide persistence flow
  //   if (widget.isStandalone) {
  //     final shouldSave = await showSiteCreationDialog(
  //       context,
  //       logCount: logs.length,
  //     );

  //     if (shouldSave == true) {
  //       Navigator.of(context).pushReplacement(
  //         MaterialPageRoute(
  //           builder:
  //               (_) => SimpleSiteCreationScreen(
  //                 retrievedLogs: logs,
  //                 panelName: widget.panelName,
  //                 panelVersionNo: widget.panelVersionNo,
  //                 panelId: deviceId.isNotEmpty ? deviceId : widget.panelId,
  //               ),
  //         ),
  //       );
  //       return;
  //     }
  //   }

  //   // 4️⃣ Default fallback
  //   await NavigationService.navigateBackToScanning(context);
  // }

  Future<void> _handleBackNavigation() async {
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      if (widget.isHistoryView) {
        Navigator.of(context).pop();
        return;
      }

      final bleManager = ble;
      final logs = bleManager.bleProcess.validEventLogs.value;
      // Prefer resolved panelId from scanned device name / provided panelId (not deviceId or network name)
      final panelIdToUse = _resolvedPanelId();

      // AppServices.serialService.disconnect();

      // //Stop BLE cleanly
      // if (bleManager.isConnected) {
      //   await bleManager.shutdown(deviceId: panelIdToUse);
      // }

      //No logs? Just go back to scanning
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

            final allSitesWithLogCount =
                await _siteService.getSitesWithLogCount();
            final updatedSiteWithLogCount = allSitesWithLogCount.firstWhere(
              (siteWithLogCount) => siteWithLogCount.site.id == existingSite.id,
              orElse:
                  () => SiteWithLogCount(
                    site: existingSite,
                    logCount: logs.length,
                    lastLogRetrieved: DateTime.now(),
                  ),
            );

            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            }

            return;
          }
        }

        final shouldCreateSite = await showSiteCreationDialog(
          context,
          logCount: logs.length,
        );
        final resolvedName = _resolvedPanelName(ble.bleProcess.panelName.value);
        final displayName = _panelDisplayName(resolvedName);
        final resolvedPanelId = _resolvedPanelId();
        print('displayName: $displayName, panelId: $resolvedPanelId');

        if (shouldCreateSite == true) {
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
          return;
        }
      }

      await NavigationService.navigateBackToScanning(context);
    } finally {
      _isHandlingBack = false;
    }
  }

  Future<bool?> _showExistingSiteDialog(
    BuildContext context,
    String siteName,
    int logCount,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0F72E9), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Panel Already Installed',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3A3A3A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This panel is already installed at:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF0F72E9).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF0F72E9), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        siteName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F72E9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Would you like to save the $logCount retrieved log${logCount == 1 ? '' : 's'} to this existing site?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3A3A3A),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Discard Logs',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0F72E9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save to Existing Site',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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

              Text(
                'Export',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3A3A3A),
                ),
              ),

              const SizedBox(height: 12),

              // ExportTile(
              //   icon: Icons.table_chart_outlined,
              //   title: 'Export as Excel',
              //   onTap: () async {
              //     Navigator.pop(context);
              //     final logs = ble.bleProcess.validEventLogs.value;
              //     if (logs.isEmpty) return;

              //     await EventLogExcelExporter.export(logs);
              //   },
              // ),

              // ExportTile(
              //   icon: Icons.description_outlined,
              //   title: 'Export as CSV',
              //   onTap: () async {
              //     Navigator.pop(context);
              //     final logs = ble.bleProcess.validEventLogs.value;
              //     if (logs.isEmpty) return;

              //     await EventLogCsvExporter.export(logs);
              //   },
              // ),
              ExportTile(
                iconPath: "assets/svgs/share_icon_red.svg",
                title: 'Export as PDF',
                onTap: () async {
                  Navigator.pop(context);
                  final logs = _filtersApplied ? _filteredLogs : _getBaseLogs();
                  if (logs.isEmpty) return;

                  await LogReportPdfUtil.generate(
                    logs: logs,
                    siteName: 'Site Name',
                    panelName: 'Panel Name',
                    panelSerialNumber: 'Panel Serial Number',
                    installerName: 'Installer Name',
                    saqccNo: 'SAQCC No',
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
            // Date filter
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
                ).add(Duration(days: 1)); // Include the entire end date
                if (logDate.isAfter(toDate.subtract(Duration(seconds: 1)))) {
                  return false;
                }
              }
            }

            // Status filter
            if (_selectedStatuses.isNotEmpty) {
              if (log.eventStatus == null ||
                  !_selectedStatuses.contains(log.eventStatus)) {
                return false;
              }
            }

            // Event Class filter
            if (_selectedEventClasses.isNotEmpty) {
              if (log.eventClass == null ||
                  !_selectedEventClasses.contains(log.eventClass)) {
                return false;
              }
            }

            // Alarm Count filter (if provided)
            if (_alarmCount != null && _alarmCount!.isNotEmpty) {
              final count = int.tryParse(_alarmCount!);
              if (count != null) {
                // Assuming alarm count might be related to event ID or some other field
                // Adjust this logic based on your requirements
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
      _textFieldResetKey++; // Force TextField to reset
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
                final logsToDisplay =
                    _filtersApplied ? _filteredLogs : baseLogs;
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
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SvgPicture.asset('assets/svgs/background_1.svg'),
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
                            'assets/svgs/arrow_back_icon.svg',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Event Log',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),

                        GestureDetector(
                          onTap: () => _showExportBottomSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SvgPicture.asset(
                              "assets/svgs/share_icon.svg",
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showFilterBottomSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: SvgPicture.asset(
                              "assets/svgs/filter_icon.svg",
                            ),
                          ),
                        ),

                        // IconButton(
                        //   icon: const Icon(
                        //     Icons.ios_share,
                        //     color: Colors.black,
                        //   ),
                        //   onPressed: () => _showExportBottomSheet(context),
                        // ),
                        // IconButton(
                        //   icon: const Icon(
                        //     Icons.filter_alt_outlined,
                        //     color: Colors.black,
                        //   ),
                        //   onPressed: () => _showFilterBottomSheet(context),
                        // ),

                        // IconButton(
                        //   tooltip: 'Export PDF',
                        //   icon: const Icon(
                        //     Icons.picture_as_pdf,
                        //     color: Color(0xFFEC1D24),
                        //   ),
                        //   onPressed: () async {
                        //     final logs = ble.bleProcess.validEventLogs.value;

                        //     if (logs.isEmpty) return;

                        //     await EventLogPdfExporter.export(
                        //       logs: logs,
                        //       panelName: widget.panelName,
                        //       panelVersion: widget.panelVersionNo,
                        //     );
                        //   },
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(height: 19),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xffEFEEEE),
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
                              'Filter',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3A3A3A),
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
                        // Select Date Section
                        Text(
                          'Select Date',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A3A3A),
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
                                      "From",
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
                                          color: Color(0xFFE0E0E0),
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _fromDate != null
                                                ? DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(_fromDate!)
                                                : 'From',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Color(0xFF918F8F),
                                            ),
                                          ),
                                          Spacer(),
                                          SvgPicture.asset(
                                            "assets/svgs/calendar_icon.svg",
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
                                      "To",
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
                                          color: Color(0xFFE0E0E0),
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _toDate != null
                                                ? DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(_toDate!)
                                                : 'To',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Color(0xFF918F8F),
                                            ),
                                          ),
                                          Spacer(),
                                          SvgPicture.asset(
                                            "assets/svgs/calendar_icon.svg",
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

                        // Status Section - Show in rows (max 3 per row)
                        Text(
                          'Status:',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A3A3A),
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

                        // Event Class Section - Show max 3 per row
                        Text(
                          'Event Class:',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A3A3A),
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
                                // Map "Release" to "Ext. Release" and "Evacuation" to "Fire" for UI
                                String displayName = eventClass;
                                if (eventClass == "Release") {
                                  displayName = "Ext. Release";
                                }
                                if (eventClass == "Evacuation") {
                                  displayName = "Fire";
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
                                                color: const Color(0xFF918F8F),
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
                        // SizedBox(height: 21),

                        // // Alarm Count Section
                        // Text(
                        //   'Alarm Count:',
                        //   style: GoogleFonts.inter(
                        //     fontSize: 14,
                        //     fontWeight: FontWeight.bold,
                        //     color: Color(0xFF3A3A3A),
                        //   ),
                        // ),
                        // SizedBox(height: 8),
                        // TextField(
                        //   key: ValueKey('alarm_count_$_textFieldResetKey'),
                        //   onChanged: (value) {
                        //     setState(() {
                        //       _alarmCount = value.isEmpty ? null : value;
                        //     });
                        //   },
                        //   keyboardType: TextInputType.number,
                        //   decoration: InputDecoration(
                        //     hintText: 'Enter Alarm Count',
                        //     hintStyle: GoogleFonts.inter(
                        //       fontSize: 13,
                        //       color: Color(0xFFBDBDBD),
                        //     ),
                        //     border: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(4),
                        //       borderSide: BorderSide(color: Color(0xFFD7D7D7)),
                        //     ),
                        //     enabledBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(4),
                        //       borderSide: BorderSide(color: Color(0xFFD7D7D7)),
                        //     ),
                        //     focusedBorder: OutlineInputBorder(
                        //       borderRadius: BorderRadius.circular(4),
                        //       borderSide: BorderSide(
                        //         color: Color(0xFFEC1D24),
                        //         width: 2,
                        //       ),
                        //     ),
                        //     contentPadding: EdgeInsets.symmetric(
                        //       horizontal: 12,
                        //       vertical: 14,
                        //     ),
                        //   ),
                        //   style: GoogleFonts.inter(
                        //     fontSize: 14,
                        //     fontWeight: FontWeight.w500,
                        //     color: Color(0xFF3A3A3A),
                        //   ),
                        // ),
                        SizedBox(height: 32),

                        // Action Buttons
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
                                side: BorderSide(color: Colors.transparent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Reset',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3A3A3A),
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
                                  color: Color(0xffEC1D24),
                                  borderRadius: BorderRadius.circular(28.5),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 13,
                                    ),
                                    child: Text(
                                      "Apply Now",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Expanded(
                            //   child: ElevatedButton(
                            //     onPressed: () {
                            // _applyFilters();
                            // Navigator.pop(context);
                            //     },
                            //     style: ElevatedButton.styleFrom(
                            //       padding: EdgeInsets.symmetric(vertical: 14),
                            //       backgroundColor: Color(0xFFEC1D24),
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //       elevation: 0,
                            //     ),
                            //     child: Text(
                            //       'Apply Now',
                            //       style: GoogleFonts.inter(
                            //         fontSize: 14,
                            //         fontWeight: FontWeight.w600,
                            //         color: Colors.white,
                            //       ),
                            //     ),
                            //   ),
                            // ),
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
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: Column(
        children: [
          // Panel Info Row
          Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/panel_icon.svg',
                height: 62,
                width: 62,
              ),
              SizedBox(width: 14),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: ble.bleProcess.panelName,
                  builder: (context, panelNameValue, _) {
                    final resolvedName = _resolvedPanelName(panelNameValue);
                    final displayName = _panelDisplayName(resolvedName);
                    final displayId = _panelDisplayId();

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff3D3D3D),
                          ),
                        ),
                        Text(
                          displayId,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF979797),
                          ),
                        ),

                        ValueListenableBuilder(
                          valueListenable: ble.isConnectedNotifier,
                          builder: (context, isConnected, child) {
                            return RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Status : ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF979797),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        isConnected
                                            ? 'Connected'
                                            : 'Disconnected',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isConnected
                                              ? Color(0xFF00A706)
                                              : Color(0xFFEC1D24),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Divider(color: Color(0xFF000000).withAlpha(46), thickness: 1),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Log View",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A3A3A),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                                color: Color(0xFFEC1D24),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: SvgPicture.asset(
                                  'assets/svgs/list_deselected_icon.svg',
                                  colorFilter: ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            )
                            : SvgPicture.asset(
                              'assets/svgs/list_deselected_icon.svg',
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
                              'assets/svgs/table_deselected_icon.svg',
                            )
                            : Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                color: Color(0xFFEC1D24),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: SvgPicture.asset(
                                  'assets/svgs/table_deselected_icon.svg',
                                  colorFilter: ColorFilter.mode(
                                    Colors.white,
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
                _LogListView(displayLogs: logsToDisplay),
                _LogTableView(displayLogs: logsToDisplay),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}

Widget _buildProgressBar() {
  return ValueListenableBuilder<int>(
    valueListenable: ble.bleProcess.read1000LogsCount,
    builder: (context, readCount, child) {
      return ValueListenableBuilder<List<LogModel>>(
        valueListenable: ble.bleProcess.validEventLogs,
        builder: (context, validLogs, child) {
          final progress = readCount / 1000.0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFB9B9B9).withOpacity(0.31),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: $readCount / 1000',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3D3D3D),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Valid Logs: ${validLogs.length}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEC1D24),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFEC1D24),
                    ),
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

// ---------- UPDATED _LogListView: header + rows share one horizontal scroll ----------
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

  // One horizontal controller for header + all rows (they will be inside the same horizontal scroll view)
  final ScrollController _horizontalController = ScrollController();

  // Sorting state
  String? _sortColumn;
  bool _sortAscending = true;
  List<LogModel> _sortedLogs = [];

  // Fixed widths for columns (same as before)
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

  // total width computed from column widths
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

  // Row height (can be adjusted)
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
    // Update _sortedLogs when displayLogs changes
    if (widget.displayLogs.length != oldWidget.displayLogs.length ||
        !listEquals(widget.displayLogs, oldWidget.displayLogs)) {
      setState(() {
        _sortedLogs = List.from(widget.displayLogs);
        // Re-apply sorting if there was a sort active
        if (_sortColumn != null) {
          _sortedLogs.sort((a, b) {
            int comparison = 0;

            switch (_sortColumn) {
              case 'eventId':
                final aId = int.tryParse(a.eventId ?? '0') ?? 0;
                final bId = int.tryParse(b.eventId ?? '0') ?? 0;
                comparison = aId.compareTo(bId);
                break;
              case 'dateTime':
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
              case 'subType':
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
              case 'panelNo':
                comparison = (a.panelNo ?? '').compareTo(b.panelNo ?? '');
                break;
              case 'moduleNo':
                comparison = (a.moduleNo ?? '').compareTo(b.moduleNo ?? '');
                break;
              case 'lBusNo':
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
          // Second tap: sort descending
          _sortAscending = false;
        } else {
          // Third tap: clear sorting
          _sortColumn = null;
          _sortAscending = true;
          _sortedLogs = List.from(widget.displayLogs);
          return;
        }
      } else {
        // First tap: sort ascending
        _sortColumn = column;
        _sortAscending = true;
      }

      _sortedLogs = List.from(widget.displayLogs);

      _sortedLogs.sort((a, b) {
        int comparison = 0;

        switch (column) {
          case 'eventId':
            final aId = int.tryParse(a.eventId ?? '0') ?? 0;
            final bId = int.tryParse(b.eventId ?? '0') ?? 0;
            comparison = aId.compareTo(bId);
            break;
          case 'dateTime':
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
          case 'subType':
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
          case 'panelNo':
            comparison = (a.panelNo ?? '').compareTo(b.panelNo ?? '');
            break;
          case 'moduleNo':
            comparison = (a.moduleNo ?? '').compareTo(b.moduleNo ?? '');
            break;
          case 'lBusNo':
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
      color: Colors.white,
      child: Row(
        children: [
          _buildHeaderCell('ID', wEventId, 'eventId'),
          _buildHeaderCell('Date & Time', wDateTime, 'dateTime'),
          _buildHeaderCell('Status', wEventStatus, 'status'),
          _buildHeaderCell('Class', wEventClass, 'class'),
          _buildHeaderCell('Type', wEventType, 'type'),
          _buildHeaderCell('Sub Type', wEventSubType, 'subType'),
          _buildHeaderCell('Source', wEventSource, 'source'),
          _buildHeaderCell('Identifier', wIdentifier, 'identifier'),
          _buildHeaderCell('Text', wText, 'text'),
          _buildHeaderCell('Panel no', wPanelNo, 'panelNo'),
          _buildHeaderCell('Module no', wModuleNo, 'moduleNo'),
          _buildHeaderCell('L-Bus no', wLbusNo, 'lBusNo'),
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
                  color: isActive ? Color(0xFFEC1D24) : Color(0xFF3A3A3A),
                ),
              ),
            ),
            SizedBox(width: 4),
            if (isActive)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: Color(0xFFEC1D24),
              )
            else
              Icon(Icons.unfold_more, size: 16, color: Color(0xFF999999)),
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
        color: Color(0xff696969),
      );
    } else if (dataType == DataType.dateTime) {
      textStyle = GoogleFonts.inter(fontSize: 12, color: Color(0xff696969));
    } else {
      textStyle = GoogleFonts.inter(fontSize: 13, color: Color(0xff696969));
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
        // we get vertical space available to this widget, use it to size the internal ListView
        final double availableHeight = constraints.maxHeight;

        return SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: _totalTableWidth + 16,
            height:
                availableHeight, // constrain vertical space for internal Column/ListView
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header (will scroll horizontally because it's inside the outer SingleChildScrollView)
                _buildHeader(),
                const Divider(height: 1, thickness: 1),
                // Expanded ListView takes remaining vertical space and scrolls vertically only.
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
                                    ? Colors.white
                                    : const Color(0xFFFAFAFA),
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
                                        'dd-MM-yyyy\nhh:mm:ss a',
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

// ---------- Unchanged _LogTableView (kept for completeness) ----------
class _LogTableView extends StatefulWidget {
  final List<LogModel> displayLogs;

  const _LogTableView({required this.displayLogs});

  @override
  State<_LogTableView> createState() => _LogTableViewState();
}

class _LogTableViewState extends State<_LogTableView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.separated(
      shrinkWrap: true,
      // physics: NeverScrollableScrollPhysics(),
      itemCount: widget.displayLogs.length,
      separatorBuilder: (context, index) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = widget.displayLogs[index];
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFF9F9F9),
            border: Border.all(color: Color(0xFFD7D7D7), width: 1),
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
                            'dd/MM/yyyy - hh:mm a',
                          ).format(log.eventDateTime!.toLocal())
                          : 'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF696969),
                      ),
                    ),
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF0F72E9),
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Divider(
                    color: Color(0xFF000000).withAlpha(43),
                    thickness: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Panel No', log.panelNo ?? ''),
                    _buildInfoColumn('L-Bus No', log.lBusNo ?? ''),
                    _buildInfoColumn('Module No', log.moduleNo ?? ''),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Divider(
                    color: Color(0xFF000000).withAlpha(43),
                    thickness: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Status', log.eventStatus ?? ''),
                    _buildInfoColumn('Event Class', log.eventClass ?? ''),
                    _buildInfoColumn('Source', log.eventSource ?? ''),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Divider(
                    color: Color(0xFF000000).withAlpha(43),
                    thickness: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Event Type', log.eventType ?? ''),
                    _buildInfoColumn('Event', log.eventSubType ?? ''),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Divider(
                    color: Color(0xFF000000).withAlpha(43),
                    thickness: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('Identifier', log.identifier ?? ''),
                    _buildInfoColumn('Text', log.text ?? ''),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
              color: Color(0xFF3A3A3A),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF696969),
            ),
          ),
        ],
      ),
    );
  }
}
