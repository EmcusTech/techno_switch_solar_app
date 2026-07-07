import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_controller.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';
import 'package:techno_switch_solar_app/features/settings/bindings/settings_binding.dart';
import 'package:techno_switch_solar_app/features/settings/models/settings_args.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class HomeScreenBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<HomeScreenController>()) {
      Get.delete<HomeScreenController>();
    }
    if (Get.isRegistered<HelpScreenController>()) {
      Get.delete<HelpScreenController>();
    }
    Get.lazyPut<HomeScreenController>(() => HomeScreenController());
    Get.lazyPut<HelpScreenController>(() => HelpScreenController());
    SettingsBinding(
      args: SettingsArgs(
        panelName: StringConstants.rhino2008,
        panelVersionNo: StringConstants.s098,
        embedded: true,
      ),
    ).dependencies();
  }
}
