import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/config/ble/ext_out_setup_payload_debug.dart';
import 'package:techno_switch_solar_app/config/ui/ext_out_config_options.dart';
import 'package:techno_switch_solar_app/config/ui/ext_out_config_ui_bridge.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Controller for the Ext-Out (extinguishant) configuration bottom sheet.
///
/// Differs from the standard template in two ways, both preserved here:
///   * load is connected-first (read manager when live, else cache),
///   * apply is gated by `isExtOutApplyButtonActive` unless embedded in the
///     create-project flow.
class ExtOutController extends PeripheralModeController {
  ExtOutController({
    required super.deviceId,
    required super.refreshTrigger,
    this.embedInCreateFlow = false,
  });

  final bool embedInCreateFlow;

  List<String> get enabledOptions => ExtOutConfigOptions.enabledOptions;

  List<String> get actuatorTypeOptions => ExtOutConfigOptions.actuatorTypeOptions;

  List<String> get functionOptions => ExtOutConfigOptions.functionOptions;

  List<String> get resetInCountOptions => ExtOutConfigOptions.resetInCountOptions;

  List<String> get holdCountOptions => ExtOutConfigOptions.holdCountOptions;

  List<String> get actionOptions => ExtOutConfigOptions.actionOptions;

  final String autoError = "Countdown Auto must be between 0 and 60";
  final String manError = StringConstants.countdownManMustBeBetween0And60;
  final String releaseError = StringConstants.releaseTimeMustBeBetween10And300;
  final String resetDelayError =
      StringConstants.resetDelayMustBeBetween0And1800;

  late String enabled;
  late String actuatorType;
  late String function;
  late String resetInCount;
  late String holdCount;
  late String action;

  late TextEditingController autoCtrl;
  late TextEditingController manCtrl;
  late TextEditingController releaseCtrl;
  late TextEditingController resetDelayCtrl;

  @override
  void initModel() {
    autoCtrl = TextEditingController();
    manCtrl = TextEditingController();
    releaseCtrl = TextEditingController();
    resetDelayCtrl = TextEditingController();
    _applyUiState(ExtOutUiState.defaults());
  }

  @override
  void disposeModel() {
    autoCtrl.dispose();
    manCtrl.dispose();
    releaseCtrl.dispose();
    resetDelayCtrl.dispose();
  }

  @override
  Future<void> loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
    }
    if (manager?.isConnected == true) {
      loadFromManager();
      final cached = await loadCache();
      if (cached != null) {
        _applyCachedSolarMode(cached);
      }
      return;
    }
    final cached = await loadCache();
    if (cached != null) {
      applyCachedData(cached);
      refreshUi();
      return;
    }
    loadFromManager();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadExtOutSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    _applyUiState(ExtOutConfigUiBridge.fromCacheMap(data));
    _applyCachedSolarMode(data);
  }

  void _applyCachedSolarMode(Map<String, dynamic> data) {
    final solarRaw = data[StringConstants.issolar];
    if (manager != null && solarRaw is bool) {
      manager!.bleProcess.isExtOutApplyButtonActive.value = solarRaw;
    }
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;
    _applyUiState(ExtOutConfigUiBridge.fromBleProcess(manager!.bleProcess));
    refreshUi();
  }

  ExtOutUiState _currentUiState() => ExtOutUiState(
    enabled: enabled,
    actuatorType: actuatorType,
    function: function,
    resetInCount: resetInCount,
    holdCount: holdCount,
    action: action,
    countdownAuto: int.tryParse(autoCtrl.text) ?? 0,
    countdownMan: int.tryParse(manCtrl.text) ?? 0,
    releaseTime: int.tryParse(releaseCtrl.text) ?? 0,
    resetDelay: int.tryParse(resetDelayCtrl.text) ?? 0,
  );

  void _applyUiState(ExtOutUiState ui) {
    enabled = ui.enabled;
    actuatorType = ui.actuatorType;
    function = ui.function;
    resetInCount = ui.resetInCount;
    holdCount = ui.holdCount;
    action = ui.action;
    autoCtrl.text = ui.countdownAuto.toString();
    manCtrl.text = ui.countdownMan.toString();
    releaseCtrl.text = ui.releaseTime.toString();
    resetDelayCtrl.text = ui.resetDelay.toString();
  }

  @override
  void pushToManager() {
    ExtOutConfigUiBridge.applyToBleProcess(_currentUiState(), manager!.bleProcess);
    if (kDebugMode) {
      ExtOutSetupPayloadDebug.printApplyFrame(manager!);
    }
  }

  @override
  Future<void> save() =>
      PanelConfigCacheSync.saveExtOut(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() {
    final auto = int.tryParse(autoCtrl.text);
    final man = int.tryParse(manCtrl.text);
    final release = int.tryParse(releaseCtrl.text);
    final resetDelay = int.tryParse(resetDelayCtrl.text);

    if (auto == null || auto < 0 || auto > 60) return false;
    if (man == null || man < 0 || man > 60) return false;
    if (release == null || release < 10 || release > 300) return false;
    if (resetDelay == null || resetDelay < 0 || resetDelay > 1800) return false;
    return true;
  }

  @override
  void updateValidationErrors() {}

  /// Whether apply is permitted (solar/DIP gate), ignoring form validity.
  bool get canApply =>
      manager != null && manager!.bleProcess.isExtOutApplyButtonActive.value;

  @override
  Future<bool> commitLocal() async {
    if (manager == null) return false;
    if (!computeIsValid()) return false;
    if (!embedInCreateFlow && !canApply) return false;

    FocusManager.instance.primaryFocus?.unfocus();
    pushToManager();
    await save();
    return true;
  }

  // ---- UI intents ----

  void setEnabled(String v) {
    enabled = v;
    refreshUi();
  }

  void setActuatorType(String v) {
    actuatorType = v;
    refreshUi();
  }

  void setFunction(String v) {
    function = v;
    refreshUi();
  }

  void setResetInCount(String v) {
    resetInCount = v;
    refreshUi();
  }

  void setHoldCount(String v) {
    holdCount = v;
    refreshUi();
  }

  void setAction(String v) {
    action = v;
    refreshUi();
  }

  void onFieldChanged() => refreshUi();
}
