import 'package:get/get.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/features/dashboard/models/project_dashboard_args.dart';
import 'package:Technoswitch/features/settings/bindings/settings_binding.dart';
import 'package:Technoswitch/features/settings/models/settings_args.dart';
import 'package:Technoswitch/features/test_mode/bindings/test_mode_binding.dart';
import 'package:Technoswitch/features/test_mode/models/test_mode_args.dart';

class ProjectDashboardBinding extends Bindings {
  ProjectDashboardBinding({required this.args});

  final ProjectDashboardArgs args;

  @override
  void dependencies() {
    if (Get.isRegistered<ProjectDashboardController>()) {
      Get.delete<ProjectDashboardController>();
    }
    Get.put(ProjectDashboardController(args: args));
    SettingsBinding(
      args: SettingsArgs(
        panelName: args.panelName,
        panelVersionNo: args.panelVersionNo,
        embedded: true,
      ),
    ).dependencies();
    TestModeBinding(
      args: TestModeArgs(
        panelName: args.panelName,
        siteId: args.siteId,
        embedded: true,
      ),
    ).dependencies();
  }
}
