import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_app_bar.dart';
import 'package:Technoswitch/features/dashboard/widgets/windows/windows_dashboard_content.dart';
import 'package:flutter/material.dart';
import 'package:Technoswitch/features/dashboard/controllers/project_dashboard_controller.dart';
import 'package:Technoswitch/features/dashboard/widgets/dashboard_app_bar.dart';
import 'package:Technoswitch/features/dashboard/widgets/dashboard_content.dart';
import 'package:Technoswitch/features/dashboard/widgets/dashboard_shell.dart';

class WindowsDashboardTab extends StatelessWidget {
  const WindowsDashboardTab({
    super.key,
    required this.controller,
    required this.onExport,
  });

  final ProjectDashboardController controller;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WindowsDashboardAppBar(
            onBack: controller.handleBackNavigation,
            onExport: onExport,
          ),
          const SizedBox(height: 12),
          WindowsDashboardContent(controller: controller),
        ],
      ),
    );
  }
}
