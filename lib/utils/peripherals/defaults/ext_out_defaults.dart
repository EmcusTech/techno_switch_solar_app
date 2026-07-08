import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/modes/ext_zone_mode_util.dart';

/// Factory defaults for Ext Out (extinguishant) configuration.
abstract final class ExtOutDefaults {
  static const int enabledBle = 1;
  static const String enabledLabel = StringConstants.yes;

  static const int actuatorTypeBle = 0;
  static const String actuatorTypeLabel = 'Not Defined';

  static const int functionBle = 0;
  static const String functionLabel = 'Z1 and Z2';

  static const int countdownAutoBle = 10;
  static const int countdownManBle = 15;
  static const int releaseTimeBle = 10;
  static const int resetDelayBle = 5;

  /// UI index: Reset in Count = No (reset not allowed during countdown).
  static const int resetAllowedBle = 1;
  static const String resetInCountLabel = StringConstants.no;

  static const int holdModeBle = 2;
  static const String holdCountLabel = StringConstants.suspend;

  static const int actionBle = 0;
  static const String actionLabel = 'Continous';

  static ExtZoneModeConfig get modeConfig => const ExtZoneModeConfig(
    extZoneEnable: ExtZoneEnable.enabled,
    extZoneMode: ExtZoneMode.normal,
    holdMode: HoldMode.suspendCount,
    resetAllowed: false,
    flowDetectionUsed: false,
  );

  static String get modeHex => ExtZoneModeCodec.encodeHex(modeConfig);

  static Map<String, dynamic> toCacheMap() => {
    'enabled': enabledBle,
    StringConstants.actuatortype: actuatorTypeBle,
    'function': functionBle,
    StringConstants.resetallowed: resetAllowedBle,
    StringConstants.holdmode: holdModeBle,
    'action': actionBle,
    'countdownAuto': countdownAutoBle,
    'countdownMan': countdownManBle,
    'releaseTime': releaseTimeBle,
    StringConstants.resetdelay: resetDelayBle,
  };
}
