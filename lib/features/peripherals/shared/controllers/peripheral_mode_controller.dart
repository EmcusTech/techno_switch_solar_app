import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';

/// Base controller for the peripheral configuration bottom sheets
/// (relay, zone, input, sounder, general, etc.).
///
/// Captures the shared lifecycle that every sheet previously implemented inside
/// its `State`:
///   load -> (cache hit) applyCachedData / (cache miss) loadFromManager
///   commit -> validate -> pushToManager -> save
///
/// Subclasses implement only the model-specific mapping. The View rebuilds via
/// `GetBuilder<T>` and calls [update] (through [refreshUi]) for coarse rebuilds,
/// matching the previous whole-sheet `setState` behaviour.
abstract class PeripheralModeController extends GetxController {
  PeripheralModeController({
    required this.deviceId,
    required this.refreshTrigger,
  });

  final String deviceId;
  final ValueNotifier<int> refreshTrigger;

  /// Resolved live BLE manager. Null until [loadData] runs (or when the
  /// `BleLogController` is not registered, e.g. in the create-project flow).
  BleManager? manager;

  @override
  void onInit() {
    super.onInit();
    initModel();
    loadData();
    refreshTrigger.addListener(onRefreshTriggered);
  }

  @override
  void onClose() {
    refreshTrigger.removeListener(onRefreshTriggered);
    disposeModel();
    super.onClose();
  }

  void onRefreshTriggered() => loadFromManager();

  Future<void> loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    final cached = await loadCache();
    if (cached != null) {
      applyCachedData(cached);
      refreshUi();
      return;
    }
    loadFromManager();
  }

  /// Validate, push the edited values into the BLE manager and persist them.
  /// Returns false (without side effects) when validation fails or no manager
  /// is available, matching the previous `commitLocal` contract.
  Future<bool> commitLocal() async {
    updateValidationErrors();
    if (!computeIsValid() || manager == null) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    pushToManager();
    await save();
    return true;
  }

  /// Trigger a coarse rebuild of the bound `GetBuilder`.
  void refreshUi() => update();

  // ---- Subclass hooks (model-specific) ----

  /// Build the editable model objects (e.g. the list of `RelayConfig`).
  void initModel();

  /// Dispose any owned `TextEditingController`s / resources.
  void disposeModel();

  /// Load the persisted cache map for this peripheral, or null on miss.
  Future<Map<String, dynamic>?> loadCache();

  /// Populate the model from a cache map.
  void applyCachedData(Map<String, dynamic> data);

  /// Populate the model from the live BLE manager.
  void loadFromManager();

  /// Write the edited model values back into the BLE manager.
  void pushToManager();

  /// Persist the pushed values (e.g. `PanelConfigCacheSync.saveRelay`).
  Future<void> save();

  /// Whether the current model passes validation.
  bool computeIsValid();

  /// Recompute and store any validation error messages.
  void updateValidationErrors();
}
