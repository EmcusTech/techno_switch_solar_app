import 'package:get/get.dart';
import 'package:techno_switch_solar_app/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';

class ProjectDashboardBinding extends Bindings {
  ProjectDashboardBinding({required this.args});

  final ProjectDashboardArgs args;

  @override
  void dependencies() {
    Get.lazyPut<ProjectDashboardController>(
      () => ProjectDashboardController(args: args),
    );
  }
}
