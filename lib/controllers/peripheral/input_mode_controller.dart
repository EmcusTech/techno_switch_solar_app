import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/modes/input_mode_util.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Controller for the Input Mode bottom sheet.
class InputModeController extends PeripheralModeController {
  InputModeController({required super.deviceId, required super.refreshTrigger});

  final List<String> groupOptions = ['None', 'General', StringConstants.extOut];

  final Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [
      StringConstants.extnlFault,
      StringConstants.reset,
      StringConstants.extnlControlsEnabled,
      StringConstants.silenceAlarm,
      StringConstants.soundAlarm,
      StringConstants.silenceBuzzer,
      StringConstants.mute,
      StringConstants.extnlSupervisory,
      StringConstants.extnlSupplyFault,
    ],
    StringConstants.extOut: [
      StringConstants.manualTrigger,
      StringConstants.manualMode,
      StringConstants.hold,
      StringConstants.extnlDisableGas,
      StringConstants.extnlExtFault,
    ],
  };

  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];

  late String group;
  late String function;
  late String enabled;
  late String test;
  late String inverted;

  late TextEditingController inputTextCtrl;

  String? inputTextError;

  @override
  void initModel() {
    group = groupOptions[0];
    function = functionOptionsMap[group]!.first;
    enabled = yesNoOptions[0];
    test = yesNoOptions[0];
    inverted = yesNoOptions[0];
    inputTextCtrl = TextEditingController();
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
    final g = (data['group'] as int?) ?? 0;
    group = groupOptions[g.clamp(0, groupOptions.length - 1)];
    final f = (data['function'] as int?) ?? 0;
    final opts = functionOptionsMap[group]!;
    function = opts[f.clamp(0, opts.length - 1)];
    enabled =
        (data['enabled'] as bool?) == true ? yesNoOptions[1] : yesNoOptions[0];
    test = (data['test'] as bool?) == true ? yesNoOptions[1] : yesNoOptions[0];
    inverted =
        (data['inverted'] as bool?) == true ? yesNoOptions[1] : yesNoOptions[0];
    inputTextCtrl.text = (data['text'] as String?) ?? '';
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;
    group = groupOptions[manager!.inputSetupGroup.value];
    function = functionOptionsMap[group]![manager!.inputSetupFunction.value];
    enabled =
        manager!.isInputSetupEnabled.value ? yesNoOptions[1] : yesNoOptions[0];
    test = manager!.isInputSetupTest.value ? yesNoOptions[1] : yesNoOptions[0];
    inverted =
        manager!.isInputSetupInverted.value ? yesNoOptions[1] : yesNoOptions[0];
    inputTextCtrl.text = manager!.inputSetupText.value;
    refreshUi();
  }

  int returnIndex(String value, List<String> list) => list.indexOf(value);

  @override
  void pushToManager() {
    final groupIndex = returnIndex(group, groupOptions);
    final functionIndex = returnIndex(function, functionOptionsMap[group]!);
    final isEnabled = enabled == StringConstants.yes;
    final isTest = test == StringConstants.yes;
    final isInverted = inverted == StringConstants.yes;

    final config = InputModeConfig(
      inputEnable: InputEnable.values[isEnabled ? 1 : 0],
      inputMode: InputMode.values[isTest ? 1 : 0],
      latchMode: LatchMode.nonLatched,
      invertMode: InvertMode.values[isInverted ? 1 : 0],
    );

    final String hexValue = InputModeCodec.encodeHex(config);

    manager!.inputMode.value = hexValue;
    manager!.inputSetupGroup.value = groupIndex;
    manager!.inputSetupFunction.value = functionIndex;
    manager!.isInputSetupEnabled.value = isEnabled;
    manager!.isInputSetupTest.value = isTest;
    manager!.isInputSetupInverted.value = isInverted;
    manager!.inputSetupText.value = inputTextCtrl.text;
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
    if (enabled == StringConstants.no) {
      test = StringConstants.no;
    }
    refreshUi();
  }

  void setTest(String v) {
    test = v;
    if (test == StringConstants.yes) {
      enabled = StringConstants.yes;
    }
    refreshUi();
  }

  void setInverted(String v) {
    inverted = v;
    refreshUi();
  }
}
