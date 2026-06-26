import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:techno_switch_solar_app/ble/controller/ble_log_controller.dart';
import 'package:techno_switch_solar_app/controllers/peripheral/peripheral_mode_controller.dart';
import 'package:techno_switch_solar_app/models/l_bus_setup_data_model.dart';
import 'package:techno_switch_solar_app/panel_config/panel_config_cache_sync.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';
import 'package:techno_switch_solar_app/utils/constants/string_constants.dart';

/// Controller for the L-Bus bottom sheet. Unlike the other peripheral sheets,
/// L-Bus is list-based (31 buses, selected via [selectedBus]) and listens to the
/// manager's `lBusSetupDataList`, so [loadData] is overridden.
class LBusController extends PeripheralModeController {
  LBusController({required super.deviceId, required super.refreshTrigger});

  int selectedBus = 1;

  final List<String> yesNoOptions = [StringConstants.no, StringConstants.yes];
  final List<String> productOptions = ['None', StringConstants.rhino103r];

  String enabled = StringConstants.no;
  String idLed = StringConstants.no;
  String product = 'None';

  late final TextEditingController deviceTextController;
  late final TextEditingController idController;
  late final TextEditingController revisionController;
  late final TextEditingController productRevController;
  late final TextEditingController hardwareController;
  late final TextEditingController firmwareController;
  late final TextEditingController dateController;
  late final TextEditingController protocolController;

  @override
  void initModel() {
    deviceTextController = TextEditingController();
    idController = TextEditingController();
    revisionController = TextEditingController();
    productRevController = TextEditingController();
    hardwareController = TextEditingController(text: '-');
    firmwareController = TextEditingController(text: '-');
    dateController = TextEditingController();
    protocolController = TextEditingController();
  }

  @override
  void disposeModel() {
    manager?.lBusSetupDataList.removeListener(_onListChanged);
    deviceTextController.dispose();
    idController.dispose();
    revisionController.dispose();
    productRevController.dispose();
    hardwareController.dispose();
    firmwareController.dispose();
    dateController.dispose();
    protocolController.dispose();
  }

  void _onListChanged() => loadFromManager();

  @override
  Future<void> loadData() async {
    if (Get.isRegistered<BleLogController>()) {
      manager = Get.find<BleLogController>().bleManager;
      manager?.lBusSetupDataList.addListener(_onListChanged);
    }
    if (manager?.isConnected == true) {
      loadFromManager();
      return;
    }
    final cached = await PeripheralSetupCache.loadLBusSetup(deviceId);
    if (cached != null && cached.isNotEmpty) {
      final list = cached.map((e) => LBusSetupData.fromJson(e)).toList();
      while (list.length < 31) {
        list.add(const LBusSetupData());
      }
      manager?.lBusSetupDataList.value = list;
    }
    loadFromManager();
  }

  // Unused for L-Bus (see [loadData] override), required by the base class.
  @override
  Future<Map<String, dynamic>?> loadCache() async => null;

  @override
  void applyCachedData(Map<String, dynamic> data) {}

  @override
  void loadFromManager() {
    if (!Get.isRegistered<BleLogController>()) return;
    manager = Get.find<BleLogController>().bleManager;

    final index = selectedBus - 1;
    if (index < 0 || index >= manager!.lBusSetupDataList.value.length) {
      return;
    }

    final data = manager!.lBusSetupDataList.value[index];

    enabled = yesNoOptions.contains(data.enabled) ? data.enabled : yesNoOptions.first;
    idLed = yesNoOptions.contains(data.idLed) ? data.idLed : yesNoOptions.first;
    product =
        productOptions.contains(data.product) ? data.product : productOptions.first;
    deviceTextController.text = data.deviceText;
    idController.text = data.id.toString();
    revisionController.text = data.revision.toString();
    productRevController.text = data.productRev;
    hardwareController.text = data.hardware.isEmpty ? '-' : data.hardware;
    firmwareController.text = data.firmware.isEmpty ? '-' : data.firmware;
    dateController.text = data.date;
    protocolController.text = data.protocol.toString();
    refreshUi();
  }

  void _saveCurrentBusToManager() {
    if (manager == null) return;
    final index = selectedBus - 1;
    if (index < 0 || index >= manager!.lBusSetupDataList.value.length) return;

    final existing = manager!.lBusSetupDataList.value[index];
    final updated = existing.copyWith(
      enabled: enabled,
      idLed: idLed,
      product: product,
      deviceText: deviceTextController.text,
      id: int.tryParse(idController.text) ?? existing.id,
      revision: int.tryParse(revisionController.text) ?? existing.revision,
      productRev: productRevController.text,
      hardware: hardwareController.text,
      firmware: firmwareController.text,
      date: dateController.text,
      protocol: int.tryParse(protocolController.text) ?? existing.protocol,
    );

    final list = List<LBusSetupData>.from(manager!.lBusSetupDataList.value);
    list[index] = updated;
    manager!.lBusSetupDataList.value = list;
  }

  @override
  void pushToManager() => _saveCurrentBusToManager();

  @override
  Future<void> save() =>
      PanelConfigCacheSync.saveLBus(manager!, deviceId, refreshTrigger);

  @override
  bool computeIsValid() => deviceTextController.text.length <= 21;

  @override
  void updateValidationErrors() {}

  // ---- UI intents ----

  void setEnabled(String v) {
    enabled = v;
    refreshUi();
  }

  void setIdLed(String v) {
    idLed = v;
    refreshUi();
  }

  void setProduct(String v) {
    product = v;
    refreshUi();
  }

  void onDeviceTextChanged() => refreshUi();

  void selectBus(int number) {
    _saveCurrentBusToManager();
    selectedBus = number;
    loadFromManager();
  }
}
