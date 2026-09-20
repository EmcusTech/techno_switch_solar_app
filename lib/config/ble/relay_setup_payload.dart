import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/relay_cfg_def.dart';

abstract final class RelaySetupPayload {
  static const int structOffset = ConfigSetupPayload.structOffset;

  static void writeToPacket(Uint8List packet, RelayCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static RelayCfgDef readFromPacket(List<int> payload) {
    return RelayCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, RelayCfgDef.byteLength),
    );
  }
}
