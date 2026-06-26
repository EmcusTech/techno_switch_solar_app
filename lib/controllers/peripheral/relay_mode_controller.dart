import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class RelayConfig {
  String group = 'None';
  String function = 'None';
  String enabled = StringConstants.no;

  TextEditingController outputTextController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();
}

/// Controller for the Relay Mode bottom sheet. Owns the editable relay model,
/// validation, and the load/push/save lifecycle (see [PeripheralModeController]).
class RelayModeController extends PeripheralModeController {
  RelayModeController({required super.deviceId, required super.refreshTrigger});

  final List<String> groupOptions = [
    'None',
    'General',
    'Zone',
    StringConstants.extOut,
  ];

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [
      'Fault',
      StringConstants.extnlFault,
      StringConstants.supplyFault,
      StringConstants.extnlSupplyFault,
      StringConstants.sounderFault,
      StringConstants.sounderSilenced,
      StringConstants.sounderActivated,
      StringConstants.sounderDisabled,
      StringConstants.disablement,
      StringConstants.test,
      'Fire',
      StringConstants.reset,
      StringConstants.controlsEnabled,
      StringConstants.supervisory,
      StringConstants.fireSnd,
    ],
    'Zone': ['Fault', 'Fire', StringConstants.disablement, StringConstants.fireSnd],
    StringConstants.extOut: [
      StringConstants.releaseInitiated,
      StringConstants.extAgentReleased,
      StringConstants.releaseHold,
      StringConstants.manualMode,
      StringConstants.manualRelease,
      StringConstants.extnlExtFault,
      StringConstants.extSnd1,
      'Ext. Snd 2',
      StringConstants.manReleaseSnd,
    ],
  };

  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];

  late List<RelayConfig> relays;

  final Map<int, String?> outputTextErrors = {};
  final Map<int, String?> dynamicFieldErrors = {};

  @override
  void initModel() {
    relays = List.generate(3, (_) => RelayConfig());
  }

  @override
  void disposeModel() {
    for (final relay in relays) {
      relay.outputTextController.dispose();
      relay.dynamicController.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadRelaySetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    for (int i = 0; i < 3; i++) {
      final key = 'r${i + 1}';
      final r = data[key] as Map<String, dynamic>?;
      if (r == null) continue;
      relays[i].enabled =
          (r['enabled'] as bool?) == true ? StringConstants.yes : StringConstants.no;
      final g = (r['group'] as int?) ?? 0;
      relays[i].group = groupOptions[g.clamp(0, groupOptions.length - 1)];
      final f = (r['function'] as int?) ?? 0;
      final opts = functionOptionsMap[relays[i].group]!;
      relays[i].function = opts[f.clamp(0, opts.length - 1)];
      relays[i].outputTextController.text = (r['outputText'] as String?) ?? '';
      relays[i].dynamicController.text =
          (r[StringConstants.outputtext] as String?) ?? '';
    }
    for (int i = 0; i < 3; i++) {
      if (relays[i].group == StringConstants.extOut) {
        relays[i].dynamicController.text = '1';
      }
    }
    if (manager != null) {
      applyRelayTestFlagsFromCacheMap(manager!, data);
    }
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    relays[0].enabled =
        manager!.isRelayOneSetupEnabled.value ? StringConstants.yes : StringConstants.no;
    relays[0].group = groupOptions[manager!.relayOneSetupGroup.value];
    relays[0].function =
        functionOptionsMap[relays[0].group]![manager!.relayOneSetupFunction.value];
    relays[0].outputTextController.text = manager!.relayOneSetupOutputText.value;
    relays[0].dynamicController.text = manager!.relayOneSetupDynamicText.value;

    relays[1].enabled =
        manager!.isRelayTwoSetupEnabled.value ? StringConstants.yes : StringConstants.no;
    relays[1].group = groupOptions[manager!.relayTwoSetupGroup.value];
    relays[1].function =
        functionOptionsMap[relays[1].group]![manager!.relayTwoSetupFunction.value];
    relays[1].outputTextController.text = manager!.relayTwoSetupOutputText.value;
    relays[1].dynamicController.text = manager!.relayTwoSetupDynamicText.value;

    relays[2].enabled =
        manager!.isRelayThreeSetupEnabled.value ? StringConstants.yes : StringConstants.no;
    relays[2].group = groupOptions[manager!.relayThreeSetupGroup.value];
    relays[2].function =
        functionOptionsMap[relays[2].group]![manager!.relayThreeSetupFunction.value];
    relays[2].outputTextController.text = manager!.relayThreeSetupOutputText.value;
    relays[2].dynamicController.text = manager!.relayThreeSetupDynamicText.value;

    for (int i = 0; i < 3; i++) {
      if (relays[i].group == StringConstants.extOut) {
        relays[i].dynamicController.text = '1';
      }
    }
    refreshUi();
  }

  @override
  void pushToManager() {
    final m = manager!;
    final snapshotTest = [
      m.isRelayOneSetupTest.value,
      m.isRelayTwoSetupTest.value,
      m.isRelayThreeSetupTest.value,
    ];
    for (int i = 0; i < 3; i++) {
      final relay = relays[i];

      final isEnabled = relay.enabled == StringConstants.yes;
      final isTest = isEnabled && snapshotTest[i];

      final groupIndex = returnIndex(relay.group, groupOptions);
      final functionIndex = returnIndex(
        relay.function,
        functionOptionsMap[relay.group]!,
      );

      switch (i) {
        case 0:
          manager!.relayOneSetupGroup.value = groupIndex;
          manager!.relayOneSetupFunction.value = functionIndex;
          manager!.isRelayOneSetupEnabled.value = isEnabled;
          manager!.isRelayOneSetupTest.value = isTest;
          manager!.relayOneSetupOutputText.value = relay.outputTextController.text;
          manager!.relayOneSetupDynamicText.value = relay.dynamicController.text;
          break;

        case 1:
          manager!.relayTwoSetupGroup.value = groupIndex;
          manager!.relayTwoSetupFunction.value = functionIndex;
          manager!.isRelayTwoSetupEnabled.value = isEnabled;
          manager!.isRelayTwoSetupTest.value = isTest;
          manager!.relayTwoSetupOutputText.value = relay.outputTextController.text;
          manager!.relayTwoSetupDynamicText.value = relay.dynamicController.text;
          break;

        case 2:
          manager!.relayThreeSetupGroup.value = groupIndex;
          manager!.relayThreeSetupFunction.value = functionIndex;
          manager!.isRelayThreeSetupEnabled.value = isEnabled;
          manager!.isRelayThreeSetupTest.value = isTest;
          manager!.relayThreeSetupOutputText.value = relay.outputTextController.text;
          manager!.relayThreeSetupDynamicText.value = relay.dynamicController.text;
          break;
      }
    }
    syncRelayOutputModeHexFromBleManager(m);
  }

  @override
  Future<void> save() =>
      PanelConfigCacheSync.saveRelay(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() {
    for (int i = 0; i < 3; i++) {
      final relay = relays[i];
      if (relay.outputTextController.text.length > 21) return false;
      if (relay.group == 'Zone') {
        final val = int.tryParse(relay.dynamicController.text);
        if (val == null || val < 1 || val > 3) return false;
      }
    }
    return true;
  }

  @override
  void updateValidationErrors() {
    outputTextErrors.clear();
    dynamicFieldErrors.clear();
    for (int i = 0; i < 3; i++) {
      final relay = relays[i];
      if (relay.outputTextController.text.length > 21) {
        outputTextErrors[i] =
            'Output text must be at most 21 characters (currently ${relay.outputTextController.text.length})';
      }
      if (relay.group == 'Zone') {
        final val = int.tryParse(relay.dynamicController.text);
        if (val == null || val < 1 || val > 3) {
          dynamicFieldErrors[i] = StringConstants.zoneMustBeBetween1And3;
        }
      }
    }
  }

  int returnIndex(String value, List<String> list) => list.indexOf(value);

  // ---- UI intents ----

  void setGroup(int index, String v) {
    relays[index].group = v;
    relays[index].function = functionOptionsMap[v]!.first;
    if (v == StringConstants.extOut) {
      relays[index].dynamicController.text = '1';
    }
    refreshUi();
  }

  void setFunction(int index, String v) {
    relays[index].function = v;
    refreshUi();
  }

  void setEnabled(int index, String v) {
    relays[index].enabled = v;
    if (v == StringConstants.no && manager != null) {
      clearRelayTestOnManager(manager!, index);
    }
    refreshUi();
  }

  void onDynamicFieldChanged() => refreshUi();
}
