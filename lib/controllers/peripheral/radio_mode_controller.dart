import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

class RadioConfig {
  String enabled = StringConstants.no;
  String module = 'None';
  String advertise = StringConstants.no;
  String connection = StringConstants.no;
  String service = StringConstants.no;
  String programming = StringConstants.no;
  String boot = StringConstants.no;

  TextEditingController nameController = TextEditingController();
  TextEditingController numberController = TextEditingController();
}

/// Controller for the Radio Mode bottom sheet. Apply writes directly to the
/// manager (no cache persistence), so [save] is a no-op and the View calls
/// [pushToManager] on apply.
class RadioModeController extends PeripheralModeController {
  RadioModeController({required super.deviceId, required super.refreshTrigger});

  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];
  final List<String> moduleOptions = ['None', StringConstants.bluenrgMB];

  late RadioConfig radio;

  String? nameError;
  String? numberError;

  @override
  void initModel() {
    radio = RadioConfig();
  }

  @override
  void disposeModel() {
    radio.nameController.dispose();
    radio.numberController.dispose();
  }

  @override
  Future<Map<String, dynamic>?> loadCache() =>
      PeripheralSetupCache.loadRadioSetup(deviceId);

  @override
  void applyCachedData(Map<String, dynamic> data) {
    radio.enabled = (data['enabled'] as bool?) == true ? StringConstants.yes : StringConstants.no;
    final module = (data['module'] as int?) ?? 0;
    radio.module = module == 0 ? 'None' : StringConstants.bluenrgMB;
    radio.nameController.text = (data['name'] as String?) ?? '';
    radio.numberController.text = (data['number'] as String?) ?? '';
    radio.advertise = (data['advertise'] as bool?) == true ? StringConstants.yes : StringConstants.no;
    radio.connection = (data['connection'] as bool?) == true ? StringConstants.yes : StringConstants.no;
    radio.service = (data['service'] as bool?) == true ? StringConstants.yes : StringConstants.no;
    radio.programming = (data['programming'] as bool?) == true ? StringConstants.yes : StringConstants.no;
    radio.boot = (data['boot'] as bool?) == true ? StringConstants.yes : StringConstants.no;
  }

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;

    manager = Get.find<BleLogController>().bleManager;

    radio.enabled = manager!.isRadioSetupEnabled.value ? StringConstants.yes : StringConstants.no;
    radio.module = manager!.radioSetupModule.value == 0 ? 'None' : StringConstants.bluenrgMB;
    radio.nameController.text = manager!.radioSetupName.value;
    radio.numberController.text = manager!.radioSetupNo.value;
    radio.advertise = manager!.isRadioSetupAdvertised.value ? StringConstants.yes : StringConstants.no;
    radio.connection = manager!.isRadioSetupConnected.value ? StringConstants.yes : StringConstants.no;
    radio.service = manager!.isRadioSetupServiced.value ? StringConstants.yes : StringConstants.no;
    radio.programming = manager!.isRadioSetupProgrammed.value ? StringConstants.yes : StringConstants.no;
    radio.boot = manager!.isRadioSetupBooted.value ? StringConstants.yes : StringConstants.no;

    refreshUi();
  }

  @override
  void pushToManager() {
    manager!.isRadioSetupEnabled.value = true; // Fixed to Yes
    manager!.radioSetupModule.value = moduleOptions.indexOf(radio.module);
    manager!.radioSetupName.value = radio.nameController.text;
    manager!.radioSetupNo.value = radio.numberController.text;
    manager!.isRadioSetupAdvertised.value = radio.advertise == StringConstants.yes;
    manager!.isRadioSetupConnected.value = radio.connection == StringConstants.yes;
    manager!.isRadioSetupServiced.value = radio.service == StringConstants.yes;
    manager!.isRadioSetupProgrammed.value = radio.programming == StringConstants.yes;
    manager!.isRadioSetupBooted.value = radio.boot == StringConstants.yes;
  }

  @override
  Future<void> save() async {}

  @override
  bool computeIsValid() {
    if (radio.nameController.text.length > 21) return false;
    if (radio.numberController.text.isEmpty) return false;
    final number = int.tryParse(radio.numberController.text);
    if (number == null) return false;
    return true;
  }

  @override
  void updateValidationErrors() {
    nameError = null;
    numberError = null;

    if (radio.nameController.text.length > 21) {
      nameError =
          'Name must be at most 21 characters (currently ${radio.nameController.text.length})';
    }

    if (radio.numberController.text.isEmpty) {
      numberError = StringConstants.numberCannotBeEmpty;
    } else {
      final number = int.tryParse(radio.numberController.text);
      if (number == null) {
        numberError = StringConstants.invalidNumber;
      }
    }
  }

  // ---- UI intents ----

  void setModule(String v) {
    radio.module = v;
    refreshUi();
  }

  void setAdvertise(String v) {
    radio.advertise = v;
    refreshUi();
  }

  void setConnection(String v) {
    radio.connection = v;
    refreshUi();
  }

  void setService(String v) {
    radio.service = v;
    refreshUi();
  }

  void setProgramming(String v) {
    radio.programming = v;
    refreshUi();
  }

  void setBoot(String v) {
    radio.boot = v;
    refreshUi();
  }
}
