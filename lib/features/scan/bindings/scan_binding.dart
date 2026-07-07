import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/scan/controllers/scan_controller.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';

class ScanBinding extends Bindings {
  ScanBinding({required this.args});

  final ScanFlowArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<ScanController>()) {
      Get.delete<ScanController>();
    }
    Get.lazyPut<ScanController>(() => ScanController(args: args));
  }
}
