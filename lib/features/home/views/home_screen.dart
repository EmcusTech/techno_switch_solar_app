import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/create_project/bindings/create_project_binding.dart';
import 'package:techno_switch_solar_app/features/create_project/views/create_project_screen.dart';
import 'package:techno_switch_solar_app/features/scan/bindings/scan_binding.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/views/scanning_screen.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_screen.dart';
import 'package:techno_switch_solar_app/utils/app/app_services.dart';
import 'package:techno_switch_solar_app/utils/app/app_state.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/log_retrieval_service.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:intl/intl.dart';
import '../../settings/views/settings_screen.dart';
import '../../help/views/help_screen.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';

import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    SettingsScreen(
      panelName: StringConstants.rhino2008,
      panelVersionNo: StringConstants.s098,
    ),
    const HelpScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _handleBluetoothCleanup();
  }

  Future<void> _handleBluetoothCleanup() async {
    if (AppServices.isConnected) {
      await AppServices.disconnect();
    }

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
      backgroundColor: ColorConstants.white,
      extendBody: true,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: ColorConstants.blackMaterial.withValues(alpha: 0.1),
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
                  AssetConstants.homeIcon,
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 0 ? ColorConstants.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: StringConstants.home,
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  AssetConstants.settingIcon,
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 1 ? ColorConstants.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: StringConstants.settings,
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  AssetConstants.helpIcon,
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 2 ? ColorConstants.white : Colors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: StringConstants.help,
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: ColorConstants.white,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            backgroundColor: ColorConstants.primary,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: StyleConstants.black12w600Style,
            unselectedLabelStyle: StyleConstants.black12w500Style,
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

class _HomeContentState extends State<_HomeContent> with RouteAware {
  final SiteService _siteService = SiteService();
  final LogRetrievalService _logRetrievalService = LogRetrievalService();
  List<SiteWithLogCount> _sites = [];
  bool _isLoading = true;
  Map<int, int> lastRetrievalCounts = {};
  Map<int, DateTime?> lastRetrievalDates = {};
  final ble = Get.find<BleLogController>().bleManager;
  bool _routeSubscriptionRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeSubscriptionRegistered) {
      final route = ModalRoute.of(context);
      if (route is PageRoute) {
        appRouteObserver.subscribe(this, route);
        _routeSubscriptionRegistered = true;
      }
    }
  }

  @override
  void dispose() {
    if (_routeSubscriptionRegistered) {
      appRouteObserver.unsubscribe(this);
      _routeSubscriptionRegistered = false;
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSites();
    });
  }

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
          colors: [ColorConstants.scaffoldGradientTop, ColorConstants.white],
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
                  color: ColorConstants.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        SvgPicture.asset(AssetConstants.background1),
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
                      if (ble.isConnected) {
                        await ble.disconnectConnectedDevice();
                      }
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            ScanBinding(
                              args: ScanFlowArgs.scanning(),
                            ).dependencies();
                            return const ScanningScreen();
                          },
                        ),
                      );
                    },
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConstants.errorIconBackground,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: SvgPicture.asset(
                          AssetConstants.logo,
                          height: 59.29,
                          width: 51,
                          colorFilter: ColorFilter.mode(
                            ColorConstants.primary,
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
                StringConstants.tapToConnect,
                style: StyleConstants.textDark14w400Style,
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
              StringConstants.quickLinks,
              style: StyleConstants.textDark18w700Style,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  CreateProjectBinding().dependencies();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreateSiteScreen(),
                    ),
                  );
                },
                child: _buildQuickLinkItem(
                  AssetConstants.newProjectIcon,
                  StringConstants.newSite,
                ),
              ),
              _buildQuickLinkItem(
                AssetConstants.openProjectIcon,
                StringConstants.openSite,
                isEnabled: false,
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        ScanBinding(
                          args: ScanFlowArgs.scanning(isLiveEventLogs: true),
                        ).dependencies();
                        return const ScanningScreen();
                      },
                    ),
                  );
                },
                child: _buildQuickLinkItem(
                  AssetConstants.maintenanceIcon,
                  StringConstants.liveEvents,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        ScanBinding(
                          args: ScanFlowArgs.scanning(isLiveEvent: true),
                        ).dependencies();
                        return const ScanningScreen();
                      },
                    ),
                  );
                },
                child: _buildQuickLinkItem(
                  AssetConstants.retrieveLogIcon,
                  StringConstants.retrieveLog,
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
                isEnabled == true
                    ? ColorConstants.transparent
                    : Colors.grey.shade200,
            border: Border.all(
              color:
                  isEnabled == true
                      ? ColorConstants.primary.withValues(alpha: 0.31)
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
                        ColorConstants.primary.withValues(alpha: 0.31),
                        BlendMode.srcIn,
                      ),
            ),
          ),
        ),
        SizedBox(height: 11),
        Text(text, style: StyleConstants.textDark11w400Style),
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
                StringConstants.recentSites,
                style: StyleConstants.textDark18w700Style,
              ),
              if (_sites.isNotEmpty)
                Text(
                  StringConstants.viewAll,
                  style: StyleConstants.textGray14w500Style,
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

    lastRetrievalCounts = counts;
    lastRetrievalDates = dates;
  }

  Widget _buildLastLogSummary(SiteWithLogCount siteWithLogCount) {
    final site = siteWithLogCount.site;
    final DateTime createdAt = site.createdAt;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '${DateFormat('MMM d').format(createdAt)}, '
            '${DateFormat('yyyy').format(createdAt)} • '
            '${DateFormat('hh:mm a').format(createdAt)}',
            style: StyleConstants.textMuted11w400Style,
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
          child: CircularProgressIndicator(color: ColorConstants.primary),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height - 550,
      child: RefreshIndicator(
        color: ColorConstants.primary,
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
                  StringConstants.noSitesYet,
                  style: StyleConstants.textDark14w400Style,
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
                  color: ColorConstants.white,
                  border: Border.all(
                    color: ColorConstants.iconDisabled.withValues(alpha: 0.31),
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
                        AssetConstants.panelIconImage,
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
                              style: StyleConstants.textDark16w700Style,
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
                        color: ColorConstants.primary,
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
