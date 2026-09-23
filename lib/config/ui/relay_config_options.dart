import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Dropdown option catalogs for Relay configuration (index = wire value).
abstract final class RelayConfigOptions {
  static const List<String> groupOptions = [
    'None',
    'General',
    'Zone',
    StringConstants.extOut,
  ];

  static const Map<String, List<String>> functionOptionsMap = {
    'None': ['None'],
    'General': [
      'Fault',
      StringConstants.extnlFault,
      StringConstants.supplyFault,
      StringConstants.extnlSupplyFault,
      StringConstants.sounderFault,
      StringConstants.sounderSilenced,
      StringConstants.sounderActivated,
      StringConstants.sounderDisabled,
      StringConstants.disablement,
      StringConstants.test,
      'Fire',
      StringConstants.reset,
      StringConstants.controlsEnabled,
      StringConstants.supervisory,
      StringConstants.fireSnd,
    ],
    'Zone': [
      'Fault',
      'Fire',
      StringConstants.disablement,
      StringConstants.fireSnd,
    ],
    StringConstants.extOut: [
      StringConstants.releaseInitiated,
      StringConstants.extAgentReleased,
      StringConstants.releaseHold,
      StringConstants.manualMode,
      StringConstants.manualRelease,
      StringConstants.extnlExtFault,
      StringConstants.extSnd1,
      'Ext. Snd 2',
      StringConstants.manReleaseSnd,
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

  static String labelFor(List<String> options, int index) {
    return options[clampIndex(index, options)];
  }

  static int indexFor(List<String> options, String label) {
    final index = options.indexOf(label);
    return index < 0 ? 0 : index;
  }

  static String groupLabel(int value) => labelFor(groupOptions, value);

  static int groupIndex(String label) => indexFor(groupOptions, label);

  static List<String> functionOptionsForGroup(String group) {
    return functionOptionsMap[group] ?? functionOptionsMap['None']!;
  }

  static String functionLabel(int groupIndex, int functionIndex) {
    final group = groupLabel(groupIndex);
    final options = functionOptionsForGroup(group);
    return options[clampIndex(functionIndex, options)];
  }

  static int functionIndex(String group, String function) {
    return indexFor(functionOptionsForGroup(group), function);
  }

  static String yesNoLabel(bool value) =>
      value ? StringConstants.yes : StringConstants.no;

  static bool yesNoValue(String label) => label == StringConstants.yes;
}
