import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/updates_controller.dart';

/// Feature-scoped binding for the firmware update flow.
///
/// Registers [UpdatesController] lazily while the firmware sheet is open.
/// Call [dependencies] before showing the sheet and `Get.delete<UpdatesController>()`
/// once it closes so the controller does not outlive the flow.
class FirmwareBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpdatesController>(() => UpdatesController());
  }
}
