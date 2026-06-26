import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_access_password_popup.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_bulk_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_feedback_dialogs.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/widgets/bottom_sheets/config_log_bottomsheet.dart';

Future<void> presentPostConnectConfigLogCompareAfterDownload({
  required BuildContext context,
  required bool Function() isMounted,
  required DiscoveredDevice device,
  required PanelConfigRefreshNotifiers refreshNotifiers,
  required ValueNotifier<bool> navigatingToDeviceConnecting,
}) async {
  if (!isMounted() || !context.mounted) return;

  final bleManager = Get.find<BleLogController>().bleManager;
  final bleController = Get.find<BleLogController>();

  final compareResult = ValueNotifier<ConfigCompareResult?>(null);
  final isWorking = ValueNotifier<bool>(false);
  var userChoseAction = false;

  Future<ConfigCompareResult> buildCompare() async {
    return PanelConfigBulkSync.buildConfigCompareResultFromCache(
      bleManager,
      device.id,
    );
  }

  compareResult.value = await buildCompare();

  if (!isMounted() || !context.mounted) {
    compareResult.dispose();
    isWorking.dispose();
    return;
  }

  PanelAccessPasswordDelegates delegates({
    Future<void> Function()? afterBulkApply,
  }) {
    return PanelAccessPasswordDelegates(
      saveExtOutCache:
          () => PanelConfigCacheSync.saveExtOut(
            bleManager,
            device.id,
            refreshNotifiers.extOut,
          ),
      saveInputCache:
          () => PanelConfigCacheSync.saveInput(
            bleManager,
            device.id,
            refreshNotifiers.input,
          ),
      saveRelayCache:
          () => PanelConfigCacheSync.saveRelay(
            bleManager,
            device.id,
            refreshNotifiers.relay,
          ),
      saveZoneCache:
          () => PanelConfigCacheSync.saveZone(
            bleManager,
            device.id,
            refreshNotifiers.zone,
          ),
      saveRadioCache:
          () => PanelConfigCacheSync.saveRadio(
            bleManager,
            device.id,
            refreshNotifiers.zone,
          ),
      saveLBusCache:
          () => PanelConfigCacheSync.saveLBus(
            bleManager,
            device.id,
            refreshNotifiers.zone,
          ),
      saveSounderCache:
          () => PanelConfigCacheSync.saveSounder(
            bleManager,
            device.id,
            refreshNotifiers.sounder,
          ),
      saveServiceDueCache:
          () => PanelConfigCacheSync.saveServiceDue(
            bleManager,
            device.id,
            refreshNotifiers.serviceDue,
          ),
      saveAccessCodeCache:
          () => PanelConfigCacheSync.saveAccessCode(
            bleManager,
            device.id,
            refreshNotifiers.accessCode,
          ),
      savePanelInfoCache:
          () => PanelConfigCacheSync.savePanelInfo(
            bleManager,
            device.id,
            refreshNotifiers.panelInfo,
          ),
      saveGeneralModuleCache:
          () => PanelConfigCacheSync.saveGeneralModule(
            bleManager,
            device.id,
            refreshNotifiers.generalModule,
          ),
      showApplySuccess: (ctx, msg, {subtitle}) {
        showPanelApplySuccessDialog(
          ctx,
          bleManager.bleProcess,
          msg,
          subtitle: subtitle,
        );
      },
      showDownloadSuccess: showPanelDownloadSuccessDialog,
      openLogRetrievalLoading: (_) {},
      afterBulkApplyAccessGranted: afterBulkApply,
    );
  }

  Future<void> onUsePanelDataInApp() async {
    userChoseAction = true;
    await PanelConfigCacheSync.saveAllFromBle(
      bleManager,
      device.id,
      refreshNotifiers,
    );
    refreshNotifiers.bumpAll();
  }

  void onApplyLocalToPanel() {
    userChoseAction = true;
    if (!isMounted() || !context.mounted) return;
    showPanelAccessPasswordPopup(
      context: context,
      isMounted: isMounted,
      bleManager: bleManager,
      bleController: bleController,
      selectedDevice: device,
      navigatingToDeviceConnecting: navigatingToDeviceConnecting,
      delegates: delegates(
        afterBulkApply: () async {
          try {
            await PanelConfigBulkSync.runConfigLogApplyRemaining(
              bleController,
              bleManager,
            );
            await PanelConfigCacheSync.saveAllFromBle(
              bleManager,
              device.id,
              refreshNotifiers,
            );
            refreshNotifiers.bumpAll();
            if (isMounted() && context.mounted) {
              showPanelApplySuccessDialog(
                context,
                bleManager.bleProcess,
                'Configuration',
                subtitle: 'Your saved setup has been applied to the panel.',
              );
            }
            compareResult.value = await buildCompare();
          } finally {
            bleManager.bleProcess.clearPeripheralApplyDoneFlags();
          }
        },
      ),
      onCall: () {
        bleManager.bleProcess.isPanelInfoSetupApplyCommandActive.value = true;
        bleController.startPanelInfoSetupApply();
      },
      isPanelInfoSetup: true,
      mode: 'bottomsheet_apply',
      isConfigLogBulkApply: true,
      showDetailedConfigLogBulkBleProgressInAccessDialog: false,
      configLogWorking: isWorking,
    );
  }

  Future<void> onDownloadAndCompare() async {
    await showPanelAccessPasswordPopup(
      context: context,
      isMounted: isMounted,
      bleManager: bleManager,
      bleController: bleController,
      selectedDevice: device,
      navigatingToDeviceConnecting: navigatingToDeviceConnecting,
      delegates: delegates(),
      onCall: () {
        bleManager.bleProcess.isModuleSetupFetchCommandActive.value = true;
        bleController.startModuleSetupFetch();
      },
      mode: 'bottomsheet_download',
      isConfigLogBulk: true,
      showDetailedConfigLogBulkBleProgressInAccessDialog: false,
      downloadSuccessMessage: 'Configuration',
      configLogWorking: isWorking,
      onDownloadComplete: () async {
        try {
          await PanelConfigBulkSync.runConfigLogFetchRemaining(
            bleController,
            bleManager,
          );
          compareResult.value = await buildCompare();
          await PanelConfigCacheSync.saveAllFromBle(
            bleManager,
            device.id,
            refreshNotifiers,
          );
          refreshNotifiers.bumpAll();
        } catch (e, _) {
          compareResult.value = ConfigCompareResult.withError(
            e is TimeoutException
                ? 'Operation timed out. Stay close to the device and try again.'
                : e.toString(),
          );
        }
      },
    );
  }

  if (!isMounted() || !context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) {
      return ConfigLogBottomSheet(
        deviceId: device.id,
        compareResult: compareResult,
        isWorking: isWorking,
        onDownloadAndCompare: onDownloadAndCompare,
        onUsePanelDataInApp: onUsePanelDataInApp,
        onApplyLocalToPanel: onApplyLocalToPanel,
        showDownloadAndCompareCta: false,
      );
    },
  ).whenComplete(() async {
    compareResult.dispose();
    isWorking.dispose();
    if (userChoseAction || !isMounted()) return;
    unawaited(
      PanelConfigCacheSync.saveAllFromBle(
        bleManager,
        device.id,
        refreshNotifiers,
      ).then((_) {
        if (isMounted()) {
          refreshNotifiers.bumpAll();
        }
      }),
    );
  });
}
