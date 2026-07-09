import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/features/create_project/controllers/create_project_ui_delegate.dart';
import 'package:techno_switch_solar_app/features/dashboard/bindings/project_dashboard_binding.dart';
import 'package:techno_switch_solar_app/features/dashboard/models/project_dashboard_args.dart';
import 'package:techno_switch_solar_app/features/dashboard/views/project_dashboard.dart';
import 'package:techno_switch_solar_app/features/scan/bindings/scan_binding.dart';
import 'package:techno_switch_solar_app/features/scan/models/scan_flow_args.dart';
import 'package:techno_switch_solar_app/features/scan/views/scanning_screen.dart';
import 'package:techno_switch_solar_app/features/sites/bindings/site_binding.dart';
import 'package:techno_switch_solar_app/features/sites/models/site_args.dart';
import 'package:techno_switch_solar_app/features/sites/views/site_screen.dart';
import 'package:techno_switch_solar_app/features/create_project/widgets/disconnect_device_dialog.dart';
import 'package:techno_switch_solar_app/models/site_model.dart';
import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/constants/color_constants.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/site_service.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/app_styled_dialogs.dart';

mixin CreateProjectUiDelegateMixin<T extends StatefulWidget> on State<T>
    implements CreateProjectUiDelegate {
  @override
  bool get isMounted => mounted;

  @override
  BuildContext get uiContext => context;

  @override
  Future<void> dismissKeyboardFully() async {
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<Object>(
      StringConstants.textinputHide,
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  Future<void> settleImeBeforeShowingDialog() async {
    await dismissKeyboardFully();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await dismissKeyboardFully();
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 280));
  }

  @override
  void showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? ColorConstants.primary : ColorConstants.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Future<bool?> showCreateSiteConfirmDialog() {
    return showAppStyledTwoActionDialog<bool>(
      context: context,
      title: UiStrings.createSiteDialogTitle,
      message: UiStrings.createSiteConfirmMessage,
      leadingActionLabel: UiStrings.cancelButton,
      trailingActionLabel: UiStrings.createButton,
      leadingValue: false,
      trailingValue: true,
    );
  }

  @override
  Future<bool?> showApplyPanelSettingsConfirmDialog() {
    return showAppStyledTwoActionDialog<bool>(
      context: context,
      title: UiStrings.applyPanelSettingsDialogTitle,
      message: UiStrings.applyPanelSettingsConfirmMessage,
      leadingActionLabel: UiStrings.cancelButton,
      trailingActionLabel: UiStrings.nextButton,
      leadingValue: false,
      trailingValue: true,
    );
  }

  @override
  Future<bool?> showCreateSiteNoConfigChangesConfirmDialog() {
    return showAppStyledTwoActionDialog<bool>(
      context: context,
      title: UiStrings.createSiteNoConfigChangesDialogTitle,
      message: UiStrings.createSiteNoConfigChangesConfirmMessage,
      leadingActionLabel: UiStrings.cancelButton,
      trailingActionLabel: UiStrings.createButton,
      leadingValue: false,
      trailingValue: true,
    );
  }

  @override
  Future<bool?> showDisconnectConfirmDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DisconnectDeviceDialog(),
    );
  }

  @override
  Future<String?> showEnterPanelIdDialog({String? initialValue}) {
    return showAppStyledTextInputDialog(
      context: context,
      title: UiStrings.enterPanelIdDialogTitle,
      message:
          'Enter the panel ID for this site (e.g. AB12). It should match the ID in the panel BLE name TECHNOSWITCH_XXXX when you connect later.',
      hintText: UiStrings.panelIdLabel,
      initialValue: initialValue,
      validator: (value) {
        if (!BleNameUtils.isValidManualPanelId(value)) {
          return StringConstants.enterAValidPanelIDLettersNumbersOr;
        }
        return null;
      },
    );
  }

  @override
  Future<void> showPanelAlreadyAssignedDialog() {
    return showAppStyledOneActionDialog(
      context: context,
      title: StringConstants.panelAlreadyAssigned,
      message: UiStrings.panelIdAlreadyLinkedMessage,
    );
  }

  @override
  Future<String?> showPanelAlreadyOnSiteDialog() {
    return showAppStyledTwoActionDialog<String>(
      context: context,
      title: StringConstants.panelAlreadyOnASite,
      message:
          'This panel is assigned to another site. Move it to the new site you are creating, or skip and return home.',
      leadingActionLabel: 'Skip',
      trailingActionLabel: StringConstants.replace,
      leadingValue: 'skip',
      trailingValue: 'move',
    );
  }

  @override
  Future<void> showMandatoryConfigDownloadDialog() {
    return showAppStyledOneActionDialog(
      context: context,
      title: UiStrings.mandatoryConfigDownloadDialogTitle,
      message: UiStrings.mandatoryConfigDownloadDialogMessage,
      actionLabel: UiStrings.mandatoryConfigDownloadButton,
    );
  }

  @override
  Future<bool?> openScanningScreen(String? expectedPanelType) {
    ScanBinding(
      args: ScanFlowArgs.scanning(
        createProjectExpectedPanelType: expectedPanelType,
      ),
    ).dependencies();
    return Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ScanningScreen()));
  }

  @override
  void popScreen() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void popToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void openProjectDashboard({
    required DiscoveredDevice device,
    required int siteId,
    required String siteName,
  }) {
    ProjectDashboardBinding(
      args: ProjectDashboardArgs(
        panelVersionNo: device.id,
        panelName: device.name,
        selectedDevice: device,
        siteId: siteId,
        siteName: siteName,
      ),
    ).dependencies();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProjectDashboardScreen()),
    );
  }

  @override
  void openSiteScreen({
    required SiteModel site,
    required SiteWithLogCount siteWithLogCount,
  }) {
    SiteBinding(
      args: SiteArgs(site: site, siteWithLogCount: siteWithLogCount),
    ).dependencies();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SiteScreen()));
  }
}
