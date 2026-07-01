import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/zone_setup_manager_sync.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class ZoneConfig {
  final int zoneNumber;

  String type = PanelValues.zoneTypeNone;
  String enabled = PanelValues.noOption;
  String mode = PanelValues.zoneModeNormal;

  TextEditingController zoneTextController = TextEditingController();
  TextEditingController verificationTimeController = TextEditingController();

  ZoneConfig({required this.zoneNumber});
}

/// Controller for the Zone Mode bottom sheet.
class ZoneModeController extends PeripheralModeController {
  ZoneModeController({required super.deviceId, required super.refreshTrigger});

  final List<String> typeOptions = PanelValues.zoneTypeOptions;
  final List<String> yesNoOptions = [PanelValues.noOption, PanelValues.yesOption];
  final List<String> modeOptions = PanelValues.zoneModeOptions;

  late List<ZoneConfig> zones;

  final Map<int, String?> zoneTextErrors = {};
  final Map<int, String?> verificationErrors = {};

  @override
  void initModel() {
    zones = List.generate(3, (i) => ZoneConfig(zoneNumber: i + 1));
  }

  @override
  void disposeModel() {
    for (final zone in zones) {
      zone.zoneTextController.dispose();
      zone.verificationTimeController.dispose();
    }
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadZoneSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    for (int i = 0; i < 3; i++) {
      final key = 'z${i + 1}';
      final z = data[key] as Map<String, dynamic>?;
      if (z == null) continue;
      zones[i].type =
          (z['type'] as int?) == 1
              ? PanelValues.zoneTypeIsMtl5561
              : PanelValues.zoneTypeNone;
      zones[i].enabled =
          (z['enabled'] as bool?) == true
              ? PanelValues.yesOption
              : PanelValues.noOption;
      final dm = (z[StringConstants.isMTL5561] as int?) ?? 0;
      zones[i].mode = modeOptions[dm.clamp(0, modeOptions.length - 1)];
      zones[i].verificationTimeController.text =
          (z[StringConstants.verificationtime] as String?) ?? '0';
      zones[i].zoneTextController.text = (z['text'] as String?) ?? '';
    }
    if (manager != null) {
      applyZoneTestFlagsFromCacheMap(manager!, data);
    }
    _normalizeVerificationTimes();
  }

  void _normalizeVerificationTimes() {
    for (int i = 0; i < 3; i++) {
      final z = zones[i];
      if (z.mode == StringConstants.normal || z.mode == StringConstants.none) {
        z.verificationTimeController.text = '0';
      } else if (z.mode == StringConstants.immediate) {
        z.verificationTimeController.text = '30';
      }
    }
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    zones[0].type =
        manager!.zoneOneSetupType.value == 0 ? StringConstants.none : 'IS (MTL 5561)';
    zones[0].enabled = manager!.isZoneOneSetupEnabled.value ? StringConstants.yes : 'No';
    final int dm1 = manager!.zoneOneSetupDetectionMode.value;
    zones[0].mode =
        (dm1 >= 0 && dm1 < modeOptions.length) ? modeOptions[dm1] : modeOptions.first;
    zones[0].verificationTimeController.text =
        manager!.zoneOneSetupVerificationTime.value;
    zones[0].zoneTextController.text = manager!.zoneOneSetupText.value;

    zones[1].type =
        manager!.zoneTwoSetupType.value == 0 ? StringConstants.none : 'IS (MTL 5561)';
    zones[1].enabled = manager!.isZoneTwoSetupEnabled.value ? StringConstants.yes : 'No';
    final int dm2 = manager!.zoneTwoSetupDetectionMode.value;
    zones[1].mode =
        (dm2 >= 0 && dm2 < modeOptions.length) ? modeOptions[dm2] : modeOptions.first;
    zones[1].verificationTimeController.text =
        manager!.zoneTwoSetupVerificationTime.value;
    zones[1].zoneTextController.text = manager!.zoneTwoSetupText.value;

    zones[2].type =
        manager!.zoneThreeSetupType.value == 0 ? StringConstants.none : 'IS (MTL 5561)';
    zones[2].enabled = manager!.isZoneThreeSetupEnabled.value ? StringConstants.yes : 'No';
    final int dm3 = manager!.zoneThreeSetupDetectionMode.value;
    zones[2].mode =
        (dm3 >= 0 && dm3 < modeOptions.length) ? modeOptions[dm3] : modeOptions.first;
    zones[2].verificationTimeController.text =
        manager!.zoneThreeSetupVerificationTime.value;
    zones[2].zoneTextController.text = manager!.zoneThreeSetupText.value;

    _normalizeVerificationTimes();
    refreshUi();
  }

  @override
  void pushToManager() {
    final m = manager!;
    final snapshotTest = [
      m.isZoneOneSetupTest.value,
      m.isZoneTwoSetupTest.value,
      m.isZoneThreeSetupTest.value,
    ];
    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      final effectiveTest = zone.enabled == StringConstants.yes && snapshotTest[i];

      switch (i) {
        case 0:
          m.zoneOneSetupText.value = zone.zoneTextController.text;
          m.zoneOneSetupType.value = typeOptions.indexOf(zone.type);
          m.isZoneOneSetupEnabled.value = zone.enabled == StringConstants.yes;
          m.isZoneOneSetupTest.value = effectiveTest;
          m.zoneOneSetupVerificationTime.value = zone.verificationTimeController.text;
          m.zoneOneSetupDetectionMode.value = modeOptions.indexOf(zone.mode);
          break;

        case 1:
          m.zoneTwoSetupText.value = zone.zoneTextController.text;
          m.zoneTwoSetupType.value = typeOptions.indexOf(zone.type);
          m.isZoneTwoSetupEnabled.value = zone.enabled == StringConstants.yes;
          m.isZoneTwoSetupTest.value = effectiveTest;
          m.zoneTwoSetupVerificationTime.value = zone.verificationTimeController.text;
          m.zoneTwoSetupDetectionMode.value = modeOptions.indexOf(zone.mode);
          break;

        case 2:
          m.zoneThreeSetupText.value = zone.zoneTextController.text;
          m.zoneThreeSetupType.value = typeOptions.indexOf(zone.type);
          m.isZoneThreeSetupEnabled.value = zone.enabled == StringConstants.yes;
          m.isZoneThreeSetupTest.value = effectiveTest;
          m.zoneThreeSetupVerificationTime.value = zone.verificationTimeController.text;
          m.zoneThreeSetupDetectionMode.value = modeOptions.indexOf(zone.mode);
          break;
      }
    }
    syncZoneModeHexFromBleManager(m);
  }

  @override
  Future<void> save() =>
      PanelConfigCacheSync.saveZone(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() {
    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      if (zone.zoneTextController.text.length > 21) return false;
      final mode = zone.mode;
      if (mode == StringConstants.normal || mode == StringConstants.none) {
        if (zone.verificationTimeController.text != '0') return false;
      } else if (mode == StringConstants.verified) {
        final val = int.tryParse(zone.verificationTimeController.text);
        if (val == null || val < 10 || val > 60) return false;
      } else if (mode == StringConstants.immediate) {
        if (zone.verificationTimeController.text != '30') return false;
      }
    }
    return true;
  }

  @override
  void updateValidationErrors() {
    zoneTextErrors.clear();
    verificationErrors.clear();
    for (int i = 0; i < 3; i++) {
      final zone = zones[i];
      if (zone.zoneTextController.text.length > 21) {
        zoneTextErrors[i] =
            'Zone text must be at most 21 characters (currently ${zone.zoneTextController.text.length})';
      }
      final mode = zone.mode;
      if (mode == StringConstants.normal || mode == StringConstants.none) {
        if (zone.verificationTimeController.text != '0') {
          verificationErrors[i] = StringConstants.mustBe0ForImmediateNormalMode;
        }
      } else if (mode == StringConstants.verified) {
        final val = int.tryParse(zone.verificationTimeController.text);
        if (val == null || val < 10 || val > 60) {
          verificationErrors[i] = StringConstants.mustBeBetween10And60ForVerifiedMode;
        }
      } else if (mode == StringConstants.immediate) {
        if (zone.verificationTimeController.text != '30') {
          verificationErrors[i] = StringConstants.mustBe30ForConfirmedMode;
        }
      }
    }
  }

  // ---- UI intents ----

  void setType(int index, String v) {
    zones[index].type = v;
    refreshUi();
  }

  void setEnabled(int index, String v) {
    zones[index].enabled = v;
    if (v == 'No' && manager != null) {
      clearZoneTestOnManager(manager!, index);
    }
    refreshUi();
  }

  void setMode(int index, String v) {
    final zone = zones[index];
    zone.mode = v;
    if (v == StringConstants.normal || v == StringConstants.none) {
      zone.verificationTimeController.text = '0';
    } else if (v == StringConstants.immediate) {
      zone.verificationTimeController.text = '30';
    }
    zoneTextErrors.remove(index);
    verificationErrors.remove(index);
    refreshUi();
  }

  void onVerificationTimeChanged() => refreshUi();
}
