import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/features/dashboard/bindings/project_dashboard_binding.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/dashboard/views/project_dashboard.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/controllers/site_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_detail_screen.dart';
import 'package:techno_switch_solar_app/features/sites/widgets/site_confirm_delete_dialog.dart';
import 'package:techno_switch_solar_app/models/panel_model.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';

mixin SiteUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements SiteUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  Future<bool?> showDeleteSiteDialog({required String siteName}) {
    return SiteConfirmDeleteDialog.show(
      context,
      title: StringConstants.deleteSite,
      message: UiStrings.deleteSiteConfirmMessage(siteName),
      confirmLabel: StringConstants.delete,
    );
  }

  @override
  Future<bool?> showDeletePanelDialog({required PanelModel panel}) {
    return SiteConfirmDeleteDialog.show(
      context,
      title: StringConstants.removePanel,
      message: StringConstants.removePanelConfirmationMessage(
        panel.panelName,
        panel.panelId,
      ),
      confirmLabel: StringConstants.remove,
    );
  }

  @override
  void showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? ColorConstants.primary,
      ),
    );
  }

  @override
  void popScreen([bool? result]) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Future<void> openSiteDetail({
    required SiteWithLogCount siteWithLogCount,
  }) async {
    if (!mounted) return;
    SiteDetailBinding(
      args: SiteDetailArgs(siteWithLogCount: siteWithLogCount),
    ).dependencies();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SiteDetailScreen()),
    );
  }

  @override
  void openProjectDashboard({required ProjectDashboardArgs args}) {
    if (!mounted) return;
    ProjectDashboardBinding(args: args).dependencies();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectDashboardScreen()),
    );
  }
}
