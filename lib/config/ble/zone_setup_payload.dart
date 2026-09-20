import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/zone_cfg_def.dart';

abstract final class ZoneSetupPayload {
  static const int structOffset = ConfigSetupPayload.structOffset;

  static void writeToPacket(Uint8List packet, ZoneCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static ZoneCfgDef readFromPacket(List<int> payload) {
    return ZoneCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(payload, ZoneCfgDef.byteLength),
    );
  }
}
