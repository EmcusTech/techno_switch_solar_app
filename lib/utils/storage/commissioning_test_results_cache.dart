import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum CommissioningTestType { walkTest, relayTest, sounderTest }

class CommissioningTestResultsCache {
  CommissioningTestResultsCache._();

  static const String _keyPrefix = 'commissioning_test_';

  static String _key(String deviceId, CommissioningTestType type) {
    final suffix = switch (type) {
      CommissioningTestType.walkTest => 'walk_test',
      CommissioningTestType.relayTest => 'relay_test',
      CommissioningTestType.sounderTest => 'sounder_test',
    };
    return '$_keyPrefix${deviceId}_$suffix';
  }

  static Future<Map<String, dynamic>?> load(
    String deviceId,
    CommissioningTestType type,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(deviceId, type));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> loadItems(
    String deviceId,
    CommissioningTestType type,
  ) async {
    final data = await load(deviceId, type);
    final items = data?['items'];
    if (items is! Map) return {};
    return Map<String, dynamic>.from(items);
  }

  static Future<void> mergeResults(
    String deviceId,
    CommissioningTestType type,
    Map<String, String> results,
  ) async {
    if (results.isEmpty) return;
    final existing = await loadItems(deviceId, type);
    final now = DateTime.now().toIso8601String();
    for (final entry in results.entries) {
      existing[entry.key] = {'result': entry.value, 'testedAt': now};
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(deviceId, type),
      jsonEncode({'items': existing}),
    );
  }

  static String? resultForItem(Map<String, dynamic> items, String itemId) {
    final item = items[itemId];
    if (item is! Map) return null;
    final result = item['result'];
    return result is String ? result : null;
  }
}
