import 'package:get/get.dart';
import 'package:techno_switch_solar_app/controllers/create_project_controller.dart';

class CreateProjectBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateProjectController>(() => CreateProjectController());
  }
}
