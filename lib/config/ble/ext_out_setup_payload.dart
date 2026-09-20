import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/ext_out_cfg_def.dart';

abstract final class ExtOutSetupPayload {
  static const int structOffset = ConfigSetupPayload.structOffset;

  static void writeToPacket(Uint8List packet, ExtOutCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static ExtOutCfgDef readFromPacket(List<int> payload) {
    return ExtOutCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, ExtOutCfgDef.byteLength),
    );
  }
}
