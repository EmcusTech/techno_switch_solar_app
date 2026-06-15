import 'package:shared_preferences/shared_preferences.dart';

class EncryptionKeyStore {
  EncryptionKeyStore._();

  static const String _storageKey = 'technoswitch_ble_encryption_key';
  static final EncryptionKeyStore instance = EncryptionKeyStore._();

  Future<void> saveKey(String? hexKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (hexKey == null || hexKey.isEmpty) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, hexKey.toLowerCase());
    }
  }

  Future<String?> readKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_storageKey);
    if (key == null || key.isEmpty) {
      return null;
    }
    return key;
  }

  Future<void> clear() => saveKey(null);
}
