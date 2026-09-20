import 'dart:typed_data';

import 'package:techno_switch_solar_app/config/system_config_limits.dart';
import 'package:techno_switch_solar_app/config/structs/struct_bytes.dart';
import 'package:techno_switch_solar_app/utils/peripherals/defaults/ble_module_defaults.dart';

/// Mirrors firmware `st_ble_module_cfg_def` (31 bytes, packed).
class BleModuleCfgDef {
  const BleModuleCfgDef({
    this.bleEnable = BleModuleDefaults.bleEnable,
    this.bleName = BleModuleDefaults.bleName,
    this.bleId = BleModuleDefaults.bleId,
    this.bleAdvEnable = BleModuleDefaults.bleAdvEnable,
  });

  static const int byteLength = 31;

  final int bleEnable;
  final String bleName;
  final String bleId;
  final int bleAdvEnable;

  factory BleModuleCfgDef.fromBytes(Uint8List bytes, {int offset = 0}) {
    if (offset < 0 || offset + byteLength > bytes.length) {
      throw RangeError(
        'BleModuleCfgDef requires $byteLength bytes at offset $offset',
      );
    }
    return BleModuleCfgDef(
      bleEnable: bytes[offset],
      bleName: StructBytes.readFixedText(
        bytes,
        offset + 1,
        SystemConfigLimits.bleAdvNameLength,
      ),
      bleId: StructBytes.readFixedAsciiDigits(
        bytes,
        offset + 22,
        SystemConfigLimits.bleAdvIdLength,
      ),
      bleAdvEnable: bytes[offset + 30],
    );
  }

  factory BleModuleCfgDef.fromCacheMap(Map<String, dynamic> data) {
    return BleModuleCfgDef(
      bleEnable:
          (data['bleEnable'] as num?)?.toInt() ?? BleModuleDefaults.bleEnable,
      bleName: (data['bleName'] as String?) ?? BleModuleDefaults.bleName,
      bleId: (data['bleId'] as String?) ?? BleModuleDefaults.bleId,
      bleAdvEnable:
          (data['bleAdvEnable'] as num?)?.toInt() ??
          BleModuleDefaults.bleAdvEnable,
    );
  }

  Uint8List toBytes() {
    final buf = Uint8List(byteLength);
    buf[0] = bleEnable & 0xFF;
    StructBytes.writeFixedText(
      buf,
      1,
      bleName,
      SystemConfigLimits.bleAdvNameLength,
    );
    StructBytes.writeFixedAsciiDigits(
      buf,
      22,
      bleId,
      SystemConfigLimits.bleAdvIdLength,
    );
    buf[30] = bleAdvEnable & 0xFF;
    return buf;
  }

  Map<String, dynamic> toCacheMap() => {
    'bleEnable': bleEnable,
    'bleName': bleName,
    'bleId': bleId,
    'bleAdvEnable': bleAdvEnable,
  };
}
