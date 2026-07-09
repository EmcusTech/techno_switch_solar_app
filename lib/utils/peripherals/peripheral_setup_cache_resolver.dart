import 'package:techno_switch_solar_app/utils/constants/ble/ble_name_utils.dart';
import 'package:techno_switch_solar_app/utils/storage/commissioning_test_results_cache.dart';

/// Resolves peripheral / commissioning cache across BLE MAC and logical panel ids.
abstract final class PeripheralSetupCacheResolver {
  /// Ordered, de-duplicated cache keys to try (most specific first).
  static List<String> cacheDeviceIdCandidates({
    required String primaryDeviceId,
    String? bleName,
    String? panelVersionNo,
  }) {
    final ids = <String>[];
    void add(String? id) {
      final trimmed = id?.trim() ?? '';
      if (trimmed.isEmpty || ids.contains(trimmed)) return;
      ids.add(trimmed);
    }

    add(primaryDeviceId);
    add(BleNameUtils.parseTechnoswitchPanelId(bleName ?? ''));
    add(BleNameUtils.normalizeManualPanelId(bleName ?? ''));
    add(panelVersionNo);
    add(BleNameUtils.parseTechnoswitchPanelId(panelVersionNo ?? ''));
    return ids;
  }

  static Future<Map<String, dynamic>?> loadMap(
    List<String> deviceIds,
    Future<Map<String, dynamic>?> Function(String id) loader,
  ) async {
    for (final id in deviceIds) {
      final data = await loader(id);
      if (data != null) return data;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>?> loadList(
    List<String> deviceIds,
    Future<List<Map<String, dynamic>>?> Function(String id) loader,
  ) async {
    for (final id in deviceIds) {
      final data = await loader(id);
      if (data != null && data.isNotEmpty) return data;
    }
    return null;
  }

  static Future<Map<String, dynamic>> loadCommissioningItems(
    List<String> deviceIds,
    CommissioningTestType type,
  ) async {
    for (final id in deviceIds) {
      final data = await CommissioningTestResultsCache.loadItems(id, type);
      if (data.isNotEmpty) return data;
    }
    return const {};
  }
}
