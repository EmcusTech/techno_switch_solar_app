import 'package:flutter/foundation.dart';
import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_cache_to_ble.dart';
import 'package:techno_switch_solar_app/utils/peripherals/peripheral_config_snapshot.dart';
import 'package:techno_switch_solar_app/utils/storage/peripheral_setup_cache.dart';

class PanelConfigRefreshNotifiers {
  PanelConfigRefreshNotifiers({
    required this.relay,
    required this.input,
    required this.zone,
    required this.extOut,
    required this.sounder,
    required this.serviceDue,
    required this.accessCode,
    required this.panelInfo,
    required this.generalModule,
  });

  final ValueNotifier<int> relay;
  final ValueNotifier<int> input;
  final ValueNotifier<int> zone;
  final ValueNotifier<int> extOut;
  final ValueNotifier<int> sounder;
  final ValueNotifier<int> serviceDue;
  final ValueNotifier<int> accessCode;
  final ValueNotifier<int> panelInfo;
  final ValueNotifier<int> generalModule;

  void bumpAll() {
    relay.value++;
    input.value++;
    zone.value++;
    extOut.value++;
    sounder.value++;
    serviceDue.value++;
    accessCode.value++;
    panelInfo.value++;
    generalModule.value++;
  }
}

class PanelConfigCacheSync {
  PanelConfigCacheSync._();

  static Future<void> saveRelay(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveRelaySetup(
      deviceId,
      PeripheralConfigSnapshot.relayMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveInput(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveInputSetup(
      deviceId,
      PeripheralConfigSnapshot.inputMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveZone(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveZoneSetup(
      deviceId,
      PeripheralConfigSnapshot.zoneMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveExtOut(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveExtOutSetup(
      deviceId,
      PeripheralConfigSnapshot.extOutMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveSounder(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveSounderSetup(
      deviceId,
      PeripheralConfigSnapshot.sounderMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveServiceDue(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveServiceDueSetup(
      deviceId,
      PeripheralConfigSnapshot.serviceDueMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveRadio(
    BleManager m,
    String deviceId,
    ValueNotifier<int> zoneTrigger,
  ) async {
    await PeripheralSetupCache.saveRadioSetup(
      deviceId,
      PeripheralConfigSnapshot.radioMap(m),
    );
    zoneTrigger.value++;
  }

  static Future<void> saveModule(BleManager m, String deviceId) async {
    await PeripheralSetupCache.saveModuleSetup(
      deviceId,
      PeripheralConfigSnapshot.moduleMap(m),
    );
  }

  static Future<void> saveLBus(
    BleManager m,
    String deviceId,
    ValueNotifier<int> zoneTrigger,
  ) async {
    await PeripheralSetupCache.saveLBusSetup(
      deviceId,
      PeripheralConfigSnapshot.lBusList(m),
    );
    zoneTrigger.value++;
  }

  static Future<void> saveAccessCode(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveAccessCodeSetup(
      deviceId,
      PeripheralConfigSnapshot.accessCodeList(m),
    );
    trigger.value++;
  }

  static Future<void> savePanelInfo(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.savePanelInfoSetup(
      deviceId,
      PeripheralConfigSnapshot.panelInfoMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveGeneralModule(
    BleManager m,
    String deviceId,
    ValueNotifier<int> trigger,
  ) async {
    await PeripheralSetupCache.saveGeneralModuleSetup(
      deviceId,
      PeripheralConfigSnapshot.generalModuleMap(m),
    );
    trigger.value++;
  }

  static Future<void> saveAllFromBle(
    BleManager m,
    String deviceId,
    PanelConfigRefreshNotifiers n,
  ) async {
    await saveRelay(m, deviceId, n.relay);
    await saveInput(m, deviceId, n.input);
    await saveZone(m, deviceId, n.zone);
    await saveExtOut(m, deviceId, n.extOut);
    await saveSounder(m, deviceId, n.sounder);
    await saveServiceDue(m, deviceId, n.serviceDue);
    await saveModule(m, deviceId);
    await saveLBus(m, deviceId, n.zone);
    await saveAccessCode(m, deviceId, n.accessCode);
    await savePanelInfo(m, deviceId, n.panelInfo);
    await saveGeneralModule(m, deviceId, n.generalModule);
  }

  /// Rehydrates in-memory BLE state from local cache (e.g. when the user skips
  /// a post-connect config download).
  static Future<void> restoreAllFromCacheToBle(
    BleManager m,
    String deviceId, [
    PanelConfigRefreshNotifiers? n,
  ]) async {
    await PeripheralCacheToBle.applyToBleManager(m, deviceId);
    n?.bumpAll();
  }
}
