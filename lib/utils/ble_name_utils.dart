/// Utilities for parsing and displaying BLE device names.
///
/// The BLE name format may change, but the 8-character ID at the end is stable.
class BleNameUtils {
  BleNameUtils._();

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
