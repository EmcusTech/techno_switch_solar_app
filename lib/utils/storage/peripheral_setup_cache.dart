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
  static String _radioKey(String deviceId) =>
      '${_keyPrefix}${deviceId}_radio';
  static String _moduleKey(String deviceId) =>
      '${_keyPrefix}${deviceId}_module';
  static String _lBusKey(String deviceId) =>
      '${_keyPrefix}${deviceId}_l_bus';

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

  // ───────────────── Radio ─────────────────

  static Future<void> saveRadioSetup(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_radioKey(deviceId), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadRadioSetup(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_radioKey(deviceId));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // ───────────────── Module ─────────────────

  static Future<void> saveModuleSetup(
    String deviceId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_moduleKey(deviceId), jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadModuleSetup(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_moduleKey(deviceId));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  // ───────────────── L-Bus ─────────────────

  static Future<void> saveLBusSetup(
    String deviceId,
    List<Map<String, dynamic>> buses,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lBusKey(deviceId), jsonEncode({'buses': buses}));
  }

  static Future<List<Map<String, dynamic>>?> loadLBusSetup(
    String deviceId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lBusKey(deviceId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final buses = decoded['buses'] as List<dynamic>?;
      if (buses == null) return null;
      return buses
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
