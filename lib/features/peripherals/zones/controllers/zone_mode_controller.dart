import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/config/ble/zone_setup_payload_debug.dart';
import 'package:techno_switch_solar_app/config/ui/zone_config_options.dart';
import 'package:techno_switch_solar_app/config/ui/zone_config_ui_bridge.dart';
import 'package:techno_switch_solar_app/features/peripherals/shared/controllers/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/zone_defaults.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/zone_setup_manager_sync.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class ZoneConfig {
  final int zoneNumber;

  String type = ZoneDefaults.typeLabel;
  String enabled = ZoneDefaults.enabledLabel;
  String mode = ZoneDefaults.modeLabel;

  TextEditingController zoneTextController = TextEditingController();
  TextEditingController verificationTimeController = TextEditingController();

  ZoneConfig({required this.zoneNumber});
}

/// Controller for the Zone Mode bottom sheet.
class ZoneModeController extends PeripheralModeController {
  ZoneModeController({required super.deviceId, required super.refreshTrigger});

  List<String> get typeOptions => ZoneConfigOptions.typeOptions;

  List<String> get yesNoOptions => ZoneConfigOptions.yesNoOptions;

  List<String> get modeOptions => ZoneConfigOptions.modeOptions;

  late List<ZoneConfig> zones;

  final Map<int, String?> zoneTextErrors = {};
  final Map<int, String?> verificationErrors = {};

  @override
  void initModel() {
    zones = List.generate(3, (i) {
      final zone = ZoneConfig(zoneNumber: i + 1);
      _applyUiStateToZone(zone, ZoneUiState.defaults(zoneNumber: i + 1));
      return zone;
    });
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
      _applyUiStateToZone(
        zones[i],
        ZoneConfigUiBridge.fromCacheMap(z, zoneNumber: i + 1),
      );
    }
    if (manager != null) {
      applyZoneTestFlagsFromCacheMap(manager!, data);
    }
    _normalizeVerificationTimes();
  }

  void _normalizeVerificationTimes() {
    for (int i = 0; i < 3; i++) {
      final z = zones[i];
      if (z.mode == StringConstants.immediate ||
          z.mode == StringConstants.normal) {
        z.verificationTimeController.text = '0';
      } else if (z.mode == StringConstants.confirmed) {
        z.verificationTimeController.text = '30';
      }
    }
  }

  bool _requiresZeroVerification(String mode) =>
      mode == StringConstants.immediate || mode == StringConstants.normal;

  bool _requiresConfirmedVerification(String mode) =>
      mode == StringConstants.confirmed;

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    for (int i = 0; i < 3; i++) {
      _applyUiStateToZone(
        zones[i],
        ZoneConfigUiBridge.fromBleProcess(manager!.bleProcess, i),
      );
    }

    _normalizeVerificationTimes();
    refreshUi();
  }

  ZoneUiState _currentUiState(int index) {
    final zone = zones[index];
    return ZoneUiState(
      zoneNumber: zone.zoneNumber,
      type: zone.type,
      enabled: zone.enabled,
      mode: zone.mode,
      zoneText: zone.zoneTextController.text,
      verificationTime: zone.verificationTimeController.text,
    );
  }

  void _applyUiStateToZone(ZoneConfig zone, ZoneUiState ui) {
    zone.type = ui.type;
    zone.enabled = ui.enabled;
    zone.mode = ui.mode;
    zone.zoneTextController.text = ui.zoneText;
    zone.verificationTimeController.text = ui.verificationTime;
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
      final ui = _currentUiState(i);
      final effectiveTest =
          ZoneConfigOptions.yesNoValue(ui.enabled) && snapshotTest[i];
      ZoneConfigUiBridge.applyToBleProcess(
        ui,
        m.bleProcess,
        test: effectiveTest,
      );
    }

    if (kDebugMode) {
      ZoneSetupPayloadDebug.printApplyFrames(m);
    }
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
      if (_requiresZeroVerification(mode)) {
        if (zone.verificationTimeController.text != '0') return false;
      } else if (mode == StringConstants.verified) {
        final val = int.tryParse(zone.verificationTimeController.text);
        if (val == null || val < 10 || val > 60) return false;
      } else if (_requiresConfirmedVerification(mode)) {
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
      if (_requiresZeroVerification(mode)) {
        if (zone.verificationTimeController.text != '0') {
          verificationErrors[i] = StringConstants.mustBe0ForImmediateNormalMode;
        }
      } else if (mode == StringConstants.verified) {
        final val = int.tryParse(zone.verificationTimeController.text);
        if (val == null || val < 10 || val > 60) {
          verificationErrors[i] =
              StringConstants.mustBeBetween10And60ForVerifiedMode;
        }
      } else if (_requiresConfirmedVerification(mode)) {
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
    if (_requiresZeroVerification(v)) {
      zone.verificationTimeController.text = '0';
    } else if (_requiresConfirmedVerification(v)) {
      zone.verificationTimeController.text = '30';
    }
    zoneTextErrors.remove(index);
    verificationErrors.remove(index);
    refreshUi();
  }

  void onVerificationTimeChanged() => refreshUi();
}
