import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/logs/controllers/log_controller.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';

class LogBinding extends Bindings {
  LogBinding({required this.args});

  final LogFlowArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<LogController>()) {
      Get.delete<LogController>();
    }
    Get.lazyPut<LogController>(() => LogController(args: args));
  }
}
