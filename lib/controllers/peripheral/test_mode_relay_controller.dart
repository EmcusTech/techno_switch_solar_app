import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/peripheral_test_mode_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Controller for the Test Mode (relay) bottom sheet.
///
/// Edits the per-relay test flags directly on the live manager; the View
/// streams them via `AnimatedBuilder`. Apply syncs the relay output-mode hex.
class TestModeRelayController extends PeripheralModeController {
  TestModeRelayController({
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
      applyRelayTestFlagsFromCacheMap(manager!, cached);
      refreshUi();
      return;
    }
    loadFromManager();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadRelaySetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    if (manager == null) return;
    applyRelayTestFlagsFromCacheMap(manager!, data);
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
    setRelayTestOnManager(m, index, test);
    if (test) setRelayEnabledOnManager(m, index, true);
  }

  /// Apply action: persist the relay output-mode hex derived from the flags.
  void applyTest() {
    if (manager == null) return;
    syncRelayOutputModeHexFromBleManager(manager!);
  }
}
