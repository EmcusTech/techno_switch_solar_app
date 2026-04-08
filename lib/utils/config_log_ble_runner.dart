import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

void _throwIfPanelNack(BleProcess p) {
  final msg = p.processDesc.value;
  if (msg.contains('NACK')) {
    throw Exception(msg);
  }
}

Future<void> _waitUntilFlagClears(ValueNotifier<bool> flag) async {
  if (!flag.value) return;
  final completer = Completer<void>();
  void listener() {
    if (!flag.value) {
      flag.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    }
  }

  flag.addListener(listener);
  await completer.future.timeout(
    const Duration(minutes: 4),
    onTimeout: () {
      flag.removeListener(listener);
      throw TimeoutException(
        'Timed out waiting for operation: ${flag.hashCode}',
      );
    },
  );
}

/// Downloads all panel configuration areas in sequence (required by BLE state machine).
Future<void> downloadFullPanelConfiguration(BleLogController ble) async {
  final p = ble.bleProcess;

  Future<void> step(
    ValueNotifier<bool> fetchFlag,
    Future<void> Function() start,
  ) async {
    fetchFlag.value = true;
    await start();
    await _waitUntilFlagClears(fetchFlag);
    _throwIfPanelNack(p);
  }

  await step(p.isRelaySetupFetchCommandActive, ble.startRelaySetupFetch);
  await step(p.isInputSetupFetchCommandActive, ble.startInputSetupFetch);
  await step(p.isZoneSetupFetchCommandActive, ble.startZoneSetupFetch);
  await step(p.isSounderSetupFetchCommandActive, ble.startSounderSetupFetch);
  await step(p.isModuleSetupFetchCommandActive, ble.startModuleSetupFetch);
  await step(p.isLBusSetupFetchCommandActive, ble.startLBusSetupFetch);
  await step(p.isExtOutCommandFetchActive, ble.startExtOutFetch);
  await step(p.isServiceDueFetchCommandActive, ble.startServiceDueFetch);
  await step(
    p.isAccessCodeSetupFetchCommandActive,
    ble.startAccessCodeSetupFetch,
  );
  await step(
    p.isPanelInfoSetupFetchCommandActive,
    ble.startPanelInfoSetupFetch,
  );
  await step(
    p.isGeneralModuleSetupFetchCommandActive,
    ble.startGeneralModuleSetupFetch,
  );
  await step(p.isAdcSetupFetchCommandActive, ble.startAdcSetupFetch);
}

Future<void> _waitApplyDone(ValueNotifier<bool> applyFlag) async {
  if (!applyFlag.value) return;
  final completer = Completer<void>();
  void listener() {
    if (!applyFlag.value) {
      applyFlag.removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    }
  }

  applyFlag.addListener(listener);
  await completer.future.timeout(
    const Duration(minutes: 4),
    onTimeout: () {
      applyFlag.removeListener(listener);
      throw TimeoutException('Timed out waiting for apply');
    },
  );
}

Future<void> _applyStep(
  BleLogController ble,
  ValueNotifier<bool> applyFlag,
  Future<void> Function() startApply,
) async {
  applyFlag.value = true;
  await startApply();
  await _waitApplyDone(applyFlag);
}

/// Pushes cached/default configuration to the panel (read-only sections skipped).
Future<void> applyBaselineToPanel(BleLogController ble) async {
  final p = ble.bleProcess;

  await _applyStep(
    ble,
    p.isRelaySetupCommandApplyActive,
    ble.startRelaySetupApply,
  );
  await _applyStep(ble, p.isInputSetupApplyActive, ble.startInputSetupApply);
  await _applyStep(
    ble,
    p.isZoneSetupCommandApplyActive,
    ble.startZoneSetupApply,
  );
  await _applyStep(
    ble,
    p.isSounderSetupApplyCommandActive,
    ble.startSounderSetupApply,
  );
  await _applyStep(
    ble,
    p.isLBusSetupApplyCommandActive,
    ble.startLBusSetupApply,
  );
  await _applyStep(ble, p.isExtOutCommandApplyActive, ble.startExtOutApply);
  await _applyStep(
    ble,
    p.isServiceDueApplyCommandActive,
    ble.startServiceDueApply,
  );
  await _applyStep(
    ble,
    p.isAccessCodeSetupApplyCommandActive,
    ble.startAccessCodeSetupApply,
  );
  await _applyStep(
    ble,
    p.isPanelInfoSetupApplyCommandActive,
    ble.startPanelInfoSetupApply,
  );
  await _applyStep(
    ble,
    p.isGeneralModuleSetupApplyCommandActive,
    ble.startGeneralModuleSetupApply,
  );
}
