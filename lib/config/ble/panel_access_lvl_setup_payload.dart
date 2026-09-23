import 'dart:typed_data';

import 'package:techno_switch_solar_app/ble/ble_manager.dart';
import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/panel_access_lvl_cfg_def.dart';
import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/models/access_code_mode_model.dart';

/// SETUP_ACCESS_CODE data section inside the 216-byte BLE frame.
///
/// One command carries a single `st_panel_access_lvl_def` (31 bytes) at [13].
abstract final class PanelAccessLvlSetupPayload {
  static const int commandOffset = ConfigSetupPayload.commandOffset;
  static const int structOffset = ConfigSetupPayload.structOffset;

  static const int byteLength = PanelAccessLvlCfgDef.byteLength;

  static PanelAccessLvlCfgDef fromBleManager(BleManager manager, int index) {
    if (index < 0 || index >= SystemConfigLimits.maxPanelAccCodeNo) {
      throw RangeError(
        'access code index must be 0..${SystemConfigLimits.maxPanelAccCodeNo - 1}, got $index',
      );
    }

    final list = manager.accessCodeSetupDataList.value;
    if (index >= list.length) {
      return PanelAccessLvlCfgDef(accessCodeNo: index + 1);
    }

    return PanelAccessLvlCfgDef.fromSetupData(list[index]);
  }

  static void applyToBleManager(
    BleManager manager,
    int index,
    PanelAccessLvlCfgDef config,
  ) {
    if (index < 0 || index >= SystemConfigLimits.maxPanelAccCodeNo) {
      throw RangeError(
        'access code index must be 0..${SystemConfigLimits.maxPanelAccCodeNo - 1}, got $index',
      );
    }

    final updated = List<AccessCodeSetupData>.from(
      manager.accessCodeSetupDataList.value,
    );
    while (updated.length < SystemConfigLimits.maxPanelAccCodeNo) {
      updated.add(AccessCodeSetupData(accessCodeNo: updated.length + 1));
    }
    updated[index] = config.toSetupData();
    manager.accessCodeSetupDataList.value = updated;
  }

  static AccessCodeSetupData readSetupDataFromPacket(List<int> payload) {
    return readFromPacket(payload).toSetupData();
  }

  static void writeToPacket(Uint8List packet, PanelAccessLvlCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static PanelAccessLvlCfgDef readFromPacket(List<int> payload) {
    return PanelAccessLvlCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, byteLength),
    );
  }
}
