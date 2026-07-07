import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
class BleNameUtils {
  BleNameUtils._();

  static const String technoswitchBlePrefix = StringConstants.technoswitch;

  static final RegExp _technoswitchPanelIdPattern = RegExp(
    r'^TECHNOSWITCH_(.+)$',
    caseSensitive: false,
  );

  static String? parseTechnoswitchPanelId(String bleName) {
    final match = _technoswitchPanelIdPattern.firstMatch(bleName.trim());
    final id = match?.group(1)?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static String technoswitchBleNameForPanelId(String panelId) {
    return '$technoswitchBlePrefix${normalizeManualPanelId(panelId)}';
  }

  static String normalizeManualPanelId(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parsed = parseTechnoswitchPanelId(trimmed);
    return parsed ?? trimmed;
  }

  static bool isValidManualPanelId(String raw) {
    final id = normalizeManualPanelId(raw);
    if (id.isEmpty || id.length > 64) return false;
    return RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id);
  }

  static String getDisplayIdFromBleName(String bleName) {
    final trimmed = bleName.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 8) return trimmed;
    return trimmed.substring(trimmed.length - 8);
  }

  static String getDisplayPrefixFromBleName(String bleName) {
    final trimmed = bleName.trim();

    final underscoreIndex = trimmed.indexOf('_');

    if (underscoreIndex == -1) {
      return trimmed;
    }

    return trimmed.substring(0, underscoreIndex);
  }
}
