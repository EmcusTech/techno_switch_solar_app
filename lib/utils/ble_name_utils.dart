/// Utilities for parsing and displaying BLE device names.
///
/// The BLE name format may change, but the 8-character ID at the end is stable.
/// Pre-provisioned sites use [technoswitchBlePrefix] + panel id, e.g. `TECHNOSWITCH_AB12`.
class BleNameUtils {
  BleNameUtils._();

  static const String technoswitchBlePrefix = 'TECHNOSWITCH_';

  static final RegExp _technoswitchPanelIdPattern = RegExp(
    r'^TECHNOSWITCH_(.+)$',
    caseSensitive: false,
  );

  /// Parses `TECHNOSWITCH_XXXX` → `XXXX`. Returns null if the name does not match.
  static String? parseTechnoswitchPanelId(String bleName) {
    final match = _technoswitchPanelIdPattern.firstMatch(bleName.trim());
    final id = match?.group(1)?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  /// Builds the expected BLE advertised name for a logical panel id.
  static String technoswitchBleNameForPanelId(String panelId) {
    return '$technoswitchBlePrefix${normalizeManualPanelId(panelId)}';
  }

  /// Normalizes user-entered panel id (strips optional `TECHNOSWITCH_` prefix).
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

  /// Returns the last 8 characters of the BLE name as the display ID.
  /// The 8-char ID is the stable part regardless of name format.
  static String getDisplayIdFromBleName(String bleName) {
    final trimmed = bleName.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 8) return trimmed;
    return trimmed.substring(trimmed.length - 8);
  }

  /// Returns the prefix part of the BLE name (everything before the last 8 chars).
  /// Used for display when showing "Brand" + "ID" layout.
  static String getDisplayPrefixFromBleName(String bleName) {
    final trimmed = bleName.trim();

    final underscoreIndex = trimmed.indexOf('_');

    if (underscoreIndex == -1) {
      return trimmed; // No underscore found
    }

    return trimmed.substring(0, underscoreIndex);
  }
}
