import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/home/bindings/home_screen_binding.dart';
import 'package:techno_switch_solar_app/features/home/views/home_screen.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/simple_site_creation_controller.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_screen.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

mixin SimpleSiteCreationUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements SimpleSiteCreationUiDelegate {
  SimpleSiteCreationController get simpleSiteCreationController;

  @override
  bool get isMounted => mounted;

  @override
  void popScreen([int? siteId]) {
    if (!mounted) return;
    Navigator.of(context).pop(siteId);
  }

  @override
  void popBack() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorConstants.success,
      ),
    );
  }

  @override
  void openHomeAndClearStack() {
    if (!mounted) return;
    HomeScreenBinding().dependencies();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Future<void> openExistingSite({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  }) async {
    if (!mounted) return;
    SiteBinding(
      args: SiteArgs(site: site, siteWithLogCount: siteWithLogCount),
    ).dependencies();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SiteScreen()),
      (route) => false,
    );
  }

  @override
  Future<void> disconnectBle() async {
    await simpleSiteCreationController.disconnectBleDevice();
  }
}
