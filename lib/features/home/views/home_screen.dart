import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_controller.dart';
import 'package:techno_switch_solar_app/features/help/views/help_screen.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/settings/views/settings_screen.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_screen.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/style_constants.dart';

class HomeScreen extends GetView<HomeScreenController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomePageHost(controller: controller);
  }
}

class _HomePageHost extends StatefulWidget {
  const _HomePageHost({required this.controller});

  final HomeScreenController controller;

  @override
  State<_HomePageHost> createState() => _HomePageHostState();
}

class _HomePageHostState extends State<_HomePageHost>
    with RouteAware
    implements HomeScreenUiDelegate {
  HomeScreenController get _controller => widget.controller;
  bool _routeSubscriptionRegistered = false;

  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  Future<void> openScanning(ScanFlowArgs args) async {
    if (!mounted) return;
    await _controller.openScanning(args);
  }

  @override
  void openCreateProject() {
    _controller.openNewSite();
  }

  @override
  Future<bool?> openSite({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  }) {
    return Navigator.of(uiContext).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => SiteScreen(
              site: site,
              siteWithLogCount: siteWithLogCount,
            ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.attachUi(this);
  }

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
    _controller.detachUi();
    if (Get.isRegistered<HomeScreenController>()) {
      Get.delete<HomeScreenController>();
    }
    if (Get.isRegistered<HelpScreenController>()) {
      Get.delete<HelpScreenController>();
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.refreshSites();
    });
  }

  List<Widget> _screens() {
    return [
      _buildHomeContent(),
      SettingsScreen(
        panelName: StringConstants.rhino2008,
        panelVersionNo: StringConstants.s098,
      ),
      const HelpScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeScreenController>(
      init: _controller,
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorConstants.white,
          extendBody: true,
          body: _screens()[controller.selectedIndex],
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
                        controller.selectedIndex == 0
                            ? ColorConstants.white
                            : Colors.grey,
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
                        controller.selectedIndex == 1
                            ? ColorConstants.white
                            : Colors.grey,
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
                        controller.selectedIndex == 2
                            ? ColorConstants.white
                            : Colors.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: StringConstants.help,
                  ),
                ],
                currentIndex: controller.selectedIndex,
                selectedItemColor: ColorConstants.white,
                unselectedItemColor: Colors.grey,
                onTap: controller.setSelectedIndex,
                backgroundColor: ColorConstants.primary,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: StyleConstants.black12w600Style,
                unselectedLabelStyle: StyleConstants.black12w500Style,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return GetBuilder<HomeScreenController>(
      builder:
          (controller) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorConstants.scaffoldGradientTop,
                  ColorConstants.white,
                ],
              ),
            ),
            child: Stack(
              children: [
                _buildHeader(controller),
                Padding(
                  padding: const EdgeInsets.only(top: 250),
                  child: _buildQuickLinks(controller),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 354),
                  child: _buildRecentSites(controller),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader(HomeScreenController controller) {
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
                    onTap: controller.openTapToConnectScan,
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

  Widget _buildQuickLinks(HomeScreenController controller) {
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
                onTap: controller.openNewSite,
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
                onTap: controller.openLiveEventsScan,
                child: _buildQuickLinkItem(
                  AssetConstants.maintenanceIcon,
                  StringConstants.liveEvents,
                ),
              ),
              GestureDetector(
                onTap: controller.openRetrieveLogScan,
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

  Widget _buildRecentSites(HomeScreenController controller) {
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
              if (controller.sites.isNotEmpty)
                Text(
                  StringConstants.viewAll,
                  style: StyleConstants.textGray14w500Style,
                ),
            ],
          ),
          SizedBox(height: 12),
          _buildRecentSitesItem(controller),
        ],
      ),
    );
  }

  Widget _buildLastLogSummary(
    HomeScreenController controller,
    SiteWithLogCount siteWithLogCount,
  ) {
    final displayDate = controller.siteSummaryDate(siteWithLogCount);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(
            '${DateFormat('MMM d').format(displayDate)}, '
            '${DateFormat('yyyy').format(displayDate)} • '
            '${DateFormat('hh:mm a').format(displayDate)}',
            style: StyleConstants.textMuted11w400Style,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSitesItem(HomeScreenController controller) {
    if (controller.isLoading) {
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
        onRefresh: controller.refreshSites,
        child: ListView.separated(
          physics: AlwaysScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: controller.sites.isEmpty ? 1 : controller.sites.length,
          separatorBuilder: (context, index) {
            return SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            if (controller.sites.isEmpty) {
              return Center(
                child: Text(
                  StringConstants.noSitesYet,
                  style: StyleConstants.textDark14w400Style,
                ),
              );
            }
            final siteWithLogCount = controller.sites[index];
            final site = siteWithLogCount.site;

            return GestureDetector(
              onTap: () => controller.openSite(siteWithLogCount),
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
                            _buildLastLogSummary(controller, siteWithLogCount),
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
