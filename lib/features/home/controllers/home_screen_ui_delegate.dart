import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

abstract class HomeScreenUiDelegate {
  bool get isMounted;

  BuildContext get uiContext;

  Future<void> openScanning(ScanFlowArgs args);

  void openCreateProject();

  Future<bool?> openSite({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  });
}
