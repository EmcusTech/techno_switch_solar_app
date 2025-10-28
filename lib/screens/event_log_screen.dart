// event_log_screen_sync_headers.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/widgets/site_creation_dialog.dart';
import 'package:techno_switch_solar_app/screens/simple_site_creation_screen.dart';
import 'package:techno_switch_solar_app/screens/site_screen.dart';

class EventLogScreen extends StatefulWidget {
  final List<LogModel> logDataList;
  final String panelVersionNo;
  final String panelName;
  final bool isStandalone; // True if accessed without site context
  final String? panelId; // Panel ID to preserve across disconnects
  const EventLogScreen({
    super.key,
    required this.logDataList,
    required this.panelVersionNo,
    required this.panelName,
    this.isStandalone = false,
    this.panelId,
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
  const _EventLogContent({
    required this.logDataList,
    required this.panelName,
    required this.panelVersionNo,
    required this.isStandalone,
    this.panelId,
  });

  @override
  State<_EventLogContent> createState() => _EventLogContentState();
}

class _EventLogContentState extends State<_EventLogContent> {
  bool _isListSelected = true;
  int _selectedViewIndex = 0; // 0 for list, 1 for table
  List<LogModel> _displayLogs = [];
  String? _storedPanelId;

  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();

  Future<void> _handleBackNavigation() async {
    final panelIdToUse =
        _storedPanelId ?? AppServices.serialService.currentPanelId;

    AppServices.serialService.disconnect();

    if (widget.isStandalone && _displayLogs.isNotEmpty) {
      if (panelIdToUse != null) {
        final existingPanel = await _panelService.getPanelByPanelId(
          panelIdToUse,
        );
        if (existingPanel != null && existingPanel.siteId != null) {
          final existingSite = await _siteService.getSiteById(
            existingPanel.siteId!,
          );
          if (existingSite != null) {
            final shouldNavigateToSite = await _showExistingSiteDialog(
              context,
              existingSite.siteName,
              _displayLogs.length,
            );

            if (shouldNavigateToSite == true) {
              await _siteService.storeLogs(
                _displayLogs,
                siteId: existingSite.id!,
              );

              final allSitesWithLogCount =
                  await _siteService.getSitesWithLogCount();
              final updatedSiteWithLogCount = allSitesWithLogCount.firstWhere(
                (siteWithLogCount) =>
                    siteWithLogCount.site.id == existingSite.id,
                orElse:
                    () => SiteWithLogCount(
                      site: existingSite,
                      logCount: _displayLogs.length,
                      lastLogRetrieved: DateTime.now(),
                    ),
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder:
                      (context) => SiteScreen(
                        site: existingSite,
                        siteWithLogCount: updatedSiteWithLogCount,
                      ),
                ),
                (route) => false,
              );
            } else {
              await NavigationService.navigateBackToScanning(context);
            }
            return;
          }
        }
      }

      final shouldCreateSite = await showSiteCreationDialog(
        context,
        logCount: _displayLogs.length,
      );

      if (shouldCreateSite == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => SimpleSiteCreationScreen(
                  retrievedLogs: _displayLogs,
                  panelName: widget.panelName,
                  panelVersionNo: widget.panelVersionNo,
                  panelId: panelIdToUse,
                ),
          ),
        );
        return;
      }
    }

    await NavigationService.navigateBackToScanning(context);
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

  @override
  void initState() {
    super.initState();
    _storedPanelId = widget.panelId ?? AppServices.serialService.currentPanelId;
    _displayLogs =
        widget.logDataList.where((log) => log.isValid == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: EdgeInsets.only(top: 54),
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
                      SizedBox(width: 8),
                      Text(
                        'Event Log Retrieval',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                    child: _buildLogStatus(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogStatus() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Panel Info Row
          Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/panel_icon.svg',
                height: 81,
                width: 81,
              ),
              SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.panelName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.panelVersionNo,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF979797),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'status : ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF979797),
                          ),
                        ),
                        TextSpan(
                          text:
                              AppServices.isConnected
                                  ? 'connected'
                                  : 'disconnected',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                AppServices.isConnected
                                    ? Color(0xFF00A706)
                                    : Color(0xFFEC1D24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: 15),
          Divider(color: Color(0xFF000000).withAlpha(46), thickness: 1),
          SizedBox(height: 15),
          Row(
            children: [
              Text(
                'Event Log',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              Spacer(),
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
              SizedBox(width: 21),
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
          SizedBox(height: 20),
          Expanded(
            child: IndexedStack(
              index: _selectedViewIndex,
              children: [
                _LogListView(displayLogs: _displayLogs),
                _LogTableView(displayLogs: _displayLogs),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
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

  // Fixed widths for columns (same as before)
  static const double wEventId = 80;
  static const double wDateTime = 180;
  static const double wEventStatus = 120;
  static const double wEventClass = 120;
  static const double wEventType = 150;
  static const double wEventSubType = 150;
  static const double wEventSource = 120;
  static const double wIdentifier = 120;
  static const double wText = 120;
  static const double wPanelNo = 100;
  static const double wModuleNo = 100;
  static const double wLbusNo = 100;

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
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.white,
      child: Row(
        children: [
          _buildHeaderCell('Event ID', wEventId),
          _buildHeaderCell('Date & Time', wDateTime),
          _buildHeaderCell('Event Status', wEventStatus),
          _buildHeaderCell('Event Class', wEventClass),
          _buildHeaderCell('Event Type', wEventType),
          _buildHeaderCell('Event Sub Type', wEventSubType),
          _buildHeaderCell('Event Source', wEventSource),
          _buildHeaderCell('Identifier', wIdentifier),
          _buildHeaderCell('Text', wText),
          _buildHeaderCell('Panel no', wPanelNo),
          _buildHeaderCell('Module no', wModuleNo),
          _buildHeaderCell('L-Bus no', wLbusNo),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: Color(0xFF3A3A3A),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: Color(0xFF696969),
        ),
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
                    itemCount: widget.displayLogs.length,
                    itemBuilder: (context, index) {
                      final log = widget.displayLogs[index];
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
                                _buildDataCell(log.eventId ?? '', wEventId),
                                _buildDataCell(
                                  log.eventDateTime != null
                                      ? DateFormat(
                                        'dd-MM-yyyy\nhh:mm:ss a',
                                      ).format(log.eventDateTime!)
                                      : '',
                                  wDateTime,
                                ),
                                _buildDataCell(
                                  log.eventStatus ?? '',
                                  wEventStatus,
                                ),
                                _buildDataCell(
                                  log.eventClass ?? '',
                                  wEventClass,
                                ),
                                _buildDataCell(log.eventType ?? '', wEventType),
                                _buildDataCell(
                                  log.eventSubType ?? '',
                                  wEventSubType,
                                ),
                                _buildDataCell(
                                  log.eventSource ?? '',
                                  wEventSource,
                                ),
                                _buildDataCell(
                                  log.identifier ?? '',
                                  wIdentifier,
                                ),
                                _buildDataCell(log.text ?? '', wText),
                                _buildDataCell(log.panelNo ?? '', wPanelNo),
                                _buildDataCell(log.moduleNo ?? '', wModuleNo),
                                _buildDataCell(log.lBusNo ?? '', wLbusNo),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.panelText ?? 'No Text',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3A3A3A),
                          ),
                        ),
                        Text(
                          log.eventDateTime != null
                              ? DateFormat(
                                'dd/MM/yyyy - hh:mm a',
                              ).format(log.eventDateTime!.toLocal())
                              : 'N/A',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF696969),
                          ),
                        ),
                      ],
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
                          log.eventId ?? '0149',
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
                    _buildInfoColumn('Event Status', log.eventStatus ?? ''),
                    _buildInfoColumn('Event Class', log.eventClass ?? ''),
                    _buildInfoColumn('Event Source', log.eventSource ?? ''),
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
                    _buildInfoColumn('Event Sub Type', log.eventSubType ?? ''),
                  ],
                ),
                if (log.identifier != null &&
                    log.identifier!.isNotEmpty &&
                    log.identifier != "-")
                  Column(
                    children: [
                      SizedBox(height: 22),
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3A3A3A),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF696969),
            ),
          ),
        ],
      ),
    );
  }
}
