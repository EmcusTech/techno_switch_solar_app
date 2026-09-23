import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/config/ble/relay_setup_payload_debug.dart';
import 'package:techno_switch_solar_app/config/ui/relay_config_options.dart';
import 'package:techno_switch_solar_app/config/ui/relay_config_ui_bridge.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class RelayConfig {
  String group = RelayUiState.defaults(relayNumber: 1).group;
  String function = RelayUiState.defaults(relayNumber: 1).function;
  String enabled = RelayUiState.defaults(relayNumber: 1).enabled;

  TextEditingController outputTextController = TextEditingController();
  TextEditingController dynamicController = TextEditingController();
}

/// Controller for the Relay Mode bottom sheet. Owns the editable relay model,
/// validation, and the load/push/save lifecycle (see [PeripheralModeController]).
class RelayModeController extends PeripheralModeController {
  RelayModeController({required super.deviceId, required super.refreshTrigger});

  List<String> get groupOptions => RelayConfigOptions.groupOptions;

  Map<String, List<String>> get functionOptionsMap =>
      RelayConfigOptions.functionOptionsMap;

  List<String> get yesNoOptions => RelayConfigOptions.yesNoOptions;

  late List<RelayConfig> relays;

  final Map<int, String?> outputTextErrors = {};
  final Map<int, String?> dynamicFieldErrors = {};

  @override
  void initModel() {
    relays = List.generate(3, (i) {
      final config = RelayConfig();
      _applyUiStateToRelay(
        config,
        RelayUiState.defaults(relayNumber: i + 1),
      );
      return config;
    });
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
      _applyUiStateToRelay(
        relays[i],
        RelayConfigUiBridge.fromCacheMap(r, relayNumber: i + 1),
      );
    }
    if (manager != null) {
      applyRelayTestFlagsFromCacheMap(manager!, data);
    }
    for (int i = 0; i < 3; i++) {
      if (relays[i].group == StringConstants.extOut) {
        relays[i].dynamicController.text = '1';
      }
    }
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    for (int i = 0; i < 3; i++) {
      _applyUiStateToRelay(
        relays[i],
        RelayConfigUiBridge.fromBleProcess(manager!.bleProcess, i),
      );
    }

    for (int i = 0; i < 3; i++) {
      if (relays[i].group == StringConstants.extOut) {
        relays[i].dynamicController.text = '1';
      }
    }
    refreshUi();
  }

  RelayUiState _currentUiState(int index) {
    final relay = relays[index];
    return RelayUiState(
      relayNumber: index + 1,
      group: relay.group,
      function: relay.function,
      enabled: relay.enabled,
      outputText: relay.outputTextController.text,
      dynamicValue: relay.dynamicController.text,
    );
  }

  void _applyUiStateToRelay(RelayConfig relay, RelayUiState ui) {
    relay.group = ui.group;
    relay.function = ui.function;
    relay.enabled = ui.enabled;
    relay.outputTextController.text = ui.outputText;
    relay.dynamicController.text = ui.dynamicValue;
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
      final ui = _currentUiState(i);
      final effectiveTest =
          RelayConfigOptions.yesNoValue(ui.enabled) && snapshotTest[i];
      RelayConfigUiBridge.applyToBleProcess(
        ui,
        m.bleProcess,
        test: effectiveTest,
      );
    }

    if (kDebugMode) {
      RelaySetupPayloadDebug.printApplyFrames(m);
    }
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
