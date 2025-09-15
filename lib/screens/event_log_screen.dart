import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/navigation_service.dart';
import 'package:techno_switch_solar_app/widgets/site_creation_dialog.dart';
import 'package:techno_switch_solar_app/screens/simple_site_creation_screen.dart';

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
  List<LogModel> _displayLogs = [];
  String _connectionStatus = "Disconnected";
  String? _storedPanelId; // Store panel ID to preserve across disconnects

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

    // If this is standalone mode (not from a site) and we have logs, show dialog
    if (widget.isStandalone && _displayLogs.isNotEmpty) {
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
    _displayLogs = List.from(widget.logDataList);

    // Set connection status based on whether we have logs
    if (_displayLogs.isNotEmpty) {
      _connectionStatus = "Connected - ${_displayLogs.length} logs retrieved";
    } else if (AppServices.isConnected) {
      _connectionStatus = "Connected - No logs retrieved";
    } else {
      _connectionStatus = "Device not connected";
    }
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
                        'Event Log Retrieval ',
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
              InkWell(
                onTap: () async {
                  // Use the same logic as back navigation to ensure panel ID is preserved
                  await _handleBackNavigation();
                },
                child: Container(
                  height: 40,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFFEC1D24),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        'Disconnect',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
          _isListSelected ? _buildList() : _buildTable(),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Event ID',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Date & Time',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Event Status',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // Table rows
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _displayLogs.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = _displayLogs[index];
            return Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      log.eventId ?? '',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      log.eventDateTime != null
                          ? DateFormat(
                            'dd-MM-yyyy hh:mm:ss a',
                          ).format(log.eventDateTime!)
                          : '',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      log.eventStatus ?? '',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTable() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _displayLogs.length,
      separatorBuilder: (context, index) {
        return SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final log = _displayLogs[index];
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
