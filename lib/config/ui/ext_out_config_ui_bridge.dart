import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/ext_out_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/ext_out_cfg_def.dart';
import 'package:techno_switch_solar_app/config/ui/ext_out_config_options.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/ext_out_defaults.dart';

/// UI-facing state for the Ext-Out configuration sheet (labels, not wire indices).
class ExtOutUiState {
  const ExtOutUiState({
    required this.enabled,
    required this.actuatorType,
    required this.function,
    required this.resetInCount,
    required this.holdCount,
    required this.action,
    required this.countdownAuto,
    required this.countdownMan,
    required this.releaseTime,
    required this.resetDelay,
  });

  final String enabled;
  final String actuatorType;
  final String function;
  final String resetInCount;
  final String holdCount;
  final String action;
  final int countdownAuto;
  final int countdownMan;
  final int releaseTime;
  final int resetDelay;

  factory ExtOutUiState.defaults() => ExtOutUiState(
    enabled: ExtOutDefaults.enabledLabel,
    actuatorType: ExtOutDefaults.actuatorTypeLabel,
    function: ExtOutDefaults.functionLabel,
    resetInCount: ExtOutDefaults.resetInCountLabel,
    holdCount: ExtOutDefaults.holdCountLabel,
    action: ExtOutDefaults.actionLabel,
    countdownAuto: ExtOutDefaults.countdownAutoBle,
    countdownMan: ExtOutDefaults.countdownManBle,
    releaseTime: ExtOutDefaults.releaseTimeBle,
    resetDelay: ExtOutDefaults.resetDelayBle,
  );
}

abstract final class ExtOutConfigUiBridge {
  static ExtOutUiState fromStruct(ExtOutCfgDef config) {
    return ExtOutUiState(
      enabled: ExtOutConfigOptions.enabledLabel(config.extOutEnable),
      actuatorType: ExtOutConfigOptions.actuatorTypeLabel(config.extOutType),
      function: ExtOutConfigOptions.functionLabel(config.extOutFunc),
      resetInCount: ExtOutConfigOptions.resetInCountLabel(config.resetInCount),
      holdCount: ExtOutConfigOptions.holdCountLabel(config.holdCount),
      action: ExtOutConfigOptions.actionLabel(config.action),
      countdownAuto: config.countdownAuto,
      countdownMan: config.countdownMan,
      releaseTime: config.releaseTime,
      resetDelay: config.resetDelay,
    );
  }

  static ExtOutCfgDef toStruct(ExtOutUiState ui) {
    return ExtOutCfgDef(
      extOutEnable: ExtOutConfigOptions.enabledIndex(ui.enabled),
      extOutType: ExtOutConfigOptions.actuatorTypeIndex(ui.actuatorType),
      extOutFunc: ExtOutConfigOptions.functionIndex(ui.function),
      countdownAuto: ui.countdownAuto,
      countdownMan: ui.countdownMan,
      releaseTime: ui.releaseTime,
      resetDelay: ui.resetDelay,
      resetInCount: ExtOutConfigOptions.resetInCountIndex(ui.resetInCount),
      holdCount: ExtOutConfigOptions.holdCountIndex(ui.holdCount),
      action: ExtOutConfigOptions.actionIndex(ui.action),
    );
  }

  static ExtOutUiState fromCacheMap(Map<String, dynamic> data) {
    return fromStruct(ExtOutCfgDef.fromCacheMap(data));
  }

  static Map<String, dynamic> toCacheMap(ExtOutUiState ui) {
    return toStruct(ui).toCacheMap();
  }

  static ExtOutUiState fromBleProcess(BleProcess process) {
    return fromStruct(ExtOutSetupPayload.fromBleProcess(process));
  }

  static void applyToBleProcess(ExtOutUiState ui, BleProcess process) {
    ExtOutSetupPayload.applyToBleProcess(toStruct(ui), process);
  }
}
