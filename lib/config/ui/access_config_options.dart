import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Dropdown option catalogs for Access Code configuration (index = wire value).
abstract final class AccessConfigOptions {
  static const List<String> accessLevelNames = [
    StringConstants.notUsed,
    StringConstants.untrainedUser,
    StringConstants.authorisedUser,
    StringConstants.commissioning,
  ];

  static int clampIndex(int index, List<String> options) {
    if (options.isEmpty) return 0;
    return index.clamp(0, options.length - 1);
  }

  static String accessLevelLabel(int value) {
    return accessLevelNames[clampIndex(value, accessLevelNames)];
  }

  static int accessLevelIndex(String label) {
    final index = accessLevelNames.indexOf(label);
    return index < 0 ? 0 : index;
  }
}
