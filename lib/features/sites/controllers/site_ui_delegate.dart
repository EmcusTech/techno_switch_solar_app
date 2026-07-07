import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

abstract class SiteUiDelegate {
  bool get isMounted;

  Future<bool?> showDeleteSiteDialog({required String siteName});

  Future<bool?> showDeletePanelDialog({required PanelModel panel});

  void showSnackBar(String message, {Color? backgroundColor});

  void popScreen([bool? result]);

  Future<void> openSiteDetail({required SiteWithLogCount siteWithLogCount});

  void openProjectDashboard({required ProjectDashboardArgs args});
}

abstract class SiteDetailUiDelegate {
  bool get isMounted;

  void popScreen();
}

abstract class SimpleSiteCreationUiDelegate {
  bool get isMounted;

  void popScreen([int? siteId]);

  void popBack();

  void showSuccessSnackBar(String message);

  void openHomeAndClearStack();

  Future<void> openExistingSite({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  });

  Future<void> disconnectBle();
}
