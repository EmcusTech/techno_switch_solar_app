import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/screens/scanning_screen.dart';
import 'package:techno_switch_solar_app/screens/site_screen.dart';
import 'package:techno_switch_solar_app/services/app_services.dart';
import 'package:techno_switch_solar_app/services/app_state.dart';
import 'package:techno_switch_solar_app/services/site_service.dart';
import 'package:techno_switch_solar_app/services/log_retrieval_service.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    SettingsScreen(panelName: 'RHINO2008', panelVersionNo: '0.98'),
    const HelpScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Disconnect Bluetooth when returning to home screen
    _handleBluetoothCleanup();
  }

  Future<void> _handleBluetoothCleanup() async {
    // If there's an active Bluetooth connection, disconnect it
    // This ensures clean state when user returns to home
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

    // Reset app state for fresh start
    AppState.reset();
  }

  void _onItemTapped(int index) {
    if (index == 1 || index == 2) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: BottomNavigationBar(
            iconSize: 24,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/svgs/home_icon.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 0 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/svgs/setting_icon.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 1 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/svgs/help_icon.svg',
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 2 ? Colors.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Help',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            backgroundColor: Color(0xffEC1D24),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final SiteService _siteService = SiteService();
  final LogRetrievalService _logRetrievalService = LogRetrievalService();
  List<SiteWithLogCount> _sites = [];
  bool _isLoading = true;
  Map<int, int> _lastRetrievalCounts = {};
  Map<int, DateTime?> _lastRetrievalDates = {};

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final sites = await _siteService.getSitesWithLogCount();
      await _loadLatestRetrievals(sites);
      setState(() {
        _sites = sites;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading sites: $error');
    }
  }

  Future<void> _refreshSites() async {
    setState(() {
      _isLoading = true;
    });
    await _loadSites();
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
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.only(top: 250),
            child: _buildQuickLinks(context),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 354),
            child: _buildRecentSites(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40),
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
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: InkWell(
                    onTap: () async {
                      // await testPasskeyFrameGeneration('1974');
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScanningScreen(),
                        ),
                      );
                      if (mounted) {
                        await _refreshSites();
                      }
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

  Widget _buildQuickLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Quick Links',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D3D3D),
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (context) => CreateSiteScreenRefactored(),
                  //   ),
                  // );
                },
                child: _buildQuickLinkItem(
                  'assets/svgs/new_project_icon.svg',
                  'New Site',
                  isEnabled: false,
                ),
              ),
              _buildQuickLinkItem(
                'assets/svgs/open_project_icon.svg',
                'Open Site',
                isEnabled: false,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => ScanningScreen(isLiveEventLogs: true),
                    ),
                  );
                },
                child: _buildQuickLinkItem(
                  'assets/svgs/maintenance_icon.svg',
                  'Live Events',
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ScanningScreen(isLiveEvent: true),
                    ),
                  );
                },
                child: _buildQuickLinkItem(
                  'assets/svgs/retrieve_log_icon.svg',
                  'Retrieve Log',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkItem(
    String imagePath,
    String text, {
    bool? isEnabled = true,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color:
                isEnabled == true ? Colors.transparent : Colors.grey.shade200,
            border: Border.all(
              color:
                  isEnabled == true
                      ? Color(0xFFEC1D24).withValues(alpha: 0.31)
                      : Colors.grey.shade200,
              width: 1,
            ),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(17.0),
            child: SvgPicture.asset(
              imagePath,
              colorFilter:
                  isEnabled == true
                      ? null
                      : ColorFilter.mode(
                        Color(0xFFEC1D24).withValues(alpha: 0.31),
                        BlendMode.srcIn,
                      ),
            ),
          ),
        ),
        SizedBox(height: 11),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFF3D3D3D),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSites() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Sites',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3D3D3D),
                ),
              ),
              if (_sites.isNotEmpty)
                Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666).withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          _buildRecentSitesItem(),
        ],
      ),
    );
  }

  Future<void> _loadLatestRetrievals(List<SiteWithLogCount> sites) async {
    final counts = <int, int>{};
    final dates = <int, DateTime?>{};

    for (final siteWithCount in sites) {
      final siteId = siteWithCount.site.id;
      if (siteId == null) continue;

      try {
        final latest = await _logRetrievalService.getMostRecentLogRetrieval(
          siteId,
        );
        if (latest != null) {
          counts[siteId] = latest.logCount;
          dates[siteId] = latest.retrievalDate;
        } else {
          dates[siteId] = siteWithCount.lastLogRetrieved;
        }
      } catch (_) {
        dates[siteId] = siteWithCount.lastLogRetrieved;
      }
    }

    _lastRetrievalCounts = counts;
    _lastRetrievalDates = dates;
  }

  Widget _buildLastLogSummary(SiteWithLogCount siteWithLogCount) {
    final site = siteWithLogCount.site;

    // Use site creation time instead of last log time
    final DateTime createdAt = site.createdAt;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '${DateFormat('MMM d').format(createdAt)}, '
            '${DateFormat('yyyy').format(createdAt)} • '
            '${DateFormat('hh:mm a').format(createdAt)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF918F8F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSitesItem() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: Color(0xFFEC1D24)),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 550,
      child: RefreshIndicator(
        color: Color(0xFFEC1D24),
        onRefresh: _refreshSites,
        child: ListView.separated(
          physics: AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _sites.isEmpty ? 1 : _sites.length,
          separatorBuilder: (context, index) {
            return SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            if (_sites.isEmpty) {
              return Center(
                child: Text(
                  'No Sites Yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3D3D3D),
                  ),
                ),
              );
            }
            final siteWithLogCount = _sites[index];
            final site = siteWithLogCount.site;

            return GestureDetector(
              onTap: () async {
                final deleted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder:
                        (context) => SiteScreen(
                          site: site,
                          siteWithLogCount: siteWithLogCount,
                        ),
                  ),
                );

                if (deleted == true) {
                  await _refreshSites();
                }
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
                    vertical: 8.0,
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
                              site.siteName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3D3D3D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            _buildLastLogSummary(siteWithLogCount),
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
            );
          },
        ),
      ),
    );
  }
}
