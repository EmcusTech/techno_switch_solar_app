import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/ble/config_setup_payload.dart';
import 'package:techno_switch_solar_app/config/structs/panel_properties_cfg_def.dart';

abstract final class PanelPropertiesSetupPayload {
  static const int structOffset = ConfigSetupPayload.structOffset;

  static void writeToPacket(Uint8List packet, PanelPropertiesCfgDef config) {
    ConfigSetupPayload.writeStruct(packet, config.toBytes());
  }

  static PanelPropertiesCfgDef readFromPacket(List<int> payload) {
    return PanelPropertiesCfgDef.fromBytes(
      ConfigSetupPayload.readStructBytes(
        payload,
        PanelPropertiesCfgDef.byteLength,
      ),
    );
  }
}
