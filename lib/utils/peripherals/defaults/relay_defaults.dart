import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Factory defaults for Relay configuration (all three relays).
abstract final class RelayDefaults {
  static const String outputText = '';
  static const String groupLabel = StringConstants.zone;
  static const int groupBle = 2;
  static const String functionLabel = 'Fire';
  static const int functionBle = 1;
  static const String enabledLabel = PanelValues.yesOption;
  static const bool enabledBle = true;
  static const bool testBle = false;

  static String zoneNumberForRelay(int relayIndex) => '${relayIndex + 1}';

  static Map<String, dynamic> relayEntry(int relayIndex) => {
    'outputText': outputText,
    'group': groupBle,
    'function': functionBle,
    StringConstants.outputtext: zoneNumberForRelay(relayIndex),
    'enabled': enabledBle,
    'test': testBle,
  };

  static Map<String, dynamic> toCacheMap() => {
    'r1': relayEntry(0),
    'r2': relayEntry(1),
    'r3': relayEntry(2),
  };
}
