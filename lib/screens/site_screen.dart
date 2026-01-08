import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/screens/site_detail_screen.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:intl/intl.dart';

class SiteScreen extends StatefulWidget {
  final SiteModel site;
  final SiteWithLogCount siteWithLogCount;
  const SiteScreen({
    super.key,
    required this.site,
    required this.siteWithLogCount,
  });

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  final SiteService _siteService = SiteService();
  List<PanelModel> _panels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPanels();
  }

  Future<void> _loadPanels() async {
    try {
      print(
        'DEBUG: Loading panels for site ${widget.site.id} (${widget.site.siteName})',
      );

      // First, check if any panels exist at all
      final allPanels = await _siteService.getAllPanels();
      print('DEBUG: Total panels in database: ${allPanels.length}');
      for (int i = 0; i < allPanels.length; i++) {
        print(
          'DEBUG: All Panel $i: ${allPanels[i].panelId} - ${allPanels[i].panelName} (siteId: ${allPanels[i].siteId})',
        );
      }

      // Check unassigned panels
      final unassignedPanels = await _siteService.getUnassignedPanels();
      print('DEBUG: Unassigned panels: ${unassignedPanels.length}');

      // Now check panels for this specific site
      final panels = await _siteService.getSitePanels(widget.site.id!);
      print('DEBUG: Loaded ${panels.length} panels for site ${widget.site.id}');
      for (int i = 0; i < panels.length; i++) {
        print(
          'DEBUG: Site Panel $i: ${panels[i].panelId} - ${panels[i].panelName}',
        );
      }

      setState(() {
        _panels = panels;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading panels: $error');
    }
  }

  Future<void> _refreshSites() async {
    setState(() {
      _isLoading = true;
    });
    await _loadPanels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6EBEB), Colors.white],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshSites,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(children: [_buildHeader(context), _buildPanels()]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Align(
            alignment: Alignment.topCenter,
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: 166,
                height: 166,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffEC1D24).withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        SvgPicture.asset('assets/svgs/background_1.svg'),
        Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScanningScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFBDEE1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: SvgPicture.asset(
                          'assets/svgs/logo.svg',
                          height: 59.29,
                          width: 51,
                          colorFilter: ColorFilter.mode(
                            Color(0xFFEC1D24),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Text(
                'Tap to connect',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3D3D3D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.site.siteName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              GestureDetector(
                onTap: () {
                  print('DEBUG: Navigating to site detail screen');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => SiteDetailScreen(
                            siteWithLogCount: widget.siteWithLogCount,
                          ),
                    ),
                  );
                },
                child: Text(
                  'Site Details',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEC1D24),
                  ),
                ),
              ),
              // if (_panels.isNotEmpty)
              //   Text(
              //     '${_panels.length} panel${_panels.length == 1 ? '' : 's'}',
              //     style: GoogleFonts.inter(
              //       fontSize: 14,
              //       fontWeight: FontWeight.w500,
              //       color: Color(0xFF666666),
              //     ),
              //   ),
            ],
          ),
          SizedBox(height: 20),
          _buildPanelItem(),
        ],
      ),
    );
  }

  Widget _buildPanelItem() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFFEC1D24)),
        ),
      );
    }

    if (_panels.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Color(0xFFB9B9B9).withValues(alpha: 0.31),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            SvgPicture.asset(
              'assets/svgs/new_project_icon.svg',
              height: 48,
              width: 48,
              colorFilter: ColorFilter.mode(
                Color(0xFFEC1D24).withValues(alpha: 0.5),
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No Panels Yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D3D3D),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Connect to a panel to associate it with this site',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _panels.length,
      separatorBuilder: (context, index) {
        return SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final panel = _panels[index];

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => ProjectDashboardScreen(
                      selectedDevice: DiscoveredDevice(
                        name: panel.panelName,
                        id: panel.panelId,
                        rssi: 0,
                        serviceData: {},
                        manufacturerData: Uint8List(0),
                        serviceUuids: [],
                      ),
                      panelName: panel.panelName,
                      panelVersionNo: panel.deviceDisplayInfo,
                      siteId: widget.site.id!,
                      siteName: widget.site.siteName,
                    ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Color(0xFFB9B9B9).withValues(alpha: 0.31),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Image.asset('assets/images/panel_icon.png'),
                  SizedBox(width: 14.31),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          panel.panelName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D3D3D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          panel.panelId,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF918F8F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Text(
                        //   '${panel.deviceType.toUpperCase()} • ${panel.deviceDisplayInfo}',
                        //   style: GoogleFonts.inter(
                        //     fontSize: 11,
                        //     fontWeight: FontWeight.w400,
                        //     color: Color(0xFF666666),
                        //   ),
                        //   maxLines: 1,
                        //   overflow: TextOverflow.ellipsis,
                        // ),
                        // if (panel.lastConnected != null) ...[
                        //   SizedBox(height: 2),
                        //   Text(
                        //     'Last connected: ${DateFormat('MMM d, y').format(panel.lastConnected!)}',
                        //     style: GoogleFonts.inter(
                        //       fontSize: 10,
                        //       fontWeight: FontWeight.w400,
                        //       color: Color(0xFF999999),
                        //     ),
                        //   ),
                        // ],
                        if (widget.siteWithLogCount.logCount > 0) ...[
                          // SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timeline,
                                size: 12,
                                color: Color(0xFF00A706),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${widget.siteWithLogCount.logCount} log${widget.siteWithLogCount.logCount == 1 ? '' : 's'}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF00A706),
                                ),
                              ),
                              if (widget.siteWithLogCount.lastLogRetrieved !=
                                  null) ...[
                                SizedBox(width: 8),
                                Text(
                                  'Last: ${DateFormat('MMM d').format(widget.siteWithLogCount.lastLogRetrieved!)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF918F8F),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          SizedBox(height: 4),
                          Text(
                            'No logs yet',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF918F8F),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  SvgPicture.asset('assets/svgs/arrow_right_colored_icon.svg'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
