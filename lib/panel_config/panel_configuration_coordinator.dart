import 'dart:async';

import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/ble/blue_plus_adapter.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_access_password_popup.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_bulk_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_feedback_dialogs.dart';
import 'package:techno_switch_solar_app/features/logs/bindings/log_binding.dart';
import 'package:techno_switch_solar_app/features/logs/models/log_flow_args.dart';
import 'package:techno_switch_solar_app/features/logs/views/log_retrieval_loading_screen.dart';
import 'package:techno_switch_solar_app/features/scan/views/scanning_screen.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PanelConfigurationCoordinator {
  PanelConfigurationCoordinator({
    required this.bleManager,
    required this.bleController,
    required this.device,
    required this.refreshNotifiers,
    required this.navigatingToDeviceConnecting,
    this.useDialogOnlyBulkProgress = false,
    this.saveCachesAfterBulkDownload = true,
  });

  final BleManager bleManager;
  final BleLogController bleController;
  final DiscoveredDevice device;
  final PanelConfigRefreshNotifiers refreshNotifiers;
  final ValueNotifier<bool> navigatingToDeviceConnecting;
  final bool useDialogOnlyBulkProgress;
  final bool saveCachesAfterBulkDownload;

  PanelAccessPasswordDelegates _delegates({
    Future<void> Function()? afterBulkApplyAccessGranted,
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
      openLogRetrievalLoading:
          useDialogOnlyBulkProgress
              ? (_) {}
              : (dialogContext) {
                LogBinding(
                  args: LogFlowArgs.loading(
                    scanType: ScanType.bluetooth,
                    selectedDevice: device,
                    connectedDevice: device,
                  ),
                ).dependencies();
                Navigator.of(dialogContext).push(
                  MaterialPageRoute(
                    builder: (_) => const LogRetrievalLoadingScreen(),
                  ),
                );
              },
      afterBulkApplyAccessGranted: afterBulkApplyAccessGranted,
    );
  }

  void startBulkDownload({
    required BuildContext context,
    required bool Function() isMounted,
  }) {
    showPanelAccessPasswordPopup(
      context: context,
      isMounted: isMounted,
      bleManager: bleManager,
      bleController: bleController,
      selectedDevice: device,
      navigatingToDeviceConnecting: navigatingToDeviceConnecting,
      delegates: _delegates(),
      onCall: () {
        bleManager.bleProcess.isModuleSetupFetchCommandActive.value = true;
        bleController.startModuleSetupFetch();
      },
      mode: 'bottomsheet_download',
      isConfigLogBulk: true,
      downloadSuccessMessage: StringConstants.configuration,
      onDownloadComplete: _onConfigLogBulkDownloadComplete,
    );
  }

  Future<void> _onConfigLogBulkDownloadComplete() async {
    await PanelConfigBulkSync.runConfigLogFetchRemaining(
      bleController,
      bleManager,
    );
    if (saveCachesAfterBulkDownload) {
      await PanelConfigCacheSync.saveAllFromBle(
        bleManager,
        device.id,
        refreshNotifiers,
      );
      refreshNotifiers.bumpAll();
    }
  }

  Future<void> startBulkDownloadAwaitCompletion({
    required BuildContext context,
    required bool Function() isMounted,
  }) async {
    var configDownloadFinished = false;
    await showPanelAccessPasswordPopup(
      context: context,
      isMounted: isMounted,
      bleManager: bleManager,
      bleController: bleController,
      selectedDevice: device,
      navigatingToDeviceConnecting: navigatingToDeviceConnecting,
      delegates: _delegates(),
      onCall: () {
        bleManager.bleProcess.isModuleSetupFetchCommandActive.value = true;
        bleController.startModuleSetupFetch();
      },
      mode: 'bottomsheet_download',
      isConfigLogBulk: true,
      downloadSuccessMessage: StringConstants.configuration,
      onDownloadComplete: () async {
        await _onConfigLogBulkDownloadComplete();
        configDownloadFinished = true;
      },
    );
    if (configDownloadFinished) {
      await Future.delayed(const Duration(milliseconds: 2200));
    }
  }

  Future<void> startBulkApply({
    required BuildContext context,
    required bool Function() isMounted,
  }) {
    final completer = Completer<void>();

    showPanelAccessPasswordPopup(
      context: context,
      isMounted: isMounted,
      bleManager: bleManager,
      bleController: bleController,
      selectedDevice: device,
      navigatingToDeviceConnecting: navigatingToDeviceConnecting,
      delegates: _delegates(
        afterBulkApplyAccessGranted: () async {
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
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e, st) {
            if (!completer.isCompleted) {
              completer.completeError(e, st);
            }
            rethrow;
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
    );

    return completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout:
          () => throw TimeoutException(StringConstants.bulkApplyTimedOut),
    );
  }
}
