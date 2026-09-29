import 'package:flutter/material.dart';
import 'package:Technoswitch/features/scan/models/scan_flow_args.dart';
import 'package:Technoswitch/models/site_model.dart';
import 'package:Technoswitch/utils/site_service.dart';

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
