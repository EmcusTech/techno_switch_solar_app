import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

/// Single registration point for app-wide GetX dependencies.
///
/// Invoked once from `main()` before `runApp`. Keeps DI wiring in one place
/// instead of scattered `Get.put` calls across the codebase.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<BleManager>(BleManager(), permanent: true);
    Get.lazyPut<BleLogController>(() => BleLogController(), fenix: true);
  }
}
