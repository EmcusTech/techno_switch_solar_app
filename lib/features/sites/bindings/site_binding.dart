import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/simple_site_creation_controller.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_controller.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';

class SiteBinding extends Bindings {
  SiteBinding({required this.args});

  final SiteArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<SiteController>()) {
      Get.delete<SiteController>();
    }
    Get.lazyPut<SiteController>(() => SiteController(args: args));
  }
}

class SiteDetailBinding extends Bindings {
  SiteDetailBinding({required this.args});

  final SiteDetailArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<SiteDetailController>()) {
      Get.delete<SiteDetailController>();
    }
    Get.lazyPut<SiteDetailController>(() => SiteDetailController(args: args));
  }
}

class SimpleSiteCreationBinding extends Bindings {
  SimpleSiteCreationBinding({required this.args});

  final SimpleSiteCreationArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<SimpleSiteCreationController>()) {
      Get.delete<SimpleSiteCreationController>();
    }
    Get.lazyPut<SimpleSiteCreationController>(
      () => SimpleSiteCreationController(args: args),
    );
  }
}
