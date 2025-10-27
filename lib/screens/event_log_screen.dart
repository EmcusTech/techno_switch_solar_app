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
    this.isStandalone = false, // Default to false for existing usage
    this.panelId, // Optional panel ID parameter
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

// Create a separate widget for the EventLog content
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
  String? _storedPanelId; // Store panel ID to preserve across disconnects

  final PanelService _panelService = PanelService();
  final SiteService _siteService = SiteService();

  Future<void> _handleBackNavigation() async {
    // Use stored panel ID (captured during initState) instead of current one
    final panelIdToUse =
        _storedPanelId ?? AppServices.serialService.currentPanelId;
    print(
      "DEBUG: EventLog - Panel ID before disconnect: $panelIdToUse (stored: $_storedPanelId, current: ${AppServices.serialService.currentPanelId})",
    );

    // Disconnect Bluetooth
    AppServices.serialService.disconnect();
    print(
      "DEBUG: EventLog - Panel ID after disconnect: ${AppServices.serialService.currentPanelId}",
    );

    // If this is standalone mode (not from a site) and we have logs, check panel association first
    if (widget.isStandalone && _displayLogs.isNotEmpty) {
      // Check if panel is already associated with a site
      if (panelIdToUse != null) {
        final existingPanel = await _panelService.getPanelByPanelId(
          panelIdToUse,
        );
        if (existingPanel != null && existingPanel.siteId != null) {
          // Panel is already associated with a site - show existing site dialog
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
              // Save logs to the existing site
              await _siteService.storeLogs(
                _displayLogs,
                siteId: existingSite.id!,
              );

              // Navigate to the existing site screen
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
              // User chose not to save logs, navigate back to scanning
              await NavigationService.navigateBackToScanning(context);
            }
            return;
          }
        }
      }

      // Panel is not associated with any site, show normal site creation dialog
      final shouldCreateSite = await showSiteCreationDialog(
        context,
        logCount: _displayLogs.length,
      );

      if (shouldCreateSite == true) {
        print(
          "DEBUG: EventLog - Navigating to site creation with panel ID: $panelIdToUse",
        );
        // Navigate to site creation screen with logs and panel ID
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => SimpleSiteCreationScreen(
                  retrievedLogs: _displayLogs,
                  panelName: widget.panelName,
                  panelVersionNo: widget.panelVersionNo,
                  panelId: panelIdToUse, // Pass the stored panel ID
                ),
          ),
        );
        return;
      }
    }

    // Default behavior: navigate back to scanning screen
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
              onPressed: () {
                Navigator.of(context).pop(false);
              },
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
              onPressed: () {
                Navigator.of(context).pop(true);
              },
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
    // Use the panel ID passed from the constructor (captured before disconnect)
    // Fall back to current service panel ID if not provided
    _storedPanelId = widget.panelId ?? AppServices.serialService.currentPanelId;
    print(
      "DEBUG: EventLog - Stored panel ID at init: $_storedPanelId (from widget: ${widget.panelId}, from service: ${AppServices.serialService.currentPanelId})",
    );

    // Initialize display logs with the data passed from loading screen
    _displayLogs =
        widget.logDataList.where((log) => log.isValid == true).toList();
  }

  @override
  void dispose() {
    // Don't dispose the shared service here, as other screens might still be using it
    // _serialService.dispose(); // Commented out
    // Don't disconnect here - let _handleBackNavigation handle it properly
    // AppServices.serialService.disconnect();
    super.dispose();
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
                        onTap: () async {
                          await _handleBackNavigation();
                        },
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
                _buildLogStatusContainer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogStatusContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: SingleChildScrollView(child: _buildLogStatus()),
      ),
    );
  }

  Widget _buildLogStatus() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Panel Information Row
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
              // InkWell(
              //   onTap: () async {
              //     // Use the same logic as back navigation to ensure panel ID is preserved
              //     await _handleBackNavigation();
              //   },
              //   child: Container(
              //     height: 40,
              //     width: 80,
              //     decoration: BoxDecoration(
              //       color: Color(0xFFEC1D24),
              //       borderRadius: BorderRadius.circular(5),
              //     ),
              //     child: Padding(
              //       padding: const EdgeInsets.all(8.0),
              //       child: Center(
              //         child: Text(
              //           'Disconnect',
              //           style: GoogleFonts.inter(
              //             fontSize: 10,
              //             fontWeight: FontWeight.w500,
              //             color: Colors.white,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              // Transform.rotate(
              //   angle: 180 * 3.14159 / 360,
              //   child: Icon(
              //     Icons.arrow_forward_ios,
              //     size: 18,
              //     color: Color(0xFF696969),
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 10),

          // // Log Retrieval Status
          // Container(
          //   padding: EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: Color(0xFFF9F9F9),
          //     borderRadius: BorderRadius.circular(8),
          //     border: Border.all(color: Color(0xFFD7D7D7)),
          //   ),
          //   child: Column(
          //     children: [
          //       Row(
          //         children: [
          //           Icon(
          //             _connectionStatus.contains("Retrieving") ||
          //                     _connectionStatus.contains("Processing")
          //                 ? Icons.sync
          //                 : _connectionStatus.contains("Complete") ||
          //                     _connectionStatus.contains("received")
          //                 ? Icons.check_circle
          //                 : Icons.info,
          //             color:
          //                 _connectionStatus.contains("Retrieving") ||
          //                         _connectionStatus.contains("Processing")
          //                     ? Colors.orange
          //                     : _connectionStatus.contains("Complete") ||
          //                         _connectionStatus.contains("received")
          //                     ? Color(0xFF00A706)
          //                     : Color(0xFF979797),
          //           ),
          //           SizedBox(width: 8),
          //           Expanded(
          //             child: Text(
          //               _connectionStatus,
          //               style: GoogleFonts.inter(
          //                 fontSize: 14,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //       if (_realTimeLogs.length > widget.logDataList.length)
          //         Padding(
          //           padding: EdgeInsets.only(top: 8),
          //           child: Text(
          //             '${_realTimeLogs.length - widget.logDataList.length} new logs retrieved',
          //             style: GoogleFonts.inter(
          //               fontSize: 12,
          //               color: Color(0xFF00A706),
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //         ),
          //     ],
          //   ),
          // ),
          SizedBox(height: 15),
          Divider(
            color: Color(0xFF000000).withValues(alpha: 0.18),
            thickness: 1,
          ),
          SizedBox(height: 15),

          // Event Log Header
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
                onTap: () {
                  setState(() {
                    _isListSelected = true;
                    _selectedViewIndex = 0;
                  });
                },
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
                onTap: () {
                  setState(() {
                    _isListSelected = false;
                    _selectedViewIndex = 1;
                  });
                },
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
          IndexedStack(
            index: _selectedViewIndex,
            sizing: StackFit.passthrough,
            children: [
              _LogListView(displayLogs: _displayLogs),
              _LogTableView(displayLogs: _displayLogs),
            ],
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }
}

// Separate StatefulWidget for ListView with AutomaticKeepAliveClientMixin
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

  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Sync scroll controllers
    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients &&
          _bodyScrollController.offset != _headerScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _bodyScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable table header
        SingleChildScrollView(
          controller: _headerScrollController,
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            color: Colors.white,
            child: Row(
              children: [
                _buildHeaderCell('Event ID', 80),
                _buildHeaderCell('Date & Time', 180),
                _buildHeaderCell('Event Status', 120),
                _buildHeaderCell('Event Class', 120),
                _buildHeaderCell('Event Type', 150),
                _buildHeaderCell('Event Sub Type', 150),
                _buildHeaderCell('Event Source', 120),
                _buildHeaderCell('Identifier', 120),
                _buildHeaderCell('Text', 120),
                _buildHeaderCell('Panel no', 100),
                _buildHeaderCell('Module no', 100),
                _buildHeaderCell('L-Bus no', 100),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // Scrollable table rows
        SingleChildScrollView(
          controller: _bodyScrollController,
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(widget.displayLogs.length, (index) {
              final log = widget.displayLogs[index];
              return Column(
                children: [
                  if (index > 0) const Divider(height: 1),
                  Container(
                    color: index % 2 == 0 ? Colors.white : Color(0xFFFAFAFA),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        _buildDataCell(log.eventId ?? '', 80),
                        _buildDataCell(
                          log.eventDateTime != null
                              ? DateFormat(
                                'dd-MM-yyyy\nhh:mm:ss a',
                              ).format(log.eventDateTime!)
                              : '',
                          180,
                        ),
                        _buildDataCell(log.eventStatus ?? '', 120),
                        _buildDataCell(log.eventClass ?? '', 120),
                        _buildDataCell(log.eventType ?? '', 150),
                        _buildDataCell(log.eventSubType ?? '', 150),
                        _buildDataCell(log.eventSource ?? '', 120),
                        _buildDataCell(log.identifier ?? '', 120),
                        _buildDataCell(log.text ?? '', 120),
                        _buildDataCell(log.panelNo ?? '', 100),
                        _buildDataCell(log.moduleNo ?? '', 100),
                        _buildDataCell(log.lBusNo ?? '', 100),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
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
}

// Separate StatefulWidget for TableView with AutomaticKeepAliveClientMixin
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.displayLogs.length,
      separatorBuilder: (context, index) {
        return SizedBox(height: 10);
      },
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
                    color: Color(0xFF000000).withValues(alpha: 0.17),
                    thickness: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel No',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.panelNo ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'L-Bus No',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.lBusNo ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Module No',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.moduleNo ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Divider(
                    color: Color(0xFF000000).withValues(alpha: 0.17),
                    thickness: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Status',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.eventStatus ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Class',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.eventClass ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Source',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.eventSource ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Divider(
                    color: Color(0xFF000000).withValues(alpha: 0.17),
                    thickness: 1,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Type',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.eventType ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Sub Type',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                          Text(
                            log.eventSubType ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF696969),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Identifier',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3A3A3A),
                                  ),
                                ),
                                Text(
                                  log.identifier ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF696969),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Text',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3A3A3A),
                                  ),
                                ),
                                Text(
                                  log.text ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF696969),
                                  ),
                                ),
                              ],
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
  }
}
