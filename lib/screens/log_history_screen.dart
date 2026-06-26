import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/models/log_model.dart';
import 'package:techno_switch_solar_app/models/log_retrieval_model.dart';
import 'package:techno_switch_solar_app/screens/event_log_screen.dart';
import 'package:techno_switch_solar_app/services/log_retrieval_service.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class LogHistoryScreen extends StatefulWidget {
  final String panelName;
  final String panelVersionNo;
  final int? siteId;
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
  final bleController = Get.find<BleLogController>();

  @override
  void initState() {
    super.initState();
    _loadLogHistory();
  }

  Future<void> _loadLogHistory() async {
    if (widget.siteId == null || widget.siteId == 0) {
      setState(() {
        _logRetrievals = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final retrievals = await _logRetrievalService.getLogRetrievalsForSite(
        widget.siteId!,
      );
      setState(() {
        _logRetrievals = retrievals;
        _isLoading = false;
      });
    } catch (error) {
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
          StringConstants.logRetrievalHistory,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ColorConstants.textDark,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: MediaQuery.of(context).size.height - 350,
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(color: ColorConstants.primary),
                  )
                  : _logRetrievals.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: ColorConstants.borderGray),
                        SizedBox(height: 16),
                        Text(
                          StringConstants.noLogHistory,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.textGray,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          StringConstants.logRetrievalsWillAppearHereWhenYouRetrieveLogsForThisSite,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: ColorConstants.textPlaceholder,
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
        "${dateRetrieved.day.toString().padLeft(2, '0')}/${dateRetrieved.month.toString().padLeft(2, '0')}/${dateRetrieved.year} - ${dateRetrieved.hour.toString().padLeft(2, '0')}:${dateRetrieved.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () => _openLogSession(logRetrieval),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConstants.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorConstants.surfaceCard),
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withOpacity(0.05),
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
                color: ColorConstants.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                color: ColorConstants.danger,
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
                      color: ColorConstants.blackMaterial,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Log Records : ${logRetrieval.logCount}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Date Retrieved : $formattedDate',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: ColorConstants.textMediumGray,
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
          content: Text(StringConstants.unableToOpenThisLogSessionMissingId),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(color: ColorConstants.primary),
          ),
    );

    try {
      final List<LogModel> logs = await _logRetrievalService
          .getLogsForRetrieval(logRetrieval);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => EventLogScreen(
                  logDataList: logs,
                  panelName: widget.panelName,
                  panelVersionNo: widget.panelVersionNo,
                  isStandalone: false,
                  isHistoryView: true,
                  siteId: widget.siteId,
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
    return WillPopScope(
      onWillPop: () async {
        return false;
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
                        Text(
                          StringConstants.logHistory,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 23),
                  _buildDashboardContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContainer() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: ColorConstants.white,
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
                    BleNameUtils.getDisplayPrefixFromBleName(widget.panelName),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
                      return Text(
                        isConnected ? StringConstants.connected : StringConstants.disconnected,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isConnected
                                  ? ColorConstants.success
                                  : ColorConstants.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(color: ColorConstants.blackMaterial.withValues(alpha: 0.18), thickness: 1),
          SizedBox(height: 10),
          _buildLogHistorySection(),
        ],
      ),
    );
  }
}
