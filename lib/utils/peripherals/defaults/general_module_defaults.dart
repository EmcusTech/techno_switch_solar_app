import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Factory defaults for General module configuration.
abstract final class GeneralModuleDefaults {
  // UI / cache (string labels)
  static const int lvlTimeout = 300;
  static const String silenceBuzzerLevel = StringConstants.accessLevel1;
  static const String silenceSoundersLevel = StringConstants.accessLevel2;
  static const String resetLevel = StringConstants.accessLevel2;
  static const String faultLatching = StringConstants.no;

  // BLE indices (ValueNotifier storage in ble_process)
  static const int lvlTimeoutBle = 300;
  static const int silenceBuzzerLevelIndex = 0;
  static const int silenceSoundersLevelIndex = 0;
  static const int resetLevelIndex = 0;
  static const int faultLatchingIndex = 0;

  static Map<String, dynamic> toCacheMap() => {
    'lvlTimeout': lvlTimeout,
    StringConstants.silencebuzzerlevel: silenceBuzzerLevel,
    'silenceSoundersLevel': silenceSoundersLevel,
    'resetLevel': resetLevel,
    StringConstants.silencesounderslevel: faultLatching,
  };
}
