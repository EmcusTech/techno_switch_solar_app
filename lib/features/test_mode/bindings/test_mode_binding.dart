import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/test_mode/controllers/test_mode_controller.dart';
import 'package:techno_switch_solar_app/features/test_mode/models/test_mode_args.dart';

class TestModeBinding extends Bindings {
  TestModeBinding({required this.args});

  final TestModeArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<TestModeController>()) {
      Get.delete<TestModeController>();
    }
    Get.lazyPut<TestModeController>(() => TestModeController(args: args));
  }
}
