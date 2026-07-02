import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';

class ProjectDashboardArgs {
  const ProjectDashboardArgs({
    required this.panelVersionNo,
    required this.panelName,
    required this.selectedDevice,
    this.siteId,
    this.siteName,
  });

  final String panelVersionNo;
  final String panelName;
  final int? siteId;
  final String? siteName;
  final DiscoveredDevice selectedDevice;
}
