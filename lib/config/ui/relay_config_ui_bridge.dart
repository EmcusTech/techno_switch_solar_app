import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/relay_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/relay_cfg_def.dart';
import 'package:techno_switch_solar_app/config/ui/relay_config_options.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/relay_defaults.dart';

/// UI-facing state for one relay in the Relay configuration sheet.
class RelayUiState {
  const RelayUiState({
    required this.relayNumber,
    required this.group,
    required this.function,
    required this.enabled,
    required this.outputText,
    required this.dynamicValue,
    this.test = RelayDefaults.testBle,
  });

  final int relayNumber;
  final String group;
  final String function;
  final String enabled;
  final String outputText;
  final String dynamicValue;
  final bool test;

  factory RelayUiState.defaults({required int relayNumber}) {
    final defaults = RelayDefaults.relayEntry(relayNumber - 1);
    return RelayUiState(
      relayNumber: relayNumber,
      group: RelayConfigOptions.groupLabel(defaults['group'] as int),
      function: RelayConfigOptions.functionLabel(
        defaults['group'] as int,
        defaults['function'] as int,
      ),
      enabled: RelayConfigOptions.yesNoLabel(defaults['enabled'] as bool),
      outputText: RelayDefaults.outputText,
      dynamicValue: defaults[StringConstants.outputtext] as String,
      test: defaults['test'] as bool,
    );
  }
}

abstract final class RelayConfigUiBridge {
  static String dynamicValueFromStruct(RelayCfgDef config) {
    if (config.relayGrp == RelayCfgDef.relayGroupZone) {
      return config.relayZone.toString();
    }
    if (config.relayGrp == RelayCfgDef.relayGroupExtOut) {
      return config.relayExtOut.toString();
    }
    return '0';
  }

  static RelayUiState fromStruct(RelayCfgDef config) {
    return RelayUiState(
      relayNumber: config.relayNum,
      group: RelayConfigOptions.groupLabel(config.relayGrp),
      function: RelayConfigOptions.functionLabel(
        config.relayGrp,
        config.relayFunc,
      ),
      enabled: RelayConfigOptions.yesNoLabel(config.relayEnable != 0),
      outputText: config.relayText,
      dynamicValue: dynamicValueFromStruct(config),
      test: config.relayTest != 0,
    );
  }

  static RelayCfgDef toStruct(
    RelayUiState ui, {
    bool? test,
  }) {
    final groupIndex = RelayConfigOptions.groupIndex(ui.group);
    final dynamicValue =
        int.tryParse(ui.dynamicValue.trim()) ??
        int.tryParse(ui.dynamicValue.trim(), radix: 16) ??
        0;

    var relayZone = 0;
    var relayExtOut = 0;
    if (groupIndex == RelayCfgDef.relayGroupZone) {
      relayZone = dynamicValue;
    } else if (groupIndex == RelayCfgDef.relayGroupExtOut) {
      relayExtOut = dynamicValue;
    }

    return RelayCfgDef(
      relayNum: ui.relayNumber,
      relayText: ui.outputText,
      relayGrp: groupIndex,
      relayFunc: RelayConfigOptions.functionIndex(ui.group, ui.function),
      relayZone: relayZone,
      relayExtOut: relayExtOut,
      relayEnable: RelayConfigOptions.yesNoValue(ui.enabled) ? 1 : 0,
      relayTest: (test ?? ui.test) ? 1 : 0,
    );
  }

  static RelayUiState fromCacheMap(
    Map<String, dynamic> data, {
    required int relayNumber,
  }) {
    return fromStruct(RelayCfgDef.fromCacheMap(data, relayNum: relayNumber));
  }

  static Map<String, dynamic> toCacheMap(RelayUiState ui) {
    return toStruct(ui).toCacheMap();
  }

  static RelayUiState fromBleProcess(BleProcess process, int relayIndex) {
    return fromStruct(RelaySetupPayload.fromBleProcess(process, relayIndex));
  }

  static void applyToBleProcess(
    RelayUiState ui,
    BleProcess process, {
    bool? test,
  }) {
    RelaySetupPayload.applyToBleProcess(
      toStruct(ui, test: test),
      process,
      ui.relayNumber - 1,
    );
  }
}
