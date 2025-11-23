import 'package:shared_preferences/shared_preferences.dart';

/// Simple wrapper around [SharedPreferences] to persist the AES key
/// exchanged with the Technoswitch panel.
class EncryptionKeyStore {
  EncryptionKeyStore._();

  static const String _storageKey = 'technoswitch_ble_encryption_key';
  static final EncryptionKeyStore instance = EncryptionKeyStore._();

  /// Stores the provided [hexKey] string. Passing `null` clears the key.
  Future<void> saveKey(String? hexKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (hexKey == null || hexKey.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, hexKey.toLowerCase());
    }
  }

  /// Reads the cached key, or `null` if nothing has been stored yet.
  Future<String?> readKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_storageKey);
    if (key == null || key.isEmpty) {
      return null;
    }
    return key;
  }

  /// Utility helper exposed for tests / logout flows.
  Future<void> clear() => saveKey(null);
}
