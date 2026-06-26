import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

/// Controller for the Access Codes bottom sheet.
///
/// Access codes are stored as a list of [AccessCodeSetupData] in the
/// `BleManager`. Unlike the standard peripheral sheets there is no
/// `PanelConfigCacheSync` save on apply: the View pushes the edited slot back
/// into the manager list and calls `onApply`. Duplicate detection is exposed as
/// a decision (the dialog stays in the View).
class AccessCodeController extends PeripheralModeController {
  AccessCodeController({required super.deviceId, required super.refreshTrigger});

  final List<String> accessLevelNames = const [
    StringConstants.notUsed,
    StringConstants.untrainedUser,
    StringConstants.authorisedUser,
    StringConstants.commissioning,
  ];

  final TextEditingController accessLevelController = TextEditingController();
  final TextEditingController accessCodeController = TextEditingController();

  int selectedCode = 1;
  bool isAccessCodeEnabled = true;
  String accessLevelName = StringConstants.notUsed;

  void _onListChanged() => loadFromManager();

  @override
  void initModel() {}

  @override
  void disposeModel() {
    manager?.accessCodeSetupDataList.removeListener(_onListChanged);
    accessLevelController.dispose();
    accessCodeController.dispose();
  }

  /// List-based load: hydrate the manager list from cache, then read the
  /// selected slot. Mirrors the original `_loadData`.
  @override
  Future<void> loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
      manager?.accessCodeSetupDataList.addListener(_onListChanged);
    }
    final cached = await PeripheralSetupCache.loadAccessCodeSetup(deviceId);
    if (cached != null && cached.isNotEmpty) {
      final list = cached.map((e) => AccessCodeSetupData.fromJson(e)).toList();
      while (list.length < 8) {
        list.add(const AccessCodeSetupData());
      }
      manager?.accessCodeSetupDataList.value = list;
    }
    loadFromManager();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() async => null;

  @override
  void applyCachedData(Map<String, dynamic> data) {}

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    final index = selectedCode - 1;
    if (index < 0 || index >= manager!.accessCodeSetupDataList.value.length) {
      return;
    }

    final data = manager!.accessCodeSetupDataList.value[index];

    accessLevelController.text = data.accessLevel.toString();
    accessLevelName =
        accessLevelNames.contains(data.accessLevelName)
            ? data.accessLevelName
            : (data.accessLevel >= 0 &&
                data.accessLevel < accessLevelNames.length)
            ? accessLevelNames[data.accessLevel]
            : accessLevelNames.first;
    accessCodeController.text = data.accessCode;
    refreshUi();
  }

  @override
  void pushToManager() {
    if (manager == null) return;
    final index = selectedCode - 1;
    if (index < 0 || index >= manager!.accessCodeSetupDataList.value.length) {
      return;
    }

    final existing = manager!.accessCodeSetupDataList.value[index];
    final levelIndex = accessLevelNames.indexOf(accessLevelName);
    final level = levelIndex >= 0 ? levelIndex : existing.accessLevel;

    final updated = existing.copyWith(
      accessLevel: level,
      accessLevelName: accessLevelName,
      accessCode: accessCodeController.text,
    );

    final list = List<AccessCodeSetupData>.from(
      manager!.accessCodeSetupDataList.value,
    );
    list[index] = updated;
    manager!.accessCodeSetupDataList.value = list;
  }

  @override
  Future<void> save() async {}

  @override
  bool computeIsValid() {
    if (accessLevelName == accessLevelNames.first) {
      return true;
    }
    final code = int.tryParse(accessCodeController.text);
    if (code == null || code < 1 || code > 99999999) return false;
    return true;
  }

  @override
  void updateValidationErrors() {}

  // ---- Decisions (View handles the dialog) ----

  /// Returns the 1-based slot that already holds the entered code, or null when
  /// there is no duplicate.
  int? findDuplicateAccessCodeSlot() {
    if (manager == null) return null;
    if (accessLevelName == accessLevelNames.first) return null;

    final enteredCode = int.tryParse(accessCodeController.text.trim());
    if (enteredCode == null) return null;

    final currentIndex = selectedCode - 1;
    final list = manager!.accessCodeSetupDataList.value;

    for (var i = 0; i < list.length; i++) {
      if (i == currentIndex) continue;

      final other = list[i];
      if (other.accessLevelName == accessLevelNames.first) continue;

      final otherCode = int.tryParse(other.accessCode.trim());
      if (otherCode == null) continue;

      if (otherCode == enteredCode) {
        return i + 1;
      }
    }

    return null;
  }

  // ---- UI intents ----

  void setAccessLevelName(String v) {
    accessLevelName = v;
    final index = accessLevelNames.indexOf(v);
    accessLevelController.text = index.toString();
    if (v == accessLevelNames.first) {
      isAccessCodeEnabled = false;
      accessCodeController.clear();
    } else {
      isAccessCodeEnabled = true;
    }
    refreshUi();
  }

  void onAccessCodeChanged() => refreshUi();

  void selectCode(int number) {
    pushToManager();
    selectedCode = number;
    loadFromManager();
  }
}
