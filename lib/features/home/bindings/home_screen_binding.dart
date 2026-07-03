import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/home/controllers/home_screen_controller.dart';

class HomeScreenBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<HomeScreenController>()) {
      Get.delete<HomeScreenController>();
    }
    Get.lazyPut<HomeScreenController>(() => HomeScreenController());
  }
}
