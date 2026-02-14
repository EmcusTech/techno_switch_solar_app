import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches peripheral setup data per device and peripheral type.
/// Used when opening bottom sheets before a download - shows cached data or defaults.
class PeripheralSetupCache {
  PeripheralSetupCache._();

  static const String _keyPrefix = 'peripheral_';

  static String _relayKey(String deviceId) => '${_keyPrefix}${deviceId}_relay';
  static String _inputKey(String deviceId) => '${_keyPrefix}${deviceId}_input';
  static String _zoneKey(String deviceId) => '${_keyPrefix}${deviceId}_zone';
  static String _extOutKey(String deviceId) =>
      '${_keyPrefix}${deviceId}_ext_out';

  // ───────────────── Relay ─────────────────

  static Future<void> saveRelaySetup(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_relayKey(deviceId), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadRelaySetup(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_relayKey(deviceId));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // ───────────────── Input ─────────────────

  static Future<void> saveInputSetup(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inputKey(deviceId), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadInputSetup(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_inputKey(deviceId));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // ───────────────── Zone ─────────────────

  static Future<void> saveZoneSetup(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_zoneKey(deviceId), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadZoneSetup(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_zoneKey(deviceId));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // ───────────────── Ext Out ─────────────────

  static Future<void> saveExtOutSetup(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_extOutKey(deviceId), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadExtOutSetup(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_extOutKey(deviceId));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}
