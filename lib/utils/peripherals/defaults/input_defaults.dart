import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Factory defaults for Input (PROG IN 1) configuration.
abstract final class InputDefaults {
  static const String inputText = '';
  static const String groupLabel = 'General';
  static const int groupBle = 1;
  static const String functionLabel = StringConstants.extnlFault;
  static const int functionBle = 0;
  static const String enabledLabel = PanelValues.yesOption;
  static const bool enabledBle = true;
  static const String testLabel = PanelValues.noOption;
  static const bool testBle = false;
  static const String invertedLabel = PanelValues.noOption;
  static const bool invertedBle = false;

  static Map<String, dynamic> toCacheMap() => {
    'text': inputText,
    'group': groupBle,
    'function': functionBle,
    'enabled': enabledBle,
    'test': testBle,
    'inverted': invertedBle,
  };
}
