import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Technoswitch/features/create_project/bindings/create_project_binding.dart';
import 'package:Technoswitch/features/create_project/views/create_project_screen.dart';
import 'package:Technoswitch/features/home/controllers/home_screen_ui_delegate.dart';
import 'package:Technoswitch/features/scan/bindings/scan_binding.dart';
import 'package:Technoswitch/features/scan/models/scan_flow_args.dart';
import 'package:Technoswitch/features/scan/views/scanning_screen.dart';
import 'package:Technoswitch/features/scan/views/windows/windows_scanning_screen.dart';
import 'package:Technoswitch/features/sites/bindings/site_binding.dart';
import 'package:Technoswitch/features/sites/models/site_args.dart';
import 'package:Technoswitch/features/sites/views/site_screen.dart';
import 'package:Technoswitch/models/site_model.dart';
import 'package:Technoswitch/utils/site_service.dart';

mixin HomeUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements HomeScreenUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  Future<void> openScanning(ScanFlowArgs args) async {
    if (!mounted) return;
    ScanBinding(args: args).dependencies();
    await Navigator.of(uiContext).push(
      MaterialPageRoute(
        builder:
            (_) =>
                Platform.isWindows
                    ? const WindowsScanningScreen()
                    : const ScanningScreen(),
      ),
    );
  }

  @override
  void openCreateProject() {
    if (!mounted) return;
    CreateProjectBinding().dependencies();
    Navigator.of(
      uiContext,
    ).push(MaterialPageRoute(builder: (_) => const CreateSiteScreen()));
  }

  @override
  Future<bool?> openSite({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  }) {
    SiteBinding(
      args: SiteArgs(site: site, siteWithLogCount: siteWithLogCount),
    ).dependencies();
    return Navigator.of(
      uiContext,
    ).push<bool>(MaterialPageRoute(builder: (_) => const SiteScreen()));
  }
}
