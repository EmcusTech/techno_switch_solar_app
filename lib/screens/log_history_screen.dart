import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/models/log_retrieval_model.dart';
import 'package:techno_switch_solar_app/screens/device_connecting_screen.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/services/log_retrieval_service.dart';

class LogHistoryScreen extends StatefulWidget {
  final String panelName;
  final String panelVersionNo;
  final int siteId;
  const LogHistoryScreen({
    super.key,
    required this.panelName,
    required this.panelVersionNo,
    required this.siteId,
  });

  @override
  State<LogHistoryScreen> createState() => LogHistoryScreenState();
}

class LogHistoryScreenState extends State<LogHistoryScreen> {
  List<LogRetrievalModel> _logRetrievals = [];
  bool _isLoading = true;
  final LogRetrievalService _logRetrievalService = LogRetrievalService();

  @override
  void initState() {
    super.initState();
    _loadLogHistory();
  }

  Future<void> _loadLogHistory() async {
    try {
      print('DEBUG: Loading log history for siteId: ${widget.siteId}');
      final retrievals = await _logRetrievalService.getLogRetrievalsForSite(
        widget.siteId,
      );
      print('DEBUG: Found ${retrievals.length} log retrieval sessions');
      setState(() {
        _logRetrievals = retrievals;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading log history: $error');
      setState(() {
        _logRetrievals = [];
        _isLoading = false;
      });
    }
  }

  Widget _buildLogHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Log Retrieval History',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3D3D3D),
          ),
        ),
        SizedBox(height: 16),
        // Remove Expanded and use a fixed height or Flexible
        SizedBox(
          height:
              MediaQuery.of(context).size.height -
              350, // Set a fixed height or calculate based on screen size
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(color: Color(0xFFEC1D24)),
                  )
                  : _logRetrievals.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Color(0xFFE0E0E0)),
                        SizedBox(height: 16),
                        Text(
                          'No Log History',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Log retrievals will appear here when you retrieve logs for this site.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.separated(
                    itemCount: _logRetrievals.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final logRetrieval = _logRetrievals[index];
                      return _buildLogRetrievalItem(logRetrieval);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildLogRetrievalItem(LogRetrievalModel logRetrieval) {
    final DateTime dateRetrieved = logRetrieval.retrievalDate;
    final String formattedDate =
        "${dateRetrieved.day.toString().padLeft(2, '0')}/${dateRetrieved.month.toString().padLeft(2, '0')}/${dateRetrieved.year} - ${dateRetrieved.hour.toString().padLeft(2, '0')}:${dateRetrieved.minute.toString().padLeft(2, '0')}}";

    return GestureDetector(
      onTap: () => _openLogSession(logRetrieval),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE9ECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFDC3545).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                color: Color(0xFFDC3545),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logRetrieval.sessionName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Log Records : ${logRetrieval.logCount}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF696969),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Date Retrieved : $formattedDate',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF767676),
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

  Future<void> _openLogSession(LogRetrievalModel logRetrieval) async {
    if (logRetrieval.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open this log session (missing id).'),
        ),
      );
      return;
    }

    // Show a lightweight loading dialog while we fetch logs from storage
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: Color(0xFFEC1D24)),
          ),
    );

    try {
      final List<LogModel> logs = await _logRetrievalService
          .getLogsForRetrieval(logRetrieval);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // close loader
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => EventLogScreen(
                  logDataList: logs,
                  panelName: widget.panelName,
                  panelVersionNo: widget.panelVersionNo,
                  isStandalone: false,
                  isHistoryView: true,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load logs: $e')));
      }
    }
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
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: SvgPicture.asset(
                          'assets/svgs/arrow_back_icon.svg',
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Log History',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 19),
                _buildDashboardContainer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
        ),
        child: SingleChildScrollView(child: _buildDashboard()),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Panel Information Row
          Row(
            children: [
              SvgPicture.asset(
                'assets/svgs/panel_icon.svg',
                height: 62,
                width: 62,
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
                  ValueListenableBuilder(
                    valueListenable: ble.isConnectedNotifier,
                    builder: (context, isConnected, child) {
                      return RichText(
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
                              text: isConnected ? 'Connected' : 'Disconnected',
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
              ),
              // Spacer(),
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
          Divider(color: Colors.black.withValues(alpha: 0.18), thickness: 1),
          SizedBox(height: 10),
          _buildLogHistorySection(),
        ],
      ),
    );
  }
}
