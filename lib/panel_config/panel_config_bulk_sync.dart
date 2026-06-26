import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/utils/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class PanelConfigBulkSync {
  PanelConfigBulkSync._();

  static Future<void> waitUntilNotifierQuiet(ValueNotifier<bool> busy) async {
    final deadline = DateTime.now().add(const Duration(seconds: 120));
    var sawBusy = busy.value;
    while (DateTime.now().isBefore(deadline)) {
      if (busy.value) sawBusy = true;
      if (sawBusy && !busy.value) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    throw TimeoutException(
      StringConstants.bluetoothOperationTimedOut,
      const Duration(seconds: 120),
    );
  }

  static ValueNotifier<bool> fetchBusyFor(
    BleManager m,
    PeripheralConfigSection s,
  ) {
    final bp = m.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        return bp.isModuleSetupFetchCommandActive;
      case PeripheralConfigSection.panelInfo:
        return bp.isPanelInfoSetupFetchCommandActive;
      case PeripheralConfigSection.generalModule:
        return bp.isGeneralModuleSetupFetchCommandActive;
      case PeripheralConfigSection.accessCode:
        return bp.isAccessCodeSetupFetchCommandActive;
      case PeripheralConfigSection.serviceDue:
        return bp.isServiceDueFetchCommandActive;
      case PeripheralConfigSection.input:
        return bp.isInputSetupFetchCommandActive;
      case PeripheralConfigSection.relay:
        return bp.isRelaySetupFetchCommandActive;
      case PeripheralConfigSection.zone:
        return bp.isZoneSetupFetchCommandActive;
      case PeripheralConfigSection.sounder:
        return bp.isSounderSetupFetchCommandActive;
      case PeripheralConfigSection.radio:
        return bp.isRadioSetupFetchCommandActive;
      case PeripheralConfigSection.lBus:
        return bp.isLBusSetupFetchCommandActive;
      case PeripheralConfigSection.extOut:
        return bp.isExtOutCommandFetchActive;
    }
  }

  static void startFetchSection(
    BleLogController c,
    BleManager m,
    PeripheralConfigSection s,
  ) {
    final bp = m.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        bp.isModuleSetupFetchCommandActive.value = true;
        c.startModuleSetupFetch();
        break;
      case PeripheralConfigSection.panelInfo:
        bp.isPanelInfoSetupFetchCommandActive.value = true;
        c.startPanelInfoSetupFetch();
        break;
      case PeripheralConfigSection.generalModule:
        bp.isGeneralModuleSetupFetchCommandActive.value = true;
        c.startGeneralModuleSetupFetch();
        break;
      case PeripheralConfigSection.accessCode:
        bp.isAccessCodeSetupFetchCommandActive.value = true;
        c.startAccessCodeSetupFetch();
        break;
      case PeripheralConfigSection.serviceDue:
        bp.isServiceDueFetchCommandActive.value = true;
        c.startServiceDueFetch();
        break;
      case PeripheralConfigSection.input:
        bp.isInputSetupFetchCommandActive.value = true;
        c.startInputSetupFetch();
        break;
      case PeripheralConfigSection.relay:
        bp.isRelaySetupFetchCommandActive.value = true;
        c.startRelaySetupFetch();
        break;
      case PeripheralConfigSection.zone:
        bp.isZoneSetupFetchCommandActive.value = true;
        c.startZoneSetupFetch();
        break;
      case PeripheralConfigSection.sounder:
        bp.isSounderSetupFetchCommandActive.value = true;
        c.startSounderSetupFetch();
        break;
      case PeripheralConfigSection.radio:
        bp.isRadioSetupFetchCommandActive.value = true;
        c.startRadioSetupFetch();
        break;
      case PeripheralConfigSection.lBus:
        bp.isLBusSetupFetchCommandActive.value = true;
        c.startLBusSetupFetch();
        break;
      case PeripheralConfigSection.extOut:
        bp.isExtOutCommandFetchActive.value = true;
        c.startExtOutFetch();
        break;
    }
  }

  static Future<void> runConfigLogFetchRemaining(
    BleLogController bleController,
    BleManager bleManager,
  ) async {
    for (final s in kPeripheralConfigFetchOrder.skip(1)) {
      startFetchSection(bleController, bleManager, s);
      await waitUntilNotifierQuiet(fetchBusyFor(bleManager, s));
    }
  }

  static Future<ConfigCompareResult> buildConfigCompareResultFromCache(
    BleManager bleManager,
    String deviceId,
  ) async {
    return buildConfigCompareResult(
      bleManager,
      await PeripheralConfigSnapshot.fromCache(deviceId),
    );
  }

  static ConfigCompareResult buildConfigCompareResult(
    BleManager bleManager,
    Map<String, Object?> localBySection,
  ) {
    final bp = bleManager.bleProcess;
    return PeripheralConfigSnapshot.compare(
      panelBySection: PeripheralConfigSnapshot.fromBleManager(bleManager),
      localBySection: localBySection,
      lBusCommsFaultBusNumbers:
          bp.isLbusFetchHasErrors.value
              ? List<String>.from(bp.lbusFetchErrors.value)
              : const [],
    );
  }

  static ValueNotifier<bool> applyBusyFor(
    BleManager m,
    PeripheralConfigSection s,
  ) {
    final bp = m.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        return bp.isModuleSetupFetchCommandActive;
      case PeripheralConfigSection.panelInfo:
        return bp.isPanelInfoSetupApplyCommandActive;
      case PeripheralConfigSection.generalModule:
        return bp.isGeneralModuleSetupApplyCommandActive;
      case PeripheralConfigSection.accessCode:
        return bp.isAccessCodeSetupApplyCommandActive;
      case PeripheralConfigSection.serviceDue:
        return bp.isServiceDueApplyCommandActive;
      case PeripheralConfigSection.input:
        return bp.isInputSetupApplyActive;
      case PeripheralConfigSection.relay:
        return bp.isRelaySetupCommandApplyActive;
      case PeripheralConfigSection.zone:
        return bp.isZoneSetupCommandApplyActive;
      case PeripheralConfigSection.sounder:
        return bp.isSounderSetupApplyCommandActive;
      case PeripheralConfigSection.radio:
        return bp.isRadioSetupCommandApplyActive;
      case PeripheralConfigSection.lBus:
        return bp.isLBusSetupApplyCommandActive;
      case PeripheralConfigSection.extOut:
        return bp.isExtOutCommandApplyActive;
    }
  }

  static void startApplySection(
    BleLogController c,
    BleManager m,
    PeripheralConfigSection s,
  ) {
    final bp = m.bleProcess;
    switch (s) {
      case PeripheralConfigSection.module:
        break;
      case PeripheralConfigSection.panelInfo:
        bp.isPanelInfoSetupApplyCommandActive.value = true;
        c.startPanelInfoSetupApply();
        break;
      case PeripheralConfigSection.generalModule:
        bp.isGeneralModuleSetupApplyCommandActive.value = true;
        c.startGeneralModuleSetupApply();
        break;
      case PeripheralConfigSection.accessCode:
        bp.isAccessCodeSetupApplyCommandActive.value = true;
        c.startAccessCodeSetupApply();
        break;
      case PeripheralConfigSection.serviceDue:
        bp.isServiceDueApplyCommandActive.value = true;
        c.startServiceDueApply();
        break;
      case PeripheralConfigSection.input:
        bp.isInputSetupApplyActive.value = true;
        c.startInputSetupApply();
        break;
      case PeripheralConfigSection.relay:
        bp.isRelaySetupCommandApplyActive.value = true;
        c.startRelaySetupApply();
        break;
      case PeripheralConfigSection.zone:
        bp.isZoneSetupCommandApplyActive.value = true;
        c.startZoneSetupApply();
        break;
      case PeripheralConfigSection.sounder:
        bp.isSounderSetupApplyCommandActive.value = true;
        c.startSounderSetupApply();
        break;
      case PeripheralConfigSection.radio:
        bp.isRadioSetupCommandApplyActive.value = true;
        c.startRadioSetupApply();
        break;
      case PeripheralConfigSection.lBus:
        bp.isLBusSetupApplyCommandActive.value = true;
        c.startLBusSetupApply();
        break;
      case PeripheralConfigSection.extOut:
        bp.isExtOutCommandApplyActive.value = true;
        c.startExtOutApply();
        break;
    }
  }

  static Future<void> runConfigLogApplyRemaining(
    BleLogController bleController,
    BleManager bleManager,
  ) async {
    for (final s in kPeripheralConfigApplyOrder.skip(1)) {
      startApplySection(bleController, bleManager, s);
      await waitUntilNotifierQuiet(applyBusyFor(bleManager, s));
    }
  }
}
