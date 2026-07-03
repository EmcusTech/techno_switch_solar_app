import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Controller for the Test Mode (sounder) bottom sheet.
///
/// Edits the per-sounder test flags directly on the live manager; the View
/// streams them via `AnimatedBuilder`. Apply syncs the sounder output-mode hex.
class TestModeSounderController extends PeripheralModeController {
  TestModeSounderController({
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
      applySounderMainTestFlagsFromCacheMap(manager!, cached);
      refreshUi();
      return;
    }
    loadFromManager();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadSounderSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    if (manager == null) return;
    applySounderMainTestFlagsFromCacheMap(manager!, data);
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

  void onTestChanged(int index, bool test) {
    final m = manager;
    if (m == null) return;
    setSounderMainTestOnManager(m, index, test);
    if (test) setSounderMainEnabledOnManager(m, index, true);
  }

  /// Apply action: persist the sounder output-mode hex derived from the flags.
  void applyTest() {
    if (manager == null) return;
    syncSounderMainOutputModeHexFromBleManager(manager!);
  }
}
