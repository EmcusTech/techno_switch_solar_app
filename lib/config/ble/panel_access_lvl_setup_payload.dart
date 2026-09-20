import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/panel_access_lvl_cfg_def.dart';

abstract final class PanelAccessLvlSetupPayload {
  static const int structOffset = ConfigSetupPayload.structOffset;

  static void writeToPacket(Uint8List packet, PanelAccessLvlCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static PanelAccessLvlCfgDef readFromPacket(List<int> payload) {
    return PanelAccessLvlCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(
        payload,
        PanelAccessLvlCfgDef.byteLength,
      ),
    );
  }
}
