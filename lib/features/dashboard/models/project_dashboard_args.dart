import 'package:Technoswitch/ble/blue_plus_adapter.dart';

class ProjectDashboardArgs {
  const ProjectDashboardArgs({
    required this.panelVersionNo,
    required this.panelName,
    required this.selectedDevice,
    this.siteId,
    this.siteName,
    this.awaitWindowsAccessCode = false,
    this.panelHadNoSiteBeforeConnect = false,
  });

  final String panelVersionNo;
  final String panelName;
  final int? siteId;
  final String? siteName;
  final DiscoveredDevice selectedDevice;

  /// Windows connect landed here before the access code was verified.
  final bool awaitWindowsAccessCode;

  /// True when this panel had no site until the connect that opened the dashboard.
  final bool panelHadNoSiteBeforeConnect;
}
