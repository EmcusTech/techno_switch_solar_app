import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/help/controllers/help_screen_controller.dart';

class HelpScreenBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<HelpScreenController>()) {
      Get.delete<HelpScreenController>();
    }
    Get.lazyPut<HelpScreenController>(() => HelpScreenController());
  }
}
