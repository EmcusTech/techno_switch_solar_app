import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/log_retrieval_model.dart';
import '../services/log_retrieval_service.dart';

class LogHistoryScreen extends StatefulWidget {
  final int siteId;
  final String siteName;

  const LogHistoryScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<LogHistoryScreen> createState() => _LogHistoryScreenState();
}

class _LogHistoryScreenState extends State<LogHistoryScreen> {
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
      final retrievals = await _logRetrievalService.getLogRetrievalsForSite(
        widget.siteId,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Log History',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: Column(children: [_buildDeviceHeader(), _buildLogHistorySection()]),
    );
  }

  Widget _buildDeviceHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF28A745),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.device_hub, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RHINO2008',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'version : 0.98',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6C757D),
                  ),
                ),
                Text(
                  'status : Offline',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C757D), size: 24),
        ],
      ),
    );
  }

  Widget _buildLogHistorySection() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Log Retrieval History',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFEC1D24),
                        ),
                      )
                      : _logRetrievals.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Color(0xFFE0E0E0),
                            ),
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
                        separatorBuilder:
                            (context, index) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final logRetrieval = _logRetrievals[index];
                          return _buildLogRetrievalItem(logRetrieval);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogRetrievalItem(LogRetrievalModel logRetrieval) {
    final DateTime dateRetrieved = logRetrieval.retrievalDate;
    final String formattedDate =
        "${dateRetrieved.day.toString().padLeft(2, '0')}/${dateRetrieved.month.toString().padLeft(2, '0')}/${dateRetrieved.year} - ${dateRetrieved.hour.toString().padLeft(2, '0')}:${dateRetrieved.minute.toString().padLeft(2, '0')} ${dateRetrieved.hour >= 12 ? 'PM' : 'AM'}";

    return Container(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFDC3545).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Log Records : ${logRetrieval.logCount}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6C757D),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Date Retrieved : $formattedDate',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
