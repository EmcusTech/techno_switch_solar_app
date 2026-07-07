import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/settings/controllers/settings_controller.dart';
import 'package:techno_switch_solar_app/features/settings/models/settings_args.dart';

class SettingsBinding extends Bindings {
  SettingsBinding({required this.args});

  final SettingsArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<SettingsController>()) {
      Get.delete<SettingsController>();
    }
    Get.lazyPut<SettingsController>(() => SettingsController(args: args));
  }
}
