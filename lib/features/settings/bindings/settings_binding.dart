import 'package:get/get.dart';
import 'package:Technoswitch/features/settings/controllers/settings_controller.dart';
import 'package:Technoswitch/features/settings/models/settings_args.dart';

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
