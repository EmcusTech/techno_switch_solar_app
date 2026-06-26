import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/zone_setup_manager_sync.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Controller for the Walk Test (zone) bottom sheet.
///
/// Edits the per-zone test flags directly on the live manager (no local model);
/// the View streams them via `AnimatedBuilder`. Apply syncs the zone-mode hex.
class WalkTestZoneController extends PeripheralModeController {
  WalkTestZoneController({
    required super.deviceId,
    required super.refreshTrigger,
  });

  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];

  @override
  void initModel() {}

  @override
  void disposeModel() {}

  @override
  Future<void> loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    final cached = await loadCache();
    if (cached != null && manager != null) {
      applyZoneTestFlagsFromCacheMap(manager!, cached);
      refreshUi();
      return;
    }
    loadFromManager();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadZoneSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    if (manager == null) return;
    applyZoneTestFlagsFromCacheMap(manager!, data);
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;
    refreshUi();
  }

  @override
  void pushToManager() {}

  @override
  Future<void> save() async {}

  @override
  bool computeIsValid() => true;

  @override
  void updateValidationErrors() {}

  // ---- UI intents ----

  void onTestChanged(int zoneIndex, bool test) {
    final m = manager;
    if (m == null) return;
    setZoneTestOnManager(m, zoneIndex, test);
    if (test) {
      setZoneEnabledOnManager(m, zoneIndex, true);
    }
  }

  /// Apply action: persist the zone-mode hex derived from the test flags.
  void applyTest() {
    if (manager == null) return;
    syncZoneModeHexFromBleManager(manager!);
  }
}
