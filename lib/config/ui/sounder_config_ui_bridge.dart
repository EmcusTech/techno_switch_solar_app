import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/sounder_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/sounder_cfg_def.dart';
import 'package:techno_switch_solar_app/config/ui/sounder_config_options.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/sounder_defaults.dart';

/// UI-facing state for one main sounder in the Sounder configuration sheet.
class SounderUiState {
  const SounderUiState({
    required this.sounderNumber,
    required this.group,
    required this.function,
    required this.enabled,
    required this.type,
    required this.outputText,
    required this.functionNo,
    this.test = SounderDefaults.testBle,
  });

  final int sounderNumber;
  final String group;
  final String function;
  final String enabled;
  final String type;
  final String outputText;
  final String functionNo;
  final bool test;

  factory SounderUiState.defaults({required int sounderNumber}) {
    final defaults = SounderDefaults.mainSounderEntry(sounderNumber - 1);
    final group = SounderConfigOptions.groupLabel(defaults['group'] as int);
    return SounderUiState(
      sounderNumber: sounderNumber,
      group: group,
      function: SounderConfigOptions.functionLabel(
        defaults['group'] as int,
        defaults['function'] as int,
      ),
      enabled: SounderConfigOptions.yesNoLabel(defaults['enabled'] as bool),
      type: SounderConfigOptions.typeLabel(defaults['normal'] as bool),
      outputText: SounderDefaults.outputText,
      functionNo: (defaults['functionNo'] as int).toString(),
      test: defaults['test'] as bool,
    );
  }
}

abstract final class SounderConfigUiBridge {
  static int functionNoFromStruct(SounderCfgDef config) {
    if (config.sounderGrp == SounderCfgDef.sounderGroupZone) {
      return config.sounderZone;
    }
    if (config.sounderGrp == SounderCfgDef.sounderGroupExtOut) {
      return config.sounderExtOut;
    }
    return 0;
  }

  static SounderUiState fromStruct(SounderCfgDef config) {
    return SounderUiState(
      sounderNumber: config.sounderNum,
      group: SounderConfigOptions.groupLabel(config.sounderGrp),
      function: SounderConfigOptions.functionLabel(
        config.sounderGrp,
        config.sounderFunc,
      ),
      enabled: SounderConfigOptions.yesNoLabel(config.sounderEnable != 0),
      type: SounderConfigOptions.typeLabel(config.sounderType != 0),
      outputText: config.sounderText,
      functionNo: functionNoFromStruct(config).toString(),
      test: config.sounderTest != 0,
    );
  }

  static SounderCfgDef toStruct(
    SounderUiState ui, {
    bool? test,
  }) {
    final groupIndex = SounderConfigOptions.groupIndex(ui.group);
    final functionNo =
        int.tryParse(ui.functionNo.trim()) ??
        int.tryParse(ui.functionNo.trim(), radix: 16) ??
        0;

    var sounderZone = 0;
    var sounderExtOut = 0;
    if (groupIndex == SounderCfgDef.sounderGroupZone) {
      sounderZone = functionNo;
    } else if (groupIndex == SounderCfgDef.sounderGroupExtOut) {
      sounderExtOut = functionNo;
    }

    return SounderCfgDef(
      sounderNum: ui.sounderNumber,
      sounderText: ui.outputText,
      sounderGrp: groupIndex,
      sounderFunc: SounderConfigOptions.functionIndex(ui.group, ui.function),
      sounderZone: sounderZone,
      sounderExtOut: sounderExtOut,
      sounderEnable: SounderConfigOptions.yesNoValue(ui.enabled) ? 1 : 0,
      sounderTest: (test ?? ui.test) ? 1 : 0,
      sounderType: SounderConfigOptions.typeIsNormal(ui.type) ? 1 : 0,
    );
  }

  static SounderUiState fromCacheMap(
    Map<String, dynamic> data, {
    required int sounderNumber,
  }) {
    return fromStruct(
      SounderCfgDef.fromCacheMap(data, sounderNum: sounderNumber),
    );
  }

  static Map<String, dynamic> toCacheMap(SounderUiState ui) {
    return toStruct(ui).toCacheMap();
  }

  static SounderUiState fromBleProcess(BleProcess process, int sounderIndex) {
    return fromStruct(SounderSetupPayload.fromBleProcess(process, sounderIndex));
  }

  static void applyToBleProcess(
    SounderUiState ui,
    BleProcess process, {
    bool? test,
  }) {
    SounderSetupPayload.applyToBleProcess(
      toStruct(ui, test: test),
      process,
      ui.sounderNumber - 1,
    );
  }
}
