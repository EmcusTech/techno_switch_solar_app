import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/ble_module_cfg_def.dart';

abstract final class BleModuleSetupPayload {
  static const int structOffset = ConfigSetupPayload.structOffset;

  static void writeToPacket(Uint8List packet, BleModuleCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static BleModuleCfgDef readFromPacket(List<int> payload) {
    return BleModuleCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, BleModuleCfgDef.byteLength),
    );
  }
}
