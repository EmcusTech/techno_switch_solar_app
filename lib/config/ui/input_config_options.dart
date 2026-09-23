import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Dropdown option catalogs for Input configuration (index = wire value).
abstract final class InputConfigOptions {
  static const List<String> groupOptions = [
    'None',
    'General',
    StringConstants.extOut,
  ];

  static const Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [
      StringConstants.extnlFault,
      StringConstants.reset,
      StringConstants.extnlControlsEnabled,
      StringConstants.silenceAlarm,
      StringConstants.soundAlarm,
      StringConstants.silenceBuzzer,
      StringConstants.mute,
      StringConstants.extnlSupervisory,
      StringConstants.extnlSupplyFault,
    ],
    StringConstants.extOut: [
      StringConstants.manualTrigger,
      StringConstants.manualMode,
      StringConstants.hold,
      StringConstants.extnlDisableGas,
      StringConstants.extnlExtFault,
    ],
  };

  static const List<String> yesNoOptions = [
    StringConstants.no,
    StringConstants.yes,
  ];

  static int clampIndex(int index, List<String> options) {
    if (options.isEmpty) return 0;
    return index.clamp(0, options.length - 1);
  }

  static String groupLabel(int index) {
    return groupOptions[clampIndex(index, groupOptions)];
  }

  static int groupIndex(String label) {
    final index = groupOptions.indexOf(label);
    return index < 0 ? 0 : index;
  }

  static List<String> functionOptionsForGroup(String group) {
    return functionOptionsMap[group] ?? functionOptionsMap['None']!;
  }

  static String functionLabel(int groupIndex, int functionIndex) {
    final group = groupLabel(groupIndex);
    final options = functionOptionsForGroup(group);
    return options[clampIndex(functionIndex, options)];
  }

  static int functionIndex(String group, String function) {
    final options = functionOptionsForGroup(group);
    final index = options.indexOf(function);
    return index < 0 ? 0 : index;
  }

  static String yesNoLabel(int value) {
    return yesNoOptions[clampIndex(value, yesNoOptions)];
  }

  static int yesNoIndex(String label) {
    final index = yesNoOptions.indexOf(label);
    return index < 0 ? 0 : index;
  }

  static int yesNoFromBool(bool value) => value ? 1 : 0;
}
