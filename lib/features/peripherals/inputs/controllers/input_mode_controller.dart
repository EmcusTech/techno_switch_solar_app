import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/config/ble/input_setup_payload_debug.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/config/ui/input_config_options.dart';
import 'package:techno_switch_solar_app/config/ui/input_config_ui_bridge.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

/// Controller for the Input Mode bottom sheet.
class InputModeController extends PeripheralModeController {
  InputModeController({required super.deviceId, required super.refreshTrigger});

  List<String> get groupOptions => InputConfigOptions.groupOptions;

  Map<String, List<String>> get functionOptionsMap =>
      InputConfigOptions.functionOptionsMap;

  List<String> get yesNoOptions => InputConfigOptions.yesNoOptions;

  late String group;
  late String function;
  late String enabled;
  late String test;
  late String inverted;

  late TextEditingController inputTextCtrl;

  String? inputTextError;

  @override
  void initModel() {
    inputTextCtrl = TextEditingController();
    _applyUiState(InputUiState.defaults());
  }

  @override
  void disposeModel() {
    inputTextCtrl.dispose();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadInputSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    _applyUiState(InputConfigUiBridge.fromCacheMap(data));
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;
    _applyUiState(InputConfigUiBridge.fromBleProcess(manager!.bleProcess));
    refreshUi();
  }

  InputUiState _currentUiState() => InputUiState(
    group: group,
    function: function,
    enabled: enabled,
    test: test,
    inverted: inverted,
    inputText: inputTextCtrl.text,
  );

  void _applyUiState(InputUiState ui) {
    group = ui.group;
    function = ui.function;
    enabled = ui.enabled;
    test = ui.test;
    inverted = ui.inverted;
    inputTextCtrl.text = ui.inputText;
  }

  @override
  void pushToManager() {
    InputConfigUiBridge.applyToBleProcess(_currentUiState(), manager!.bleProcess);
    if (kDebugMode) {
      InputSetupPayloadDebug.printApplyFrame(manager!);
    }
  }

  @override
  Future<void> save() =>
      PanelConfigCacheSync.saveInput(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() => inputTextCtrl.text.length <= 21;

  @override
  void updateValidationErrors() {
    inputTextError =
        inputTextCtrl.text.length > 21
            ? 'Input text must be at most 21 characters (currently ${inputTextCtrl.text.length})'
            : null;
  }

  // ---- UI intents ----

  void setGroup(String v) {
    group = v;
    function = functionOptionsMap[group]!.first;
    refreshUi();
  }

  void setFunction(String v) {
    function = v;
    refreshUi();
  }

  void setEnabled(String v) {
    enabled = v;
    if (enabled == yesNoOptions.first) {
      test = yesNoOptions.first;
    }
    refreshUi();
  }

  void setTest(String v) {
    test = v;
    if (test == yesNoOptions.last) {
      enabled = yesNoOptions.last;
    }
    refreshUi();
  }

  void setInverted(String v) {
    inverted = v;
    refreshUi();
  }
}
