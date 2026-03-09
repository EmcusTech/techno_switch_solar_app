import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/screens/site_detail_screen.dart';
import 'package:techno_switch_solar_app/screens/project_dashboard.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/services/log_retrieval_service.dart';
import 'package:techno_switch_solar_app/services/panel_service.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/widgets/common/common_cta_button.dart';
import 'package:techno_switch_solar_app/utils/ble_name_utils.dart';

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
  final LogRetrievalService _logRetrievalService = LogRetrievalService();
  final PanelService _panelService = PanelService();
  List<PanelModel> _panels = [];
  bool _isLoading = true;
  bool _isDeletingSite = false;
  int? _lastRetrievalLogCount;
  DateTime? _lastRetrievalDate;

  @override
  void initState() {
    super.initState();
    _loadPanels();
    _loadLatestRetrievalInfo();
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

  Future<void> _loadLatestRetrievalInfo() async {
    try {
      final latest = await _logRetrievalService.getMostRecentLogRetrieval(
        widget.site.id!,
      );
      if (!mounted) return;
      setState(() {
        _lastRetrievalLogCount = latest?.logCount;
        _lastRetrievalDate = latest?.retrievalDate;
      });
    } catch (error) {
      print('Error loading latest retrieval info: $error');
    }
  }

  Future<void> _refreshSites() async {
    setState(() {
      _isLoading = true;
    });
    await _loadPanels();
  }

  Future<void> _confirmDeleteSite() async {
    if (widget.site.id == null || _isDeletingSite) return;

    final shouldDelete = await showDialog<bool>(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ───────── Icon ─────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 32,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ───────── Title ─────────
                Text(
                  'Delete site?',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // ───────── Description ─────────
                Text(
                  'This will remove "${widget.site.siteName}".\n'
                  'All logs will be deleted and panels will be unassigned.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF918F8F),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // ───────── Actions ─────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFD0D0D0), // subtle neutral border
                            width: 1,
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC1D24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

    if (shouldDelete == true) {
      await _deleteSite();
    }
  }

  Future<void> _deleteSite() async {
    setState(() {
      _isDeletingSite = true;
    });

    try {
      final deleted = await _siteService.deleteSite(widget.site.id!);
      if (!mounted) return;

      if (deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site "${widget.site.siteName}" deleted'),
            backgroundColor: const Color(0xFFEC1D24),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete site'),
            backgroundColor: Color(0xFFEC1D24),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting site: $error'),
          backgroundColor: const Color(0xFFEC1D24),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingSite = false;
        });
      }
    }
  }

  Future<void> _confirmDeletePanel(PanelModel panel) async {
    final shouldDelete = await showDialog<bool>(
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ───────── Icon ─────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBDEE1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 32,
                      color: Color(0xFFEC1D24),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ───────── Title ─────────
                Text(
                  'Remove panel?',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D3D3D),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // ───────── Description ─────────
                Text(
                  'Remove panel "${panel.panelName}" (${panel.panelId}) '
                  'from this site?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF918F8F),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // ───────── Actions ─────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFD0D0D0), // subtle neutral border
                            width: 1,
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC1D24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(
                          'Remove',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

    if (shouldDelete == true) {
      await _deletePanel(panel);
    }
  }

  Future<void> _deletePanel(PanelModel panel) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deleted = await _panelService.deletePanel(panel.panelId);
      if (!mounted) return;

      if (deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Panel "${panel.panelName}" deleted'),
            backgroundColor: const Color(0xFFEC1D24),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete panel'),
            backgroundColor: Color(0xFFEC1D24),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting panel: $error'),
          backgroundColor: const Color(0xFFEC1D24),
        ),
      );
    } finally {
      if (mounted) {
        await _loadPanels();
      }
    }
  }

  Widget _buildLastLogSummary() {
    final int? lastLogCount = _lastRetrievalLogCount;
    final DateTime? lastLogDate =
        _lastRetrievalDate ?? widget.siteWithLogCount.lastLogRetrieved;

    if ((lastLogCount ?? 0) <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'No logs yet',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFF918F8F),
          ),
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.timeline, size: 12, color: const Color(0xFF00A706)),
        const SizedBox(width: 4),
        Text(
          '$lastLogCount log${lastLogCount == 1 ? '' : 's'}',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF00A706),
          ),
        ),
        if (lastLogDate != null) ...[
          const SizedBox(width: 8),
          Text(
            'Last: ${DateFormat('MMM d').format(lastLogDate)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF918F8F),
            ),
          ),
        ],
      ],
    );
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
        child: Stack(
          children: [
            _buildHeader(context),
            // Padding(
            //   padding: const EdgeInsets.only(top: 330),
            //   child: Column(
            //     children: [
            //       _buildSiteDetails(),
            //       SizedBox(height: 20),
            //       _buildPanels(),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(top: 100),
        //   child: Align(
        //     alignment: Alignment.topCenter,
        //     child: Opacity(
        //       opacity: 0.3,
        //       child: Container(
        //         width: 166,
        //         height: 166,
        //         decoration: BoxDecoration(
        //           shape: BoxShape.circle,
        //           color: Color(0xffEC1D24).withValues(alpha: 0.5),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        SvgPicture.asset('assets/svgs/background_1.svg'),
        // Padding(
        //   padding: const EdgeInsets.only(top: 100),
        //   child: Column(
        //     children: [
        //       Align(
        //         alignment: Alignment.topCenter,
        //         child: Padding(
        //           padding: const EdgeInsets.all(30.0),
        //           child: InkWell(
        //             onTap: () {
        //               Navigator.of(context).push(
        //                 MaterialPageRoute(
        //                   builder: (context) => ScanningScreen(),
        //                 ),
        //               );
        //             },
        //             child: Container(
        //               width: 106,
        //               height: 106,
        //               decoration: BoxDecoration(
        //                 shape: BoxShape.circle,
        //                 color: Color(0xFFFBDEE1),
        //               ),
        //               child: Padding(
        //                 padding: const EdgeInsets.all(25.0),
        //                 child: SvgPicture.asset(
        //                   'assets/svgs/logo.svg',
        //                   height: 59.29,
        //                   width: 51,
        //                   colorFilter: ColorFilter.mode(
        //                     Color(0xFFEC1D24),
        //                     BlendMode.srcIn,
        //                   ),
        //                 ),
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //       SizedBox(height: 15),
        //       Text(
        //         'Tap to connect',
        //         style: GoogleFonts.inter(
        //           fontSize: 14,
        //           fontWeight: FontWeight.w400,
        //           color: Color(0xFF3D3D3D),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              _buildSiteDetails(),
              SizedBox(height: 20),
              _buildPanels(),
            ],
          ),
        ),
        Positioned(
          top: 50,
          left: 20,
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF3D3D3D),
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Site Information',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSiteDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFFE2E2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 15,
                bottom: 15,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset('assets/svgs/location_icon.svg'),
                          SizedBox(width: 8),
                          Text(
                            widget.site.siteName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Site Information',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Color(0xFF737373),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      _confirmDeleteSite();
                    },
                    child: SvgPicture.asset(
                      'assets/svgs/delete_icon.svg',
                      colorFilter: ColorFilter.mode(
                        Color(0xFFFF6467),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/svgs/site_calender_icon.svg'),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Color(0xFF737373),
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM d, y',
                            ).format(widget.siteWithLogCount.site.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF737373),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  CommonCtaButton(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => SiteDetailScreen(
                                siteWithLogCount: widget.siteWithLogCount,
                              ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('assets/svgs/details_icon.svg'),
                        SizedBox(width: 8),
                        Text(
                          'View Site Details',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
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
    );
  }

  Widget _buildPanels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Panels',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D3D3D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.45,
      child: RefreshIndicator(
        color: Color(0xFFEC1D24),
        onRefresh: _refreshSites,
        child: ListView.separated(
          physics: AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _panels.length,
          separatorBuilder: (context, index) {
            return SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            final panel = _panels[index];
            final panelName = panel.panelName;

            void onTap() {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ProjectDashboardScreen(
                        selectedDevice: DiscoveredDevice(
                          name: panelName,
                          id: panel.panelId,
                          rssi: 0,
                          serviceData: {},
                          manufacturerData: Uint8List(0),
                          serviceUuids: [],
                        ),
                        panelName: panelName,
                        panelVersionNo: panel.deviceDisplayInfo,
                        siteId: widget.site.id!,
                        siteName: widget.site.siteName,
                      ),
                ),
              );
            }

            return _PanelListItemWidget(
              panel: panel,
              lastLogSummary: _buildLastLogSummary(),
              onTap: onTap,
              onDelete: () => _confirmDeletePanel(panel),
            );
          },
        ),
      ),
    );
  }
}

class _PanelListItemWidget extends StatefulWidget {
  final PanelModel panel;
  final Widget lastLogSummary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PanelListItemWidget({
    required this.panel,
    required this.lastLogSummary,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_PanelListItemWidget> createState() => _PanelListItemWidgetState();
}

class _PanelListItemWidgetState extends State<_PanelListItemWidget>
    with SingleTickerProviderStateMixin {
  SlidableController? _slidableController;

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _slidableController == null) return;
      await _slidableController!.openEndActionPane();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _slidableController?.close();
      }
    });
  }

  @override
  void dispose() {
    _slidableController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    return GestureDetector(
      onLongPress: () {
        _slidableController?.openEndActionPane();
      },
      child: Slidable(
        controller: _slidableController,
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              onPressed: (BuildContext context) {
                widget.onDelete();
              },
              backgroundColor: const Color.fromARGB(255, 245, 63, 57),
              foregroundColor: Colors.white,
              icon: CupertinoIcons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: GestureDetector(
          onTap: widget.onTap,
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
                  Image.asset(
                    'assets/images/panel_icon.png',
                    height: 62,
                    width: 62,
                  ),
                  SizedBox(width: 14.31),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          panel.deviceType == 'bluetooth'
                              ? BleNameUtils.getDisplayPrefixFromBleName(
                                panel.panelName,
                              )
                              : panel.panelName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D3D3D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          panel.deviceType == 'bluetooth'
                              ? BleNameUtils.getDisplayIdFromBleName(
                                panel.panelName,
                              )
                              : panel.panelId,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF918F8F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // widget.lastLogSummary,
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFFEC1D24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
