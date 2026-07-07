import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/modes/ext_zone_mode_util.dart';
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

  final List<String> enabledOptions = [StringConstants.no, StringConstants.yes];
  final List<String> actuatorTypeOptions = [
    'Not Defined',
    StringConstants.metron,
    StringConstants.solenoid,
    StringConstants.aerosol,
  ];
  final List<String> functionOptions = [
    'Z1 and Z2',
    StringConstants.z2AndZ3,
    StringConstants.z1AndZ3,
    StringConstants.z1AndZ2AndZ3,
    StringConstants.z12,
    StringConstants.z22,
    StringConstants.z32,
    StringConstants.any2Zones,
    StringConstants.any1Zone,
  ];
  final List<String> resetInCountOptions = [
    StringConstants.yes,
    StringConstants.no,
  ];
  final List<String> holdCountOptions = [
    'Disabled',
    StringConstants.restart,
    StringConstants.suspend,
    StringConstants.disabled,
  ];
  final List<String> actionOptions = [
    'Continous',
    StringConstants.pulse100msOn,
    StringConstants.pulse300msOn,
    StringConstants.pulse600msOn,
    StringConstants.pulse1sOn,
    StringConstants.pulse5sOn,
    StringConstants.pulsing100msOn500msOff,
    StringConstants.pulsing300msOn15sOff,
    StringConstants.pulsing600msOn3sOff,
    StringConstants.pulsing1sOn5sOff,
  ];

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
    autoCtrl = TextEditingController(text: "10");
    manCtrl = TextEditingController(text: "15");
    releaseCtrl = TextEditingController(text: "10");
    resetDelayCtrl = TextEditingController(text: "5");
    enabled = enabledOptions[0];
    actuatorType = actuatorTypeOptions[0];
    function = functionOptions[0];
    resetInCount = resetInCountOptions[0];
    holdCount = holdCountOptions[0];
    action = actionOptions[0];
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
    final en = (data['enabled'] as int?) ?? 0;
    enabled = enabledOptions[en.clamp(0, enabledOptions.length - 1)];
    final at = (data[StringConstants.actuatortype] as int?) ?? 0;
    actuatorType =
        actuatorTypeOptions[at.clamp(0, actuatorTypeOptions.length - 1)];
    final fn = (data['function'] as int?) ?? 0;
    function = functionOptions[fn.clamp(0, functionOptions.length - 1)];
    final ra = (data[StringConstants.resetallowed] as int?) ?? 0;
    resetInCount =
        resetInCountOptions[ra.clamp(0, resetInCountOptions.length - 1)];
    final hc = (data[StringConstants.holdmode] as int?) ?? 0;
    holdCount = holdCountOptions[hc.clamp(0, holdCountOptions.length - 1)];
    final ac = (data['action'] as int?) ?? 0;
    action = actionOptions[ac.clamp(0, actionOptions.length - 1)];
    autoCtrl.text = (data['countdownAuto'] as int?)?.toString() ?? '10';
    manCtrl.text = (data['countdownMan'] as int?)?.toString() ?? '15';
    releaseCtrl.text = (data['releaseTime'] as int?)?.toString() ?? '10';
    resetDelayCtrl.text =
        (data[StringConstants.resetdelay] as int?)?.toString() ?? '5';
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
    autoCtrl.text = manager!.extZoneCountdownAuto.value.toString();
    manCtrl.text = manager!.extZoneCountdownMan.value.toString();
    releaseCtrl.text = manager!.extZoneReleaseTime.value.toString();
    resetDelayCtrl.text = manager!.extZoneResetDelay.value.toString();
    enabled = enabledOptions[manager!.isExtZoneEnabled.value];
    actuatorType = actuatorTypeOptions[manager!.extZoneActuatorType.value];
    function = functionOptions[manager!.extZoneFunction.value];
    resetInCount = resetInCountOptions[manager!.isResetAllowed.value];
    holdCount = holdCountOptions[manager!.extZoneHoldMode.value];
    action = actionOptions[manager!.extZoneAction.value];
    refreshUi();
  }

  int returnIndex(String value, List<String> list) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == value) {
        return i;
      }
    }
    return -1;
  }

  @override
  void pushToManager() {
    final m = manager!;
    int zoneEnable = returnIndex(enabled, enabledOptions);
    int holdRestart = returnIndex(holdCount, holdCountOptions);
    int resetAllowedInt = returnIndex(resetInCount, resetInCountOptions);
    int functionInt = returnIndex(function, functionOptions);
    int actuaturTypeInt = returnIndex(actuatorType, actuatorTypeOptions);
    bool resetAllowed = resetAllowedInt == 0;

    final config = ExtZoneModeConfig(
      extZoneEnable: ExtZoneEnable.values[zoneEnable],
      extZoneMode: ExtZoneMode.normal,
      holdMode: HoldMode.values[holdRestart],
      resetAllowed: resetAllowed,
      flowDetectionUsed: false,
    );

    final String hexValue = ExtZoneModeCodec.encodeHex(config);

    m.isExtZoneEnabled.value = zoneEnable;
    m.extZoneMode.value = hexValue;
    m.extZoneCountdownAuto.value = int.parse(
      autoCtrl.text.isEmpty ? '0' : autoCtrl.text,
    );
    m.extZoneCountdownMan.value = int.parse(manCtrl.text);
    m.extZoneReleaseTime.value = int.parse(releaseCtrl.text);
    m.extZoneResetDelay.value = int.parse(resetDelayCtrl.text);
    m.extZoneAction.value = returnIndex(action, actionOptions);
    m.extZoneFunction.value = functionInt;
    m.extZoneActuatorType.value = actuaturTypeInt;
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
