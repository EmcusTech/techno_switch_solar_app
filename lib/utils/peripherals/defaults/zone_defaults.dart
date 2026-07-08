import 'package:techno_switch_solar_app/utils/constants/strings/panel_values.dart';

/// Factory defaults for Zone configuration (all three zones).
abstract final class ZoneDefaults {
  static const String text = '';
  static const String typeLabel = PanelValues.zoneTypeNormal;
  static const int typeBle = 0;
  static const String enabledLabel = PanelValues.yesOption;
  static const bool enabledBle = true;
  static const bool testBle = false;
  static const String modeLabel = PanelValues.zoneModeImmediate;
  static const int detectionModeBle = 0;
  /// Immediate/Normal modes require 0s; Confirmed requires 30s per [ZoneModeController].
  static const String verificationTime = '0';

  static Map<String, dynamic> zoneEntry() => {
    'text': text,
    'type': typeBle,
    'enabled': enabledBle,
    'test': testBle,
    'detectionMode': detectionModeBle,
    'verificationTime': verificationTime,
  };

  static Map<String, dynamic> toCacheMap() => {
    'z1': zoneEntry(),
    'z2': zoneEntry(),
    'z3': zoneEntry(),
  };
}
