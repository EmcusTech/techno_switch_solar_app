import 'package:Technoswitch/config/ble/config_setup_payload.dart';
import 'package:Technoswitch/config/structs/module_id_data_def.dart';

/// Module-id response data inside the 216-byte BLE frame.
///
/// `st_module_id_data_def` (30 bytes) starts at [13].
abstract final class ModuleIdPayload {
  static const int structOffset = ConfigSetupPayload.structOffset;
  static const int byteLength = ModuleIdDataDef.byteLength;

  static ModuleIdDataDef readFromPacket(List<int> payload) {
    final bytes = ConfigSetupPayload.readStructBytes(payload, byteLength);
    return ModuleIdDataDef.fromBytes(bytes);
  }

  static void logResponse(List<int> payload) {
    try {
      final config = readFromPacket(payload);
      print(
        'MODULE_ID st_module_id_data_def: '
        'moduleTypeId=${config.moduleTypeId} '
        'moduleType=${config.moduleType} '
        'moduleRev=${config.moduleRev} '
        'moduleName="${config.moduleName}" '
        'hardware=${config.hdwMajor}.${config.hdwMinor}.${config.hdwOption}.${config.hdwVrsn} '
        'software=${config.swMajor}.${config.swMinor}.${config.swRelease}.${config.swBuild} '
        'swDate=${config.swDate} '
        'swYear=${config.swYear} '
        'swMonth=${config.swMonth} '
        'swDay=${config.swDay} '
        'protocol=${config.swProtocol}',
      );
    } catch (e) {
      print('MODULE_ID st_module_id_data_def: failed to read response: $e');
    }
  }
}
