import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_configuration_coordinator.dart';
import 'package:techno_switch_solar_app/utils/panel_config/post_connect_config_log_compare.dart';
import 'package:techno_switch_solar_app/widgets/dialogs/app_styled_dialogs.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

PanelConfigRefreshNotifiers _ephemeralPanelRefreshNotifiers() {
  return PanelConfigRefreshNotifiers(
    relay: ValueNotifier(0),
    input: ValueNotifier(0),
    zone: ValueNotifier(0),
    extOut: ValueNotifier(0),
    sounder: ValueNotifier(0),
    serviceDue: ValueNotifier(0),
    accessCode: ValueNotifier(0),
    panelInfo: ValueNotifier(0),
    generalModule: ValueNotifier(0),
  );
}

Future<void> offerOptionalFullConfigDownloadAfterConnect({
  required BuildContext context,
  required bool Function() isMounted,
  required DiscoveredDevice device,
  PanelConfigRefreshNotifiers? refreshNotifiers,
  ValueNotifier<bool>? navigatingToDeviceConnecting,
  bool awaitDownloadIfAccepted = false,
  bool showConfigLogCompareAfterDownload = false,
  bool panelHadNoSiteBeforeConnect = false,
}) async {
  final wantDownload = await showAppStyledTwoActionDialog<bool>(
    context: context,
    title: StringConstants.downloadPanelConfiguration,
    message: '',
    leadingActionLabel: UiStrings.noButton,
    trailingActionLabel: UiStrings.yesButton,
    leadingValue: false,
    trailingValue: true,
  );
  if (!isMounted()) return;

  final bleManager = Get.find<BleManager>();

  if (wantDownload != true) {
    await PanelConfigCacheSync.restoreAllFromCacheToBle(
      bleManager,
      device.id,
      refreshNotifiers,
    );
    return;
  }

  if (!context.mounted) return;
  final bleController = Get.find<BleLogController>();
  final notifiers = refreshNotifiers ?? _ephemeralPanelRefreshNotifiers();
  final nav = navigatingToDeviceConnecting ?? ValueNotifier<bool>(false);

  final bool deferWritingCachesUntilConfigLogResolution =
      awaitDownloadIfAccepted &&
      showConfigLogCompareAfterDownload &&
      !panelHadNoSiteBeforeConnect;

  final coordinator = PanelConfigurationCoordinator(
    bleManager: bleManager,
    bleController: bleController,
    device: device,
    refreshNotifiers: notifiers,
    navigatingToDeviceConnecting: nav,
    useDialogOnlyBulkProgress: true,
    saveCachesAfterBulkDownload: !deferWritingCachesUntilConfigLogResolution,
  );
  if (awaitDownloadIfAccepted) {
    try {
      await coordinator.startBulkDownloadAwaitCompletion(
        context: context,
        isMounted: isMounted,
      );
      if (showConfigLogCompareAfterDownload &&
          !panelHadNoSiteBeforeConnect &&
          isMounted() &&
          context.mounted) {
        await presentPostConnectConfigLogCompareAfterDownload(
          context: context,
          isMounted: isMounted,
          device: device,
          refreshNotifiers: notifiers,
          navigatingToDeviceConnecting: nav,
        );
      }
    } catch (_) {}
  } else {
    coordinator.startBulkDownload(context: context, isMounted: isMounted);
  }
}
