import 'package:flutter/material.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Controller for the General Module bottom sheet.
class GeneralModuleController extends PeripheralModeController {
  GeneralModuleController({
    required super.deviceId,
    required super.refreshTrigger,
  });

  final TextEditingController lvlTimeoutController = TextEditingController();

  String silenceBuzzerLevel = StringConstants.accessLevel1;
  String silenceSoundersLevel = StringConstants.accessLevel2;
  String resetLevel = StringConstants.accessLevel2;
  String faultLatching = StringConstants.no;

  final List<String> buzzerOptions = [
    StringConstants.accessLevel1,
    StringConstants.accessLevel2,
  ];
  final List<String> sounderOptions = [
    StringConstants.accessLevel2,
    StringConstants.accessLevel3,
  ];
  final List<String> resetOptions = [
    StringConstants.accessLevel2,
    StringConstants.accessLevel3,
  ];
  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];

  @override
  void initModel() {}

  @override
  void disposeModel() {
    lvlTimeoutController.dispose();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadGeneralModuleSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    lvlTimeoutController.text = (data['lvlTimeout'] as num?)?.toString() ?? '0';
    silenceBuzzerLevel =
        (data[StringConstants.silencebuzzerlevel] as String?) ?? buzzerOptions.first;
    silenceSoundersLevel =
        (data['silenceSoundersLevel'] as String?) ?? sounderOptions.first;
    resetLevel = (data['resetLevel'] as String?) ?? resetOptions.first;
    faultLatching =
        (data[StringConstants.silencesounderslevel] as String?) ?? yesNoOptions.first;
  }

  @override
  void loadFromManager() {
    if (manager == null) return;
    final bp = manager!.bleProcess;
    lvlTimeoutController.text = bp.generalModuleLvlTimeOut.value.toString();
    silenceBuzzerLevel =
        bp.generalModuleSilenceBuzzerLvl.value < buzzerOptions.length
            ? buzzerOptions[bp.generalModuleSilenceBuzzerLvl.value]
            : buzzerOptions.first;
    silenceSoundersLevel =
        bp.generalModuleSilenceSounderLvl.value < sounderOptions.length
            ? sounderOptions[bp.generalModuleSilenceSounderLvl.value]
            : sounderOptions.first;
    resetLevel =
        bp.generalModuleResetLvl.value < resetOptions.length
            ? resetOptions[bp.generalModuleResetLvl.value]
            : resetOptions.first;
    faultLatching =
        bp.generalModuleFaultLatching.value < yesNoOptions.length
            ? yesNoOptions[bp.generalModuleFaultLatching.value]
            : yesNoOptions.first;
    refreshUi();
  }

  @override
  void pushToManager() {
    if (manager == null) return;
    final bp = manager!.bleProcess;
    bp.generalModuleLvlTimeOut.value =
        int.tryParse(lvlTimeoutController.text) ?? 0;
    bp.generalModuleSilenceBuzzerLvl.value = buzzerOptions
        .indexOf(silenceBuzzerLevel)
        .clamp(0, buzzerOptions.length - 1);
    bp.generalModuleSilenceSounderLvl.value = sounderOptions
        .indexOf(silenceSoundersLevel)
        .clamp(0, sounderOptions.length - 1);
    bp.generalModuleResetLvl.value =
        resetOptions.indexOf(resetLevel).clamp(0, resetOptions.length - 1);
    bp.generalModuleFaultLatching.value = yesNoOptions
        .indexOf(faultLatching)
        .clamp(0, yesNoOptions.length - 1);
  }

  @override
  Future<void> save() async {
    await PeripheralSetupCache.saveGeneralModuleSetup(deviceId, {
      'lvlTimeout': int.tryParse(lvlTimeoutController.text) ?? 0,
      StringConstants.silencebuzzerlevel: silenceBuzzerLevel,
      'silenceSoundersLevel': silenceSoundersLevel,
      'resetLevel': resetLevel,
      StringConstants.silencesounderslevel: faultLatching,
    });
    refreshTrigger.value++;
  }

  @override
  bool computeIsValid() {
    final lvlTimeout = int.tryParse(lvlTimeoutController.text);
    if (lvlTimeout == null || lvlTimeout < 30 || lvlTimeout > 300) {
      return false;
    }
    return true;
  }

  @override
  void updateValidationErrors() {}

  // ---- UI intents ----

  void setSilenceBuzzerLevel(String v) {
    silenceBuzzerLevel = v;
    refreshUi();
  }

  void setSilenceSoundersLevel(String v) {
    silenceSoundersLevel = v;
    refreshUi();
  }

  void setResetLevel(String v) {
    resetLevel = v;
    refreshUi();
  }

  void setFaultLatching(String v) {
    faultLatching = v;
    refreshUi();
  }

  void onLvlTimeoutChanged() => refreshUi();
}
