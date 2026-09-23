import 'package:techno_switch_solar_app/ble/ble_process.dart';
import 'package:techno_switch_solar_app/config/ble/panel_properties_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/panel_properties_cfg_def.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/general_module_defaults.dart';

/// Bridge between the combined panel-properties struct and the three UI modules.
abstract final class PanelPropertiesConfigUiBridge {
  static PanelPropertiesCfgDef fromBleProcess(BleProcess process) {
    return PanelPropertiesSetupPayload.fromBleProcess(process);
  }

  static void applyToBleProcess(
    PanelPropertiesCfgDef config,
    BleProcess process,
  ) {
    PanelPropertiesSetupPayload.applyToBleProcess(config, process);
  }

  static PanelPropertiesCfgDef fromCacheMaps({
    Map<String, dynamic>? panelInfo,
    Map<String, dynamic>? generalModule,
    Map<String, dynamic>? serviceDue,
  }) {
    return PanelPropertiesCfgDef.fromCacheMap({
      ...?panelInfo,
      ...?generalModule,
      ...?serviceDue,
    });
  }

  static Map<String, dynamic> toPanelInfoCacheMap(PanelPropertiesCfgDef config) {
    return {
      'panelId': config.panelNum,
      'panelName': config.panelName,
      'delay': config.eventReminderDelay,
    };
  }

  static Map<String, dynamic> toGeneralModuleCacheMap(
    PanelPropertiesCfgDef config,
  ) {
    return {
      'lvlTimeout': config.lvlTimeout,
      StringConstants.silencebuzzerlevel: _silenceBuzzerLabel(
        config.silenceBuzzLvl,
      ),
      'silenceSoundersLevel': _silenceSounderLabel(config.silenceSndrLvl),
      'resetLevel': _resetLevelLabel(config.resetLvl),
      StringConstants.silencesounderslevel: config.faultLatch == 0
          ? StringConstants.no
          : StringConstants.yes,
    };
  }

  static Map<String, dynamic> toServiceDueCacheMap(
    PanelPropertiesCfgDef config,
  ) {
    return {
      'year': PanelPropertiesSetupPayload.serviceYearFromWire(
        config.serviceDueYear,
      ),
      'month': config.serviceDueMonth,
      'day': config.serviceDueDay,
      'hour': config.serviceDueHour,
      'minute': config.serviceDueMinute,
      'company': config.companyName,
      'contact': config.serviceContact,
      'reminder': config.remEnable,
    };
  }

  static String _silenceBuzzerLabel(int index) {
    const options = [
      StringConstants.accessLevel1,
      StringConstants.accessLevel2,
    ];
    if (index < 0 || index >= options.length) {
      return GeneralModuleDefaults.silenceBuzzerLevel;
    }
    return options[index];
  }

  static String _silenceSounderLabel(int index) {
    const options = [
      StringConstants.accessLevel2,
      StringConstants.accessLevel3,
    ];
    if (index < 0 || index >= options.length) {
      return GeneralModuleDefaults.silenceSoundersLevel;
    }
    return options[index];
  }

  static String _resetLevelLabel(int index) {
    const options = [
      StringConstants.accessLevel2,
      StringConstants.accessLevel3,
    ];
    if (index < 0 || index >= options.length) {
      return GeneralModuleDefaults.resetLevel;
    }
    return options[index];
  }
}
