import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/zone_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/zone_cfg_def.dart';
import 'package:techno_switch_solar_app/config/ui/zone_config_options.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/zone_defaults.dart';

/// UI-facing state for one zone in the Zone configuration sheet.
class ZoneUiState {
  const ZoneUiState({
    required this.zoneNumber,
    required this.type,
    required this.enabled,
    required this.mode,
    required this.zoneText,
    required this.verificationTime,
    this.test = ZoneDefaults.testBle,
  });

  final int zoneNumber;
  final String type;
  final String enabled;
  final String mode;
  final String zoneText;
  final String verificationTime;
  final bool test;

  factory ZoneUiState.defaults({required int zoneNumber}) => ZoneUiState(
    zoneNumber: zoneNumber,
    type: ZoneDefaults.typeLabel,
    enabled: ZoneDefaults.enabledLabel,
    mode: ZoneDefaults.modeLabel,
    zoneText: ZoneDefaults.text,
    verificationTime: ZoneDefaults.verificationTime,
    test: ZoneDefaults.testBle,
  );
}

abstract final class ZoneConfigUiBridge {
  static ZoneUiState fromStruct(ZoneCfgDef config) {
    return ZoneUiState(
      zoneNumber: config.zoneNum,
      type: ZoneConfigOptions.typeLabel(config.zoneType),
      enabled: ZoneConfigOptions.yesNoLabel(config.zoneEnable != 0),
      mode: ZoneConfigOptions.modeLabel(config.zoneMode),
      zoneText: config.zoneText,
      verificationTime: config.verifyTime.toString(),
      test: config.zoneTest != 0,
    );
  }

  static ZoneCfgDef toStruct(
    ZoneUiState ui, {
    bool? test,
  }) {
    final verifyTime =
        int.tryParse(ui.verificationTime) ??
        int.tryParse(ZoneDefaults.verificationTime) ??
        0;

    return ZoneCfgDef(
      zoneNum: ui.zoneNumber,
      zoneText: ui.zoneText,
      zoneType: ZoneConfigOptions.typeIndex(ui.type),
      zoneEnable: ZoneConfigOptions.yesNoValue(ui.enabled) ? 1 : 0,
      zoneTest: (test ?? ui.test) ? 1 : 0,
      zoneMode: ZoneConfigOptions.modeIndex(ui.mode),
      verifyTime: verifyTime,
    );
  }

  static ZoneUiState fromCacheMap(
    Map<String, dynamic> data, {
    required int zoneNumber,
  }) {
    return fromStruct(ZoneCfgDef.fromCacheMap(data, zoneNum: zoneNumber));
  }

  static Map<String, dynamic> toCacheMap(ZoneUiState ui) {
    return toStruct(ui).toCacheMap();
  }

  static ZoneUiState fromBleProcess(BleProcess process, int zoneIndex) {
    return fromStruct(ZoneSetupPayload.fromBleProcess(process, zoneIndex));
  }

  static void applyToBleProcess(
    ZoneUiState ui,
    BleProcess process, {
    bool? test,
  }) {
    ZoneSetupPayload.applyToBleProcess(
      toStruct(ui, test: test),
      process,
      ui.zoneNumber - 1,
    );
  }

  static void applyAllToBleProcess(
    List<ZoneUiState> zones,
    BleProcess process, {
    List<bool>? testFlags,
  }) {
    for (var i = 0; i < zones.length; i++) {
      final test = testFlags != null && i < testFlags.length ? testFlags[i] : null;
      applyToBleProcess(zones[i], process, test: test);
    }
  }
}
