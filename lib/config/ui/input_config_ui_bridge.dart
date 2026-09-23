import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/input_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/input_cfg_def.dart';
import 'package:techno_switch_solar_app/config/ui/input_config_options.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/input_defaults.dart';

/// UI-facing state for the Input configuration sheet (labels, not wire indices).
class InputUiState {
  const InputUiState({
    required this.group,
    required this.function,
    required this.enabled,
    required this.test,
    required this.inverted,
    required this.inputText,
  });

  final String group;
  final String function;
  final String enabled;
  final String test;
  final String inverted;
  final String inputText;

  factory InputUiState.defaults() => InputUiState(
    group: InputDefaults.groupLabel,
    function: InputDefaults.functionLabel,
    enabled: InputDefaults.enabledLabel,
    test: InputDefaults.testLabel,
    inverted: InputDefaults.invertedLabel,
    inputText: InputDefaults.inputText,
  );
}

abstract final class InputConfigUiBridge {
  static InputUiState fromStruct(InputCfgDef config) {
    return InputUiState(
      group: InputConfigOptions.groupLabel(config.inputGrp),
      function: InputConfigOptions.functionLabel(
        config.inputGrp,
        config.inputFunc,
      ),
      enabled: InputConfigOptions.yesNoLabel(config.inputEnable),
      test: InputConfigOptions.yesNoLabel(config.inputTest),
      inverted: InputConfigOptions.yesNoLabel(config.inputInvert),
      inputText: config.inputText,
    );
  }

  static InputCfgDef toStruct(InputUiState ui) {
    final groupIndex = InputConfigOptions.groupIndex(ui.group);
    return InputCfgDef(
      inputText: ui.inputText,
      inputGrp: groupIndex,
      inputFunc: InputConfigOptions.functionIndex(ui.group, ui.function),
      inputEnable: InputConfigOptions.yesNoIndex(ui.enabled),
      inputTest: InputConfigOptions.yesNoIndex(ui.test),
      inputInvert: InputConfigOptions.yesNoIndex(ui.inverted),
    );
  }

  static InputUiState fromCacheMap(Map<String, dynamic> data) {
    return fromStruct(InputCfgDef.fromCacheMap(data));
  }

  static Map<String, dynamic> toCacheMap(InputUiState ui) {
    return toStruct(ui).toCacheMap();
  }

  static InputUiState fromBleProcess(BleProcess process) {
    return fromStruct(InputSetupPayload.fromBleProcess(process));
  }

  static void applyToBleProcess(InputUiState ui, BleProcess process) {
    InputSetupPayload.applyToBleProcess(toStruct(ui), process);
  }
}
