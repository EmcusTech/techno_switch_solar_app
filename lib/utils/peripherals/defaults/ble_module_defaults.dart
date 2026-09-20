/// Factory defaults for BLE module (`st_ble_module_cfg_def`) configuration.
abstract final class BleModuleDefaults {
  static const int bleEnable = 1;
  static const String bleName = '';
  static const String bleId = '';
  static const int bleAdvEnable = 1;

  static Map<String, dynamic> toCacheMap() => {
    'bleEnable': bleEnable,
    'bleName': bleName,
    'bleId': bleId,
    'bleAdvEnable': bleAdvEnable,
  };
}
