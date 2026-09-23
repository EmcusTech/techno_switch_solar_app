import 'package:techno_switch_solar_app/config/structs/panel_access_lvl_cfg_def.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';

/// Thin bridge between [AccessCodeSetupData] and [PanelAccessLvlCfgDef].
abstract final class AccessConfigUiBridge {
  static PanelAccessLvlCfgDef toStruct(AccessCodeSetupData data) {
    return PanelAccessLvlCfgDef.fromSetupData(data);
  }

  static AccessCodeSetupData fromStruct(PanelAccessLvlCfgDef config) {
    return config.toSetupData();
  }

  static AccessCodeSetupData fromCacheMap(Map<String, dynamic> data) {
    return PanelAccessLvlCfgDef.fromCacheMap(data).toSetupData();
  }

  static Map<String, dynamic> toCacheMap(AccessCodeSetupData data) {
    return toStruct(data).toCacheMap();
  }
}
