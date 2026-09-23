import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Dropdown option catalogs for Ext-Out configuration (index = wire value).
abstract final class ExtOutConfigOptions {
  static const List<String> enabledOptions = [
    StringConstants.no,
    StringConstants.yes,
  ];

  static const List<String> actuatorTypeOptions = [
    'Not Defined',
    StringConstants.metron,
    StringConstants.solenoid,
    StringConstants.aerosol,
  ];

  static const List<String> functionOptions = [
    'Z1 and Z2',
    StringConstants.z2AndZ3,
    StringConstants.z1AndZ3,
    StringConstants.z1AndZ2AndZ3,
    StringConstants.z12,
    StringConstants.z22,
    StringConstants.z32,
    StringConstants.any2Zones,
    StringConstants.any1Zone,
  ];

  static const List<String> resetInCountOptions = [
    StringConstants.yes,
    StringConstants.no,
  ];

  static const List<String> holdCountOptions = [
    'Disabled',
    StringConstants.restart,
    StringConstants.suspend,
    StringConstants.disabled,
  ];

  static const List<String> actionOptions = [
    'Continous',
    StringConstants.pulse100msOn,
    StringConstants.pulse300msOn,
    StringConstants.pulse600msOn,
    StringConstants.pulse1sOn,
    StringConstants.pulse5sOn,
    StringConstants.pulsing100msOn500msOff,
    StringConstants.pulsing300msOn15sOff,
    StringConstants.pulsing600msOn3sOff,
    StringConstants.pulsing1sOn5sOff,
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

  static String enabledLabel(int value) => labelFor(enabledOptions, value);

  static int enabledIndex(String label) => indexFor(enabledOptions, label);

  static String actuatorTypeLabel(int value) =>
      labelFor(actuatorTypeOptions, value);

  static int actuatorTypeIndex(String label) =>
      indexFor(actuatorTypeOptions, label);

  static String functionLabel(int value) => labelFor(functionOptions, value);

  static int functionIndex(String label) => indexFor(functionOptions, label);

  static String resetInCountLabel(int value) =>
      labelFor(resetInCountOptions, value);

  static int resetInCountIndex(String label) =>
      indexFor(resetInCountOptions, label);

  static String holdCountLabel(int value) => labelFor(holdCountOptions, value);

  static int holdCountIndex(String label) => indexFor(holdCountOptions, label);

  static String actionLabel(int value) => labelFor(actionOptions, value);

  static int actionIndex(String label) => indexFor(actionOptions, label);
}
