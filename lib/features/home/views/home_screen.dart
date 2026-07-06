import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_controller.dart';
import 'package:techno_switch_solar_app/features/help/views/help_screen.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/features/home/views/home_ui_delegate_mixin.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_bottom_nav.dart';
import 'package:techno_switch_solar_app/features/home/widgets/home_tab.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/features/settings/views/settings_screen.dart';
import 'package:techno_switch_solar_app/utils/app/navigation_service.dart';
import 'package:techno_switch_solar_app/utils/constants/asset_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with RouteAware, HomeUiDelegateMixin {
  late final HomeScreenController _controller;
  bool _routeSubscriptionRegistered = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<HomeScreenController>();
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
    if (Get.isRegistered<SettingsController>()) {
      Get.delete<SettingsController>();
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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeScreenController>(
      init: _controller,
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorConstants.white,
          extendBody: true,
          body: IndexedStack(
            index: controller.selectedIndex,
            children: [
              HomeTab(controller: controller),
              const SettingsScreen(),
              const HelpScreen(),
            ],
          ),
          bottomNavigationBar: HomeBottomNav(controller: controller),
        );
      },
    );
  }
}
