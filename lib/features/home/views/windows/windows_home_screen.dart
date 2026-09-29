import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import 'package:Technoswitch/features/help/controllers/help_screen_controller.dart';
import 'package:Technoswitch/features/help/views/help_screen.dart';
import 'package:Technoswitch/features/home/controllers/home_screen_controller.dart';
import 'package:Technoswitch/features/home/views/home_ui_delegate_mixin.dart';
import 'package:Technoswitch/features/home/widgets/home_bottom_nav.dart';
import 'package:Technoswitch/features/home/widgets/windows/ble_connect_widget.dart';
import 'package:Technoswitch/features/home/widgets/windows/live_event_widget.dart';
import 'package:Technoswitch/features/home/widgets/windows/new_site_widget.dart';
import 'package:Technoswitch/features/home/widgets/windows/open_site_widget.dart';
import 'package:Technoswitch/features/home/widgets/windows/recent_sites_table_widget.dart';
import 'package:Technoswitch/features/home/widgets/windows/retrieve_log_widget.dart';
import 'package:Technoswitch/features/home/widgets/windows/usb_connect_widget.dart';
import 'package:Technoswitch/features/home/widgets/windows/windows_home_tab.dart';
import 'package:Technoswitch/features/settings/controllers/settings_controller.dart';
import 'package:Technoswitch/features/settings/views/settings_screen.dart';
import 'package:Technoswitch/utils/app/navigation_service.dart';
import 'package:Technoswitch/utils/constants/color_constants.dart';

class WindowsHomeScreen extends StatefulWidget {
  const WindowsHomeScreen({super.key});

  @override
  State<WindowsHomeScreen> createState() => _WindowsHomeScreenState();
}

class _WindowsHomeScreenState extends State<WindowsHomeScreen>
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
          body: Padding(
            padding: EdgeInsets.all(context.r(8)),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _returnUsbConnectWidget(),
                      context.horizontalSpace(8),
                      _returnBleConnectWidget(controller),
                      context.horizontalSpace(8),
                      Expanded(
                        child: Row(
                          children: [
                            Column(
                              children: [
                                _returnNewSiteWidget(),
                                context.verticalSpace(8),
                                _returnRetrieveLogWidget(),
                              ],
                            ),
                            context.horizontalSpace(8),
                            Column(
                              children: [
                                _returnLiveEventWidget(),
                                context.verticalSpace(8),
                                _returnOpenSiteWidget(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                context.verticalSpace(16),
                Expanded(child: _returnRecentSitesWidget(controller)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _returnUsbConnectWidget() {
    return UsbConnectWidget();
  }

  Widget _returnBleConnectWidget(HomeScreenController controller) {
    return BleConnectWidget(controller: controller);
  }

  Widget _returnNewSiteWidget() {
    return NewSiteWidget();
  }

  Widget _returnLiveEventWidget() {
    return LiveEventWidget();
  }

  Widget _returnRetrieveLogWidget() {
    return RetrieveLogWidget();
  }

  Widget _returnOpenSiteWidget() {
    return OpenSiteWidget();
  }

  Widget _returnRecentSitesWidget(HomeScreenController controller) {
    return RecentSitesTableWidget(controller: controller);
  }
}
